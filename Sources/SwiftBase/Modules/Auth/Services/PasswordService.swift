import Foundation
import Crypto

/// Service for password hashing and verification
///
/// NOTE: This implementation uses SHA256 with salt as a placeholder.
/// In production, this should be replaced with proper bcrypt hashing.
/// Consider adding a bcrypt package like: https://github.com/vapor/bcrypt
public actor PasswordService {
    private let cost: Int
    private let logger: LoggerService

    public init(cost: Int = 12) {
        self.cost = cost
        self.logger = LoggerService.shared
    }

    /// Hash a password
    /// - Parameter password: Plain text password
    /// - Returns: Hashed password string
    public func hash(_ password: String) throws -> String {
        // Generate a random salt
        let salt = generateSalt()

        // Combine password and salt
        let combined = password + salt

        // Hash using SHA256 (placeholder for bcrypt)
        let data = Data(combined.utf8)
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        // Store as: algorithm$cost$salt$hash
        // Format compatible with bcrypt structure for future migration
        return "sha256$\(cost)$\(salt)$\(hashString)"
    }

    /// Verify a password against a hash
    /// - Parameters:
    ///   - password: Plain text password to verify
    ///   - hash: Stored password hash
    /// - Returns: True if password matches
    public func verify(_ password: String, against hash: String) throws -> Bool {
        // Parse the hash string
        let components = hash.split(separator: "$")
        guard components.count == 4 else {
            throw PasswordError.invalidHashFormat
        }

        let algorithm = String(components[0])
        let salt = String(components[2])
        let storedHash = String(components[3])

        // Verify algorithm
        guard algorithm == "sha256" else {
            throw PasswordError.unsupportedAlgorithm(algorithm)
        }

        // Hash the provided password with the stored salt
        let combined = password + salt
        let data = Data(combined.utf8)
        let computedHash = SHA256.hash(data: data)
        let computedHashString = computedHash.compactMap { String(format: "%02x", $0) }.joined()

        // Constant-time comparison to prevent timing attacks
        return constantTimeCompare(computedHashString, storedHash)
    }

    /// Generate a random salt
    private func generateSalt() -> String {
        let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString()
    }

    /// Constant-time string comparison
    private func constantTimeCompare(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }

        var result: UInt8 = 0
        for (a, b) in zip(lhs.utf8, rhs.utf8) {
            result |= a ^ b
        }

        return result == 0
    }
}

// MARK: - Errors

public enum PasswordError: Error, CustomStringConvertible {
    case invalidHashFormat
    case unsupportedAlgorithm(String)
    case hashingFailed(String)

    public var description: String {
        switch self {
        case .invalidHashFormat:
            return "Invalid password hash format"
        case .unsupportedAlgorithm(let algo):
            return "Unsupported hashing algorithm: \(algo)"
        case .hashingFailed(let msg):
            return "Password hashing failed: \(msg)"
        }
    }
}
