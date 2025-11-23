import Foundation
import Hummingbird
import NIOCore

/// Controller for user management endpoints (admin operations)
public struct UserController: Sendable {
    private let userService: UserService
    private let jwtService: JWTService
    private let logger: LoggerService

    public init(userService: UserService, jwtService: JWTService) {
        self.userService = userService
        self.jwtService = jwtService
        self.logger = LoggerService.shared
    }

    // MARK: - Request/Response Types

    public struct CreateUserRequest: Codable {
        public let email: String
        public let password: String
        public let metadata: [String: String]?
    }

    public struct UpdateUserRequest: Codable {
        public let email: String?
        public let password: String?
        public let email_verified: Bool?
        public let metadata: [String: String]?
    }

    public struct ListUsersResponse: Codable, ResponseEncodable {
        public let success: Bool
        public let users: [User.Response]
        public let count: Int
    }

    public struct UserResponse: Codable, ResponseEncodable {
        public let success: Bool
        public let user: User.Response
    }

    public struct MessageResponse: Codable, ResponseEncodable {
        public let success: Bool
        public let message: String
    }

    // MARK: - User Management

    /// List all users
    nonisolated public func listUsers(_ request: Request, context: some RequestContext) async throws -> ListUsersResponse {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        // Parse query parameters
        let limit = request.uri.queryParameters.get("limit").flatMap { Int($0) }
        let offset = request.uri.queryParameters.get("offset").flatMap { Int($0) }
        let search = request.uri.queryParameters.get("search")

        logger.info("Listing users by admin '\(claims.sub)' (limit: \(limit ?? 0), offset: \(offset ?? 0))")

        let users = try await userService.listUsers(
            limit: limit,
            offset: offset,
            search: search
        )

        let responses = users.map { $0.toResponse() }

        return ListUsersResponse(
            success: true,
            users: responses,
            count: responses.count
        )
    }

    /// Get a user by ID
    nonisolated public func getUser(_ request: Request, context: some RequestContext) async throws -> UserResponse {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        guard let userId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "User ID required")
        }

        logger.info("Fetching user '\(userId)' by admin '\(claims.sub)'")

        let user = try await userService.getUser(id: userId)

        return UserResponse(
            success: true,
            user: user.toResponse()
        )
    }

    /// Create a new user
    nonisolated public func createUser(_ request: Request, context: some RequestContext) async throws -> UserResponse {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        let body = try await request.decode(as: CreateUserRequest.self, context: context)

        logger.info("Creating user '\(body.email)' by admin '\(claims.sub)'")

        let user = try await userService.createUser(
            email: body.email,
            password: body.password,
            metadata: body.metadata ?? [:]
        )

        return UserResponse(
            success: true,
            user: user.toResponse()
        )
    }

    /// Update a user
    nonisolated public func updateUser(_ request: Request, context: some RequestContext) async throws -> UserResponse {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        guard let userId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "User ID required")
        }

        let body = try await request.decode(as: UpdateUserRequest.self, context: context)

        logger.info("Updating user '\(userId)' by admin '\(claims.sub)'")

        let user = try await userService.updateUser(
            id: userId,
            email: body.email,
            password: body.password,
            emailVerified: body.email_verified,
            metadata: body.metadata
        )

        return UserResponse(
            success: true,
            user: user.toResponse()
        )
    }

    /// Delete a user
    nonisolated public func deleteUser(_ request: Request, context: some RequestContext) async throws -> MessageResponse {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        guard let userId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "User ID required")
        }

        logger.info("Deleting user '\(userId)' by admin '\(claims.sub)'")

        try await userService.deleteUser(id: userId)

        return MessageResponse(
            success: true,
            message: "User deleted successfully"
        )
    }

    // MARK: - User Operations

    /// Verify a user's email
    nonisolated public func verifyEmail(_ request: Request, context: some RequestContext) async throws -> UserResponse {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        guard let userId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "User ID required")
        }

        logger.info("Verifying email for user '\(userId)' by admin '\(claims.sub)'")

        let user = try await userService.verifyUserEmail(id: userId)

        return UserResponse(
            success: true,
            user: user.toResponse()
        )
    }

    /// Revoke all sessions for a user
    nonisolated public func revokeSessions(_ request: Request, context: some RequestContext) async throws -> MessageResponse {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        guard let userId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "User ID required")
        }

        logger.info("Revoking all sessions for user '\(userId)' by admin '\(claims.sub)'")

        try await userService.revokeAllSessions(userId: userId)

        return MessageResponse(
            success: true,
            message: "All sessions revoked successfully"
        )
    }

    // MARK: - Statistics

    /// Get user statistics
    nonisolated public func getUserStats(_ request: Request, context: some RequestContext) async throws -> UserStats {
        // Validate authentication (admin only)
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        logger.info("Fetching user statistics by admin '\(claims.sub)'")

        return try await userService.getUserStats()
    }
}
