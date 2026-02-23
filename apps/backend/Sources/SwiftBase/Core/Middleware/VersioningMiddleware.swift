import Foundation
import Hummingbird
import HTTPTypes

/// Middleware for API versioning
public struct VersioningMiddleware<Context: RequestContext>: RouterMiddleware {
    private let currentVersion: String
    private let supportedVersions: [String]
    private let defaultVersion: String
    private let enforcePathVersioning: Bool

    public init(
        currentVersion: String = "1.0",
        supportedVersions: [String] = ["1.0"],
        defaultVersion: String = "1.0",
        enforcePathVersioning: Bool = false
    ) {
        self.currentVersion = currentVersion
        self.supportedVersions = supportedVersions
        self.defaultVersion = defaultVersion
        self.enforcePathVersioning = enforcePathVersioning
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        // Extract version from path (e.g., /api/v1/query -> v1)
        let pathComponents = request.uri.path.split(separator: "/")

        var requestedVersion = defaultVersion

        // Look for version in path
        for component in pathComponents {
            if component.hasPrefix("v") && component.count > 1 {
                // Check if this looks like a version (v followed by number)
                let versionString = String(component.dropFirst())
                let firstChar = versionString.first
                if let char = firstChar, char.isNumber {
                    // Try to match version (normalize v1 -> 1.0, v1.0 -> 1.0)
                    if let matched = matchVersion(versionString, against: supportedVersions) {
                        requestedVersion = matched
                        break
                    } else if enforcePathVersioning {
                        // Only throw error if enforcing path versioning
                        throw HTTPError(.badRequest, message: "API version '\(component)' is not supported. Supported versions: \(supportedVersions.map { "v\($0)" }.joined(separator: ", "))")
                    }
                    // If not enforcing, just use default version and continue
                }
            }
        }

        // Check version header (always validate headers)
        if let versionHeader = request.headers[.init("API-Version")!] {
            if let matched = matchVersion(versionHeader, against: supportedVersions) {
                requestedVersion = matched
            } else {
                throw HTTPError(.badRequest, message: "API version '\(versionHeader)' is not supported. Supported versions: \(supportedVersions.joined(separator: ", "))")
            }
        }

        // Process request
        var response = try await next(request, context)

        // Add version info to response headers
        response.headers[.init("API-Version")!] = requestedVersion
        response.headers[.init("API-Supported-Versions")!] = supportedVersions.joined(separator: ", ")

        return response
    }

    /// Match a version string against supported versions
    /// Handles both "1" -> "1.0" and "1.0" -> "1.0" matching
    private func matchVersion(_ version: String, against supportedVersions: [String]) -> String? {
        // Direct match
        if supportedVersions.contains(version) {
            return version
        }

        // Try to normalize: "1" -> "1.0"
        let normalizedVersion: String
        if !version.contains(".") {
            normalizedVersion = "\(version).0"
        } else {
            normalizedVersion = version
        }

        if supportedVersions.contains(normalizedVersion) {
            return normalizedVersion
        }

        // Try reverse: check if any supported version matches when normalized
        for supported in supportedVersions {
            // Extract major version from supported (e.g., "1.0" -> "1")
            if let major = supported.split(separator: ".").first,
               String(major) == version {
                return supported
            }
        }

        return nil
    }
}

/// Helper to create versioned route groups
public struct APIVersioning {
    /// Create a versioned router group
    public static func createVersionedGroup(
        router: Router<some RequestContext>,
        version: String
    ) -> RouterGroup<some RequestContext> {
        return router.group("api/v\(version)")
    }

    /// Get the current API version
    public static let currentVersion = "1.0"

    /// Get all supported API versions
    public static let supportedVersions = ["1.0"]
}
