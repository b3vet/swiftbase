import Foundation
import Hummingbird
import HTTPTypes
import NIOCore

/// Middleware for centralized error handling
public struct ErrorMiddleware<Context: RequestContext>: RouterMiddleware {
    private let logger: LoggerService
    private let includeStackTrace: Bool

    public init(
        logger: LoggerService = .shared,
        includeStackTrace: Bool = false
    ) {
        self.logger = logger
        self.includeStackTrace = includeStackTrace
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        do {
            return try await next(request, context)
        } catch {
            return handleError(error, request: request)
        }
    }

    private func handleError(_ error: Error, request: Request) -> Response {
        // Log the error
        logger.error("Request error on \(request.method.rawValue) \(request.uri.path)", error: error)

        // Convert error to standardized response
        let errorResponse: ErrorResponse
        let statusCode: HTTPResponse.Status

        if let httpError = error as? HTTPError {
            // Handle HTTPError from Hummingbird
            statusCode = httpError.status
            errorResponse = ErrorResponse(
                code: getErrorCode(for: httpError.status),
                message: httpError.body ?? "Request failed"
            )
        } else if let appError = error as? AppError {
            // Handle our custom AppError
            statusCode = HTTPResponse.Status(code: appError.statusCode)
            errorResponse = ErrorResponse(error: appError)
        } else if let appErrorProtocol = error as? AppErrorProtocol {
            // Handle any error conforming to AppErrorProtocol (including StorageError)
            statusCode = HTTPResponse.Status(code: appErrorProtocol.statusCode)
            errorResponse = ErrorResponse(error: appErrorProtocol)
        } else if let validationError = error as? ValidationError {
            // Handle validation errors
            statusCode = .unprocessableContent
            errorResponse = ErrorResponse(
                code: "VALIDATION_ERROR",
                message: validationError.description
            )
        } else if let dbError = error as? DatabaseError {
            // Handle database errors
            statusCode = .internalServerError
            errorResponse = ErrorResponse(
                code: "DATABASE_ERROR",
                message: dbError.description
            )
        } else {
            // Handle unknown errors
            statusCode = .internalServerError
            errorResponse = ErrorResponse(
                code: "INTERNAL_SERVER_ERROR",
                message: includeStackTrace ? error.localizedDescription : "An internal error occurred"
            )
        }

        // Encode response
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(errorResponse),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            // Fallback if encoding fails
            let fallback = """
            {"success":false,"error":{"code":"ENCODING_ERROR","message":"Failed to encode error response","timestamp":"\(ISO8601DateFormatter().string(from: Date()))"}}
            """
            return Response(
                status: .internalServerError,
                headers: [.contentType: "application/json"],
                body: .init(byteBuffer: ByteBuffer(string: fallback))
            )
        }

        return Response(
            status: statusCode,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    private func getErrorCode(for status: HTTPResponse.Status) -> String {
        switch status {
        case .badRequest:
            return "BAD_REQUEST"
        case .unauthorized:
            return "UNAUTHORIZED"
        case .forbidden:
            return "FORBIDDEN"
        case .notFound:
            return "NOT_FOUND"
        case .methodNotAllowed:
            return "METHOD_NOT_ALLOWED"
        case .conflict:
            return "CONFLICT"
        case .unprocessableContent:
            return "UNPROCESSABLE_CONTENT"
        case .tooManyRequests:
            return "TOO_MANY_REQUESTS"
        case .internalServerError:
            return "INTERNAL_SERVER_ERROR"
        case .notImplemented:
            return "NOT_IMPLEMENTED"
        case .badGateway:
            return "BAD_GATEWAY"
        case .serviceUnavailable:
            return "SERVICE_UNAVAILABLE"
        default:
            return "HTTP_\(status.code)"
        }
    }
}

// MARK: - Enhanced ErrorResponse

extension ErrorResponse {
    /// Create error response from HTTP status
    public static func fromStatus(_ status: HTTPResponse.Status, message: String? = nil) -> ErrorResponse {
        let code: String
        let defaultMessage: String

        switch status {
        case .badRequest:
            code = "BAD_REQUEST"
            defaultMessage = "Bad request"
        case .unauthorized:
            code = "UNAUTHORIZED"
            defaultMessage = "Unauthorized"
        case .forbidden:
            code = "FORBIDDEN"
            defaultMessage = "Forbidden"
        case .notFound:
            code = "NOT_FOUND"
            defaultMessage = "Not found"
        case .conflict:
            code = "CONFLICT"
            defaultMessage = "Conflict"
        case .unprocessableContent:
            code = "UNPROCESSABLE_CONTENT"
            defaultMessage = "Unprocessable content"
        case .internalServerError:
            code = "INTERNAL_SERVER_ERROR"
            defaultMessage = "Internal server error"
        default:
            code = "HTTP_\(status.code)"
            defaultMessage = "Request failed"
        }

        return ErrorResponse(code: code, message: message ?? defaultMessage)
    }
}
