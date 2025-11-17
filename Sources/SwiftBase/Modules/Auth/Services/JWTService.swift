import Foundation
import SwiftJWT

/// Service for JWT token generation and validation
public actor JWTService {
    private let secret: String
    private let accessTokenExpiry: Int // minutes
    private let refreshTokenExpiry: Int // days
    private let logger: LoggerService

    public init(
        secret: String,
        accessTokenExpiry: Int = 15,
        refreshTokenExpiry: Int = 7
    ) {
        self.secret = secret
        self.accessTokenExpiry = accessTokenExpiry
        self.refreshTokenExpiry = refreshTokenExpiry
        self.logger = LoggerService.shared
    }

    // MARK: - Token Generation

    /// Generate an access token
    public func generateAccessToken(userId: String, type: String) throws -> String {
        let now = Date()
        let expiresAt = now.addingTimeInterval(TimeInterval(accessTokenExpiry * 60))

        let claims = AccessTokenClaims(
            userId: userId,
            type: type,
            issuedAt: now,
            expiresAt: expiresAt
        )

        var jwt = JWT(claims: claims)
        let signer = JWTSigner.hs256(key: Data(secret.utf8))

        guard let token = try? jwt.sign(using: signer) else {
            throw JWTError.signingFailed
        }

        return token
    }

    /// Generate a refresh token
    public func generateRefreshToken(userId: String, type: String) throws -> (token: String, stored: StoredRefreshToken) {
        let now = Date()
        let expiresAt = now.addingTimeInterval(TimeInterval(refreshTokenExpiry * 24 * 60 * 60))
        let tokenId = UUID().uuidString

        let claims = RefreshTokenClaims(
            userId: userId,
            type: type,
            tokenId: tokenId,
            issuedAt: now,
            expiresAt: expiresAt
        )

        var jwt = JWT(claims: claims)
        let signer = JWTSigner.hs256(key: Data(secret.utf8))

        guard let token = try? jwt.sign(using: signer) else {
            throw JWTError.signingFailed
        }

        let stored = StoredRefreshToken(
            tokenId: tokenId,
            issuedAt: now,
            expiresAt: expiresAt
        )

        return (token, stored)
    }

    /// Generate both access and refresh tokens
    public func generateTokenPair(userId: String, type: String) throws -> (pair: TokenPair, stored: StoredRefreshToken) {
        let accessToken = try generateAccessToken(userId: userId, type: type)
        let (refreshToken, stored) = try generateRefreshToken(userId: userId, type: type)

        let pair = TokenPair(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: accessTokenExpiry * 60
        )

        return (pair, stored)
    }

    // MARK: - Token Validation

    /// Validate and decode an access token
    public func validateAccessToken(_ token: String) throws -> AccessTokenClaims {
        let verifier = JWTVerifier.hs256(key: Data(secret.utf8))

        guard let jwt = try? JWT<AccessTokenClaims>(jwtString: token, verifier: verifier) else {
            throw JWTError.invalidToken
        }

        // Check expiration
        if jwt.claims.exp < Date() {
            throw JWTError.tokenExpired
        }

        return jwt.claims
    }

    /// Validate and decode a refresh token
    public func validateRefreshToken(_ token: String) throws -> RefreshTokenClaims {
        let verifier = JWTVerifier.hs256(key: Data(secret.utf8))

        guard let jwt = try? JWT<RefreshTokenClaims>(jwtString: token, verifier: verifier) else {
            throw JWTError.invalidToken
        }

        // Check expiration
        if jwt.claims.exp < Date() {
            throw JWTError.tokenExpired
        }

        return jwt.claims
    }

    // MARK: - Token Helpers

    /// Extract user ID from token without full validation (for logging/debugging)
    public func extractUserId(from token: String) -> String? {
        guard let jwt = try? JWT<AccessTokenClaims>(jwtString: token) else {
            return nil
        }
        return jwt.claims.sub
    }
}

// MARK: - Errors

public enum JWTError: Error, CustomStringConvertible {
    case signingFailed
    case invalidToken
    case tokenExpired
    case invalidSecret

    public var description: String {
        switch self {
        case .signingFailed:
            return "Failed to sign JWT token"
        case .invalidToken:
            return "Invalid JWT token"
        case .tokenExpired:
            return "JWT token has expired"
        case .invalidSecret:
            return "Invalid JWT secret"
        }
    }
}
