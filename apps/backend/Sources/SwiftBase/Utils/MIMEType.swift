import Foundation

/// MIME type detection utility
public struct MIMEType: Sendable {

    /// Detect MIME type from file extension
    public static func detect(from filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        return mimeTypes[ext] ?? "application/octet-stream"
    }

    /// Detect MIME type from file data (basic magic number detection)
    public static func detect(from data: Data) -> String {
        guard data.count > 12 else {
            return "application/octet-stream"
        }

        let bytes = [UInt8](data.prefix(12))

        // Check magic numbers
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        } else if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        } else if bytes.starts(with: [0x47, 0x49, 0x46]) {
            return "image/gif"
        } else if bytes.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            return "application/pdf"
        } else if bytes.starts(with: [0x50, 0x4B, 0x03, 0x04]) ||
                  bytes.starts(with: [0x50, 0x4B, 0x05, 0x06]) ||
                  bytes.starts(with: [0x50, 0x4B, 0x07, 0x08]) {
            return "application/zip"
        } else if bytes.starts(with: [0x1F, 0x8B]) {
            return "application/gzip"
        } else if bytes.starts(with: [0x42, 0x4D]) {
            return "image/bmp"
        } else if bytes.starts(with: [0x49, 0x49, 0x2A, 0x00]) ||
                  bytes.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) {
            return "image/tiff"
        } else if String(data: data.prefix(5), encoding: .utf8)?.starts(with: "{") == true ||
                  String(data: data.prefix(5), encoding: .utf8)?.starts(with: "[") == true {
            return "application/json"
        } else if String(data: data.prefix(5), encoding: .utf8)?.starts(with: "<?xml") == true {
            return "application/xml"
        }

        return "application/octet-stream"
    }

    /// Get file extension from MIME type
    public static func getExtension(for mimeType: String) -> String {
        for (ext, mime) in mimeTypes {
            if mime == mimeType {
                return ext
            }
        }
        return "bin"
    }

    /// Check if MIME type is an image
    public static func isImage(_ mimeType: String) -> Bool {
        return mimeType.starts(with: "image/")
    }

    /// Check if MIME type is a video
    public static func isVideo(_ mimeType: String) -> Bool {
        return mimeType.starts(with: "video/")
    }

    /// Check if MIME type is audio
    public static func isAudio(_ mimeType: String) -> Bool {
        return mimeType.starts(with: "audio/")
    }

    /// Check if MIME type is text
    public static func isText(_ mimeType: String) -> Bool {
        return mimeType.starts(with: "text/") ||
               mimeType == "application/json" ||
               mimeType == "application/xml" ||
               mimeType == "application/javascript"
    }

    // MARK: - MIME Type Map

    private static let mimeTypes: [String: String] = [
        // Images
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "gif": "image/gif",
        "webp": "image/webp",
        "svg": "image/svg+xml",
        "ico": "image/x-icon",
        "bmp": "image/bmp",
        "tiff": "image/tiff",
        "tif": "image/tiff",

        // Documents
        "pdf": "application/pdf",
        "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xls": "application/vnd.ms-excel",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "ppt": "application/vnd.ms-powerpoint",
        "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "odt": "application/vnd.oasis.opendocument.text",
        "ods": "application/vnd.oasis.opendocument.spreadsheet",

        // Text
        "txt": "text/plain",
        "html": "text/html",
        "htm": "text/html",
        "css": "text/css",
        "csv": "text/csv",
        "md": "text/markdown",

        // Code
        "js": "application/javascript",
        "json": "application/json",
        "xml": "application/xml",
        "yaml": "application/x-yaml",
        "yml": "application/x-yaml",

        // Archives
        "zip": "application/zip",
        "tar": "application/x-tar",
        "gz": "application/gzip",
        "bz2": "application/x-bzip2",
        "7z": "application/x-7z-compressed",
        "rar": "application/x-rar-compressed",

        // Audio
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "ogg": "audio/ogg",
        "m4a": "audio/mp4",
        "flac": "audio/flac",
        "aac": "audio/aac",

        // Video
        "mp4": "video/mp4",
        "avi": "video/x-msvideo",
        "mov": "video/quicktime",
        "wmv": "video/x-ms-wmv",
        "flv": "video/x-flv",
        "webm": "video/webm",
        "mkv": "video/x-matroska",

        // Fonts
        "woff": "font/woff",
        "woff2": "font/woff2",
        "ttf": "font/ttf",
        "otf": "font/otf",
        "eot": "application/vnd.ms-fontobject",

        // Other
        "bin": "application/octet-stream",
        "exe": "application/x-msdownload",
        "dmg": "application/x-apple-diskimage",
        "iso": "application/x-iso9660-image"
    ]
}
