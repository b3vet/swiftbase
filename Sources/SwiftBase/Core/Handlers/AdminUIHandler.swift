import Foundation
import Hummingbird
import HTTPTypes
import NIOCore

/// Dedicated handler for AdminUI static files
/// Uses explicit switch-based routing to avoid routing conflicts
/// Includes optimizations: preload hints, cache headers, and resource prioritization
public struct AdminUIHandler: Sendable {
    private let publicDirectory: String
    private let logger: LoggerService

    /// Cached list of critical assets for preloading (CSS and JS bundles)
    private let criticalAssets: [PreloadAsset]

    /// Asset preload configuration
    private struct PreloadAsset: Sendable {
        let path: String
        let type: String  // "style", "script", "font"
        let crossorigin: Bool

        var linkHeader: String {
            var link = "</admin/\(path)>; rel=preload; as=\(type)"
            if crossorigin {
                link += "; crossorigin"
            }
            return link
        }
    }

    public init(
        publicDirectory: String = "Sources/SwiftBase/Resources/Public",
        logger: LoggerService
    ) {
        self.publicDirectory = publicDirectory
        self.logger = logger

        // Discover critical assets for preloading
        self.criticalAssets = Self.discoverCriticalAssets(in: publicDirectory, logger: logger)
    }

    /// Discover CSS and JS assets in the assets directory for preloading
    private static func discoverCriticalAssets(in directory: String, logger: LoggerService) -> [PreloadAsset] {
        var assets: [PreloadAsset] = []
        let assetsPath = "\(directory)/assets"

        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: assetsPath) else {
            logger.debug("No assets directory found for preloading")
            return []
        }

        for file in contents {
            if file.hasSuffix(".css") {
                assets.append(PreloadAsset(path: "assets/\(file)", type: "style", crossorigin: false))
                logger.debug("Discovered CSS asset for preload: \(file)")
            } else if file.hasSuffix(".js") && !file.contains("chunk") {
                // Only preload main JS bundles, not chunks (they load on demand)
                assets.append(PreloadAsset(path: "assets/\(file)", type: "script", crossorigin: false))
                logger.debug("Discovered JS asset for preload: \(file)")
            } else if file.hasSuffix(".woff2") || file.hasSuffix(".woff") {
                assets.append(PreloadAsset(path: "assets/\(file)", type: "font", crossorigin: true))
                logger.debug("Discovered font asset for preload: \(file)")
            }
        }

        return assets
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

        // Cache control based on file type
        if relativePath.hasPrefix("assets/") {
            // Cache assets for 1 year (they have hashed filenames)
            headers[.cacheControl] = "public, max-age=31536000, immutable"

            // Add priority hints for critical resources
            if relativePath.hasSuffix(".css") {
                headers[HTTPField.Name("X-Content-Type-Options")!] = "nosniff"
            }
        } else if relativePath == "index.html" {
            // Don't cache index.html
            headers[.cacheControl] = "no-cache, no-store, must-revalidate"
            headers[HTTPField.Name("Pragma")!] = "no-cache"
            headers[HTTPField.Name("Expires")!] = "0"

            // Add preload hints for critical assets via Link header
            if !criticalAssets.isEmpty {
                let linkHeaders = criticalAssets.map { $0.linkHeader }.joined(separator: ", ")
                headers[HTTPField.Name("Link")!] = linkHeaders
                logger.debug("Added preload hints for \(criticalAssets.count) assets")
            }

            // Add security headers for HTML
            headers[HTTPField.Name("X-Frame-Options")!] = "SAMEORIGIN"
            headers[HTTPField.Name("X-Content-Type-Options")!] = "nosniff"
            headers[HTTPField.Name("Referrer-Policy")!] = "strict-origin-when-cross-origin"
        } else {
            // Other root files - short cache
            headers[.cacheControl] = "public, max-age=3600"
        }

        logger.info("Served \(relativePath) (\(data.count) bytes, \(contentType))")

        return Response(
            status: .ok,
            headers: headers,
            body: .init(byteBuffer: ByteBuffer(data: data))
        )
    }

    /// Refresh critical assets list (call after UI rebuild)
    public mutating func refreshCriticalAssets() {
        let newAssets = Self.discoverCriticalAssets(in: publicDirectory, logger: logger)
        // Note: Since this is a struct, caller needs to reassign
        logger.info("Refreshed critical assets list: \(newAssets.count) assets discovered")
    }
}
