import Foundation
import Hummingbird

// MARK: - Standardized API Response

/// Standardized API response wrapper for all endpoints
public struct APIResponse<T: Codable & Sendable>: Codable, Sendable, ResponseEncodable {
    public let success: Bool
    public let data: T?
    public let error: ErrorDetail?
    public let metadata: ResponseMetadata?

    public init(success: Bool, data: T? = nil, error: ErrorDetail? = nil, metadata: ResponseMetadata? = nil) {
        self.success = success
        self.data = data
        self.error = error
        self.metadata = metadata
    }

    /// Create a successful response
    public static func success(data: T, metadata: ResponseMetadata? = nil) -> APIResponse<T> {
        return APIResponse(success: true, data: data, metadata: metadata)
    }

    /// Create an error response
    public static func error(code: String, message: String, metadata: [String: String]? = nil) -> APIResponse<T> {
        return APIResponse(
            success: false,
            error: ErrorDetail(code: code, message: message, metadata: metadata)
        )
    }
}

/// Error detail structure
public struct ErrorDetail: Codable, Sendable {
    public let code: String
    public let message: String
    public let metadata: [String: String]?
    public let timestamp: String

    public init(code: String, message: String, metadata: [String: String]? = nil) {
        self.code = code
        self.message = message
        self.metadata = metadata
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }
}

/// Response metadata for pagination, timing, etc.
public struct ResponseMetadata: Codable, Sendable {
    public let timestamp: String
    public let requestId: String?
    public let duration: Double?
    public let version: String?
    public let pagination: PaginationMetadata?

    public init(
        requestId: String? = nil,
        duration: Double? = nil,
        version: String? = "1.0",
        pagination: PaginationMetadata? = nil
    ) {
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.requestId = requestId
        self.duration = duration
        self.version = version
        self.pagination = pagination
    }
}

/// Pagination metadata
public struct PaginationMetadata: Codable, Sendable {
    public let total: Int?
    public let count: Int
    public let limit: Int?
    public let offset: Int?
    public let hasMore: Bool?

    public init(total: Int? = nil, count: Int, limit: Int? = nil, offset: Int? = nil, hasMore: Bool? = nil) {
        self.total = total
        self.count = count
        self.limit = limit
        self.offset = offset
        self.hasMore = hasMore
    }
}

// MARK: - Empty Data Type

/// Empty data type for responses with no data
public struct EmptyData: Codable, Sendable {
    public init() {}
}

// MARK: - Generic Data Wrapper

/// Generic wrapper for any codable data
public struct GenericData: Codable, Sendable {
    public let value: AnyCodable

    public init(_ value: Any) {
        self.value = AnyCodable(value)
    }
}
