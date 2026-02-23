import Foundation
import GRDB
import Hummingbird

/// Saved query model for storing reusable queries
public struct SavedQuery: Codable, Sendable, FetchableRecord, PersistableRecord {
    public var id: String
    public var name: String
    public var description: String?
    public var collectionId: String
    public var action: String  // find, findOne, create, update, delete, count
    public var queryJson: String  // JSON string of the MongoDB-style query
    public var dataJson: String?  // JSON string for create/update data
    public var createdBy: String?  // Admin ID
    public var createdAt: String
    public var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case collectionId = "collection_id"
        case action
        case queryJson = "query_json"
        case dataJson = "data_json"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public static let databaseTableName = "_saved_queries"

    public init(
        id: String = UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: ""),
        name: String,
        description: String? = nil,
        collectionId: String,
        action: String,
        queryJson: String,
        dataJson: String? = nil,
        createdBy: String? = nil,
        createdAt: String = Date().iso8601String,
        updatedAt: String = Date().iso8601String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.collectionId = collectionId
        self.action = action
        self.queryJson = queryJson
        self.dataJson = dataJson
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Response Models

extension SavedQuery {
    /// Response model for API
    public struct Response: Codable, ResponseEncodable {
        public let id: String
        public let name: String
        public let description: String?
        public let collectionId: String
        public let action: String
        public let query: [String: Any]
        public let data: [String: Any]?
        public let createdBy: String?
        public let createdAt: String
        public let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case id, name, description, action, query, data
            case collectionId = "collection_id"
            case createdBy = "created_by"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }

        public init(from savedQuery: SavedQuery) throws {
            self.id = savedQuery.id
            self.name = savedQuery.name
            self.description = savedQuery.description
            self.collectionId = savedQuery.collectionId
            self.action = savedQuery.action

            // Parse query JSON
            if let queryData = savedQuery.queryJson.data(using: .utf8),
               let queryDict = try? JSONSerialization.jsonObject(with: queryData) as? [String: Any] {
                self.query = queryDict
            } else {
                self.query = [:]
            }

            // Parse data JSON if present
            if let dataJsonString = savedQuery.dataJson,
               let dataData = dataJsonString.data(using: .utf8),
               let dataDict = try? JSONSerialization.jsonObject(with: dataData) as? [String: Any] {
                self.data = dataDict
            } else {
                self.data = nil
            }

            self.createdBy = savedQuery.createdBy
            self.createdAt = savedQuery.createdAt
            self.updatedAt = savedQuery.updatedAt
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.description = try container.decodeIfPresent(String.self, forKey: .description)
            self.collectionId = try container.decode(String.self, forKey: .collectionId)
            self.action = try container.decode(String.self, forKey: .action)

            // Decode query as generic dictionary
            self.query = try container.decode([String: AnyCodableValue].self, forKey: .query).mapValues { $0.value }
            self.data = try container.decodeIfPresent([String: AnyCodableValue].self, forKey: .data)?.mapValues { $0.value }

            self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
            self.createdAt = try container.decode(String.self, forKey: .createdAt)
            self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(description, forKey: .description)
            try container.encode(collectionId, forKey: .collectionId)
            try container.encode(action, forKey: .action)

            // Encode query and data as AnyCodableValue
            try container.encode(query.mapValues { AnyCodableValue($0) }, forKey: .query)
            if let data = data {
                try container.encode(data.mapValues { AnyCodableValue($0) }, forKey: .data)
            }

            try container.encodeIfPresent(createdBy, forKey: .createdBy)
            try container.encode(createdAt, forKey: .createdAt)
            try container.encode(updatedAt, forKey: .updatedAt)
        }
    }

    /// List response model
    public struct ListResponse: Codable, ResponseEncodable {
        public let savedQueries: [Response]
        public let count: Int

        enum CodingKeys: String, CodingKey {
            case savedQueries = "saved_queries"
            case count
        }
    }
}

// MARK: - Request Models

extension SavedQuery {
    /// Create request model
    public struct CreateRequest: Decodable {
        public let name: String
        public let description: String?
        public let collectionId: String
        public let action: String
        public let query: [String: Any]
        public let data: [String: Any]?

        enum CodingKeys: String, CodingKey {
            case name, description, action, query, data
            case collectionId = "collection_id"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            collectionId = try container.decode(String.self, forKey: .collectionId)
            action = try container.decode(String.self, forKey: .action)

            // Decode query as dictionary using AnyCodableValue
            query = try container.decode([String: AnyCodableValue].self, forKey: .query).mapValues { $0.value }
            data = try container.decodeIfPresent([String: AnyCodableValue].self, forKey: .data)?.mapValues { $0.value }
        }
    }

    /// Update request model
    public struct UpdateRequest: Decodable {
        public let description: String?
        public let query: [String: Any]?
        public let data: [String: Any]?

        enum CodingKeys: String, CodingKey {
            case description, query, data
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            query = try container.decodeIfPresent([String: AnyCodableValue].self, forKey: .query)?.mapValues { $0.value }
            data = try container.decodeIfPresent([String: AnyCodableValue].self, forKey: .data)?.mapValues { $0.value }
        }
    }
}

// MARK: - Helper Extensions

extension Date {
    public var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}

// MARK: - AnyCodableValue

/// A wrapper for encoding/decoding Any values
public struct AnyCodableValue: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodableValue].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodableValue].self) {
            value = dictionary.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodableValue($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodableValue($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type: \(type(of: value))")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
