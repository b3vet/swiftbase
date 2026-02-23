import Foundation
import GRDB

/// Service for managing user sessions and refresh tokens
public actor SessionService {
    private let dbService: DatabaseService
    private let logger: LoggerService

    public init(dbService: DatabaseService) {
        self.dbService = dbService
        self.logger = LoggerService.shared
    }

    // MARK: - User Sessions

    /// Add a refresh token to a user
    public func addUserRefreshToken(userId: String, token: StoredRefreshToken) async throws {
        try await dbService.write { db in
            // Fetch user
            guard var user = try User.fetchOne(db, key: userId) else {
                throw DatabaseError.notFound("User not found")
            }

            // Clean expired tokens
            user.refreshTokens = user.refreshTokens.filter { !$0.isExpired }

            // Add new token
            user.refreshTokens.append(token)

            // Update user
            try user.update(db)
        }

        logger.debug("Added refresh token for user: \(userId)")
    }

    /// Remove a specific refresh token from a user
    public func removeUserRefreshToken(userId: String, tokenId: String) async throws {
        try await dbService.write { db in
            // Fetch user
            guard var user = try User.fetchOne(db, key: userId) else {
                throw DatabaseError.notFound("User not found")
            }

            // Remove the token
            user.refreshTokens.removeAll { $0.tokenId == tokenId }

            // Update user
            try user.update(db)
        }

        logger.debug("Removed refresh token \(tokenId) for user: \(userId)")
    }

    /// Remove all refresh tokens from a user (logout from all sessions)
    public func removeAllUserRefreshTokens(userId: String) async throws {
        try await dbService.write { db in
            // Fetch user
            guard var user = try User.fetchOne(db, key: userId) else {
                throw DatabaseError.notFound("User not found")
            }

            // Remove all tokens
            user.refreshTokens = []

            // Update user
            try user.update(db)
        }

        logger.info("Removed all refresh tokens for user: \(userId)")
    }

    /// Verify a user's refresh token exists and is valid
    public func verifyUserRefreshToken(userId: String, tokenId: String) async throws -> Bool {
        return try await dbService.read { db in
            guard let user = try User.fetchOne(db, key: userId) else {
                return false
            }

            // Find the token
            guard let token = user.refreshTokens.first(where: { $0.tokenId == tokenId }) else {
                return false
            }

            // Check if expired
            return !token.isExpired
        }
    }

    /// Clean expired refresh tokens for a user
    public func cleanExpiredUserTokens(userId: String) async throws {
        let cleanedCount = try await dbService.write { db in
            guard var user = try User.fetchOne(db, key: userId) else {
                return 0
            }

            let originalCount = user.refreshTokens.count
            user.refreshTokens = user.refreshTokens.filter { !$0.isExpired }

            if originalCount != user.refreshTokens.count {
                try user.update(db)
                return originalCount - user.refreshTokens.count
            }
            return 0
        }

        if cleanedCount > 0 {
            logger.debug("Cleaned \(cleanedCount) expired tokens for user: \(userId)")
        }
    }

    // MARK: - Admin Sessions

    /// Add a refresh token to an admin
    public func addAdminRefreshToken(adminId: String, token: StoredRefreshToken) async throws {
        try await dbService.write { db in
            // Fetch admin
            guard var admin = try Admin.fetchOne(db, key: adminId) else {
                throw DatabaseError.notFound("Admin not found")
            }

            // Clean expired tokens
            admin.refreshTokens = admin.refreshTokens.filter { !$0.isExpired }

            // Add new token
            admin.refreshTokens.append(token)

            // Update admin
            try admin.update(db)
        }

        logger.debug("Added refresh token for admin: \(adminId)")
    }

    /// Remove a specific refresh token from an admin
    public func removeAdminRefreshToken(adminId: String, tokenId: String) async throws {
        try await dbService.write { db in
            // Fetch admin
            guard var admin = try Admin.fetchOne(db, key: adminId) else {
                throw DatabaseError.notFound("Admin not found")
            }

            // Remove the token
            admin.refreshTokens.removeAll { $0.tokenId == tokenId }

            // Update admin
            try admin.update(db)
        }

        logger.debug("Removed refresh token \(tokenId) for admin: \(adminId)")
    }

    /// Remove all refresh tokens from an admin (logout from all sessions)
    public func removeAllAdminRefreshTokens(adminId: String) async throws {
        try await dbService.write { db in
            // Fetch admin
            guard var admin = try Admin.fetchOne(db, key: adminId) else {
                throw DatabaseError.notFound("Admin not found")
            }

            // Remove all tokens
            admin.refreshTokens = []

            // Update admin
            try admin.update(db)
        }

        logger.info("Removed all refresh tokens for admin: \(adminId)")
    }

    /// Verify an admin's refresh token exists and is valid
    public func verifyAdminRefreshToken(adminId: String, tokenId: String) async throws -> Bool {
        return try await dbService.read { db in
            guard let admin = try Admin.fetchOne(db, key: adminId) else {
                return false
            }

            // Find the token
            guard let token = admin.refreshTokens.first(where: { $0.tokenId == tokenId }) else {
                return false
            }

            // Check if expired
            return !token.isExpired
        }
    }

    /// Update last login time for a user
    public func updateUserLastLogin(userId: String) async throws {
        try await dbService.write { db in
            guard var user = try User.fetchOne(db, key: userId) else {
                throw DatabaseError.notFound("User not found")
            }

            user.lastLogin = Date()
            try user.update(db)
        }
    }

    /// Update last login time for an admin
    public func updateAdminLastLogin(adminId: String) async throws {
        try await dbService.write { db in
            guard var admin = try Admin.fetchOne(db, key: adminId) else {
                throw DatabaseError.notFound("Admin not found")
            }

            admin.lastLogin = Date()
            try admin.update(db)
        }
    }

    // MARK: - Cleanup

    /// Clean all expired tokens from all users and admins
    public func cleanupExpiredTokens() async throws {
        let (usersUpdated, adminsUpdated) = try await dbService.write { db -> (Int, Int) in
            var usersCount = 0
            var adminsCount = 0

            // Clean user tokens
            let users = try User.fetchAll(db)
            for var user in users {
                let originalCount = user.refreshTokens.count
                user.refreshTokens = user.refreshTokens.filter { !$0.isExpired }

                if originalCount != user.refreshTokens.count {
                    try user.update(db)
                    usersCount += 1
                }
            }

            // Clean admin tokens
            let admins = try Admin.fetchAll(db)
            for var admin in admins {
                let originalCount = admin.refreshTokens.count
                admin.refreshTokens = admin.refreshTokens.filter { !$0.isExpired }

                if originalCount != admin.refreshTokens.count {
                    try admin.update(db)
                    adminsCount += 1
                }
            }

            return (usersCount, adminsCount)
        }

        logger.info("Cleaned expired tokens: \(usersUpdated) users, \(adminsUpdated) admins")
    }
}
