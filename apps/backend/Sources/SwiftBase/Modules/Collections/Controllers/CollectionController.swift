import Foundation
import Hummingbird
import NIOCore

/// Controller for collection management endpoints
public struct CollectionController: Sendable {
    private let collectionService: CollectionService
    private let jwtService: JWTService
    private let logger: LoggerService

    public init(collectionService: CollectionService, jwtService: JWTService) {
        self.collectionService = collectionService
        self.jwtService = jwtService
        self.logger = LoggerService.shared
    }

    // MARK: - Request/Response Types

    public struct CreateCollectionRequest: Codable {
        public let name: String
        public let schema: [String: String]?
        public let indexes: [String]?
        public let metadata: [String: String]?
    }

    public struct UpdateCollectionRequest: Codable {
        public let schema: [String: String]?
        public let indexes: [String]?
        public let metadata: [String: String]?
    }

    public struct ListCollectionsResponse: Codable, ResponseEncodable {
        public let success: Bool
        public let collections: [Collection.Response]
        public let count: Int
    }

    // MARK: - Collection CRUD

    /// Create a new collection
    nonisolated public func createCollection(_ request: Request, context: some RequestContext) async throws -> Collection.Response {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required to create collections")
        }

        let body = try await request.decode(as: CreateCollectionRequest.self, context: context)

        logger.info("Creating collection '\(body.name)' by admin '\(claims.sub)'")

        let collection = try await collectionService.createCollection(
            name: body.name,
            schema: body.schema,
            indexes: body.indexes,
            metadata: body.metadata ?? [:]
        )

        return collection.toResponse()
    }

    /// Get a collection by name
    nonisolated public func getCollection(_ request: Request, context: some RequestContext) async throws -> Collection.Response {
        // Validate authentication
        _ = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard let collectionName = context.parameters.get("name") else {
            throw HTTPError(.badRequest, message: "Collection name required")
        }

        let collection = try await collectionService.getCollection(name: collectionName)
        let count = try await collectionService.getDocumentCount(collectionName: collectionName)

        return collection.toResponse(documentCount: count)
    }

    /// List all collections
    nonisolated public func listCollections(_ request: Request, context: some RequestContext) async throws -> ListCollectionsResponse {
        // Validate authentication
        _ = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        let collections = try await collectionService.listCollections()

        // Get document counts for each collection
        var responses: [Collection.Response] = []
        for collection in collections {
            let count = try await collectionService.getDocumentCount(collectionName: collection.name)
            responses.append(collection.toResponse(documentCount: count))
        }

        return ListCollectionsResponse(
            success: true,
            collections: responses,
            count: responses.count
        )
    }

    /// Update a collection
    nonisolated public func updateCollection(_ request: Request, context: some RequestContext) async throws -> Collection.Response {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required to update collections")
        }

        guard let collectionName = context.parameters.get("name") else {
            throw HTTPError(.badRequest, message: "Collection name required")
        }

        let body = try await request.decode(as: UpdateCollectionRequest.self, context: context)

        logger.info("Updating collection '\(collectionName)' by admin '\(claims.sub)'")

        let collection = try await collectionService.updateCollection(
            name: collectionName,
            schema: body.schema,
            indexes: body.indexes,
            metadata: body.metadata
        )

        return collection.toResponse()
    }

    /// Delete a collection
    nonisolated public func deleteCollection(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required to delete collections")
        }

        guard let collectionName = context.parameters.get("name") else {
            throw HTTPError(.badRequest, message: "Collection name required")
        }

        // Check for cascade parameter
        let cascade = request.uri.queryParameters.get("cascade") == "true"

        logger.info("Deleting collection '\(collectionName)' (cascade: \(cascade)) by admin '\(claims.sub)'")

        try await collectionService.deleteCollection(name: collectionName, cascade: cascade)

        let response = [
            "success": true,
            "message": "Collection '\(collectionName)' deleted successfully"
        ] as [String : Any]

        let jsonData = try JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - Collection Statistics

    /// Get collection statistics
    nonisolated public func getCollectionStats(_ request: Request, context: some RequestContext) async throws -> CollectionStats {
        // Validate authentication
        _ = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard let collectionName = context.parameters.get("name") else {
            throw HTTPError(.badRequest, message: "Collection name required")
        }

        return try await collectionService.getCollectionStats(name: collectionName)
    }

    // MARK: - Bulk Operations

    /// Execute bulk operations
    nonisolated public func executeBulkOperations(_ request: Request, context: some RequestContext) async throws -> BulkOperationResult {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        let body = try await request.decode(as: BulkOperationRequest.self, context: context)

        logger.info("Executing \(body.operations.count) bulk operations by \(claims.type) '\(claims.sub)'")

        return try await collectionService.executeBulkOperations(body)
    }
}
