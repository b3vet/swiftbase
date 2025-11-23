import Foundation
import Hummingbird

/// Controller for saved queries endpoints
public struct SavedQueryController: Sendable {
    private let savedQueryService: SavedQueryService
    private let jwtService: JWTService
    private let logger: LoggerService

    public init(savedQueryService: SavedQueryService, jwtService: JWTService, logger: LoggerService) {
        self.savedQueryService = savedQueryService
        self.jwtService = jwtService
        self.logger = logger
    }

    // MARK: - List All Saved Queries

    /// GET /api/admin/saved-queries
    nonisolated public func list(_ request: Request, context: some RequestContext) async throws -> SavedQuery.ListResponse {
        logger.debug("Listing all saved queries")

        let queries = try await savedQueryService.getAll()
        let responses = try queries.map { try SavedQuery.Response(from: $0) }

        return SavedQuery.ListResponse(
            savedQueries: responses,
            count: responses.count
        )
    }

    // MARK: - Get Saved Query by Name

    /// GET /api/admin/saved-queries/:name
    nonisolated public func get(_ request: Request, context: some RequestContext) async throws -> SavedQuery.Response {
        guard let name = context.parameters.get("name", as: String.self) else {
            throw HTTPError(.badRequest, message: "Query name is required")
        }

        logger.debug("Getting saved query: \(name)")

        guard let savedQuery = try await savedQueryService.getByName(name) else {
            throw HTTPError(.notFound, message: "Saved query not found: \(name)")
        }

        return try SavedQuery.Response(from: savedQuery)
    }

    // MARK: - Create Saved Query

    /// POST /api/admin/saved-queries
    nonisolated public func create(_ request: Request, context: some RequestContext) async throws -> SavedQuery.Response {
        let body = try await request.decode(as: SavedQuery.CreateRequest.self, context: context)

        logger.info("Creating saved query: \(body.name)")

        // Check if name already exists
        if try await savedQueryService.exists(name: body.name) {
            throw HTTPError(.conflict, message: "A query with name '\(body.name)' already exists")
        }

        // Get admin ID from auth token if available
        let adminId = try? await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService).sub

        let savedQuery = try await savedQueryService.create(
            name: body.name,
            description: body.description,
            collectionId: body.collectionId,
            action: body.action,
            query: body.query,
            data: body.data,
            createdBy: adminId
        )

        return try SavedQuery.Response(from: savedQuery)
    }

    // MARK: - Update Saved Query

    /// PUT /api/admin/saved-queries/:name
    nonisolated public func update(_ request: Request, context: some RequestContext) async throws -> SavedQuery.Response {
        guard let name = context.parameters.get("name", as: String.self) else {
            throw HTTPError(.badRequest, message: "Query name is required")
        }

        let body = try await request.decode(as: SavedQuery.UpdateRequest.self, context: context)

        logger.info("Updating saved query: \(name)")

        let savedQuery = try await savedQueryService.update(
            name: name,
            description: body.description,
            query: body.query,
            data: body.data
        )

        return try SavedQuery.Response(from: savedQuery)
    }

    // MARK: - Delete Saved Query

    /// DELETE /api/admin/saved-queries/:name
    nonisolated public func delete(_ request: Request, context: some RequestContext) async throws -> Response {
        guard let name = context.parameters.get("name", as: String.self) else {
            throw HTTPError(.badRequest, message: "Query name is required")
        }

        logger.info("Deleting saved query: \(name)")

        try await savedQueryService.delete(name: name)

        return Response(
            status: .ok,
            body: .init(byteBuffer: ByteBuffer(string: #"{"message":"Saved query deleted successfully"}"#))
        )
    }

    // MARK: - Execute Saved Query by Name

    /// POST /api/admin/saved-queries/:name/execute
    nonisolated public func execute(_ request: Request, context: some RequestContext) async throws -> Response {
        guard let name = context.parameters.get("name", as: String.self) else {
            throw HTTPError(.badRequest, message: "Query name is required")
        }

        logger.info("Executing saved query: \(name)")

        guard let savedQuery = try await savedQueryService.getByName(name) else {
            throw HTTPError(.notFound, message: "Saved query not found: \(name)")
        }

        // Parse the query JSON
        guard let queryData = savedQuery.queryJson.data(using: .utf8),
              let query = try? JSONSerialization.jsonObject(with: queryData) as? [String: Any] else {
            throw HTTPError(.internalServerError, message: "Failed to parse saved query")
        }

        // Parse data JSON if present
        var data: [String: Any]?
        if let dataJsonString = savedQuery.dataJson,
           let dataData = dataJsonString.data(using: .utf8),
           let dataDict = try? JSONSerialization.jsonObject(with: dataData) as? [String: Any] {
            data = dataDict
        }

        // Build the query execution request
        var queryRequest: [String: Any] = [
            "action": savedQuery.action,
            "collection": savedQuery.collectionId,
            "query": query
        ]

        if let data = data {
            queryRequest["data"] = data
        }

        // Convert to JSON for the query service
        let requestData = try JSONSerialization.data(withJSONObject: queryRequest)
        let requestJson = String(data: requestData, encoding: .utf8) ?? "{}"

        logger.debug("Executing query: \(requestJson)")

        // Note: This would need to be integrated with your actual QueryService
        // For now, return a placeholder response
        return Response(
            status: .ok,
            body: .init(byteBuffer: ByteBuffer(string: requestJson))
        )
    }
}
