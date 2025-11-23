import Foundation
import GRDB
import Hummingbird

/// Storage service for file operations
public actor StorageService {
    private let dbService: DatabaseService
    private let storageDirectory: String
    private let maxFileSize: Int
    private let logger: LoggerService

    public init(
        dbService: DatabaseService,
        storageDirectory: String = "./data/storage",
        maxFileSize: Int = 104_857_600, // 100MB
        logger: LoggerService = .shared
    ) {
        self.dbService = dbService
        self.storageDirectory = storageDirectory
        self.maxFileSize = maxFileSize
        self.logger = logger

        // Create storage directory if it doesn't exist
        try? FileManager.default.createDirectory(
            atPath: storageDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    // MARK: - File Upload

    /// Upload a file with streaming support
    public func uploadFile(
        data: Data,
        originalFilename: String,
        contentType: String? = nil,
        metadata: [String: String] = [:],
        userId: String? = nil,
        adminId: String? = nil
    ) async throws -> FileMetadata {
        // Validate file size
        guard data.count <= maxFileSize else {
            throw StorageError.fileTooLarge(size: data.count, max: maxFileSize)
        }

        // Generate unique filename
        let fileId = generateFileId()
        let fileExtension = (originalFilename as NSString).pathExtension
        let filename = fileExtension.isEmpty ? fileId : "\(fileId).\(fileExtension)"

        // Detect content type if not provided
        let detectedContentType = contentType ?? MIMEType.detect(from: data)

        // Create file path
        let filePath = "\(storageDirectory)/\(filename)"

        // Write file to disk
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
        } catch {
            logger.error("Failed to write file to disk", error: error)
            throw StorageError.writeFailed(error.localizedDescription)
        }

        // Create metadata record
        let fileMetadata = FileMetadata(
            id: fileId,
            filename: filename,
            originalName: originalFilename,
            contentType: detectedContentType,
            size: data.count,
            path: filePath,
            metadata: metadata,
            userId: userId,
            adminId: adminId
        )

        // Save to database
        try await dbService.write { db in
            try fileMetadata.insert(db)
        }

        logger.info("File uploaded successfully: \(fileId) (\(data.count) bytes)")

        return fileMetadata
    }

    // MARK: - File Retrieval

    /// Get file metadata by ID
    public func getFileMetadata(id: String) async throws -> FileMetadata {
        try await dbService.read { db in
            guard let file = try FileMetadata.fetchOne(db, key: id) else {
                throw StorageError.fileNotFound(id)
            }
            return file
        }
    }

    /// Get file data by ID
    public func getFileData(id: String) async throws -> Data {
        let metadata = try await getFileMetadata(id: id)

        guard FileManager.default.fileExists(atPath: metadata.path) else {
            logger.error("File not found on disk: \(metadata.path)")
            throw StorageError.fileNotFoundOnDisk(metadata.path)
        }

        do {
            return try Data(contentsOf: URL(fileURLWithPath: metadata.path))
        } catch {
            logger.error("Failed to read file from disk", error: error)
            throw StorageError.readFailed(error.localizedDescription)
        }
    }

    /// Get file data with range support (for streaming large files)
    public func getFileData(id: String, range: Range<Int>?) async throws -> (data: Data, totalSize: Int) {
        let metadata = try await getFileMetadata(id: id)

        guard FileManager.default.fileExists(atPath: metadata.path) else {
            throw StorageError.fileNotFoundOnDisk(metadata.path)
        }

        let fileURL = URL(fileURLWithPath: metadata.path)
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        if let range = range {
            // Validate range
            guard range.lowerBound >= 0 && range.upperBound <= metadata.size else {
                throw StorageError.invalidRange
            }

            // Seek to start position
            try fileHandle.seek(toOffset: UInt64(range.lowerBound))

            // Read specified range
            let length = range.upperBound - range.lowerBound
            guard let data = try fileHandle.read(upToCount: length) else {
                throw StorageError.readFailed("Failed to read file range")
            }

            return (data, metadata.size)
        } else {
            // Read entire file
            guard let data = try fileHandle.readToEnd() else {
                throw StorageError.readFailed("Failed to read file")
            }
            return (data, metadata.size)
        }
    }

    // MARK: - File Deletion

    /// Delete a file
    public func deleteFile(id: String, userId: String?, isAdmin: Bool = false) async throws {
        let metadata = try await getFileMetadata(id: id)

        // Check permissions (users can only delete their own files, admins can delete any)
        if !isAdmin {
            // User must own the file (file.userId must match their userId)
            guard let fileUserId = metadata.userId, fileUserId == userId else {
                throw StorageError.unauthorized
            }
        }

        // Delete file from disk
        if FileManager.default.fileExists(atPath: metadata.path) {
            do {
                try FileManager.default.removeItem(atPath: metadata.path)
            } catch {
                logger.error("Failed to delete file from disk", error: error)
                throw StorageError.deleteFailed(error.localizedDescription)
            }
        }

        // Delete metadata from database
        _ = try await dbService.write { db in
            try FileMetadata.deleteOne(db, key: id)
        }

        logger.info("File deleted successfully: \(id)")
    }

    // MARK: - File Listing

    /// List files with pagination and filtering
    public func listFiles(
        userId: String? = nil,
        adminId: String? = nil,
        contentType: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> (files: [FileMetadata], total: Int) {
        try await dbService.read { db in
            var query = FileMetadata.order(Column("created_at").desc)

            // Filter by owner
            if let userId = userId {
                query = query.filter(Column("user_id") == userId)
            } else if let adminId = adminId {
                query = query.filter(Column("admin_id") == adminId)
            }
            // If both are nil, return all files (admin viewing all)

            // Filter by content type
            if let contentType = contentType {
                query = query.filter(Column("content_type") == contentType)
            }

            // Get total count
            let total = try query.fetchCount(db)

            // Get paginated results
            let files = try query
                .limit(limit, offset: offset)
                .fetchAll(db)

            return (files, total)
        }
    }

    /// Search files by original name
    public func searchFiles(
        query: String,
        userId: String? = nil,
        adminId: String? = nil,
        limit: Int = 50
    ) async throws -> [FileMetadata] {
        try await dbService.read { db in
            var sqlQuery = FileMetadata
                .filter(Column("original_name").like("%\(query)%"))
                .order(Column("created_at").desc)

            // Filter by owner
            if let userId = userId {
                sqlQuery = sqlQuery.filter(Column("user_id") == userId)
            } else if let adminId = adminId {
                sqlQuery = sqlQuery.filter(Column("admin_id") == adminId)
            }
            // If both are nil, return all matching files (admin viewing all)

            return try sqlQuery.limit(limit).fetchAll(db)
        }
    }

    // MARK: - Storage Statistics

    /// Get storage statistics for a user
    public func getUserStorageStats(userId: String) async throws -> StorageStats {
        try await dbService.read { db in
            let files = try FileMetadata
                .filter(Column("user_id") == userId)
                .fetchAll(db)

            let totalSize = files.reduce(0) { $0 + $1.size }
            let fileCount = files.count

            return StorageStats(
                fileCount: fileCount,
                totalSize: totalSize,
                quota: self.maxFileSize * 100 // Example: 100 files max
            )
        }
    }

    /// Get total storage statistics
    public func getTotalStorageStats() async throws -> StorageStats {
        try await dbService.read { db in
            let files = try FileMetadata.fetchAll(db)

            let totalSize = files.reduce(0) { $0 + $1.size }
            let fileCount = files.count

            return StorageStats(
                fileCount: fileCount,
                totalSize: totalSize,
                quota: nil
            )
        }
    }

    // MARK: - Cleanup

    /// Clean up orphaned files (files on disk without database records)
    public func cleanupOrphanedFiles() async throws -> Int {
        var cleanedCount = 0

        // Get all file IDs from database
        let dbFileIds = try await dbService.read { db in
            try FileMetadata.fetchAll(db).map { $0.id }
        }

        // Get all files in storage directory
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: storageDirectory),
            includingPropertiesForKeys: nil
        )

        for fileURL in fileURLs {
            let filename = fileURL.lastPathComponent

            // Extract file ID from filename
            let fileId = (filename as NSString).deletingPathExtension

            // If file ID not in database, delete the file
            if !dbFileIds.contains(fileId) {
                try FileManager.default.removeItem(at: fileURL)
                cleanedCount += 1
                logger.info("Deleted orphaned file: \(filename)")
            }
        }

        logger.info("Cleaned up \(cleanedCount) orphaned files")
        return cleanedCount
    }

    /// Clean up missing files (database records without files on disk)
    public func cleanupMissingFiles() async throws -> Int {
        var cleanedCount = 0

        let allFiles = try await dbService.read { db in
            try FileMetadata.fetchAll(db)
        }

        for file in allFiles {
            if !FileManager.default.fileExists(atPath: file.path) {
                _ = try await dbService.write { db in
                    try FileMetadata.deleteOne(db, key: file.id)
                }
                cleanedCount += 1
                logger.info("Removed database record for missing file: \(file.id)")
            }
        }

        logger.info("Cleaned up \(cleanedCount) missing file records")
        return cleanedCount
    }

    // MARK: - Helpers

    private func generateFileId() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(16).description
    }
}

// MARK: - Storage Error

public enum StorageError: Error, CustomStringConvertible, AppErrorProtocol {
    case fileTooLarge(size: Int, max: Int)
    case fileNotFound(String)
    case fileNotFoundOnDisk(String)
    case writeFailed(String)
    case readFailed(String)
    case deleteFailed(String)
    case unauthorized
    case invalidRange

    public var code: String {
        switch self {
        case .fileTooLarge:
            return "FILE_TOO_LARGE"
        case .fileNotFound:
            return "FILE_NOT_FOUND"
        case .fileNotFoundOnDisk:
            return "FILE_NOT_FOUND_ON_DISK"
        case .writeFailed:
            return "FILE_WRITE_FAILED"
        case .readFailed:
            return "FILE_READ_FAILED"
        case .deleteFailed:
            return "FILE_DELETE_FAILED"
        case .unauthorized:
            return "UNAUTHORIZED"
        case .invalidRange:
            return "INVALID_RANGE"
        }
    }

    public var statusCode: Int {
        switch self {
        case .fileTooLarge:
            return 413 // Payload Too Large
        case .fileNotFound:
            return 404 // Not Found
        case .fileNotFoundOnDisk:
            return 500 // Internal Server Error (this is a server issue)
        case .writeFailed:
            return 500 // Internal Server Error
        case .readFailed:
            return 500 // Internal Server Error
        case .deleteFailed:
            return 500 // Internal Server Error
        case .unauthorized:
            return 403 // Forbidden
        case .invalidRange:
            return 416 // Range Not Satisfiable
        }
    }

    public var message: String {
        return description
    }

    public var metadata: [String: Any]? {
        switch self {
        case .fileTooLarge(let size, let max):
            return ["size": size, "max": max]
        default:
            return nil
        }
    }

    public var description: String {
        switch self {
        case .fileTooLarge(let size, let max):
            return "File size \(size) bytes exceeds maximum allowed size of \(max) bytes"
        case .fileNotFound(let id):
            return "File not found: \(id)"
        case .fileNotFoundOnDisk(let path):
            return "File not found on disk: \(path)"
        case .writeFailed(let reason):
            return "Failed to write file: \(reason)"
        case .readFailed(let reason):
            return "Failed to read file: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete file: \(reason)"
        case .unauthorized:
            return "Unauthorized to access this file"
        case .invalidRange:
            return "Invalid byte range requested"
        }
    }
}

// MARK: - Storage Stats

public struct StorageStats: Codable, Sendable {
    public let fileCount: Int
    public let totalSize: Int
    public let quota: Int?

    public var usedPercentage: Double? {
        guard let quota = quota, quota > 0 else { return nil }
        return Double(totalSize) / Double(quota) * 100
    }
}
