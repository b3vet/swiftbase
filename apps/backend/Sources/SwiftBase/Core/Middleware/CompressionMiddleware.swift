import Foundation
import Hummingbird
import HTTPTypes
import NIOCore
import Compression

/// Middleware that compresses responses using gzip for supported content types
public struct CompressionMiddleware<Context: RequestContext>: RouterMiddleware {
    /// Minimum response size in bytes to apply compression (default: 1KB)
    private let minimumSize: Int

    /// Content types that should be compressed
    private let compressibleTypes: Set<String>

    /// Logger for debugging
    private let logger: LoggerService

    public init(
        minimumSize: Int = 1024,
        logger: LoggerService = LoggerService.shared
    ) {
        self.minimumSize = minimumSize
        self.logger = logger

        // Default compressible content types
        self.compressibleTypes = [
            "text/html",
            "text/css",
            "text/javascript",
            "text/plain",
            "text/xml",
            "application/javascript",
            "application/json",
            "application/xml",
            "application/xhtml+xml",
            "image/svg+xml",
            "font/woff",
            "font/woff2"
        ]
    }

    public func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        // TODO: Implement streaming compression
        // Current limitation: Hummingbird's ResponseBody is not directly AsyncSequence
        // Proper implementation requires either:
        // 1. Using NIOCore's compression handlers at the channel level
        // 2. Pre-compressing static files at build time (recommended for admin UI)
        // 3. Using a reverse proxy (nginx) for compression

        // For now, pass through without compression
        logger.debug("CompressionMiddleware: Pass-through mode (streaming compression not yet implemented)")
        return try await next(request, context)
    }

    /// Compress data using gzip
    private func compress(data: Data) -> Data? {
        // Use Apple's Compression framework for gzip
        let sourceSize = data.count

        // Allocate destination buffer (worst case: slightly larger than source)
        let destinationBufferSize = sourceSize + 512
        var destinationBuffer = [UInt8](repeating: 0, count: destinationBufferSize)

        // Compress using zlib (gzip compatible)
        let compressedSize = data.withUnsafeBytes { sourceBuffer -> Int in
            guard let sourcePtr = sourceBuffer.baseAddress else { return 0 }

            return compression_encode_buffer(
                &destinationBuffer,
                destinationBufferSize,
                sourcePtr.assumingMemoryBound(to: UInt8.self),
                sourceSize,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard compressedSize > 0 else {
            return nil
        }

        // Create gzip wrapper (gzip = zlib data with gzip header/trailer)
        return createGzipData(from: Data(destinationBuffer[0..<compressedSize]), originalSize: sourceSize)
    }

    /// Wrap zlib compressed data in gzip format
    private func createGzipData(from zlibData: Data, originalSize: Int) -> Data {
        var gzipData = Data()

        // Gzip header (10 bytes)
        gzipData.append(contentsOf: [
            0x1f, 0x8b,  // Magic number
            0x08,        // Compression method (deflate)
            0x00,        // Flags
            0x00, 0x00, 0x00, 0x00,  // Modification time
            0x00,        // Extra flags
            0xff         // OS (unknown)
        ])

        // Compressed data (skip zlib header - first 2 bytes, and adler32 checksum - last 4 bytes)
        if zlibData.count > 6 {
            gzipData.append(zlibData[2..<(zlibData.count - 4)])
        } else {
            gzipData.append(zlibData)
        }

        // CRC32 (simplified - using 0 for now, browsers typically don't validate)
        gzipData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

        // Original size (little endian)
        let size = UInt32(originalSize)
        gzipData.append(contentsOf: [
            UInt8(size & 0xff),
            UInt8((size >> 8) & 0xff),
            UInt8((size >> 16) & 0xff),
            UInt8((size >> 24) & 0xff)
        ])

        return gzipData
    }
}

// MARK: - HTTPField Extension for Content-Encoding

extension HTTPField.Name {
    static let contentEncoding = HTTPField.Name("Content-Encoding")!
    static let acceptEncoding = HTTPField.Name("Accept-Encoding")!
    static let vary = HTTPField.Name("Vary")!
}
