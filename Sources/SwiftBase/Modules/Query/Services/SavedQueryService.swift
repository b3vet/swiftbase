import Foundation
import GRDB
import Hummingbird

/// Service for managing saved queries
public actor SavedQueryService: Sendable {
    private let dbService: DatabaseService
    private let logger: LoggerService

    public init(dbService: DatabaseService, logger: LoggerService) {
        self.dbService = dbService
        self.logger = logger
    }

    // MARK: - CRUD Operations

    /// Get all saved queries
    public func getAll() async throws -> [SavedQuery] {
        return try await dbService.read { db in
            try SavedQuery
                .order(Column("name"))
                .fetchAll(db)
        }
    }

    /// Get a saved query by name
    public func getByName(_ name: String) async throws -> SavedQuery? {
        return try await dbService.read { db in
            try SavedQuery
                .filter(Column("name") == name)
                .fetchOne(db)
        }
    }

    /// Get a saved query by ID
    public func getById(_ id: String) async throws -> SavedQuery? {
        return try await dbService.read { db in
            try SavedQuery
                .filter(Column("id") == id)
                .fetchOne(db)
        }
    }

    /// Create a new saved query
    public func create(
        name: String,
        description: String? = nil,
        collectionId: String,
        action: String,
        query: [String: Any],
        data: [String: Any]? = nil,
        createdBy: String? = nil
    ) async throws -> SavedQuery {
        // Validate that collection exists
        let collectionExists = try await dbService.read { db in
            try db.tableExists("_collections") &&
                Row.fetchOne(db, sql: "SELECT 1 FROM _collections WHERE id = ? OR name = ?", arguments: [collectionId, collectionId]) != nil
        }

        guard collectionExists else {
            throw HTTPError(.badRequest, message: "Collection not found: \(collectionId)")
        }

        // Convert query to JSON string
        let queryData = try JSONSerialization.data(withJSONObject: query)
        guard let queryJson = String(data: queryData, encoding: .utf8) else {
            throw HTTPError(.badRequest, message: "Invalid query format")
        }

        // Convert data to JSON string if present
        var dataJson: String?
        if let data = data {
            let dataData = try JSONSerialization.data(withJSONObject: data)
            dataJson = String(data: dataData, encoding: .utf8)
        }

        let savedQuery = SavedQuery(
            name: name,
            description: description,
            collectionId: collectionId,
            action: action,
            queryJson: queryJson,
            dataJson: dataJson,
            createdBy: createdBy
        )

        try await dbService.write { db in
            try savedQuery.insert(db)
        }

        logger.info("Created saved query: \(name)")
        return savedQuery
    }

    /// Update a saved query
    public func update(
        name: String,
        description: String? = nil,
        query: [String: Any]? = nil,
        data: [String: Any]? = nil
    ) async throws -> SavedQuery {
        guard var savedQuery = try await getByName(name) else {
            throw HTTPError(.notFound, message: "Saved query not found: \(name)")
        }

        // Update fields if provided
        if let description = description {
            savedQuery.description = description
        }

        if let query = query {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            guard let queryJson = String(data: queryData, encoding: .utf8) else {
                throw HTTPError(.badRequest, message: "Invalid query format")
            }
            savedQuery.queryJson = queryJson
        }

        if let data = data {
            let dataData = try JSONSerialization.data(withJSONObject: data)
            savedQuery.dataJson = String(data: dataData, encoding: .utf8)
        }

        savedQuery.updatedAt = Date().iso8601String

        // Create immutable copy for closure capture
        let updatedQuery = savedQuery
        try await dbService.write { db in
            try updatedQuery.update(db)
        }

        logger.info("Updated saved query: \(name)")
        return updatedQuery
    }

    /// Delete a saved query by name
    public func delete(name: String) async throws {
        guard let savedQuery = try await getByName(name) else {
            throw HTTPError(.notFound, message: "Saved query not found: \(name)")
        }

        try await dbService.write { db in
            _ = try savedQuery.delete(db)
        }

        logger.info("Deleted saved query: \(name)")
    }

    /// Check if a query name already exists
    public func exists(name: String) async throws -> Bool {
        return try await dbService.read { db in
            try SavedQuery
                .filter(Column("name") == name)
                .fetchCount(db) > 0
        }
    }

    /// Get saved queries for a specific collection
    public func getByCollection(collectionId: String) async throws -> [SavedQuery] {
        return try await dbService.read { db in
            try SavedQuery
                .filter(Column("collection_id") == collectionId)
                .order(Column("name"))
                .fetchAll(db)
        }
    }
}
