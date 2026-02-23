import ArgumentParser
import Foundation

struct DumpCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dump",
        abstract: "Backup the database"
    )

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String?

    @Flag(name: .long, help: "Compress the backup")
    var compress: Bool = false

    @Option(name: .shortAndLong, help: "Path to configuration file")
    var config: String?

    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false

    mutating func run() async throws {
        let logger = LoggerService.shared

        if verbose {
            logger.logLevel = .debug
        }

        logger.info("Backing up database...")

        // Load configuration
        let configService = try ConfigService(configPath: config)
        let dbConfig = configService.get().database

        // Initialize database service
        let dbService = try DatabaseService(
            path: dbConfig.path,
            enableWAL: dbConfig.enableWAL
        )

        let outputPath = output ?? "swiftbase_backup_\(Date().timeIntervalSince1970).db"

        try await dbService.backup(to: outputPath, compress: compress)

        logger.info("Database backup saved to: \(outputPath)")
    }
}
