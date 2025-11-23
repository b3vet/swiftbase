import Foundation
import GRDB
import Hummingbird

/// Collection model representing a data collection in the system
public struct Collection: Codable, Sendable {
    public var id: String
    public var name: String
    public var schema: [String: String]? // Field name -> type mapping
    public var indexes: [String]? // Array of indexed field names
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, schema, indexes, metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: String,
        name: String,
        schema: [String: String]? = nil,
        indexes: [String]? = nil,
        metadata: [String: String] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.schema = schema
        self.indexes = indexes
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Integration

extension Collection: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "_collections"

    public enum Columns {
        public static let id = Column("id")
        public static let name = Column("name")
        public static let schema = Column("schema")
        public static let indexes = Column("indexes")
        public static let metadata = Column("metadata")
        public static let createdAt = Column("created_at")
        public static let updatedAt = Column("updated_at")
    }

    public init(row: Row) throws {
        id = row[Columns.id]
        name = row[Columns.name]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]

        // Decode JSON fields
        if let schemaJSON: String = row[Columns.schema] {
            schema = try? JSONDecoder().decode([String: String].self, from: Data(schemaJSON.utf8))
        } else {
            schema = nil
        }

        if let indexesJSON: String = row[Columns.indexes] {
            indexes = try? JSONDecoder().decode([String].self, from: Data(indexesJSON.utf8))
        } else {
            indexes = nil
        }

        if let metadataJSON: String = row[Columns.metadata] {
            metadata = (try? JSONDecoder().decode([String: String].self, from: Data(metadataJSON.utf8))) ?? [:]
        } else {
            metadata = [:]
        }
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt

        // Encode JSON fields
        if let schema = schema {
            let data = try JSONEncoder().encode(schema)
            container[Columns.schema] = String(data: data, encoding: .utf8)
        } else {
            container[Columns.schema] = nil
        }

        if let indexes = indexes {
            let data = try JSONEncoder().encode(indexes)
            container[Columns.indexes] = String(data: data, encoding: .utf8)
        } else {
            container[Columns.indexes] = nil
        }

        let metadataData = try JSONEncoder().encode(metadata)
        container[Columns.metadata] = String(data: metadataData, encoding: .utf8)
    }
}

// MARK: - Response Models

extension Collection {
    /// Public response model (excludes sensitive data)
    public struct Response: Codable, Sendable, ResponseEncodable {
        public let id: String
        public let name: String
        public let schema: [String: String]?
        public let indexes: [String]?
        public let metadata: [String: String]
        public let documentCount: Int?
        public let createdAt: Date
        public let updatedAt: Date

        public init(
            id: String,
            name: String,
            schema: [String: String]?,
            indexes: [String]?,
            metadata: [String: String],
            documentCount: Int? = nil,
            createdAt: Date,
            updatedAt: Date
        ) {
            self.id = id
            self.name = name
            self.schema = schema
            self.indexes = indexes
            self.metadata = metadata
            self.documentCount = documentCount
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    public func toResponse(documentCount: Int? = nil) -> Response {
        return Response(
            id: id,
            name: name,
            schema: schema,
            indexes: indexes,
            metadata: metadata,
            documentCount: documentCount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Collection statistics
public struct CollectionStats: Codable, Sendable, ResponseEncodable {
    public let collection: String
    public let documentCount: Int
    public let totalSize: Int // Size in bytes
    public let averageDocumentSize: Double
    public let indexCount: Int
    public let oldestDocument: Date?
    public let newestDocument: Date?

    public init(
        collection: String,
        documentCount: Int,
        totalSize: Int,
        averageDocumentSize: Double,
        indexCount: Int,
        oldestDocument: Date?,
        newestDocument: Date?
    ) {
        self.collection = collection
        self.documentCount = documentCount
        self.totalSize = totalSize
        self.averageDocumentSize = averageDocumentSize
        self.indexCount = indexCount
        self.oldestDocument = oldestDocument
        self.newestDocument = newestDocument
    }
}

/// Bulk operation request
public struct BulkOperationRequest: Codable, Sendable {
    public let operations: [BulkOperation]

    public init(operations: [BulkOperation]) {
        self.operations = operations
    }
}

/// Single bulk operation
public struct BulkOperation: Codable, Sendable {
    public let type: BulkOperationType
    public let collection: String
    public let query: [String: AnyCodable]?
    public let data: AnyCodable?

    public init(
        type: BulkOperationType,
        collection: String,
        query: [String: AnyCodable]? = nil,
        data: AnyCodable? = nil
    ) {
        self.type = type
        self.collection = collection
        self.query = query
        self.data = data
    }
}

/// Bulk operation type
public enum BulkOperationType: String, Codable, Sendable {
    case create
    case update
    case delete
}

/// Bulk operation result
public struct BulkOperationResult: Codable, Sendable, ResponseEncodable {
    public let success: Bool
    public let results: [OperationResult]
    public let totalOperations: Int
    public let successfulOperations: Int
    public let failedOperations: Int

    public init(
        success: Bool,
        results: [OperationResult],
        totalOperations: Int,
        successfulOperations: Int,
        failedOperations: Int
    ) {
        self.success = success
        self.results = results
        self.totalOperations = totalOperations
        self.successfulOperations = successfulOperations
        self.failedOperations = failedOperations
    }
}

/// Single operation result
public struct OperationResult: Codable, Sendable {
    public let index: Int
    public let success: Bool
    public let error: String?
    public let data: AnyCodable?

    public init(index: Int, success: Bool, error: String? = nil, data: AnyCodable? = nil) {
        self.index = index
        self.success = success
        self.error = error
        self.data = data
    }
}
