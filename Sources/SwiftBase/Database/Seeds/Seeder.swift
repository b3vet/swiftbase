import Foundation
import GRDB

/// Protocol for database seeders
public protocol SeederProtocol: Sendable {
    /// Seeder name
    var name: String { get }

    /// Run the seeder
    func seed(_ db: Database) throws
}

/// Registry of all available seeders
public struct Seeder {
    /// All registered seeders
    public static var allSeeders: [SeederProtocol] {
        return [
            DefaultSeeder()
        ]
    }
}
