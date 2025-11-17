import Foundation
import Hummingbird
import NIOCore

/// Controller for query endpoints
public struct QueryController: Sendable {
    private let queryService: QueryService
    private let jwtService: JWTService
    private let logger: LoggerService

    public init(queryService: QueryService, jwtService: JWTService) {
        self.queryService = queryService
        self.jwtService = jwtService
        self.logger = LoggerService.shared
    }

    // MARK: - Main Query Endpoint

    /// Execute a query
    nonisolated public func execute(_ request: Request, context: some RequestContext) async throws -> QueryResponse {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Decode request body
        let queryRequest = try await request.decode(as: QueryRequest.self, context: context)

        logger.info("Executing \(queryRequest.action.rawValue) query on collection '\(queryRequest.collection)' by \(claims.type) '\(claims.sub)'")

        do {
            // Execute query
            logger.info("About to call queryService.execute...")
            let response = try await queryService.execute(queryRequest)
            logger.info("queryService.execute returned successfully")
            return response
        } catch let error as QueryParseError {
            logger.error("Query parse error: \(error.description)")
            throw HTTPError(.badRequest, message: error.description)
        } catch let error as HTTPError {
            throw error
        } catch {
            logger.error("Query execution error: \(error.localizedDescription)")
            throw HTTPError(.internalServerError, message: "Query execution failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Custom Query Management (Admin Only)

    /// List all custom queries
    nonisolated public func listCustomQueries(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate admin authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        let queries = await queryService.listCustomQueries()

        let response = [
            "success": true,
            "data": queries
        ] as [String : Any]

        let jsonData = try JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - Collection Management

    /// Get collection info
    nonisolated public func getCollectionInfo(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        _ = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Get collection name from path parameter
        guard let collectionName = context.parameters.get("collection") else {
            throw HTTPError(.badRequest, message: "Collection name required")
        }

        // Get count and metadata for the collection
        let countRequest = QueryRequest(
            action: .count,
            collection: collectionName
        )

        let countResponse = try await queryService.execute(countRequest)

        let response = [
            "success": true,
            "data": [
                "collection": collectionName,
                "count": countResponse.count ?? 0
            ]
        ] as [String : Any]

        let jsonData = try JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }
}
