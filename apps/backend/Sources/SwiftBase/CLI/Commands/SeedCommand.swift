import ArgumentParser
import Foundation

struct SeedCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "seed",
        abstract: "Seed the database with initial data"
    )

    @Option(name: .shortAndLong, help: "Specific seeder to run")
    var seeder: String?

    @Flag(name: .long, help: "Clear existing data before seeding")
    var fresh: Bool = false

    @Option(name: .shortAndLong, help: "Path to configuration file")
    var config: String?

    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false

    mutating func run() async throws {
        let logger = LoggerService.shared

        if verbose {
            logger.logLevel = .debug
        }

        logger.info("Seeding database...")

        if fresh {
            logger.warning("Clearing existing data...")
        }

        // Load configuration
        let configService = try ConfigService(configPath: config)
        let dbConfig = configService.get().database

        // Initialize database service
        let dbService = try DatabaseService(
            path: dbConfig.path,
            enableWAL: dbConfig.enableWAL
        )

        if let seederName = seeder {
            logger.info("Running seeder: \(seederName)")
            try await dbService.runSeeder(seederName, fresh: fresh)
        } else {
            logger.info("Running all seeders...")
            try await dbService.runAllSeeders(fresh: fresh)
        }

        logger.info("Database seeding completed!")
    }
}
