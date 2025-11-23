import Foundation
import Hummingbird

/// Middleware for JWT authentication
public struct JWTMiddleware<Context: RequestContext>: RouterMiddleware {
    private let jwtService: JWTService
    private let requireAdmin: Bool

    public init(jwtService: JWTService, requireAdmin: Bool = false) {
        self.jwtService = jwtService
        self.requireAdmin = requireAdmin
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        // Extract token from Authorization header or query parameter
        let token: String

        if let authHeader = request.headers[.authorization] {
            // Expect "Bearer <token>"
            let parts = authHeader.split(separator: " ")
            guard parts.count == 2, parts[0] == "Bearer" else {
                throw HTTPError (.unauthorized, message: "Invalid Authorization header format")
            }
            token = String(parts[1])
        } else if let tokenParam = request.uri.queryParameters.get("token") {
            // Use token from query parameter
            token = tokenParam
        } else {
            throw HTTPError(.unauthorized, message: "Missing authentication token")
        }

        // Validate token
        let claims: AccessTokenClaims
        do {
            claims = try await jwtService.validateAccessToken(token)
        } catch JWTError.tokenExpired {
            throw HTTPError(.unauthorized, message: "Token has expired")
        } catch {
            throw HTTPError(.unauthorized, message: "Invalid token")
        }

        // Check if admin is required
        if requireAdmin && claims.type != "admin" {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        // Store claims in request context for route handlers to use
        // Note: This would require extending the RequestContext
        // For now, handlers can re-validate the token if needed

        // Proceed to next handler
        return try await next(request, context)
    }
}

/// Auth-related HTTP errors
public extension HTTPError {
    static func unauthorized(_ message: String = "Unauthorized") -> HTTPError {
        return HTTPError(.unauthorized, message: message)
    }

    static func forbidden(_ message: String = "Forbidden") -> HTTPError {
        return HTTPError(.forbidden, message: message)
    }
}

/// Helper to extract user ID from token in request
public struct AuthHelpers {
    public static func extractUserId(from request: Request, jwtService: JWTService) async -> String? {
        guard let authHeader = request.headers[.authorization] else {
            return nil
        }

        let parts = authHeader.split(separator: " ")
        guard parts.count == 2, parts[0] == "Bearer" else {
            return nil
        }

        let token = String(parts[1])
        return await jwtService.extractUserId(from: token)
    }

    public static func validateAndExtractClaims(from request: Request, jwtService: JWTService) async throws -> AccessTokenClaims {
        guard let authHeader = request.headers[.authorization] else {
            throw HTTPError(.unauthorized, message: "Missing Authorization header")
        }

        let parts = authHeader.split(separator: " ")
        guard parts.count == 2, parts[0] == "Bearer" else {
            throw HTTPError(.unauthorized, message: "Invalid Authorization header format")
        }

        let token = String(parts[1])
        return try await jwtService.validateAccessToken(token)
    }
}
