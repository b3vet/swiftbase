import Foundation
import Hummingbird
import HTTPTypes
import NIOCore

/// Dedicated handler for AdminUI static files
/// Uses explicit switch-based routing to avoid routing conflicts
public struct AdminUIHandler: Sendable {
    private let publicDirectory: String
    private let logger: LoggerService

    public init(
        publicDirectory: String = "Sources/SwiftBase/Resources/Public",
        logger: LoggerService
    ) {
        self.publicDirectory = publicDirectory
        self.logger = logger
    }

    /// Main handler - routes all admin requests with clear switch logic
    public func handle(request: Request, context: some RequestContext) async throws -> Response {
        let requestPath = request.uri.path
        logger.debug("AdminUI request: \(requestPath)")

        // Normalize and parse the path
        let normalizedPath = requestPath.hasSuffix("/") && requestPath != "/"
            ? String(requestPath.dropLast())
            : requestPath

        // Route based on path pattern
        switch normalizedPath {
        case "/admin":
            // Base admin path - serve index.html
            logger.debug("Serving index.html for base admin path")
            return try await serveFile(at: "index.html")

        default:
            // All other paths under /admin
            if normalizedPath.hasPrefix("/admin/") {
                // Extract the path after /admin/
                let subPath = String(normalizedPath.dropFirst("/admin/".count))

                switch subPath {
                case "":
                    // /admin/ - serve index.html
                    logger.debug("Serving index.html for /admin/")
                    return try await serveFile(at: "index.html")

                case let path where path.hasPrefix("assets/"):
                    // Asset files - serve the actual file
                    logger.debug("Serving asset: \(path)")
                    return try await serveFile(at: path)

                case "index.html":
                    // Explicit index.html request
                    logger.debug("Serving index.html")
                    return try await serveFile(at: "index.html")

                case "vite.svg", "favicon.ico":
                    // Static files in root
                    logger.debug("Serving static file: \(subPath)")
                    return try await serveFile(at: subPath)

                default:
                    // SPA fallback - serve index.html for client-side routing
                    logger.debug("SPA fallback for: \(subPath)")
                    return try await serveFile(at: "index.html")
                }
            }

            // Path doesn't start with /admin - should not happen
            throw HTTPError(.notFound, message: "Invalid admin path")
        }
    }

    /// Serve a file from the public directory
    private func serveFile(at relativePath: String) async throws -> Response {
        let filePath = "\(publicDirectory)/\(relativePath)"
        let fileURL = URL(fileURLWithPath: filePath)

        logger.debug("Attempting to read: \(filePath)")

        // Security check: ensure path is within public directory
        let publicURL = URL(fileURLWithPath: publicDirectory)
        guard fileURL.standardized.path.hasPrefix(publicURL.standardized.path) else {
            logger.warning("Path traversal attempt blocked: \(relativePath)")
            throw HTTPError(.forbidden, message: "Access denied")
        }

        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath) else {
            logger.error("File not found: \(filePath)")
            throw HTTPError(.notFound, message: "File not found")
        }

        // Read file data
        guard let data = try? Data(contentsOf: fileURL) else {
            logger.error("Failed to read file: \(filePath)")
            throw HTTPError(.internalServerError, message: "Failed to read file")
        }

        // Determine content type
        let contentType = MIMEType.detect(from: fileURL.lastPathComponent)

        // Build response headers
        var headers: HTTPFields = [:]
        headers[.contentType] = contentType
        headers[.contentLength] = "\(data.count)"

        // Cache control
        if relativePath.hasPrefix("assets/") {
            // Cache assets for 1 year (they have hashed filenames)
            headers[.cacheControl] = "public, max-age=31536000, immutable"
        } else {
            // Don't cache index.html and other root files
            headers[.cacheControl] = "no-cache, no-store, must-revalidate"
        }

        logger.info("Served \(relativePath) (\(data.count) bytes, \(contentType))")

        return Response(
            status: .ok,
            headers: headers,
            body: .init(byteBuffer: ByteBuffer(data: data))
        )
    }
}
