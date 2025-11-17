import Foundation

/// Wrapper to make non-Sendable types work with Sendable contexts
private struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}

/// Logger service with structured JSON logging support
public final class LoggerService: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = LoggerService()

    // MARK: - Log Level

    public enum LogLevel: String, Comparable, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"

        public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.priority < rhs.priority
        }

        var priority: Int {
            switch self {
            case .debug: return 0
            case .info: return 1
            case .warning: return 2
            case .error: return 3
            case .critical: return 4
            }
        }
    }

    // MARK: - Properties

    public var logLevel: LogLevel = .info
    public var isJSONFormat: Bool = true

    private let dateFormatter: ISO8601DateFormatter
    private let queue = DispatchQueue(label: "com.swiftbase.logger", qos: .utility)

    // MARK: - Initialization

    private init() {
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    // MARK: - Public Logging Methods

    public func debug(
        _ message: String,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func warning(
        _ message: String,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, metadata: metadata, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        error: Error? = nil,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var combinedMetadata = metadata ?? [:]
        if let error = error {
            combinedMetadata["error"] = String(describing: error)
        }
        log(level: .error, message: message, metadata: combinedMetadata, file: file, function: function, line: line)
    }

    public func critical(
        _ message: String,
        error: Error? = nil,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var combinedMetadata = metadata ?? [:]
        if let error = error {
            combinedMetadata["error"] = String(describing: error)
        }
        log(level: .critical, message: message, metadata: combinedMetadata, file: file, function: function, line: line)
    }

    // MARK: - Core Logging

    private func log(
        level: LogLevel,
        message: String,
        metadata: [String: Any]?,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= logLevel else { return }

        // Wrap metadata in UncheckedSendable to safely pass to async context
        let wrappedMetadata = UncheckedSendable(metadata)

        queue.async { [weak self] in
            guard let self = self else { return }

            let logEntry = self.createLogEntry(
                level: level,
                message: message,
                metadata: wrappedMetadata.value,
                file: file,
                function: function,
                line: line
            )

            self.write(logEntry)
        }
    }

    private func createLogEntry(
        level: LogLevel,
        message: String,
        metadata: [String: Any]?,
        file: String,
        function: String,
        line: Int
    ) -> String {
        let timestamp = dateFormatter.string(from: Date())

        if isJSONFormat {
            return createJSONLogEntry(
                timestamp: timestamp,
                level: level,
                message: message,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        } else {
            return createTextLogEntry(
                timestamp: timestamp,
                level: level,
                message: message,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }
    }

    private func createJSONLogEntry(
        timestamp: String,
        level: LogLevel,
        message: String,
        metadata: [String: Any]?,
        file: String,
        function: String,
        line: Int
    ) -> String {
        var logDict: [String: Any] = [
            "timestamp": timestamp,
            "level": level.rawValue,
            "message": message,
            "source": [
                "file": (file as NSString).lastPathComponent,
                "function": function,
                "line": line
            ]
        ]

        if let metadata = metadata, !metadata.isEmpty {
            logDict["metadata"] = metadata
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: logDict, options: [])
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return """
            {"timestamp":"\(timestamp)","level":"ERROR","message":"Failed to serialize log entry","error":"\(error)"}
            """
        }
    }

    private func createTextLogEntry(
        timestamp: String,
        level: LogLevel,
        message: String,
        metadata: [String: Any]?,
        file: String,
        function: String,
        line: Int
    ) -> String {
        let fileName = (file as NSString).lastPathComponent
        var entry = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(message)"

        if let metadata = metadata, !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            entry += " | \(metadataString)"
        }

        return entry
    }

    private func write(_ logEntry: String) {
        print(logEntry)
    }

    // MARK: - Performance Logging

    public func logPerformance(
        operation: String,
        duration: TimeInterval,
        metadata: [String: Any]? = nil
    ) {
        var performanceMetadata = metadata ?? [:]
        performanceMetadata["operation"] = operation
        performanceMetadata["duration_ms"] = String(format: "%.2f", duration * 1000)

        info("Performance metric", metadata: performanceMetadata)
    }

    // MARK: - Request Logging

    public func logRequest(
        method: String,
        path: String,
        statusCode: Int,
        duration: TimeInterval,
        metadata: [String: Any]? = nil
    ) {
        var requestMetadata = metadata ?? [:]
        requestMetadata["method"] = method
        requestMetadata["path"] = path
        requestMetadata["status_code"] = statusCode
        requestMetadata["duration_ms"] = String(format: "%.2f", duration * 1000)

        let level: LogLevel = statusCode >= 500 ? .error : (statusCode >= 400 ? .warning : .info)

        log(
            level: level,
            message: "\(method) \(path) \(statusCode)",
            metadata: requestMetadata,
            file: #file,
            function: #function,
            line: #line
        )
    }
}

// MARK: - Convenience Methods

extension LoggerService {
    public func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let start = Date()
        defer {
            let duration = Date().timeIntervalSince(start)
            logPerformance(operation: operation, duration: duration)
        }
        return try block()
    }

    public func measureAsync<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let start = Date()
        defer {
            let duration = Date().timeIntervalSince(start)
            logPerformance(operation: operation, duration: duration)
        }
        return try await block()
    }
}
