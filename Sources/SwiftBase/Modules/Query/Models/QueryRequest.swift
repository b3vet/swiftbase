import Foundation
import Hummingbird

/// Query action types
public enum QueryAction: String, Codable, Sendable {
    case find
    case findOne
    case create
    case update
    case delete
    case count
    case aggregate
    case custom
}

/// Main query request structure
public struct QueryRequest: Codable, Sendable {
    public let action: QueryAction
    public let collection: String
    public let query: MongoQuery?
    public let data: AnyCodable?
    public let options: QueryOptions?
    public let custom: String? // Name of custom query
    public let params: [String: AnyCodable]? // Parameters for custom query

    public init(
        action: QueryAction,
        collection: String,
        query: MongoQuery? = nil,
        data: AnyCodable? = nil,
        options: QueryOptions? = nil,
        custom: String? = nil,
        params: [String: AnyCodable]? = nil
    ) {
        self.action = action
        self.collection = collection
        self.query = query
        self.data = data
        self.options = options
        self.custom = custom
        self.params = params
    }
}

/// MongoDB-style query structure
public struct MongoQuery: Codable, Sendable {
    public let `where`: [String: AnyCodable]?
    public let select: SelectFields?
    public let include: [String]? // Related collections to include
    public let orderBy: [String: SortOrder]?
    public let limit: Int?
    public let offset: Int?
    public let distinct: String?

    public init(
        where whereClause: [String: AnyCodable]? = nil,
        select: SelectFields? = nil,
        include: [String]? = nil,
        orderBy: [String: SortOrder]? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        distinct: String? = nil
    ) {
        self.where = whereClause
        self.select = select
        self.include = include
        self.orderBy = orderBy
        self.limit = limit
        self.offset = offset
        self.distinct = distinct
    }
}

/// Sort order
public enum SortOrder: String, Codable, Sendable {
    case asc
    case desc
}

/// Select fields can be either an array of field names or a dictionary of field: 0|1
public enum SelectFields: Codable, Sendable {
    case array([String])
    case dictionary([String: Int])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([String].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: Int].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected array or dictionary for select fields"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dict):
            try container.encode(dict)
        }
    }
}

/// Query options
public struct QueryOptions: Codable, Sendable {
    public let upsert: Bool?
    public let multi: Bool?
    public let validate: Bool?
    public let returnNew: Bool?

    public init(
        upsert: Bool? = nil,
        multi: Bool? = nil,
        validate: Bool? = nil,
        returnNew: Bool? = nil
    ) {
        self.upsert = upsert
        self.multi = multi
        self.validate = validate
        self.returnNew = returnNew
    }
}

/// Query response
public struct QueryResponse: Codable, Sendable, ResponseEncodable {
    public let success: Bool
    public let data: AnyCodable?
    public let count: Int?
    public let error: String?

    public init(success: Bool, data: AnyCodable? = nil, count: Int? = nil, error: String? = nil) {
        self.success = success
        self.data = data
        self.count = count
        self.error = error
    }
}

/// Type-erased codable wrapper for dynamic JSON data
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unable to encode value of type \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check for common types
        switch (lhs.value, rhs.value) {
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as String, let r as String):
            return l == r
        case (is NSNull, is NSNull):
            return true
        default:
            return false
        }
    }
}
