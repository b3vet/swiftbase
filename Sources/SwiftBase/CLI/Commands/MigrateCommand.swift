import ArgumentParser
import Foundation

struct MigrateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "migrate",
        abstract: "Run database migrations"
    )

    @Flag(name: .long, help: "Rollback the last migration")
    var rollback: Bool = false

    @Option(name: .long, help: "Run migrations up to specific version")
    var to: Int?

    @Option(name: .shortAndLong, help: "Path to configuration file")
    var config: String?

    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false

    mutating func run() async throws {
        let logger = LoggerService.shared

        if verbose {
            logger.logLevel = .debug
        }

        logger.info("Running database migrations...")

        // Load configuration
        let configService = try ConfigService(configPath: config)
        let dbConfig = configService.get().database

        // Initialize database service
        let dbService = try DatabaseService(
            path: dbConfig.path,
            enableWAL: dbConfig.enableWAL
        )

        if rollback {
            logger.info("Rolling back migrations...")
            try await dbService.rollbackMigration()
        } else if let targetVersion = to {
            logger.info("Migrating to version \(targetVersion)...")
            try await dbService.migrateToVersion(targetVersion)
        } else {
            logger.info("Running all pending migrations...")
            try await dbService.runMigrations()
        }

        logger.info("Migrations completed successfully!")
    }
}
