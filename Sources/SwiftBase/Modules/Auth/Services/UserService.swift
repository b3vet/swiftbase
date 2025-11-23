import Foundation
import GRDB
import Hummingbird

/// Service for managing users (admin operations)
public actor UserService {
    private let dbService: DatabaseService
    private let passwordService: PasswordService
    private let sessionService: SessionService
    private let logger: LoggerService

    public init(
        dbService: DatabaseService,
        passwordService: PasswordService,
        sessionService: SessionService
    ) {
        self.dbService = dbService
        self.passwordService = passwordService
        self.sessionService = sessionService
        self.logger = LoggerService.shared
    }

    // MARK: - User CRUD

    /// List all users with optional pagination and search
    public func listUsers(
        limit: Int? = nil,
        offset: Int? = nil,
        search: String? = nil
    ) async throws -> [User] {
        return try await dbService.read { db in
            var query = User.all()

            // Apply search filter if provided
            if let search = search, !search.isEmpty {
                query = query.filter(User.Columns.email.like("%\(search)%"))
            }

            // Apply pagination
            if let limit = limit {
                query = query.limit(limit, offset: offset ?? 0)
            }

            // Order by creation date (newest first)
            query = query.order(User.Columns.createdAt.desc)

            return try query.fetchAll(db)
        }
    }

    /// Get a user by ID
    public func getUser(id: String) async throws -> User {
        let user = try await dbService.read { db in
            try User.fetchOne(db, key: id)
        }

        guard let user = user else {
            throw HTTPError(.notFound, message: "User not found")
        }

        return user
    }

    /// Create a new user (admin operation)
    public func createUser(
        email: String,
        password: String,
        metadata: [String: String] = [:]
    ) async throws -> User {
        // Validate email format
        guard isValidEmail(email) else {
            throw HTTPError(.badRequest, message: "Invalid email format")
        }

        // Validate password
        guard password.count >= 8 else {
            throw HTTPError(.badRequest, message: "Password must be at least 8 characters")
        }

        // Hash password
        let passwordHash = try await passwordService.hash(password)

        // Generate user ID
        let userId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()

        let user = User(
            id: userId,
            email: email,
            passwordHash: passwordHash,
            emailVerified: false,
            refreshTokens: [],
            metadata: metadata,
            lastLogin: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await dbService.write { db in
            // Check if email already exists
            if try User.filter(User.Columns.email == email).fetchOne(db) != nil {
                throw HTTPError(.conflict, message: "User with email '\(email)' already exists")
            }

            let mutableUser = user
            try mutableUser.insert(db)
        }

        logger.info("Created user: \(email)")
        return user
    }

    /// Update a user (admin operation)
    public func updateUser(
        id: String,
        email: String? = nil,
        password: String? = nil,
        emailVerified: Bool? = nil,
        metadata: [String: String]? = nil
    ) async throws -> User {
        // Hash password outside of write closure if provided
        let hashedPassword: String?
        if let password = password {
            guard password.count >= 8 else {
                throw HTTPError(.badRequest, message: "Password must be at least 8 characters")
            }
            hashedPassword = try await passwordService.hash(password)
        } else {
            hashedPassword = nil
        }

        return try await dbService.write { db in
            guard var user = try User.fetchOne(db, key: id) else {
                throw HTTPError(.notFound, message: "User not found")
            }

            // Update email if provided
            if let email = email {
                guard self.isValidEmail(email) else {
                    throw HTTPError(.badRequest, message: "Invalid email format")
                }

                // Check if new email is already taken by another user
                if let existingUser = try User.filter(User.Columns.email == email).fetchOne(db),
                   existingUser.id != id {
                    throw HTTPError(.conflict, message: "Email '\(email)' is already taken")
                }

                user.email = email
            }

            // Update password if provided
            if let hashedPassword = hashedPassword {
                user.passwordHash = hashedPassword
            }

            // Update email verification status if provided
            if let emailVerified = emailVerified {
                user.emailVerified = emailVerified
            }

            // Update metadata if provided
            if let metadata = metadata {
                user.metadata = metadata
            }

            user.updatedAt = Date()

            try user.update(db)
            self.logger.info("Updated user: \(user.email)")

            return user
        }
    }

    /// Delete a user (admin operation)
    public func deleteUser(id: String) async throws {
        try await dbService.write { db in
            guard let user = try User.fetchOne(db, key: id) else {
                throw HTTPError(.notFound, message: "User not found")
            }

            try db.execute(
                sql: "DELETE FROM _users WHERE id = ?",
                arguments: [id]
            )

            self.logger.info("Deleted user: \(user.email)")
        }
    }

    // MARK: - User Operations

    /// Verify a user's email (admin operation)
    public func verifyUserEmail(id: String) async throws -> User {
        return try await dbService.write { db in
            guard var user = try User.fetchOne(db, key: id) else {
                throw HTTPError(.notFound, message: "User not found")
            }

            user.emailVerified = true
            user.updatedAt = Date()

            try user.update(db)
            self.logger.info("Verified email for user: \(user.email)")

            return user
        }
    }

    /// Revoke all sessions for a user (admin operation)
    public func revokeAllSessions(userId: String) async throws {
        // Verify user exists
        _ = try await getUser(id: userId)

        // Remove all refresh tokens
        try await sessionService.removeAllUserRefreshTokens(userId: userId)

        logger.info("Revoked all sessions for user: \(userId)")
    }

    // MARK: - Statistics

    /// Get user statistics
    public func getUserStats() async throws -> UserStats {
        return try await dbService.read { db in
            let totalUsers = try User.fetchCount(db)
            let verifiedUsers = try User.filter(User.Columns.emailVerified == true).fetchCount(db)
            let activeUsers = try User.filter(User.Columns.lastLogin != nil).fetchCount(db)

            // Get recent registrations (last 7 days)
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            let recentRegistrations = try User
                .filter(User.Columns.createdAt >= sevenDaysAgo)
                .fetchCount(db)

            return UserStats(
                totalUsers: totalUsers,
                verifiedUsers: verifiedUsers,
                activeUsers: activeUsers,
                recentRegistrations: recentRegistrations
            )
        }
    }

    // MARK: - Helper Methods

    /// Validate email format
    nonisolated private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - User Statistics Model

public struct UserStats: Codable, ResponseEncodable, Sendable {
    public let totalUsers: Int
    public let verifiedUsers: Int
    public let activeUsers: Int
    public let recentRegistrations: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case verifiedUsers = "verified_users"
        case activeUsers = "active_users"
        case recentRegistrations = "recent_registrations"
    }

    public init(
        totalUsers: Int,
        verifiedUsers: Int,
        activeUsers: Int,
        recentRegistrations: Int
    ) {
        self.totalUsers = totalUsers
        self.verifiedUsers = verifiedUsers
        self.activeUsers = activeUsers
        self.recentRegistrations = recentRegistrations
    }
}
