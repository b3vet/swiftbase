import Foundation
import Hummingbird
import NIOCore

/// Controller for query endpoints
public struct QueryController: Sendable {
    private let queryService: QueryService
    private let jwtService: JWTService
    private let savedQueryService: SavedQueryService?
    private let logger: LoggerService

    public init(queryService: QueryService, jwtService: JWTService, savedQueryService: SavedQueryService? = nil) {
        self.queryService = queryService
        self.jwtService = jwtService
        self.savedQueryService = savedQueryService
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

    // MARK: - Execute Saved Query by Name

    /// POST /api/query/execute/:queryName
    nonisolated public func executeByName(_ request: Request, context: some RequestContext) async throws -> QueryResponse {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard let savedQueryService = self.savedQueryService else {
            throw HTTPError(.internalServerError, message: "Saved query service not available")
        }

        // Get query name from path parameter
        guard let queryName = context.parameters.get("queryName", as: String.self) else {
            throw HTTPError(.badRequest, message: "Query name is required")
        }

        logger.info("Executing saved query '\(queryName)' by \(claims.type) '\(claims.sub)'")

        // Get the saved query
        guard let savedQuery = try await savedQueryService.getByName(queryName) else {
            throw HTTPError(.notFound, message: "Saved query '\(queryName)' not found")
        }

        // Parse the query JSON
        guard let queryData = savedQuery.queryJson.data(using: .utf8),
              let queryDict = try? JSONSerialization.jsonObject(with: queryData) as? [String: Any] else {
            throw HTTPError(.internalServerError, message: "Failed to parse saved query")
        }

        // Parse data JSON if present and convert to AnyCodable
        var dataCodable: AnyCodable?
        if let dataJsonString = savedQuery.dataJson,
           let dataData = dataJsonString.data(using: .utf8),
           let data = try? JSONSerialization.jsonObject(with: dataData) {
            dataCodable = AnyCodable(data)
        }

        // Parse action
        guard let action = QueryAction(rawValue: savedQuery.action) else {
            throw HTTPError(.badRequest, message: "Invalid query action: \(savedQuery.action)")
        }

        // Convert query dict to MongoQuery by encoding/decoding
        var mongoQuery: MongoQuery?
        if !queryDict.isEmpty {
            let queryData = try JSONSerialization.data(withJSONObject: queryDict)
            mongoQuery = try? JSONDecoder().decode(MongoQuery.self, from: queryData)
        }

        // Build QueryRequest
        let queryRequest = QueryRequest(
            action: action,
            collection: savedQuery.collectionId,
            query: mongoQuery,
            data: dataCodable
        )

        logger.debug("Executing saved query: action=\(action.rawValue), collection=\(savedQuery.collectionId)")

        // Execute the query
        do {
            let response = try await queryService.execute(queryRequest)
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
}
