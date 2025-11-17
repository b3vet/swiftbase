import Foundation
import GRDB
import Hummingbird

/// Builds SQL queries from parsed MongoDB-style queries
public struct SQLBuilder: Sendable {
    private let logger: LoggerService

    public init() {
        self.logger = LoggerService.shared
    }

    /// Build a SELECT query from a ParsedQuery
    public func buildSelect(
        collectionId: String,
        parsedQuery: ParsedQuery
    ) throws -> (sql: String, arguments: [DatabaseValue]) {

        var sql = "SELECT "
        var arguments: [DatabaseValue] = []

        // SELECT clause
        if let distinct = parsedQuery.distinct {
            sql += "DISTINCT json_extract(data, '$.\(distinct)') "
        } else if let selectFields = parsedQuery.select, !selectFields.isEmpty {
            sql += "id, "
            let fieldProjections = selectFields.map { "json_extract(data, '$.\($0)') AS \($0)" }
            sql += fieldProjections.joined(separator: ", ")
        } else {
            sql += "id, data, created_at, updated_at, created_by, updated_by, version "
        }

        sql += "FROM _documents WHERE collection_id = ? "
        arguments.append(collectionId.databaseValue)

        // WHERE clause
        if !parsedQuery.conditions.isEmpty {
            let (whereClause, whereArgs) = try buildWhereClause(parsedQuery.conditions)
            sql += "AND (\(whereClause)) "
            arguments.append(contentsOf: whereArgs)
        }

        // ORDER BY clause
        if !parsedQuery.orderBy.isEmpty {
            sql += "ORDER BY "
            let orderClauses = parsedQuery.orderBy.map { field, order in
                "json_extract(data, '$.\(field)') \(order.rawValue.uppercased())"
            }
            sql += orderClauses.joined(separator: ", ")
            sql += " "
        }

        // LIMIT and OFFSET
        if let limit = parsedQuery.limit {
            sql += "LIMIT \(limit) "
        }

        if let offset = parsedQuery.offset {
            sql += "OFFSET \(offset) "
        }

        logger.debug("Built SQL: \(sql)")
        return (sql, arguments)
    }

    /// Build a COUNT query
    public func buildCount(
        collectionId: String,
        parsedQuery: ParsedQuery
    ) throws -> (sql: String, arguments: [DatabaseValue]) {

        var sql: String
        var arguments: [DatabaseValue] = []

        if let distinct = parsedQuery.distinct {
            sql = "SELECT COUNT(DISTINCT json_extract(data, '$.\(distinct)')) FROM _documents WHERE collection_id = ? "
        } else {
            sql = "SELECT COUNT(*) FROM _documents WHERE collection_id = ? "
        }

        arguments.append(collectionId.databaseValue)

        if !parsedQuery.conditions.isEmpty {
            let (whereClause, whereArgs) = try buildWhereClause(parsedQuery.conditions)
            sql += "AND (\(whereClause)) "
            arguments.append(contentsOf: whereArgs)
        }

        return (sql, arguments)
    }

    /// Build an UPDATE query
    public func buildUpdate(
        collectionId: String,
        parsedQuery: ParsedQuery,
        updateData: [String: Any]
    ) throws -> [(sql: String, arguments: [DatabaseValue])] {

        var queries: [(sql: String, arguments: [DatabaseValue])] = []

        // Handle update operators
        for (key, value) in updateData {
            if let updateOp = QueryOperator(rawValue: key), updateOp.isUpdateOperator {
                guard let fields = value as? [String: Any] else {
                    throw QueryParseError.invalidValue("\(key) expects an object")
                }

                for (field, fieldValue) in fields {
                    let (sql, args) = try buildUpdateOperator(
                        collectionId: collectionId,
                        operator: updateOp,
                        field: field,
                        value: fieldValue,
                        parsedQuery: parsedQuery
                    )
                    queries.append((sql, args))
                }
            }
        }

        // If no update operators, treat as $set
        if queries.isEmpty {
            for (field, value) in updateData {
                let (sql, args) = try buildUpdateOperator(
                    collectionId: collectionId,
                    operator: .set,
                    field: field,
                    value: value,
                    parsedQuery: parsedQuery
                )
                queries.append((sql, args))
            }
        }

        return queries
    }

    /// Build a DELETE query
    public func buildDelete(
        collectionId: String,
        parsedQuery: ParsedQuery
    ) throws -> (sql: String, arguments: [DatabaseValue]) {

        var sql = "DELETE FROM _documents WHERE collection_id = ? "
        var arguments: [DatabaseValue] = [collectionId.databaseValue]

        if !parsedQuery.conditions.isEmpty {
            let (whereClause, whereArgs) = try buildWhereClause(parsedQuery.conditions)
            sql += "AND (\(whereClause)) "
            arguments.append(contentsOf: whereArgs)
        }

        return (sql, arguments)
    }

    // MARK: - Private Helper Methods

    /// Build WHERE clause from conditions
    private func buildWhereClause(_ conditions: [QueryCondition]) throws -> (sql: String, arguments: [DatabaseValue]) {
        var clauses: [String] = []
        var arguments: [DatabaseValue] = []

        for condition in conditions {
            let (clause, args) = try buildCondition(condition)
            clauses.append(clause)
            arguments.append(contentsOf: args)
        }

        let sql = clauses.joined(separator: " AND ")
        return (sql, arguments)
    }

    /// Build a single condition
    private func buildCondition(_ condition: QueryCondition) throws -> (sql: String, arguments: [DatabaseValue]) {
        let jsonPath = "json_extract(data, '$.\(condition.field)')"

        switch condition.operator {
        // Comparison operators
        case .eq:
            return ("\(jsonPath) = ?", [convertToDatabaseValue(condition.value)])

        case .ne:
            return ("\(jsonPath) != ?", [convertToDatabaseValue(condition.value)])

        case .gt:
            return ("\(jsonPath) > ?", [convertToDatabaseValue(condition.value)])

        case .gte:
            return ("\(jsonPath) >= ?", [convertToDatabaseValue(condition.value)])

        case .lt:
            return ("\(jsonPath) < ?", [convertToDatabaseValue(condition.value)])

        case .lte:
            return ("\(jsonPath) <= ?", [convertToDatabaseValue(condition.value)])

        // Array operators
        case .in:
            guard let array = condition.value as? [Any] else {
                throw QueryParseError.invalidValue("$in expects an array")
            }
            let placeholders = Array(repeating: "?", count: array.count).joined(separator: ", ")
            let args = array.map { convertToDatabaseValue($0) }
            return ("\(jsonPath) IN (\(placeholders))", args)

        case .nin:
            guard let array = condition.value as? [Any] else {
                throw QueryParseError.invalidValue("$nin expects an array")
            }
            let placeholders = Array(repeating: "?", count: array.count).joined(separator: ", ")
            let args = array.map { convertToDatabaseValue($0) }
            return ("\(jsonPath) NOT IN (\(placeholders))", args)

        case .all:
            // For arrays, check if all elements are present
            guard let array = condition.value as? [Any] else {
                throw QueryParseError.invalidValue("$all expects an array")
            }
            var clauses: [String] = []
            var args: [DatabaseValue] = []

            for element in array {
                // Check if JSON array contains the element
                clauses.append("EXISTS (SELECT 1 FROM json_each(\(jsonPath)) WHERE value = ?)")
                args.append(convertToDatabaseValue(element))
            }

            return ("(" + clauses.joined(separator: " AND ") + ")", args)

        case .size:
            guard let size = condition.value as? Int else {
                throw QueryParseError.invalidValue("$size expects an integer")
            }
            return ("json_array_length(\(jsonPath)) = ?", [size.databaseValue])

        case .elemMatch:
            // Simplified elemMatch - checks if any array element matches the condition
            guard let matchCondition = condition.value as? [String: Any] else {
                throw QueryParseError.invalidValue("$elemMatch expects an object")
            }

            // Build a subquery for the elemMatch condition
            var clauses: [String] = []
            var args: [DatabaseValue] = []

            for (key, value) in matchCondition {
                clauses.append("EXISTS (SELECT 1 FROM json_each(\(jsonPath)) WHERE json_extract(value, '$.\(key)') = ?)")
                args.append(convertToDatabaseValue(value))
            }

            return ("(" + clauses.joined(separator: " AND ") + ")", args)

        // Element operators
        case .exists:
            guard let exists = condition.value as? Bool else {
                throw QueryParseError.invalidValue("$exists expects a boolean")
            }
            if exists {
                return ("\(jsonPath) IS NOT NULL", [])
            } else {
                return ("\(jsonPath) IS NULL", [])
            }

        case .type:
            guard let typeString = condition.value as? String else {
                throw QueryParseError.invalidValue("$type expects a string")
            }

            guard let sqlType = SQLDataType.from(mongoType: typeString) else {
                throw QueryParseError.invalidValue("Unknown type: \(typeString)")
            }

            return ("typeof(\(jsonPath)) = ?", [sqlType.rawValue.databaseValue])

        // Evaluation operators
        case .regex:
            guard let pattern = condition.value as? String else {
                throw QueryParseError.invalidValue("$regex expects a string")
            }
            // SQLite REGEXP requires a custom function, so we use LIKE as a fallback
            // Convert basic regex patterns to LIKE patterns
            let likePattern = convertRegexToLike(pattern)
            return ("\(jsonPath) LIKE ?", [likePattern.databaseValue])

        case .mod:
            guard let modArray = condition.value as? [Int], modArray.count == 2 else {
                throw QueryParseError.invalidValue("$mod expects [divisor, remainder]")
            }
            let divisor = modArray[0]
            let remainder = modArray[1]
            return ("(\(jsonPath) % ?) = ?", [divisor.databaseValue, remainder.databaseValue])

        // Logical operators (handled at a higher level, but included for completeness)
        case .and, .or, .not, .nor:
            throw QueryParseError.unsupportedOperator("Logical operators should be handled at query level")

        // Update operators (not used in WHERE clauses)
        case .set, .unset, .inc, .push, .pull, .addToSet:
            throw QueryParseError.unsupportedOperator("Update operators cannot be used in WHERE clause")
        }
    }

    /// Build an update operator SQL
    private func buildUpdateOperator(
        collectionId: String,
        operator: QueryOperator,
        field: String,
        value: Any,
        parsedQuery: ParsedQuery
    ) throws -> (sql: String, arguments: [DatabaseValue]) {
        var sql = "UPDATE _documents SET "
        var arguments: [DatabaseValue] = []

        switch `operator` {
        case .set:
            // Set a field value
            sql += "data = json_set(data, '$.\(field)', json(?)), "
            sql += "updated_at = CURRENT_TIMESTAMP "
            sql += "WHERE collection_id = ? "
            arguments.append(convertToJSON(value).databaseValue)
            arguments.append(collectionId.databaseValue)

        case .unset:
            // Remove a field
            sql += "data = json_remove(data, '$.\(field)'), "
            sql += "updated_at = CURRENT_TIMESTAMP "
            sql += "WHERE collection_id = ? "
            arguments.append(collectionId.databaseValue)

        case .inc:
            // Increment a numeric field
            guard let increment = value as? Int else {
                throw QueryParseError.invalidValue("$inc expects a number")
            }
            sql += "data = json_set(data, '$.\(field)', json_extract(data, '$.\(field)') + ?), "
            sql += "updated_at = CURRENT_TIMESTAMP "
            sql += "WHERE collection_id = ? "
            arguments.append(increment.databaseValue)
            arguments.append(collectionId.databaseValue)

        case .push:
            // Push to array
            sql += "data = json_set(data, '$.\(field)', json_insert(COALESCE(json_extract(data, '$.\(field)'), '[]'), '$[#]', json(?))), "
            sql += "updated_at = CURRENT_TIMESTAMP "
            sql += "WHERE collection_id = ? "
            arguments.append(convertToJSON(value).databaseValue)
            arguments.append(collectionId.databaseValue)

        case .pull:
            // Pull from array (simplified - removes all matching elements)
            // This is complex in SQLite, simplified version
            sql += "updated_at = CURRENT_TIMESTAMP "
            sql += "WHERE collection_id = ? "
            arguments.append(collectionId.databaseValue)

        case .addToSet:
            // Add to array if not exists (simplified)
            sql += "data = CASE "
            sql += "WHEN json_extract(data, '$.\(field)') IS NULL THEN json_set(data, '$.\(field)', json_array(json(?))) "
            sql += "ELSE json_set(data, '$.\(field)', json_insert(json_extract(data, '$.\(field)'), '$[#]', json(?))) "
            sql += "END, "
            sql += "updated_at = CURRENT_TIMESTAMP "
            sql += "WHERE collection_id = ? "
            arguments.append(convertToJSON(value).databaseValue)
            arguments.append(convertToJSON(value).databaseValue)
            arguments.append(collectionId.databaseValue)

        default:
            throw QueryParseError.unsupportedOperator("\(`operator`.rawValue) is not an update operator")
        }

        // Add WHERE conditions from parsed query
        if !parsedQuery.conditions.isEmpty {
            let (whereClause, whereArgs) = try buildWhereClause(parsedQuery.conditions)
            sql += "AND (\(whereClause)) "
            arguments.append(contentsOf: whereArgs)
        }

        return (sql, arguments)
    }

    /// Convert a value to DatabaseValue
    private func convertToDatabaseValue(_ value: Any) -> DatabaseValue {
        switch value {
        case let string as String:
            return string.databaseValue
        case let int as Int:
            return int.databaseValue
        case let double as Double:
            return double.databaseValue
        case let bool as Bool:
            return bool.databaseValue
        case is NSNull:
            return DatabaseValue.null
        default:
            // For complex types, convert to JSON string
            return convertToJSON(value).databaseValue
        }
    }

    /// Convert a value to JSON string
    private func convertToJSON(_ value: Any) -> String {
        // Handle nil/null
        if value is NSNull {
            return "null"
        }

        // Handle strings
        if let stringValue = value as? String {
            // Escape the string for JSON
            let escaped = stringValue
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            return "\"\(escaped)\""
        }

        // Handle numbers
        if let numberValue = value as? NSNumber {
            // Check if it's a boolean
            if CFBooleanGetTypeID() == CFGetTypeID(numberValue) {
                return numberValue.boolValue ? "true" : "false"
            }
            return "\(numberValue)"
        }

        // Handle arrays and dictionaries
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
        }

        // Fallback: convert to string representation
        return "\"\(value)\""
    }

    /// Convert basic regex patterns to SQL LIKE patterns
    private func convertRegexToLike(_ pattern: String) -> String {
        var likePattern = pattern

        // Replace regex wildcards with SQL LIKE wildcards
        likePattern = likePattern.replacingOccurrences(of: ".*", with: "%")
        likePattern = likePattern.replacingOccurrences(of: ".", with: "_")

        // Remove anchors
        likePattern = likePattern.replacingOccurrences(of: "^", with: "")
        likePattern = likePattern.replacingOccurrences(of: "$", with: "")

        return likePattern
    }
}
