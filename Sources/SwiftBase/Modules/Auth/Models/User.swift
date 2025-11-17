import Foundation
import GRDB
import Hummingbird

/// User model
public struct User: Codable, Sendable {
    public var id: String
    public var email: String
    public var passwordHash: String
    public var emailVerified: Bool
    public var refreshTokens: [StoredRefreshToken]
    public var metadata: [String: String]
    public var lastLogin: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        email: String,
        passwordHash: String,
        emailVerified: Bool = false,
        refreshTokens: [StoredRefreshToken] = [],
        metadata: [String: String] = [:],
        lastLogin: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.emailVerified = emailVerified
        self.refreshTokens = refreshTokens
        self.metadata = metadata
        self.lastLogin = lastLogin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Record Conformance

extension User: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "_users"

    public enum Columns: String, ColumnExpression {
        case id, email, passwordHash = "password_hash", emailVerified = "email_verified"
        case refreshTokens = "refresh_tokens", metadata
        case lastLogin = "last_login", createdAt = "created_at", updatedAt = "updated_at"
    }

    public init(row: Row) throws {
        id = row[Columns.id]
        email = row[Columns.email]
        passwordHash = row[Columns.passwordHash]
        emailVerified = row[Columns.emailVerified]

        // Decode refresh tokens from JSON
        if let tokensJSON: String = row[Columns.refreshTokens] {
            refreshTokens = (try? JSONDecoder().decode([StoredRefreshToken].self, from: Data(tokensJSON.utf8))) ?? []
        } else {
            refreshTokens = []
        }

        // Decode metadata from JSON
        if let metadataJSON: String = row[Columns.metadata] {
            metadata = (try? JSONDecoder().decode([String: String].self, from: Data(metadataJSON.utf8))) ?? [:]
        } else {
            metadata = [:]
        }

        lastLogin = row[Columns.lastLogin]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.email] = email
        container[Columns.passwordHash] = passwordHash
        container[Columns.emailVerified] = emailVerified

        // Encode refresh tokens to JSON
        let tokensData = try JSONEncoder().encode(refreshTokens)
        container[Columns.refreshTokens] = String(data: tokensData, encoding: .utf8)

        // Encode metadata to JSON
        let metadataData = try JSONEncoder().encode(metadata)
        container[Columns.metadata] = String(data: metadataData, encoding: .utf8)

        container[Columns.lastLogin] = lastLogin
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
    }
}

// MARK: - Public API

public extension User {
    /// User response (without sensitive data)
    struct Response: Codable, Sendable, ResponseEncodable {
        public let id: String
        public let email: String
        public let emailVerified: Bool
        public let metadata: [String: String]
        public let lastLogin: Date?
        public let createdAt: Date

        public init(from user: User) {
            self.id = user.id
            self.email = user.email
            self.emailVerified = user.emailVerified
            self.metadata = user.metadata
            self.lastLogin = user.lastLogin
            self.createdAt = user.createdAt
        }
    }

    func toResponse() -> Response {
        return Response(from: self)
    }
}
