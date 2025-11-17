import Foundation
import GRDB
import Crypto

/// Default seeder to create initial data
public struct DefaultSeeder: SeederProtocol {
    public let name = "DefaultSeeder"

    public func seed(_ db: Database) throws {
        // Check if admin already exists
        let adminCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM _admins") ?? 0

        if adminCount == 0 {
            // Create a default admin user
            // In a real scenario, this password should be changed immediately
            let defaultPassword = "admin123"

            // Note: We can't use PasswordService here directly because it's an actor
            // So we replicate the hashing logic to match PasswordService format
            let salt = "defaultsalt"
            let cost = 12

            // Hash using SHA256 (same as PasswordService)
            let combined = defaultPassword + salt
            let data = Data(combined.utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

            // Format: algorithm$cost$salt$hash (same as PasswordService)
            let storedHash = "sha256$\(cost)$\(salt)$\(hashString)"

            try db.execute(
                sql: """
                    INSERT INTO _admins (username, password_hash)
                    VALUES (?, ?)
                    """,
                arguments: ["admin", storedHash]
            )

            print("Default admin created:")
            print("  Username: admin")
            print("  Password: \(defaultPassword)")
            print("  IMPORTANT: Change this password immediately!")
        }

        // You can add more default data here
        // For example, default collections, sample users, etc.
    }
}
