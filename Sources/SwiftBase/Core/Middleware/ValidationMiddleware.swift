import Foundation
import Hummingbird
import HTTPTypes

/// Middleware for request validation
public struct ValidationMiddleware<Context: RequestContext>: RouterMiddleware {
    private let maxBodySize: Int
    private let requiredContentType: String?
    private let validateHeaders: Bool

    public init(
        maxBodySize: Int = 10_485_760, // 10MB default
        requiredContentType: String? = nil,
        validateHeaders: Bool = true
    ) {
        self.maxBodySize = maxBodySize
        self.requiredContentType = requiredContentType
        self.validateHeaders = validateHeaders
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        // Validate request method
        guard isValidMethod(request.method) else {
            throw HTTPError(.methodNotAllowed, message: "Method \(request.method.rawValue) not allowed")
        }

        // Validate content length for POST, PUT, PATCH
        if request.method == .post || request.method == .put || request.method == .patch {
            if let contentLength = request.headers[.contentLength] {
                if let length = Int(contentLength), length > maxBodySize {
                    throw HTTPError(.contentTooLarge, message: "Request body too large. Maximum size is \(maxBodySize) bytes")
                }
            }

            // Validate content type if required
            if let requiredType = requiredContentType {
                guard let contentType = request.headers[.contentType] else {
                    throw HTTPError(.badRequest, message: "Content-Type header is required")
                }

                guard contentType.contains(requiredType) else {
                    throw HTTPError(.unsupportedMediaType, message: "Expected Content-Type: \(requiredType)")
                }
            }
        }

        // Validate required headers
        if validateHeaders {
            try validateRequiredHeaders(request)
        }

        return try await next(request, context)
    }

    private func isValidMethod(_ method: HTTPRequest.Method) -> Bool {
        // Allow common HTTP methods
        return [.get, .post, .put, .patch, .delete, .options, .head].contains(method)
    }

    private func validateRequiredHeaders(_ request: Request) throws {
        // Validate Accept header for content negotiation
        if request.method != .options {
            // We can be lenient here - if no Accept header, assume application/json
            if let accept = request.headers[.accept] {
                // Check if we can serve the requested content type
                let acceptableTypes = ["application/json", "application/*", "*/*"]
                let hasAcceptable = acceptableTypes.contains { accept.contains($0) }

                if !hasAcceptable {
                    throw HTTPError(.notAcceptable, message: "Server only produces application/json")
                }
            }
        }
    }
}

// MARK: - HTTP Status Extensions

extension HTTPResponse.Status {
    public static let contentTooLarge = HTTPResponse.Status(code: 413, reasonPhrase: "Content Too Large")
    public static let unsupportedMediaType = HTTPResponse.Status(code: 415, reasonPhrase: "Unsupported Media Type")
    public static let notAcceptable = HTTPResponse.Status(code: 406, reasonPhrase: "Not Acceptable")
}

// MARK: - HTTPError Extensions

extension HTTPError {
    public static func contentTooLarge(_ message: String) -> HTTPError {
        return HTTPError(.contentTooLarge, message: message)
    }

    public static func unsupportedMediaType(_ message: String) -> HTTPError {
        return HTTPError(.unsupportedMediaType, message: message)
    }

    public static func notAcceptable(_ message: String) -> HTTPError {
        return HTTPError(.notAcceptable, message: message)
    }
}
