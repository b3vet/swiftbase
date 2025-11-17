import ArgumentParser
import Foundation

@available(macOS 14.0, *)
@main
struct SwiftBaseCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftbase",
        abstract: "SwiftBase - A single-binary backend platform",
        version: "0.1.0",
        subcommands: [
            ServeCommand.self,
            MigrateCommand.self,
            SeedCommand.self,
            DumpCommand.self
        ],
        defaultSubcommand: ServeCommand.self
    )
}
