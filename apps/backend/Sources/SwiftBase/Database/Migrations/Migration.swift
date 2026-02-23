import Foundation
import GRDB

/// Protocol for database migrations
public protocol MigrationProtocol: Sendable {
    /// Migration version number (must be unique)
    var version: Int { get }

    /// Migration name
    var name: String { get }

    /// Run the migration (apply changes)
    func up(_ db: Database) throws

    /// Rollback the migration (revert changes)
    func down(_ db: Database) throws
}

/// Registry of all available migrations
public struct Migration {
    /// All registered migrations
    public static var allMigrations: [MigrationProtocol] {
        return [
            Migration001_CreateInitialTables(),
            Migration002_CreateIndexes(),
            Migration003_CreateTriggers(),
            Migration004_CreateSavedQueriesTable(),
            Migration005_UpdateFilesOwnership()
        ]
    }
}
