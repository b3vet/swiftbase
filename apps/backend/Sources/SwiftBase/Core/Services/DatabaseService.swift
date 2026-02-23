import Foundation
import GRDB

/// Database service for managing SQLite database connections and operations
public actor DatabaseService {

    // MARK: - Properties

    private let dbQueue: DatabaseQueue
    private let logger: LoggerService
    private let dbPath: String

    // MARK: - Initialization

    public init(
        path: String = "./data/swiftbase.db",
        enableWAL: Bool = true
    ) throws {
        self.logger = LoggerService.shared
        self.dbPath = path

        // Create data directory if it doesn't exist
        let directory = (path as NSString).deletingLastPathComponent
        if !directory.isEmpty {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true
            )
        }

        // Create database queue
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            // Enable foreign keys
            try db.execute(sql: "PRAGMA foreign_keys = ON")

            // Enable WAL mode for better concurrency
            if enableWAL {
                try db.execute(sql: "PRAGMA journal_mode = WAL")
            }
        }

        self.dbQueue = try DatabaseQueue(path: path, configuration: configuration)

        logger.info("Database initialized at: \(path)")

        // Initialize migration tracking table
        try dbQueue.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS _migrations (
                    version INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """)
        }
    }

    // MARK: - Database Access

    /// Execute a read operation
    public func read<T: Sendable>(_ block: @escaping @Sendable (Database) throws -> T) async throws -> T {
        return try await Task {
            try dbQueue.read(block)
        }.value
    }

    /// Execute a write operation
    public func write<T: Sendable>(_ block: @escaping @Sendable (Database) throws -> T) async throws -> T {
        return try await Task {
            try dbQueue.write(block)
        }.value
    }

    /// Execute operations in a transaction
    public func transaction<T: Sendable>(_ block: @escaping @Sendable (Database) throws -> T) async throws -> T {
        return try await Task {
            try dbQueue.write { db in
                var result: T!
                try db.inTransaction {
                    result = try block(db)
                    return .commit
                }
                return result
            }
        }.value
    }

    // MARK: - Migration Methods

    public func runMigrations() async throws {
        logger.info("Starting database migrations...")

        // Get list of available migrations
        let migrations = Migration.allMigrations

        // Get applied migrations
        let appliedVersions = try await dbQueue.read { db -> Set<Int> in
            let rows = try Row.fetchAll(db, sql: "SELECT version FROM _migrations")
            return Set(rows.map { $0["version"] as Int })
        }

        // Run pending migrations
        var applied = 0
        for migration in migrations.sorted(by: { $0.version < $1.version }) {
            if !appliedVersions.contains(migration.version) {
                logger.info("Running migration \(migration.version): \(migration.name)")

                try await dbQueue.write { db in
                    try migration.up(db)
                    try db.execute(
                        sql: "INSERT INTO _migrations (version, name) VALUES (?, ?)",
                        arguments: [migration.version, migration.name]
                    )
                }

                applied += 1
                logger.info("Migration \(migration.version) completed")
            }
        }

        if applied == 0 {
            logger.info("No pending migrations")
        } else {
            logger.info("Applied \(applied) migration(s)")
        }
    }

    public func rollbackMigration() async throws {
        logger.info("Rolling back last migration...")

        // Get the last applied migration
        let lastMigration = try await dbQueue.read { db -> (Int, String)? in
            guard let row = try Row.fetchOne(
                db,
                sql: "SELECT version, name FROM _migrations ORDER BY version DESC LIMIT 1"
            ) else {
                return nil
            }
            return (row["version"], row["name"])
        }

        guard let (version, name) = lastMigration else {
            logger.warning("No migrations to rollback")
            return
        }

        // Find the migration
        guard let migration = Migration.allMigrations.first(where: { $0.version == version }) else {
            throw DatabaseError.migrationFailed("Migration \(version) not found")
        }

        logger.info("Rolling back migration \(version): \(name)")

        try await dbQueue.write { db in
            try migration.down(db)
            try db.execute(sql: "DELETE FROM _migrations WHERE version = ?", arguments: [version])
        }

        logger.info("Migration \(version) rolled back successfully")
    }

    public func migrateToVersion(_ targetVersion: Int) async throws {
        logger.info("Migrating to version \(targetVersion)...")

        let currentVersion = try await getCurrentVersion()

        if targetVersion == currentVersion {
            logger.info("Already at version \(targetVersion)")
            return
        }

        if targetVersion > currentVersion {
            // Migrate up
            let migrations = Migration.allMigrations
                .filter { $0.version > currentVersion && $0.version <= targetVersion }
                .sorted { $0.version < $1.version }

            for migration in migrations {
                logger.info("Running migration \(migration.version): \(migration.name)")

                try await dbQueue.write { db in
                    try migration.up(db)
                    try db.execute(
                        sql: "INSERT INTO _migrations (version, name) VALUES (?, ?)",
                        arguments: [migration.version, migration.name]
                    )
                }

                logger.info("Migration \(migration.version) completed")
            }
        } else {
            // Migrate down
            let migrations = Migration.allMigrations
                .filter { $0.version > targetVersion && $0.version <= currentVersion }
                .sorted { $0.version > $1.version }

            for migration in migrations {
                logger.info("Rolling back migration \(migration.version): \(migration.name)")

                try await dbQueue.write { db in
                    try migration.down(db)
                    try db.execute(
                        sql: "DELETE FROM _migrations WHERE version = ?",
                        arguments: [migration.version]
                    )
                }

                logger.info("Migration \(migration.version) rolled back")
            }
        }

        logger.info("Database is now at version \(targetVersion)")
    }

    private func getCurrentVersion() async throws -> Int {
        return try await dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COALESCE(MAX(version), 0) FROM _migrations") ?? 0
        }
    }

    // MARK: - Seeding Methods

    public func runSeeder(_ name: String, fresh: Bool) async throws {
        logger.info("Running seeder: \(name)")

        if fresh {
            logger.warning("Fresh seeding not implemented yet")
        }

        // Find and run the specific seeder
        if let seeder = Seeder.allSeeders.first(where: { $0.name == name }) {
            try await dbQueue.write { db in
                try seeder.seed(db)
            }
            logger.info("Seeder '\(name)' completed successfully")
        } else {
            throw DatabaseError.queryFailed("Seeder '\(name)' not found")
        }
    }

    public func runAllSeeders(fresh: Bool) async throws {
        logger.info("Running all seeders...")

        if fresh {
            logger.warning("Clearing existing data...")
            // TODO: Implement data clearing
        }

        for seeder in Seeder.allSeeders {
            logger.info("Running seeder: \(seeder.name)")
            try await dbQueue.write { db in
                try seeder.seed(db)
            }
        }

        logger.info("All seeders completed successfully")
    }

    // MARK: - Backup Methods

    public func backup(to outputPath: String, compress: Bool) async throws {
        logger.info("Backing up database to \(outputPath)...")

        // Create backup using SQLite backup API
        try dbQueue.backup(to: DatabaseQueue(path: outputPath))

        logger.info("Database backup completed")

        if compress {
            logger.warning("Compression not implemented yet")
        }
    }

    // MARK: - Health Check

    public func healthCheck() async throws -> DatabaseHealth {
        let health = try await dbQueue.read { [self] db -> DatabaseHealth in
            // Get database size
            let pageCount = try Int.fetchOne(db, sql: "PRAGMA page_count") ?? 0
            let pageSize = try Int.fetchOne(db, sql: "PRAGMA page_size") ?? 0
            let sizeInBytes = pageCount * pageSize

            // Get migration version
            let version = try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(MAX(version), 0) FROM _migrations"
            ) ?? 0

            // Count tables
            let tableCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM sqlite_master WHERE type='table'"
            ) ?? 0

            return DatabaseHealth(
                isAccessible: true,
                sizeInBytes: sizeInBytes,
                version: version,
                tableCount: tableCount,
                path: self.dbPath
            )
        }

        return health
    }
}

// MARK: - Supporting Types

public struct DatabaseHealth: Codable, Sendable {
    public let isAccessible: Bool
    public let sizeInBytes: Int
    public let version: Int
    public let tableCount: Int
    public let path: String

    public var sizeInMB: Double {
        return Double(sizeInBytes) / 1_048_576.0
    }
}
