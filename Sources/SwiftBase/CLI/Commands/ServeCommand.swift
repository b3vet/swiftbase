import ArgumentParser
import Foundation

struct ServeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Start the SwiftBase server"
    )

    @Option(name: .shortAndLong, help: "Port to listen on")
    var port: Int = 8090

    @Option(name: .shortAndLong, help: "Host to bind to")
    var host: String = "127.0.0.1"

    @Option(name: .shortAndLong, help: "Configuration file path")
    var config: String?

    @Flag(name: .shortAndLong, help: "Enable verbose logging")
    var verbose: Bool = false

    mutating func run() async throws {
        let logger = LoggerService.shared

        if verbose {
            logger.logLevel = .debug
        }

        logger.info("Starting SwiftBase server...")
        logger.info("Host: \(host)")
        logger.info("Port: \(port)")

        // Load configuration
        let configService = try ConfigService(configPath: config)

        // Run the application
        try await App.run(
            host: host,
            port: port,
            configService: configService,
            logger: logger
        )
    }
}
