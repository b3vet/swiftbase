import Foundation
import GRDB
import Hummingbird

/// Admin user model
public struct Admin: Codable, Sendable {
    public var id: String
    public var username: String
    public var passwordHash: String
    public var refreshTokens: [StoredRefreshToken]
    public var lastLogin: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        username: String,
        passwordHash: String,
        refreshTokens: [StoredRefreshToken] = [],
        lastLogin: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.refreshTokens = refreshTokens
        self.lastLogin = lastLogin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Record Conformance

extension Admin: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "_admins"

    public enum Columns: String, ColumnExpression {
        case id, username, passwordHash = "password_hash"
        case refreshTokens = "refresh_tokens"
        case lastLogin = "last_login", createdAt = "created_at", updatedAt = "updated_at"
    }

    public init(row: Row) throws {
        id = row[Columns.id]
        username = row[Columns.username]
        passwordHash = row[Columns.passwordHash]

        // Decode refresh tokens from JSON
        if let tokensJSON: String = row[Columns.refreshTokens] {
            refreshTokens = (try? JSONDecoder().decode([StoredRefreshToken].self, from: Data(tokensJSON.utf8))) ?? []
        } else {
            refreshTokens = []
        }

        lastLogin = row[Columns.lastLogin]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.username] = username
        container[Columns.passwordHash] = passwordHash

        // Encode refresh tokens to JSON
        let tokensData = try JSONEncoder().encode(refreshTokens)
        container[Columns.refreshTokens] = String(data: tokensData, encoding: .utf8)

        container[Columns.lastLogin] = lastLogin
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
    }
}

// MARK: - Public API

public extension Admin {
    /// Admin response (without sensitive data)
    struct Response: Codable, Sendable, ResponseEncodable {
        public let id: String
        public let username: String
        public let lastLogin: Date?
        public let createdAt: Date

        public init(from admin: Admin) {
            self.id = admin.id
            self.username = admin.username
            self.lastLogin = admin.lastLogin
            self.createdAt = admin.createdAt
        }
    }

    func toResponse() -> Response {
        return Response(from: self)
    }
}
