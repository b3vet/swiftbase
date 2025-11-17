import Foundation
import Hummingbird
import HTTPTypes
import NIOCore

/// Controller for storage endpoints
public struct StorageController: Sendable {
    private let storageService: StorageService
    private let jwtService: JWTService
    private let logger: LoggerService

    public init(storageService: StorageService, jwtService: JWTService) {
        self.storageService = storageService
        self.jwtService = jwtService
        self.logger = LoggerService.shared
    }

    // MARK: - File Upload

    /// Upload a file
    nonisolated public func uploadFile(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)
        let userId = claims.sub

        // Collect file data from request body stream
        var bodyData = Data()
        for try await buffer in request.body {
            bodyData.append(contentsOf: buffer.readableBytesView)
        }

        guard !bodyData.isEmpty else {
            throw HTTPError(.badRequest, message: "No file data provided")
        }

        let data = bodyData

        // Get filename from header or use default
        let originalFilename = request.headers[.init("X-Filename")!] ?? "file.bin"

        // Get content type from header
        let contentType = request.headers[.contentType]

        // Get metadata from header (JSON)
        var metadata: [String: String] = [:]
        if let metadataHeader = request.headers[.init("X-Metadata")!],
           let metadataData = metadataHeader.data(using: .utf8),
           let metadataDict = try? JSONDecoder().decode([String: String].self, from: metadataData) {
            metadata = metadataDict
        }

        // Upload file
        let fileMetadata = try await storageService.uploadFile(
            data: data,
            originalFilename: originalFilename,
            contentType: contentType,
            metadata: metadata,
            uploadedBy: userId
        )

        // Return response
        let response = FileUploadResponse(file: fileMetadata)
        let jsonData = try JSONEncoder().encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .created,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - File Download

    /// Download a file
    nonisolated public func downloadFile(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        _ = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Get file ID from path parameter
        guard let fileId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "File ID required")
        }

        // Check for range header
        let rangeHeader = request.headers[.range]
        let range: Range<Int>? = rangeHeader.flatMap { parseRangeHeader($0) }

        // Get file data
        let (data, totalSize) = try await storageService.getFileData(id: fileId, range: range)
        let metadata = try await storageService.getFileMetadata(id: fileId)

        // Build response headers
        var headers: HTTPFields = [:]
        headers[.contentType] = metadata.contentType ?? "application/octet-stream"
        headers[.contentDisposition] = "attachment; filename=\"\(metadata.originalName)\""

        // Add range headers if applicable
        if let range = range {
            headers[.contentRange] = "bytes \(range.lowerBound)-\(range.upperBound-1)/\(totalSize)"
            headers[.contentLength] = "\(data.count)"

            return Response(
                status: .partialContent,
                headers: headers,
                body: .init(byteBuffer: ByteBuffer(data: data))
            )
        } else {
            headers[.contentLength] = "\(data.count)"

            return Response(
                status: .ok,
                headers: headers,
                body: .init(byteBuffer: ByteBuffer(data: data))
            )
        }
    }

    // MARK: - File Info

    /// Get file metadata
    nonisolated public func getFileInfo(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        _ = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)

        // Get file ID from path parameter
        guard let fileId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "File ID required")
        }

        // Get file metadata
        let metadata = try await storageService.getFileMetadata(id: fileId)

        // Return response
        let response = FileUploadResponse(file: metadata)
        let jsonData = try JSONEncoder().encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - File Deletion

    /// Delete a file
    nonisolated public func deleteFile(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)
        let userId = claims.sub
        let isAdmin = claims.type == "admin"

        // Get file ID from path parameter
        guard let fileId = context.parameters.get("id") else {
            throw HTTPError(.badRequest, message: "File ID required")
        }

        // Delete file
        try await storageService.deleteFile(id: fileId, userId: userId, isAdmin: isAdmin)

        // Return success response
        let response = [
            "success": true,
            "message": "File deleted successfully"
        ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - File Listing

    /// List files
    nonisolated public func listFiles(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)
        let userId = claims.sub
        let isAdmin = claims.type == "admin"

        // Get query parameters
        let limit = Int(request.uri.queryParameters.get("limit") ?? "50") ?? 50
        let offset = Int(request.uri.queryParameters.get("offset") ?? "0") ?? 0
        let contentType = request.uri.queryParameters.get("contentType")

        // List files (users can only see their own, admins can see all)
        let uploadedBy = isAdmin ? nil : userId
        let (files, total) = try await storageService.listFiles(
            uploadedBy: uploadedBy,
            contentType: contentType,
            limit: min(limit, 100), // Cap at 100
            offset: max(offset, 0)
        )

        // Return response
        let response = FileListResponse(
            files: files,
            total: total,
            limit: limit,
            offset: offset
        )

        let jsonData = try JSONEncoder().encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - Search

    /// Search files by name
    nonisolated public func searchFiles(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)
        let userId = claims.sub
        let isAdmin = claims.type == "admin"

        // Get query parameter
        guard let query = request.uri.queryParameters.get("q") else {
            throw HTTPError(.badRequest, message: "Search query required")
        }

        let limit = Int(request.uri.queryParameters.get("limit") ?? "50") ?? 50

        // Search files
        let uploadedBy = isAdmin ? nil : userId
        let files = try await storageService.searchFiles(
            query: query,
            uploadedBy: uploadedBy,
            limit: min(limit, 100)
        )

        // Return response
        let response = FileListResponse(
            files: files,
            total: files.count,
            limit: limit,
            offset: 0
        )

        let jsonData = try JSONEncoder().encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - Storage Stats

    /// Get storage statistics
    nonisolated public func getStorageStats(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)
        let userId = claims.sub
        let isAdmin = claims.type == "admin"

        // Get stats
        let stats = if isAdmin {
            try await storageService.getTotalStorageStats()
        } else {
            try await storageService.getUserStorageStats(userId: userId)
        }

        // Return response
        let response = [
            "success": true,
            "data": [
                "fileCount": stats.fileCount,
                "totalSize": stats.totalSize,
                "quota": stats.quota as Any,
                "usedPercentage": stats.usedPercentage as Any
            ]
        ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - Cleanup (Admin Only)

    /// Clean up orphaned files
    nonisolated public func cleanupOrphanedFiles(_ request: Request, context: some RequestContext) async throws -> Response {
        // Validate admin authentication
        let claims = try await AuthHelpers.validateAndExtractClaims(from: request, jwtService: jwtService)
        guard claims.type == "admin" else {
            throw HTTPError(.forbidden, message: "Admin access required")
        }

        // Run cleanup
        let count = try await storageService.cleanupOrphanedFiles()

        // Return response
        let response = [
            "success": true,
            "message": "Cleaned up \(count) orphaned files",
            "count": count
        ] as [String: Any]

        let jsonData = try JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return Response(
            status: .ok,
            headers: [.contentType: "application/json"],
            body: .init(byteBuffer: ByteBuffer(string: jsonString))
        )
    }

    // MARK: - Helpers

    private func parseRangeHeader(_ header: String) -> Range<Int>? {
        // Parse "bytes=0-1023" format
        let parts = header.replacingOccurrences(of: "bytes=", with: "").split(separator: "-")
        guard parts.count == 2,
              let start = Int(parts[0]),
              let end = Int(parts[1]) else {
            return nil
        }
        return start..<(end + 1)
    }
}

// MARK: - HTTPField Extensions

extension HTTPField.Name {
    public static let contentDisposition = Self("Content-Disposition")!
    public static let contentRange = Self("Content-Range")!
    public static let range = Self("Range")!
}
