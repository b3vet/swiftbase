import Foundation
import Hummingbird
import HTTPTypes
import NIOCore

/// Middleware for serving static files from the Resources/Public directory
public struct StaticFileMiddleware: Sendable {
    private let publicDirectory: String
    private let logger: LoggerService

    public init(publicDirectory: String = "Sources/SwiftBase/Resources/Public") {
        self.publicDirectory = publicDirectory
        self.logger = LoggerService.shared
    }

    /// Serve a static file or return index.html for SPA fallback
    nonisolated public func serveFile(_ request: Request, context: some RequestContext) async throws -> Response {
        // Get the requested path
        let originalPath = request.uri.path
        var path = originalPath

        // Remove leading slash if present
        if path.hasPrefix("/") {
            path = String(path.dropFirst())
        }

        // Remove /admin/ prefix if present since files are stored without it
        if path.hasPrefix("admin/") {
            path = String(path.dropFirst("admin/".count))
        } else if path == "admin" {
            path = ""
        }

        // If path is empty or ends with /, serve index.html
        if path.isEmpty || path.hasSuffix("/") {
            path = path + "index.html"
        }

        // Construct full file path
        let filePath = "\(publicDirectory)/\(path)"

        logger.debug("Static file request: \(originalPath) -> \(filePath)")

        // Try to read the file
        let fileURL = URL(fileURLWithPath: filePath)

        // Security check: ensure the resolved path is within the public directory
        let publicURL = URL(fileURLWithPath: publicDirectory)
        guard fileURL.standardized.path.hasPrefix(publicURL.standardized.path) else {
            logger.warning("Attempted path traversal attack: \(path)")
            throw HTTPError(.forbidden, message: "Access denied")
        }

        // Check if file exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) else {
            // File doesn't exist - serve index.html for SPA routing
            logger.debug("File not found, serving index.html for SPA fallback")
            return try await serveIndexHTML()
        }

        // If it's a directory, try to serve index.html from it
        if isDirectory.boolValue {
            let indexPath = "\(filePath)/index.html"
            if FileManager.default.fileExists(atPath: indexPath) {
                return try await serveFileAtPath(indexPath)
            } else {
                throw HTTPError(.notFound, message: "Directory index not found")
            }
        }

        // Serve the file
        return try await serveFileAtPath(filePath)
    }

    /// Serve index.html for SPA fallback
    private func serveIndexHTML() async throws -> Response {
        let indexPath = "\(publicDirectory)/index.html"
        return try await serveFileAtPath(indexPath)
    }

    /// Serve a file at the given path
    private func serveFileAtPath(_ filePath: String) async throws -> Response {
        // Read file data
        let fileURL = URL(fileURLWithPath: filePath)

        guard let data = try? Data(contentsOf: fileURL) else {
            logger.error("Failed to read file: \(filePath)")
            throw HTTPError(.internalServerError, message: "Failed to read file")
        }

        // Determine content type from filename (which includes the extension)
        let contentType = MIMEType.detect(from: fileURL.lastPathComponent)

        // Get file attributes for Last-Modified header
        let attributes = try? FileManager.default.attributesOfItem(atPath: filePath)
        let modificationDate = attributes?[.modificationDate] as? Date

        // Build response headers
        var headers: HTTPFields = [:]
        headers[.contentType] = contentType
        headers[.contentLength] = "\(data.count)"

        // Add caching headers for static assets
        if filePath.contains("/assets/") {
            // Cache assets for 1 year (they have hashed filenames)
            headers[.cacheControl] = "public, max-age=31536000, immutable"
        } else {
            // Don't cache index.html (for updates)
            headers[.cacheControl] = "no-cache, no-store, must-revalidate"
        }

        if let modDate = modificationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
            formatter.timeZone = TimeZone(abbreviation: "GMT")
            formatter.locale = Locale(identifier: "en_US_POSIX")
            headers[.lastModified] = formatter.string(from: modDate)
        }

        // Create response
        return Response(
            status: .ok,
            headers: headers,
            body: .init(byteBuffer: ByteBuffer(data: data))
        )
    }
}
