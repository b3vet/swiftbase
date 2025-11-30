import Foundation
import GRDB
import Hummingbird

/// Sendable wrapper for JSON dictionaries
private struct SendableJSONDict: @unchecked Sendable {
    let dict: [String: Any]
}

/// Main service for executing MongoDB-style queries
public actor QueryService {
    private let dbService: DatabaseService
    private let parser: QueryParser
    private let sqlBuilder: SQLBuilder
    private let logger: LoggerService
    private var customQueries: [String: CustomQuery] = [:]
    nonisolated(unsafe) private var broadcastService: BroadcastService?

    public init(dbService: DatabaseService) {
        self.dbService = dbService
        self.parser = QueryParser()
        self.sqlBuilder = SQLBuilder()
        self.logger = LoggerService.shared
    }

    /// Set the broadcast service for realtime events
    public func setBroadcastService(_ broadcastService: BroadcastService) {
        self.broadcastService = broadcastService
    }

    /// Get collection ID from collection name
    private func getCollectionId(name: String) async throws -> String {
        let collectionId = try await dbService.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT id FROM _collections WHERE name = ?",
                arguments: [name]
            )
        }

        guard let collectionId = collectionId else {
            throw HTTPError(.notFound, message: "Collection '\(name)' not found")
        }

        return collectionId
    }

    // MARK: - Main Query Execution

    /// Execute a query request
    public func execute(_ request: QueryRequest) async throws -> QueryResponse {
        logger.info("QueryService.execute: Starting for action '\(request.action.rawValue)'")

        // Validate the request
        try parser.validate(request)
        logger.info("QueryService.execute: Validated request")

        // Route to appropriate handler
        logger.info("QueryService.execute: Routing to handler for '\(request.action.rawValue)'")
        switch request.action {
        case .find:
            return try await executeFind(request)
        case .findOne:
            return try await executeFindOne(request)
        case .create:
            return try await executeCreate(request)
        case .update:
            return try await executeUpdate(request)
        case .delete:
            return try await executeDelete(request)
        case .count:
            return try await executeCount(request)
        case .aggregate:
            return try await executeAggregate(request)
        case .custom:
            return try await executeCustom(request)
        }
    }

    // MARK: - Query Actions

    /// Execute a find query (returns multiple documents)
    private func executeFind(_ request: QueryRequest) async throws -> QueryResponse {
        logger.info("executeFind: Starting for collection '\(request.collection)'")

        let collectionId = try await getCollectionId(name: request.collection)
        logger.info("executeFind: Got collection ID: \(collectionId)")

        let parsedQuery = try parser.parse(request.query)
        logger.info("executeFind: Parsed query")

        let (sql, args) = try sqlBuilder.buildSelect(
            collectionId: collectionId,
            parsedQuery: parsedQuery
        )
        logger.info("executeFind: Built SQL: \(sql)")

        let sendableData = try await dbService.read { db in
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return rows.compactMap { row -> SendableJSONDict? in
                // Get the JSON data column
                guard let jsonString = row["data"] as? String,
                      let jsonData = jsonString.data(using: .utf8),
                      let document = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    return nil
                }

                // Add metadata fields
                var result = document
                result["id"] = row["id"]
                result["created_at"] = row["created_at"]
                result["updated_at"] = row["updated_at"]

                return SendableJSONDict(dict: result)
            }
        }
        logger.info("executeFind: Completed database read")

        let data = sendableData.map { $0.dict }
        logger.debug("Found \(data.count) documents in collection '\(request.collection)'")

        return QueryResponse(
            success: true,
            data: AnyCodable(data),
            count: data.count
        )
    }

    /// Execute a findOne query (returns single document)
    private func executeFindOne(_ request: QueryRequest) async throws -> QueryResponse {
        let collectionId = try await getCollectionId(name: request.collection)

        // Modify query to limit to 1 result
        let modifiedQuery = request.query ?? MongoQuery()
        let mongoQuery = MongoQuery(
            where: modifiedQuery.where,
            select: modifiedQuery.select,
            include: modifiedQuery.include,
            orderBy: modifiedQuery.orderBy,
            limit: 1,
            offset: modifiedQuery.offset,
            distinct: modifiedQuery.distinct
        )

        let parsedQuery = try parser.parse(mongoQuery)
        let (sql, args) = try sqlBuilder.buildSelect(
            collectionId: collectionId,
            parsedQuery: parsedQuery
        )

        let sendableDict = try await dbService.read { db in
            guard let row = try Row.fetchOne(db, sql: sql, arguments: StatementArguments(args)) else {
                return nil as SendableJSONDict?
            }

            // Get the JSON data column
            guard let jsonString = row["data"] as? String,
                  let jsonData = jsonString.data(using: .utf8),
                  let document = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return nil
            }

            // Add metadata fields
            var result = document
            result["id"] = row["id"]
            result["created_at"] = row["created_at"]
            result["updated_at"] = row["updated_at"]

            return SendableJSONDict(dict: result)
        }

        guard let sendableDict = sendableDict else {
            throw HTTPError(.notFound, message: "Document not found")
        }

        logger.debug("Found document in collection '\(request.collection)'")

        return QueryResponse(success: true, data: AnyCodable(sendableDict.dict))
    }

    /// Execute a create query (inserts document)
    private func executeCreate(_ request: QueryRequest) async throws -> QueryResponse {
        guard let data = request.data?.value as? [String: Any] else {
            throw HTTPError(.badRequest, message: "Invalid data for create operation")
        }

        // Get collection ID from collection name
        let collectionId = try await dbService.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT id FROM _collections WHERE name = ?",
                arguments: [request.collection]
            )
        }

        guard let collectionId = collectionId else {
            throw HTTPError(.notFound, message: "Collection '\(request.collection)' not found")
        }

        // Generate document ID
        let documentId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()

        // Add _id to data if not present
        var documentData = data
        if documentData["_id"] == nil {
            documentData["_id"] = documentId
        }

        // Convert to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: documentData)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        // Insert into database
        try await dbService.write { db in
            try db.execute(
                sql: """
                INSERT INTO _documents (id, collection_id, data, created_at, updated_at, version)
                VALUES (?, ?, json(?), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1)
                """,
                arguments: [documentId, collectionId, jsonString]
            )
        }

        logger.info("Created document '\(documentId)' in collection '\(request.collection)'")

        // Add document ID
        documentData["id"] = documentId

        // Create response
        let response = QueryResponse(success: true, data: AnyCodable(documentData))

        // Broadcast create event (after creating response, before return)
        if let broadcastService = self.broadcastService {
            await broadcastService.broadcastCreate(
                collection: request.collection,
                documentId: documentId,
                document: documentData
            )
        }

        return response
    }

    /// Execute an update query
    private func executeUpdate(_ request: QueryRequest) async throws -> QueryResponse {
        guard let updateData = request.data?.value as? [String: Any] else {
            throw HTTPError(.badRequest, message: "Invalid data for update operation")
        }

        let collectionId = try await getCollectionId(name: request.collection)
        let parsedQuery = try parser.parse(request.query)

        // Get the document IDs before update for broadcasting
        let (selectSql, selectArgs) = try sqlBuilder.buildSelect(
            collectionId: collectionId,
            parsedQuery: parsedQuery
        )

        let documentIds = try await dbService.read { db in
            let rows = try Row.fetchAll(db, sql: selectSql, arguments: StatementArguments(selectArgs))
            return rows.compactMap { $0["id"] as? String }
        }

        let queries = try sqlBuilder.buildUpdate(
            collectionId: collectionId,
            parsedQuery: parsedQuery,
            updateData: updateData
        )

        var totalUpdated = 0

        for (sql, args) in queries {
            let updated = try await dbService.write { db in
                try db.execute(sql: sql, arguments: StatementArguments(args))
                return db.changesCount
            }
            totalUpdated += updated
        }

        logger.info("Updated \(totalUpdated) document(s) in collection '\(request.collection)'")

        // Create response
        let response = QueryResponse(
            success: true,
            data: AnyCodable(["updated": totalUpdated]),
            count: totalUpdated
        )

        // Broadcast update events for each updated document (after creating response)
        if let broadcastService = self.broadcastService {
            // Wrap in sendable container to satisfy Swift 6 concurrency
            let sendableData = SendableJSONDict(dict: updateData)
            for documentId in documentIds {
                await broadcastService.broadcastUpdate(
                    collection: request.collection,
                    documentId: documentId,
                    document: sendableData.dict
                )
            }
        }

        return response
    }

    /// Execute a delete query
    private func executeDelete(_ request: QueryRequest) async throws -> QueryResponse {
        let collectionId = try await getCollectionId(name: request.collection)
        let parsedQuery = try parser.parse(request.query)

        // Get the document IDs before deletion for broadcasting
        let (selectSql, selectArgs) = try sqlBuilder.buildSelect(
            collectionId: collectionId,
            parsedQuery: parsedQuery
        )

        let documentIds = try await dbService.read { db in
            let rows = try Row.fetchAll(db, sql: selectSql, arguments: StatementArguments(selectArgs))
            return rows.compactMap { $0["id"] as? String }
        }

        let (sql, args) = try sqlBuilder.buildDelete(
            collectionId: collectionId,
            parsedQuery: parsedQuery
        )

        let deletedCount = try await dbService.write { db in
            try db.execute(sql: sql, arguments: StatementArguments(args))
            return db.changesCount
        }

        logger.info("Deleted \(deletedCount) document(s) from collection '\(request.collection)'")

        // Broadcast delete events for each deleted document
        if let broadcastService = self.broadcastService {
            for documentId in documentIds {
                await broadcastService.broadcastDelete(
                    collection: request.collection,
                    documentId: documentId
                )
            }
        }

        return QueryResponse(
            success: true,
            data: AnyCodable(["deleted": deletedCount]),
            count: deletedCount
        )
    }

    /// Execute a count query
    private func executeCount(_ request: QueryRequest) async throws -> QueryResponse {
        let collectionId = try await getCollectionId(name: request.collection)
        let parsedQuery = try parser.parse(request.query)
        let (sql, args) = try sqlBuilder.buildCount(
            collectionId: collectionId,
            parsedQuery: parsedQuery
        )

        let count = try await dbService.read { db in
            try Int.fetchOne(db, sql: sql, arguments: StatementArguments(args)) ?? 0
        }

        logger.debug("Counted \(count) document(s) in collection '\(request.collection)'")

        return QueryResponse(
            success: true,
            data: AnyCodable(["count": count]),
            count: count
        )
    }

    /// Execute an aggregate query (simplified implementation)
    private func executeAggregate(_ request: QueryRequest) async throws -> QueryResponse {
        // Simplified aggregation - for MVP, just return count grouped by a field
        // Full aggregation pipeline would be more complex
        throw HTTPError(.notImplemented, message: "Aggregation not yet implemented")
    }

    /// Execute a custom query
    private func executeCustom(_ request: QueryRequest) async throws -> QueryResponse {
        guard let customName = request.custom else {
            throw HTTPError(.badRequest, message: "Custom query name required")
        }

        guard let customQuery = customQueries[customName] else {
            throw HTTPError(.notFound, message: "Custom query '\(customName)' not found")
        }

        let params = request.params?.mapValues { $0.value } ?? [:]

        // Execute custom query - returns AnyCodable which is Sendable
        let result = try await customQuery.execute(params, dbService)

        return QueryResponse(success: true, data: result)
    }

    // MARK: - Custom Query Registration

    /// Register a custom query
    public func registerCustomQuery(name: String, query: CustomQuery) async {
        customQueries[name] = query
        logger.info("Registered custom query: \(name)")
    }

    /// Unregister a custom query
    public func unregisterCustomQuery(name: String) async {
        customQueries.removeValue(forKey: name)
        logger.info("Unregistered custom query: \(name)")
    }

    /// List all registered custom queries
    public func listCustomQueries() async -> [String] {
        return Array(customQueries.keys)
    }
}

/// Protocol for custom queries
/// Note: Returns AnyCodable (which is @unchecked Sendable) to satisfy Swift 6 concurrency requirements
public protocol CustomQuery: Sendable {
    func execute(_ params: [String: Any], _ dbService: DatabaseService) async throws -> AnyCodable
}

/// Example custom query implementation
public struct CustomQueryExample: CustomQuery {
    public init() {}

    public func execute(_ params: [String: Any], _ dbService: DatabaseService) async throws -> AnyCodable {
        // Example: Get top N documents from a collection
        let collection = params["collection"] as? String ?? "default"
        let limit = params["limit"] as? Int ?? 10

        let sendableData = try await dbService.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT id, data FROM _documents
                WHERE collection_id = ?
                ORDER BY created_at DESC
                LIMIT ?
                """,
                arguments: [collection, limit]
            )

            return rows.map { row -> SendableJSONDict in
                var dict: [String: Any] = [:]
                for (column, dbValue) in row {
                    dict[column] = dbValue.storage.value
                }
                return SendableJSONDict(dict: dict)
            }
        }

        return AnyCodable(sendableData.map { $0.dict })
    }
}
