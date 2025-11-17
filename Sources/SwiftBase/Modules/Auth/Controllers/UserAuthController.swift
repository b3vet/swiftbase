import Foundation
import Hummingbird
import GRDB

/// Controller for user authentication endpoints
public struct UserAuthController: Sendable {
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

    public struct RegisterRequest: Codable {
        public let email: String
        public let password: String
        public let metadata: [String: String]?
    }

    public struct LoginRequest: Codable {
        public let email: String
        public let password: String
    }

    public struct RefreshRequest: Codable {
        public let refreshToken: String
    }

    public struct AuthResponse: Codable, ResponseEncodable {
        public let user: User.Response
        public let tokens: TokenPair
    }

    // MARK: - Register

    nonisolated public func register(_ request: Request, context: some RequestContext) async throws -> AuthResponse {
        let body = try await request.decode(as: RegisterRequest.self, context: context)

        // Validate email format
        guard body.email.contains("@") && body.email.contains(".") else {
            throw HTTPError(.badRequest, message: "Invalid email format")
        }

        // Validate password strength
        guard body.password.count >= 8 else {
            throw HTTPError(.badRequest, message: "Password must be at least 8 characters")
        }

        // Hash password
        let passwordHash = try await passwordService.hash(body.password)

        // Create user
        let userId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let user = User(
            id: userId,
            email: body.email.lowercased(),
            passwordHash: passwordHash,
            metadata: body.metadata ?? [:]
        )

        // Save user to database
        let email = body.email.lowercased()
        try await dbService.write { db in
            // Check if email already exists
            if try User.filter(User.Columns.email == email).fetchOne(db) != nil {
                throw HTTPError(.conflict, message: "Email already registered")
            }

            let mutableUser = user
            try mutableUser.insert(db)
        }

        // Generate tokens
        let (tokenPair, storedToken) = try await jwtService.generateTokenPair(userId: userId, type: "user")

        // Store refresh token
        try await sessionService.addUserRefreshToken(userId: userId, token: storedToken)

        // Update last login
        try await sessionService.updateUserLastLogin(userId: userId)

        logger.info("User registered: \(email)")

        return AuthResponse(user: user.toResponse(), tokens: tokenPair)
    }

    // MARK: - Login

    nonisolated public func login(_ request: Request, context: some RequestContext) async throws -> AuthResponse {
        let body = try await request.decode(as: LoginRequest.self, context: context)

        // Find user by email
        let email = body.email.lowercased()
        let password = body.password
        let user = try await dbService.read { db in
            try User.filter(User.Columns.email == email).fetchOne(db)
        }

        guard let user = user else {
            throw HTTPError(.unauthorized, message: "Invalid credentials")
        }

        // Verify password
        let isValid = try await passwordService.verify(password, against: user.passwordHash)
        guard isValid else {
            throw HTTPError(.unauthorized, message: "Invalid credentials")
        }

        // Generate tokens
        let (tokenPair, storedToken) = try await jwtService.generateTokenPair(userId: user.id, type: "user")

        // Store refresh token
        try await sessionService.addUserRefreshToken(userId: user.id, token: storedToken)

        // Update last login
        try await sessionService.updateUserLastLogin(userId: user.id)

        logger.info("User logged in: \(email)")

        return AuthResponse(user: user.toResponse(), tokens: tokenPair)
    }

    // MARK: - Refresh Token

    nonisolated public func refresh(_ request: Request, context: some RequestContext) async throws -> TokenPair {
        let body = try await request.decode(as: RefreshRequest.self, context: context)

        // Validate refresh token
        let claims = try await jwtService.validateRefreshToken(body.refreshToken)

        // Verify token exists in database and is valid
        guard try await sessionService.verifyUserRefreshToken(userId: claims.sub, tokenId: claims.jti) else {
            throw HTTPError(.unauthorized, message: "Invalid refresh token")
        }

        // Remove old refresh token (rotation)
        try await sessionService.removeUserRefreshToken(userId: claims.sub, tokenId: claims.jti)

        // Generate new token pair
        let (tokenPair, storedToken) = try await jwtService.generateTokenPair(userId: claims.sub, type: "user")

        // Store new refresh token
        try await sessionService.addUserRefreshToken(userId: claims.sub, token: storedToken)

        logger.debug("Tokens refreshed for user: \(claims.sub)")

        return tokenPair
    }

    // MARK: - Logout

    nonisolated public func logout(_ request: Request, context: some RequestContext) async throws -> Response {
        // Extract and validate token
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Remove all refresh tokens (logout from all sessions)
        try await sessionService.removeAllUserRefreshTokens(userId: claims.sub)

        logger.info("User logged out: \(claims.sub)")

        return Response(status: .ok, body: .init(byteBuffer: ByteBuffer(string: #"{"message":"Logged out successfully"}"#)))
    }

    // MARK: - Get Current User

    nonisolated public func getCurrentUser(_ request: Request, context: some RequestContext) async throws -> User.Response {
        // Extract and validate token
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Fetch user
        let user = try await dbService.read { db in
            try User.fetchOne(db, key: claims.sub)
        }

        guard let user = user else {
            throw HTTPError(.notFound, message: "User not found")
        }

        return user.toResponse()
    }
}
