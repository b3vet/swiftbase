import Foundation

/// Errors that can occur during query parsing
public enum QueryParseError: Error, CustomStringConvertible {
    case invalidOperator(String)
    case invalidFieldName(String)
    case invalidValue(String)
    case unsupportedOperator(String)
    case invalidLogicalExpression(String)
    case missingRequiredField(String)

    public var description: String {
        switch self {
        case .invalidOperator(let op):
            return "Invalid operator: \(op)"
        case .invalidFieldName(let field):
            return "Invalid field name: \(field)"
        case .invalidValue(let msg):
            return "Invalid value: \(msg)"
        case .unsupportedOperator(let op):
            return "Unsupported operator: \(op)"
        case .invalidLogicalExpression(let msg):
            return "Invalid logical expression: \(msg)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}

/// Parses MongoDB-style queries into SQL-compatible structures
public struct QueryParser: Sendable {
    private let logger: LoggerService

    public init() {
        self.logger = LoggerService.shared
    }

    /// Parse a MongoQuery into a ParsedQuery structure
    public func parse(_ mongoQuery: MongoQuery?) throws -> ParsedQuery {
        guard let mongoQuery = mongoQuery else {
            return ParsedQuery(conditions: [])
        }

        // Parse where clause
        let conditions = try parseWhereClause(mongoQuery.where ?? [:])

        // Parse select fields
        let selectFields = parseSelectFields(mongoQuery.select)

        // Parse order by
        let orderBy = mongoQuery.orderBy ?? [:]

        return ParsedQuery(
            conditions: conditions,
            logicalOperator: nil, // Determined during WHERE clause parsing
            orderBy: orderBy,
            limit: mongoQuery.limit,
            offset: mongoQuery.offset,
            select: selectFields,
            distinct: mongoQuery.distinct
        )
    }

    /// Parse the where clause into query conditions
    private func parseWhereClause(_ whereClause: [String: AnyCodable]) throws -> [QueryCondition] {
        var conditions: [QueryCondition] = []

        for (key, value) in whereClause {
            // Check if this is a logical operator
            if let logicalOp = QueryOperator(rawValue: key) {
                if logicalOp.isLogicalOperator {
                    let logicalConditions = try parseLogicalOperator(logicalOp, value: value.value)
                    conditions.append(contentsOf: logicalConditions)
                    continue
                }
            }

            // Otherwise, parse as a field condition
            let fieldConditions = try parseFieldCondition(field: key, value: value.value)
            conditions.append(contentsOf: fieldConditions)
        }

        return conditions
    }

    /// Parse a single field condition (can expand to multiple conditions)
    private func parseFieldCondition(field: String, value: Any) throws -> [QueryCondition] {
        // Validate field name (prevent SQL injection)
        try validateFieldName(field)

        // If value is a dictionary, it contains operators
        if let operatorDict = value as? [String: Any] {
            var conditions: [QueryCondition] = []

            for (opKey, opValue) in operatorDict {
                guard let queryOp = QueryOperator(rawValue: opKey) else {
                    throw QueryParseError.invalidOperator(opKey)
                }

                let condition = try createCondition(
                    field: field,
                    operator: queryOp,
                    value: opValue
                )
                conditions.append(condition)
            }

            return conditions
        }

        // Simple equality check
        return [QueryCondition(field: field, operator: .eq, value: value)]
    }

    /// Parse logical operators ($and, $or, $not)
    private func parseLogicalOperator(_ operator: QueryOperator, value: Any) throws -> [QueryCondition] {
        switch `operator` {
        case .and, .or:
            // $and and $or expect an array of conditions
            guard let array = value as? [[String: Any]] else {
                throw QueryParseError.invalidLogicalExpression(
                    "\(`operator`.rawValue) expects an array of conditions"
                )
            }

            var allConditions: [QueryCondition] = []
            for conditionDict in array {
                for (field, fieldValue) in conditionDict {
                    let conditions = try parseFieldCondition(field: field, value: fieldValue)
                    allConditions.append(contentsOf: conditions)
                }
            }

            return allConditions

        case .not:
            // $not expects a single condition
            guard let dict = value as? [String: Any] else {
                throw QueryParseError.invalidLogicalExpression("$not expects a condition object")
            }

            var allConditions: [QueryCondition] = []
            for (field, fieldValue) in dict {
                let conditions = try parseFieldCondition(field: field, value: fieldValue)
                allConditions.append(contentsOf: conditions)
            }

            return allConditions

        default:
            throw QueryParseError.unsupportedOperator(`operator`.rawValue)
        }
    }

    /// Create a query condition from an operator and value
    private func createCondition(
        field: String,
        operator: QueryOperator,
        value: Any
    ) throws -> QueryCondition {
        // Validate the value based on the operator
        switch `operator` {
        case .in, .nin, .all:
            // These operators expect arrays
            guard value is [Any] else {
                throw QueryParseError.invalidValue("\(`operator`.rawValue) expects an array")
            }

        case .exists:
            // $exists expects a boolean
            guard value is Bool else {
                throw QueryParseError.invalidValue("$exists expects a boolean")
            }

        case .type:
            // $type expects a string
            guard value is String else {
                throw QueryParseError.invalidValue("$type expects a string")
            }

        case .regex:
            // $regex expects a string
            guard value is String else {
                throw QueryParseError.invalidValue("$regex expects a string")
            }

        case .size:
            // $size expects an integer
            guard value is Int else {
                throw QueryParseError.invalidValue("$size expects an integer")
            }

        case .mod:
            // $mod expects an array of [divisor, remainder]
            guard let array = value as? [Int], array.count == 2 else {
                throw QueryParseError.invalidValue("$mod expects [divisor, remainder]")
            }

        default:
            break
        }

        return QueryCondition(field: field, operator: `operator`, value: value)
    }

    /// Parse select fields
    private func parseSelectFields(_ select: SelectFields?) -> [String]? {
        guard let select = select else {
            return nil
        }

        switch select {
        case .array(let fields):
            return fields

        case .dictionary(let dict):
            // Convert dictionary format to array (include fields with value 1)
            return dict.compactMap { key, value in
                value == 1 ? key : nil
            }
        }
    }

    /// Validate field name to prevent SQL injection
    private func validateFieldName(_ field: String) throws {
        // Field names should contain only alphanumeric characters, underscores, and dots
        let validPattern = "^[a-zA-Z0-9_.]+$"
        let regex = try NSRegularExpression(pattern: validPattern)
        let range = NSRange(field.startIndex..., in: field)

        guard regex.firstMatch(in: field, range: range) != nil else {
            throw QueryParseError.invalidFieldName(field)
        }

        // Prevent SQL keywords as field names
        let sqlKeywords = [
            "SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER",
            "TABLE", "FROM", "WHERE", "JOIN", "UNION", "EXEC", "EXECUTE"
        ]

        if sqlKeywords.contains(field.uppercased()) {
            throw QueryParseError.invalidFieldName("Cannot use SQL keyword as field name")
        }
    }

    /// Validate and sanitize a complete query request
    public func validate(_ request: QueryRequest) throws {
        // Validate collection name
        try validateFieldName(request.collection)

        // Validate query if present
        if let query = request.query {
            _ = try parse(query)
        }

        // Validate custom query name if present
        if let custom = request.custom {
            try validateFieldName(custom)
        }

        // Validate limit and offset
        if let limit = request.query?.limit {
            guard limit > 0 && limit <= 1000 else {
                throw QueryParseError.invalidValue("Limit must be between 1 and 1000")
            }
        }

        if let offset = request.query?.offset {
            guard offset >= 0 else {
                throw QueryParseError.invalidValue("Offset must be non-negative")
            }
        }
    }
}
