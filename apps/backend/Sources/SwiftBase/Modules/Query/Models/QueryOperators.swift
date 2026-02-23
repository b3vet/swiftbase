import Foundation

/// MongoDB-style query operators
public enum QueryOperator: String, Sendable {
    // Comparison Operators
    case eq = "$eq"           // Equals
    case ne = "$ne"           // Not equals
    case gt = "$gt"           // Greater than
    case gte = "$gte"         // Greater than or equal
    case lt = "$lt"           // Less than
    case lte = "$lte"         // Less than or equal
    case `in` = "$in"         // In array
    case nin = "$nin"         // Not in array

    // Logical Operators
    case and = "$and"         // Logical AND
    case or = "$or"           // Logical OR
    case not = "$not"         // Logical NOT
    case nor = "$nor"         // Logical NOR

    // Element Operators
    case exists = "$exists"   // Field exists
    case type = "$type"       // Field type check

    // Evaluation Operators
    case regex = "$regex"     // Regular expression
    case mod = "$mod"         // Modulo operation

    // Array Operators
    case all = "$all"         // All elements match
    case elemMatch = "$elemMatch" // Element match
    case size = "$size"       // Array size

    // Update Operators
    case set = "$set"         // Set field
    case unset = "$unset"     // Remove field
    case inc = "$inc"         // Increment
    case push = "$push"       // Push to array
    case pull = "$pull"       // Pull from array
    case addToSet = "$addToSet" // Add to set

    /// Returns true if this is a comparison operator
    public var isComparisonOperator: Bool {
        switch self {
        case .eq, .ne, .gt, .gte, .lt, .lte, .in, .nin:
            return true
        default:
            return false
        }
    }

    /// Returns true if this is a logical operator
    public var isLogicalOperator: Bool {
        switch self {
        case .and, .or, .not, .nor:
            return true
        default:
            return false
        }
    }

    /// Returns true if this is an element operator
    public var isElementOperator: Bool {
        switch self {
        case .exists, .type:
            return true
        default:
            return false
        }
    }

    /// Returns true if this is an array operator
    public var isArrayOperator: Bool {
        switch self {
        case .all, .elemMatch, .size, .in, .nin:
            return true
        default:
            return false
        }
    }

    /// Returns true if this is an update operator
    public var isUpdateOperator: Bool {
        switch self {
        case .set, .unset, .inc, .push, .pull, .addToSet:
            return true
        default:
            return false
        }
    }
}

/// Parsed query condition
public struct QueryCondition: @unchecked Sendable {
    public let field: String
    public let `operator`: QueryOperator
    public let value: Any

    public init(field: String, operator: QueryOperator, value: Any) {
        self.field = field
        self.operator = `operator`
        self.value = value
    }
}

/// Logical expression combining multiple conditions
public enum LogicalExpression: Sendable {
    case and([QueryCondition])
    case or([QueryCondition])
    case not(QueryCondition)
    case single(QueryCondition)

    /// Recursively flattens nested logical expressions
    public func flatten() -> [QueryCondition] {
        switch self {
        case .and(let conditions), .or(let conditions):
            return conditions
        case .not(let condition), .single(let condition):
            return [condition]
        }
    }
}

/// Parsed query representation
public struct ParsedQuery: Sendable {
    public let conditions: [QueryCondition]
    public let logicalOperator: QueryOperator? // $and or $or if multiple conditions
    public let orderBy: [String: SortOrder]
    public let limit: Int?
    public let offset: Int?
    public let select: [String]?
    public let distinct: String?

    public init(
        conditions: [QueryCondition],
        logicalOperator: QueryOperator? = nil,
        orderBy: [String: SortOrder] = [:],
        limit: Int? = nil,
        offset: Int? = nil,
        select: [String]? = nil,
        distinct: String? = nil
    ) {
        self.conditions = conditions
        self.logicalOperator = logicalOperator
        self.orderBy = orderBy
        self.limit = limit
        self.offset = offset
        self.select = select
        self.distinct = distinct
    }

    public var isEmpty: Bool {
        return conditions.isEmpty
    }
}

/// SQL data types for type checking
public enum SQLDataType: String, Sendable {
    case text = "TEXT"
    case integer = "INTEGER"
    case real = "REAL"
    case blob = "BLOB"
    case null = "NULL"

    /// Maps MongoDB $type values to SQL types
    public static func from(mongoType: String) -> SQLDataType? {
        switch mongoType.lowercased() {
        case "string":
            return .text
        case "number", "int", "long", "double":
            return .real
        case "bool", "boolean":
            return .integer
        case "null":
            return .null
        case "array", "object":
            return .text // JSON stored as text
        default:
            return nil
        }
    }
}
