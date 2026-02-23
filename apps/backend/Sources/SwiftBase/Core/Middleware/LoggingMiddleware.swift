import Foundation
import Hummingbird
import HTTPTypes

/// Middleware for request/response logging with performance metrics
public struct LoggingMiddleware<Context: RequestContext>: RouterMiddleware {
    private let logger: LoggerService
    private let logRequestBody: Bool
    private let logResponseBody: Bool

    public init(
        logger: LoggerService = .shared,
        logRequestBody: Bool = false,
        logResponseBody: Bool = false
    ) {
        self.logger = logger
        self.logRequestBody = logRequestBody
        self.logResponseBody = logResponseBody
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        // Generate request ID
        let requestId = UUID().uuidString

        // Start timing
        let startTime = Date()

        // Extract request info
        let method = request.method.rawValue
        let path = request.uri.path
        let query = request.uri.query ?? ""
        let clientIP = extractClientIP(from: request)
        let userAgent = request.headers[.userAgent] ?? "unknown"

        // Log incoming request
        logger.info("📨 Incoming request", metadata: [
            "requestId": requestId,
            "method": method,
            "path": path,
            "query": query,
            "clientIP": clientIP,
            "userAgent": userAgent
        ])

        // Log request body if enabled
        if logRequestBody {
            if let contentType = request.headers[.contentType],
               contentType.contains("application/json") {
                // Note: We can't easily read the body here without consuming it
                // This would require buffering which affects performance
                logger.debug("Request body logging enabled (not implemented for streaming)")
            }
        }

        // Execute request
        let response: Response
        var error: Error?

        do {
            response = try await next(request, context)
        } catch let e {
            error = e
            throw e
        }

        // Calculate duration
        let duration = Date().timeIntervalSince(startTime)
        let durationMs = duration * 1000

        // Log response
        if let err = error {
            logger.error("❌ Request failed", error: err, metadata: [
                "requestId": requestId,
                "method": method,
                "path": path,
                "duration": String(format: "%.2fms", durationMs),
                "error": err.localizedDescription
            ])
        } else {
            let statusCode = response.status.code

            // Determine log level based on status code
            let logEmoji: String
            let logLevel: String
            if statusCode >= 500 {
                logEmoji = "💥"
                logLevel = "error"
            } else if statusCode >= 400 {
                logEmoji = "⚠️"
                logLevel = "warning"
            } else if statusCode >= 300 {
                logEmoji = "↩️"
                logLevel = "info"
            } else {
                logEmoji = "✅"
                logLevel = "info"
            }

            let message = "\(logEmoji) Request completed"

            let metadata: [String: String] = [
                "requestId": requestId,
                "method": method,
                "path": path,
                "status": "\(statusCode)",
                "duration": String(format: "%.2fms", durationMs)
            ]

            if logLevel == "error" {
                logger.error(message, metadata: metadata)
            } else if logLevel == "warning" {
                logger.warning(message, metadata: metadata)
            } else {
                logger.info(message, metadata: metadata)
            }
        }

        return response
    }

    private func extractClientIP(from request: Request) -> String {
        // Check X-Forwarded-For header first (for proxies)
        if let forwardedFor = request.headers[.init("X-Forwarded-For")!] {
            let ips = forwardedFor.split(separator: ",")
            if let firstIP = ips.first {
                return String(firstIP).trimmingCharacters(in: .whitespaces)
            }
        }

        // Check X-Real-IP header (nginx)
        if let realIP = request.headers[.init("X-Real-IP")!] {
            return realIP
        }

        // Fallback to remote address (not directly available in Hummingbird Request)
        return "unknown"
    }
}

// MARK: - LoggerService Extensions

extension LoggerService {
    /// Log with metadata
    public func info(_ message: String, metadata: [String: String]) {
        let metadataStr = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        info("\(message) [\(metadataStr)]")
    }

    /// Log warning with metadata
    public func warning(_ message: String, metadata: [String: String]) {
        let metadataStr = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        warning("\(message) [\(metadataStr)]")
    }

    /// Log error with metadata
    public func error(_ message: String, metadata: [String: String]) {
        let metadataStr = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        error("\(message) [\(metadataStr)]")
    }
}
