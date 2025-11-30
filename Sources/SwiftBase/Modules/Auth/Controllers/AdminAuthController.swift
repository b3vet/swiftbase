import Foundation
import Hummingbird
import GRDB

/// Controller for admin authentication endpoints
public struct AdminAuthController: Sendable {
    private let dbService: DatabaseService
    private let jwtService: JWTService
    private let passwordService: PasswordService
    private let sessionService: SessionService
    private let logger: LoggerService

    public init(
        dbService: DatabaseService,
        jwtService: JWTService,
        passwordService: PasswordService,
        sessionService: SessionService
    ) {
        self.dbService = dbService
        self.jwtService = jwtService
        self.passwordService = passwordService
        self.sessionService = sessionService
        self.logger = LoggerService.shared
    }

    // MARK: - Request/Response Types

    public struct LoginRequest: Codable {
        public let username: String
        public let password: String
    }

    public struct RefreshRequest: Codable {
        public let refreshToken: String
    }

    public struct AuthResponse: Codable, ResponseEncodable {
        public let admin: Admin.Response
        public let tokens: TokenPair
    }

    // MARK: - Login

    nonisolated public func login(_ request: Request, context: some RequestContext) async throws -> AuthResponse {
        let body = try await request.decode(as: LoginRequest.self, context: context)

        // Find admin by username
        let username = body.username
        let password = body.password
        let admin = try await dbService.read { db in
            try Admin.filter(Admin.Columns.username == username).fetchOne(db)
        }

        guard let admin = admin else {
            throw HTTPError(.unauthorized, message: "Invalid credentials")
        }

        // Verify password
        let isValid: Bool
        do {
            isValid = try await passwordService.verify(password, against: admin.passwordHash)
        } catch {
            // Password hash format error - treat as invalid credentials
            logger.warning("Password verification error for admin \(username): \(error)")
            throw HTTPError(.unauthorized, message: "Invalid credentials")
        }
        guard isValid else {
            throw HTTPError(.unauthorized, message: "Invalid credentials")
        }

        // Generate tokens
        let (tokenPair, storedToken) = try await jwtService.generateTokenPair(userId: admin.id, type: "admin")

        // Store refresh token
        try await sessionService.addAdminRefreshToken(adminId: admin.id, token: storedToken)

        // Update last login
        try await sessionService.updateAdminLastLogin(adminId: admin.id)

        logger.info("Admin logged in: \(username)")

        return AuthResponse(admin: admin.toResponse(), tokens: tokenPair)
    }

    // MARK: - Refresh Token

    nonisolated public func refresh(_ request: Request, context: some RequestContext) async throws -> TokenPair {
        let body = try await request.decode(as: RefreshRequest.self, context: context)

        // Validate refresh token
        let claims = try await jwtService.validateRefreshToken(body.refreshToken)

        // Verify it's an admin token
        guard claims.type == "admin" else {
            throw HTTPError(.unauthorized, message: "Invalid token type")
        }

        // Verify token exists in database and is valid
        guard try await sessionService.verifyAdminRefreshToken(adminId: claims.sub, tokenId: claims.jti) else {
            throw HTTPError(.unauthorized, message: "Invalid refresh token")
        }

        // Remove old refresh token (rotation)
        try await sessionService.removeAdminRefreshToken(adminId: claims.sub, tokenId: claims.jti)

        // Generate new token pair
        let (tokenPair, storedToken) = try await jwtService.generateTokenPair(userId: claims.sub, type: "admin")

        // Store new refresh token
        try await sessionService.addAdminRefreshToken(adminId: claims.sub, token: storedToken)

        logger.debug("Tokens refreshed for admin: \(claims.sub)")

        return tokenPair
    }

    // MARK: - Logout

    nonisolated public func logout(_ request: Request, context: some RequestContext) async throws -> Response {
        // Extract and validate token
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Verify it's an admin token
        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        // Remove all refresh tokens (logout from all sessions)
        try await sessionService.removeAllAdminRefreshTokens(adminId: claims.sub)

        logger.info("Admin logged out: \(claims.sub)")

        return Response(status: .ok, body: .init(byteBuffer: ByteBuffer(string: #"{"message":"Logged out successfully"}"#)))
    }

    // MARK: - Get Current Admin

    nonisolated public func getCurrentAdmin(_ request: Request, context: some RequestContext) async throws -> Admin.Response {
        // Extract and validate token
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Verify it's an admin token
        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        // Fetch admin
        let admin = try await dbService.read { db in
            try Admin.fetchOne(db, key: claims.sub)
        }

        guard let admin = admin else {
            throw HTTPError(.notFound, message: "Admin not found")
        }

        return admin.toResponse()
    }
}
