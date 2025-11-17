import Foundation

/// Base application error protocol
public protocol AppErrorProtocol: Error, CustomStringConvertible {
    var code: String { get }
    var statusCode: Int { get }
    var message: String { get }
    var metadata: [String: Any]? { get }
}

/// Main application error enum
public enum AppError: AppErrorProtocol {
    case internalServerError(String)
    case notFound(String)
    case unauthorized(String)
    case forbidden(String)
    case badRequest(String)
    case conflict(String)
    case validationFailed([ValidationError])
    case databaseError(DatabaseError)
    case configurationError(ConfigError)

    public var code: String {
        switch self {
        case .internalServerError: return "INTERNAL_SERVER_ERROR"
        case .notFound: return "NOT_FOUND"
        case .unauthorized: return "UNAUTHORIZED"
        case .forbidden: return "FORBIDDEN"
        case .badRequest: return "BAD_REQUEST"
        case .conflict: return "CONFLICT"
        case .validationFailed: return "VALIDATION_FAILED"
        case .databaseError: return "DATABASE_ERROR"
        case .configurationError: return "CONFIGURATION_ERROR"
        }
    }

    public var statusCode: Int {
        switch self {
        case .internalServerError: return 500
        case .notFound: return 404
        case .unauthorized: return 401
        case .forbidden: return 403
        case .badRequest: return 400
        case .conflict: return 409
        case .validationFailed: return 422
        case .databaseError: return 500
        case .configurationError: return 500
        }
    }

    public var message: String {
        switch self {
        case .internalServerError(let msg): return msg
        case .notFound(let msg): return msg
        case .unauthorized(let msg): return msg
        case .forbidden(let msg): return msg
        case .badRequest(let msg): return msg
        case .conflict(let msg): return msg
        case .validationFailed(let errors):
            return "Validation failed: \(errors.map { $0.description }.joined(separator: ", "))"
        case .databaseError(let error): return error.description
        case .configurationError(let error): return error.description
        }
    }

    public var metadata: [String: Any]? {
        switch self {
        case .validationFailed(let errors):
            return ["errors": errors.map { ["field": $0.field, "message": $0.message] }]
        default:
            return nil
        }
    }

    public var description: String {
        return "[\(code)] \(message)"
    }
}

// MARK: - Error Response

/// Standardized error response structure
public struct ErrorResponse: Codable, Sendable {
    public let success: Bool
    public let error: ErrorDetail

    public struct ErrorDetail: Codable, Sendable {
        public let code: String
        public let message: String
        public let metadata: [String: String]?

        public init(code: String, message: String, metadata: [String: String]? = nil) {
            self.code = code
            self.message = message
            self.metadata = metadata
        }
    }

    public init(error: AppErrorProtocol) {
        self.success = false

        // Convert metadata to string dictionary for JSON serialization
        var stringMetadata: [String: String]?
        if let metadata = error.metadata {
            stringMetadata = metadata.mapValues { String(describing: $0) }
        }

        self.error = ErrorDetail(
            code: error.code,
            message: error.message,
            metadata: stringMetadata
        )
    }

    public init(code: String, message: String, metadata: [String: String]? = nil) {
        self.success = false
        self.error = ErrorDetail(code: code, message: message, metadata: metadata)
    }
}

// MARK: - Helper Extensions

extension AppError {
    public static func wrap(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        } else if let dbError = error as? DatabaseError {
            return .databaseError(dbError)
        } else if let configError = error as? ConfigError {
            return .configurationError(configError)
        } else {
            return .internalServerError(error.localizedDescription)
        }
    }
}
