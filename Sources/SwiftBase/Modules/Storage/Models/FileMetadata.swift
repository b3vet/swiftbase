import Foundation
import GRDB

/// File metadata model
public struct FileMetadata: Codable, Sendable {
    public let id: String
    public let filename: String
    public let originalName: String
    public let contentType: String?
    public let size: Int
    public let path: String
    public let metadata: [String: String]
    public let uploadedBy: String?
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case filename
        case originalName = "original_name"
        case contentType = "content_type"
        case size
        case path
        case metadata
        case uploadedBy = "uploaded_by"
        case createdAt = "created_at"
    }

    public init(
        id: String,
        filename: String,
        originalName: String,
        contentType: String?,
        size: Int,
        path: String,
        metadata: [String: String] = [:],
        uploadedBy: String?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.originalName = originalName
        self.contentType = contentType
        self.size = size
        self.path = path
        self.metadata = metadata
        self.uploadedBy = uploadedBy
        self.createdAt = createdAt
    }
}

// MARK: - GRDB Record

extension FileMetadata: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "_files"
}

// MARK: - Response Models

/// File upload response
public struct FileUploadResponse: Codable, Sendable {
    public let success: Bool
    public let data: FileUploadData?
    public let error: String?

    public struct FileUploadData: Codable, Sendable {
        public let id: String
        public let filename: String
        public let originalName: String
        public let contentType: String?
        public let size: Int
        public let url: String
        public let createdAt: String

        public init(file: FileMetadata, baseURL: String = "") {
            self.id = file.id
            self.filename = file.filename
            self.originalName = file.originalName
            self.contentType = file.contentType
            self.size = file.size
            self.url = "\(baseURL)/api/storage/files/\(file.id)"
            self.createdAt = ISO8601DateFormatter().string(from: file.createdAt)
        }
    }

    public init(file: FileMetadata, baseURL: String = "") {
        self.success = true
        self.data = FileUploadData(file: file, baseURL: baseURL)
        self.error = nil
    }

    public init(error: String) {
        self.success = false
        self.data = nil
        self.error = error
    }
}

/// File list response
public struct FileListResponse: Codable, Sendable {
    public let success: Bool
    public let data: [FileUploadResponse.FileUploadData]
    public let total: Int
    public let limit: Int
    public let offset: Int

    public init(files: [FileMetadata], total: Int, limit: Int, offset: Int, baseURL: String = "") {
        self.success = true
        self.data = files.map { FileUploadResponse.FileUploadData(file: $0, baseURL: baseURL) }
        self.total = total
        self.limit = limit
        self.offset = offset
    }
}
