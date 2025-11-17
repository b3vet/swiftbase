import Foundation
import GRDB
import Hummingbird

/// Service for managing collections
public actor CollectionService {
    private let dbService: DatabaseService
    private let logger: LoggerService

    public init(dbService: DatabaseService) {
        self.dbService = dbService
        self.logger = LoggerService.shared
    }

    // MARK: - Collection CRUD

    /// Create a new collection
    public func createCollection(
        name: String,
        schema: [String: String]? = nil,
        indexes: [String]? = nil,
        metadata: [String: String] = [:]
    ) async throws -> Collection {
        // Validate collection name
        guard isValidCollectionName(name) else {
            throw HTTPError(.badRequest, message: "Invalid collection name. Use alphanumeric characters, underscores, and hyphens only.")
        }

        let collectionId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let collection = Collection(
            id: collectionId,
            name: name,
            schema: schema,
            indexes: indexes,
            metadata: metadata
        )

        try await dbService.write { db in
            // Check if collection already exists
            if try Collection.filter(Collection.Columns.name == name).fetchOne(db) != nil {
                throw HTTPError(.conflict, message: "Collection '\(name)' already exists")
            }

            let mutableCollection = collection
            try mutableCollection.insert(db)
        }

        logger.info("Created collection: \(name)")
        return collection
    }

    /// Get a collection by name
    public func getCollection(name: String) async throws -> Collection {
        let collection = try await dbService.read { db in
            try Collection.filter(Collection.Columns.name == name).fetchOne(db)
        }

        guard let collection = collection else {
            throw HTTPError(.notFound, message: "Collection '\(name)' not found")
        }

        return collection
    }

    /// List all collections
    public func listCollections() async throws -> [Collection] {
        return try await dbService.read { db in
            try Collection.order(Collection.Columns.createdAt.desc).fetchAll(db)
        }
    }

    /// Update collection metadata
    public func updateCollection(
        name: String,
        schema: [String: String]? = nil,
        indexes: [String]? = nil,
        metadata: [String: String]? = nil
    ) async throws -> Collection {
        try await dbService.write { db in
            guard var collection = try Collection.filter(Collection.Columns.name == name).fetchOne(db) else {
                throw HTTPError(.notFound, message: "Collection '\(name)' not found")
            }

            if let schema = schema {
                collection.schema = schema
            }

            if let indexes = indexes {
                collection.indexes = indexes
            }

            if let metadata = metadata {
                collection.metadata = metadata
            }

            collection.updatedAt = Date()

            try collection.update(db)
            return collection
        }
    }

    /// Delete a collection and optionally cascade delete all documents
    public func deleteCollection(name: String, cascade: Bool = false) async throws {
        let collectionName = name
        try await dbService.write { db in
            guard let collection = try Collection.filter(Collection.Columns.name == collectionName).fetchOne(db) else {
                throw HTTPError(.notFound, message: "Collection '\(collectionName)' not found")
            }

            if cascade {
                // Delete all documents in the collection
                try db.execute(
                    sql: "DELETE FROM _documents WHERE collection_id = ?",
                    arguments: [collection.id]
                )
            } else {
                // Check if collection has documents
                let count = try Int.fetchOne(
                    db,
                    sql: "SELECT COUNT(*) FROM _documents WHERE collection_id = ?",
                    arguments: [collection.id]
                ) ?? 0

                if count > 0 {
                    throw HTTPError(.conflict, message: "Collection '\(collectionName)' contains \(count) documents. Use cascade=true to delete them.")
                }
            }

            // Delete the collection
            try db.execute(
                sql: "DELETE FROM _collections WHERE id = ?",
                arguments: [collection.id]
            )
        }

        if cascade {
            logger.info("Deleted all documents from collection: \(name)")
        }
        logger.info("Deleted collection: \(name)")
    }

    // MARK: - Collection Statistics

    /// Get statistics for a collection
    public func getCollectionStats(name: String) async throws -> CollectionStats {
        let collection = try await getCollection(name: name)

        return try await dbService.read { db in
            let stats = try Row.fetchOne(
                db,
                sql: """
                SELECT
                    COUNT(*) as document_count,
                    COALESCE(SUM(LENGTH(data)), 0) as total_size,
                    MIN(created_at) as oldest_document,
                    MAX(created_at) as newest_document
                FROM _documents
                WHERE collection_id = ?
                """,
                arguments: [collection.id]
            )

            guard let stats = stats else {
                throw HTTPError(.internalServerError, message: "Failed to fetch collection statistics")
            }

            let documentCount: Int = stats["document_count"]
            let totalSize: Int = stats["total_size"]
            let oldestDocument: Date? = stats["oldest_document"]
            let newestDocument: Date? = stats["newest_document"]

            let averageSize = documentCount > 0 ? Double(totalSize) / Double(documentCount) : 0.0
            let indexCount = collection.indexes?.count ?? 0

            return CollectionStats(
                collection: name,
                documentCount: documentCount,
                totalSize: totalSize,
                averageDocumentSize: averageSize,
                indexCount: indexCount,
                oldestDocument: oldestDocument,
                newestDocument: newestDocument
            )
        }
    }

    /// Get document count for a collection
    public func getDocumentCount(collectionName: String) async throws -> Int {
        let collection = try await getCollection(name: collectionName)

        return try await dbService.read { db in
            try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM _documents WHERE collection_id = ?",
                arguments: [collection.id]
            ) ?? 0
        }
    }

    // MARK: - Bulk Operations

    /// Execute bulk operations
    public func executeBulkOperations(_ request: BulkOperationRequest) async throws -> BulkOperationResult {
        var results: [OperationResult] = []
        var successCount = 0
        var failureCount = 0

        for (index, operation) in request.operations.enumerated() {
            do {
                let result = try await executeSingleBulkOperation(operation)
                results.append(OperationResult(index: index, success: true, data: result))
                successCount += 1
            } catch {
                results.append(OperationResult(
                    index: index,
                    success: false,
                    error: error.localizedDescription
                ))
                failureCount += 1
            }
        }

        logger.info("Bulk operation completed: \(successCount) succeeded, \(failureCount) failed")

        return BulkOperationResult(
            success: failureCount == 0,
            results: results,
            totalOperations: request.operations.count,
            successfulOperations: successCount,
            failedOperations: failureCount
        )
    }

    /// Execute a single bulk operation
    private func executeSingleBulkOperation(_ operation: BulkOperation) async throws -> AnyCodable? {
        let collection = try await getCollection(name: operation.collection)

        switch operation.type {
        case .create:
            guard let data = operation.data?.value as? [String: Any] else {
                throw HTTPError(.badRequest, message: "Invalid data for create operation")
            }

            let documentId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            var documentData = data
            documentData["_id"] = documentId

            let jsonData = try JSONSerialization.data(withJSONObject: documentData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            try await dbService.write { db in
                try db.execute(
                    sql: """
                    INSERT INTO _documents (id, collection_id, data, created_at, updated_at, version)
                    VALUES (?, ?, json(?), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1)
                    """,
                    arguments: [documentId, collection.id, jsonString]
                )
            }

            documentData["id"] = documentId
            return AnyCodable(documentData)

        case .update:
            guard let query = operation.query,
                  let data = operation.data?.value as? [String: Any] else {
                throw HTTPError(.badRequest, message: "Invalid query or data for update operation")
            }

            // Build WHERE clause from query
            var whereClauses: [String] = []
            var arguments: [DatabaseValue] = [collection.id.databaseValue]

            for (key, value) in query {
                whereClauses.append("json_extract(data, '$.\(key)') = ?")
                arguments.append(convertToDatabaseValue(value.value))
            }

            let whereClause = whereClauses.isEmpty ? "1=1" : whereClauses.joined(separator: " AND ")

            // Simple $set operation for bulk updates
            for (field, value) in data {
                let jsonValue = convertToJSON(value)
                let fieldName = field
                let capturedArguments = arguments
                let capturedWhereClause = whereClause
                try await dbService.write { db in
                    var allArguments = [jsonValue.databaseValue]
                    allArguments.append(contentsOf: capturedArguments)
                    try db.execute(
                        sql: """
                        UPDATE _documents
                        SET data = json_set(data, '$.\(fieldName)', json(?)),
                            updated_at = CURRENT_TIMESTAMP,
                            version = version + 1
                        WHERE collection_id = ? AND \(capturedWhereClause)
                        """,
                        arguments: StatementArguments(allArguments)
                    )
                }
            }

            return AnyCodable(["updated": true])

        case .delete:
            guard let query = operation.query else {
                throw HTTPError(.badRequest, message: "Query required for delete operation")
            }

            var whereClauses: [String] = []
            var arguments: [DatabaseValue] = [collection.id.databaseValue]

            for (key, value) in query {
                whereClauses.append("json_extract(data, '$.\(key)') = ?")
                arguments.append(convertToDatabaseValue(value.value))
            }

            let whereClause = whereClauses.isEmpty ? "1=1" : whereClauses.joined(separator: " AND ")

            let capturedArguments = arguments
            let deletedCount = try await dbService.write { db in
                try db.execute(
                    sql: "DELETE FROM _documents WHERE collection_id = ? AND \(whereClause)",
                    arguments: StatementArguments(capturedArguments)
                )
                return db.changesCount
            }

            return AnyCodable(["deleted": deletedCount])
        }
    }

    // MARK: - Helper Methods

    /// Validate collection name
    private func isValidCollectionName(_ name: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_-]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(name.startIndex..., in: name)
        return regex?.firstMatch(in: name, range: range) != nil
    }

    /// Convert value to DatabaseValue
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
            return convertToJSON(value).databaseValue
        }
    }

    /// Convert value to JSON string
    private func convertToJSON(_ value: Any) -> String {
        // Handle primitive types directly
        switch value {
        case let bool as Bool:
            return bool ? "true" : "false"
        case let int as Int:
            return "\(int)"
        case let double as Double:
            return "\(double)"
        case let string as String:
            // Escape and quote strings for JSON
            let escaped = string.replacingOccurrences(of: "\\", with: "\\\\")
                                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        case is NSNull:
            return "null"
        default:
            // For complex types (arrays, dictionaries), use JSONSerialization
            if let data = try? JSONSerialization.data(withJSONObject: value),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
            // Fallback: return string representation
            return "\"\(value)\""
        }
    }
}
