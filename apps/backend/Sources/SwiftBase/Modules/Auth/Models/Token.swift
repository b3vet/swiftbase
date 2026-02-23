import Foundation
import SwiftJWT
import Hummingbird

/// JWT token pair (access token + refresh token)
public struct TokenPair: Codable, Sendable, ResponseEncodable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int // seconds until access token expires

    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

/// JWT Claims for access tokens
public struct AccessTokenClaims: Claims, Sendable {
    public let sub: String // Subject (user/admin ID)
    public let type: String // "user" or "admin"
    public let iat: Date // Issued at
    public let exp: Date // Expiration

    public init(userId: String, type: String, issuedAt: Date, expiresAt: Date) {
        self.sub = userId
        self.type = type
        self.iat = issuedAt
        self.exp = expiresAt
    }
}

/// JWT Claims for refresh tokens
public struct RefreshTokenClaims: Claims, Sendable {
    public let sub: String // Subject (user/admin ID)
    public let type: String // "user" or "admin"
    public let jti: String // JWT ID (unique token identifier)
    public let iat: Date // Issued at
    public let exp: Date // Expiration

    public init(userId: String, type: String, tokenId: String, issuedAt: Date, expiresAt: Date) {
        self.sub = userId
        self.type = type
        self.jti = tokenId
        self.iat = issuedAt
        self.exp = expiresAt
    }
}

/// Stored refresh token information
public struct StoredRefreshToken: Codable, Sendable {
    public let tokenId: String
    public let issuedAt: Date
    public let expiresAt: Date

    public init(tokenId: String, issuedAt: Date, expiresAt: Date) {
        self.tokenId = tokenId
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool {
        return Date() > expiresAt
    }
}
