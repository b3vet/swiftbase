import Foundation
import Hummingbird
import HTTPTypes

/// Middleware for CORS (Cross-Origin Resource Sharing) support
public struct CORSMiddleware<Context: RequestContext>: RouterMiddleware {
    private let allowedOrigins: [String]
    private let allowedMethods: [HTTPRequest.Method]
    private let allowedHeaders: [String]
    private let exposedHeaders: [String]
    private let allowCredentials: Bool
    private let maxAge: Int

    public init(
        allowedOrigins: [String] = ["*"],
        allowedMethods: [HTTPRequest.Method] = [.get, .post, .put, .delete, .patch, .options],
        allowedHeaders: [String] = ["Content-Type", "Authorization", "X-Requested-With"],
        exposedHeaders: [String] = ["Content-Type", "Authorization"],
        allowCredentials: Bool = true,
        maxAge: Int = 86400 // 24 hours
    ) {
        self.allowedOrigins = allowedOrigins
        self.allowedMethods = allowedMethods
        self.allowedHeaders = allowedHeaders
        self.exposedHeaders = exposedHeaders
        self.allowCredentials = allowCredentials
        self.maxAge = maxAge
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        // Get origin from request
        let origin = request.headers[.origin] ?? "*"

        // Check if origin is allowed
        let allowedOrigin: String
        if allowedOrigins.contains("*") {
            allowedOrigin = origin
        } else if allowedOrigins.contains(origin) {
            allowedOrigin = origin
        } else {
            allowedOrigin = allowedOrigins.first ?? "*"
        }

        // Handle preflight requests
        if request.method == .options {
            var headers: HTTPFields = [:]
            headers[.accessControlAllowOrigin] = allowedOrigin
            headers[.accessControlAllowMethods] = allowedMethods.map { $0.rawValue }.joined(separator: ", ")
            headers[.accessControlAllowHeaders] = allowedHeaders.joined(separator: ", ")
            headers[.accessControlMaxAge] = "\(maxAge)"

            if allowCredentials {
                headers[.accessControlAllowCredentials] = "true"
            }

            return Response(
                status: .noContent,
                headers: headers
            )
        }

        // Process normal request
        var response = try await next(request, context)

        // Add CORS headers to response
        response.headers[.accessControlAllowOrigin] = allowedOrigin
        response.headers[.accessControlExposeHeaders] = exposedHeaders.joined(separator: ", ")

        if allowCredentials {
            response.headers[.accessControlAllowCredentials] = "true"
        }

        return response
    }
}

// MARK: - HTTPField Extensions

extension HTTPField.Name {
    public static let accessControlAllowOrigin = Self("Access-Control-Allow-Origin")!
    public static let accessControlAllowMethods = Self("Access-Control-Allow-Methods")!
    public static let accessControlAllowHeaders = Self("Access-Control-Allow-Headers")!
    public static let accessControlExposeHeaders = Self("Access-Control-Expose-Headers")!
    public static let accessControlAllowCredentials = Self("Access-Control-Allow-Credentials")!
    public static let accessControlMaxAge = Self("Access-Control-Max-Age")!
    public static let origin = Self("Origin")!
}
