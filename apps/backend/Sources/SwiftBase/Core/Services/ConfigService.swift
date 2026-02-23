import Foundation

/// Configuration service for loading and managing application configuration
/// Supports JSON configuration files and environment variable overrides
public final class ConfigService: Sendable {

    // MARK: - Configuration Structure

    public struct Config: Codable, Sendable {
        public var server: ServerConfig
        public var database: DatabaseConfig
        public var auth: AuthConfig
        public var storage: StorageConfig
        public var cache: CacheConfig
        public var logging: LoggingConfig

        public init(
            server: ServerConfig = ServerConfig(),
            database: DatabaseConfig = DatabaseConfig(),
            auth: AuthConfig = AuthConfig(),
            storage: StorageConfig = StorageConfig(),
            cache: CacheConfig = CacheConfig(),
            logging: LoggingConfig = LoggingConfig()
        ) {
            self.server = server
            self.database = database
            self.auth = auth
            self.storage = storage
            self.cache = cache
            self.logging = logging
        }
    }

    public struct ServerConfig: Codable, Sendable {
        public var host: String
        public var port: Int
        public var environment: String

        public init(
            host: String = "127.0.0.1",
            port: Int = 8090,
            environment: String = "development"
        ) {
            self.host = host
            self.port = port
            self.environment = environment
        }
    }

    public struct DatabaseConfig: Codable, Sendable {
        public var path: String
        public var maxConnections: Int
        public var enableWAL: Bool

        public init(
            path: String = "./data/swiftbase.db",
            maxConnections: Int = 10,
            enableWAL: Bool = true
        ) {
            self.path = path
            self.maxConnections = maxConnections
            self.enableWAL = enableWAL
        }
    }

    public struct AuthConfig: Codable, Sendable {
        public var jwtSecret: String
        public var accessTokenExpiry: Int  // in minutes
        public var refreshTokenExpiry: Int // in days
        public var bcryptCost: Int

        public init(
            jwtSecret: String = "",
            accessTokenExpiry: Int = 15,
            refreshTokenExpiry: Int = 7,
            bcryptCost: Int = 12
        ) {
            self.jwtSecret = jwtSecret
            self.accessTokenExpiry = accessTokenExpiry
            self.refreshTokenExpiry = refreshTokenExpiry
            self.bcryptCost = bcryptCost
        }
    }

    public struct StorageConfig: Codable, Sendable {
        public var path: String
        public var maxFileSize: Int // in bytes

        public init(
            path: String = "./data/storage",
            maxFileSize: Int = 104_857_600 // 100MB
        ) {
            self.path = path
            self.maxFileSize = maxFileSize
        }
    }

    public struct CacheConfig: Codable, Sendable {
        public var enabled: Bool
        public var ttl: Int // in seconds
        public var maxSize: Int // max items

        public init(
            enabled: Bool = true,
            ttl: Int = 300, // 5 minutes
            maxSize: Int = 1000
        ) {
            self.enabled = enabled
            self.ttl = ttl
            self.maxSize = maxSize
        }
    }

    public struct LoggingConfig: Codable, Sendable {
        public var level: String
        public var format: String

        public init(
            level: String = "info",
            format: String = "json"
        ) {
            self.level = level
            self.format = format
        }
    }

    // MARK: - Properties

    private let config: Config

    // MARK: - Initialization

    public init(configPath: String? = nil) throws {
        var loadedConfig: Config

        if let path = configPath {
            // Load from specified file
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            loadedConfig = try JSONDecoder().decode(Config.self, from: data)
        } else {
            // Try to load from default locations
            if let defaultConfig = try? Self.loadDefaultConfig() {
                loadedConfig = defaultConfig
            } else {
                // Use default configuration
                loadedConfig = Config()
            }
        }

        // Apply environment variable overrides
        self.config = Self.applyEnvironmentOverrides(to: loadedConfig)

        // Validate configuration
        try validate()
    }

    // MARK: - Public Methods

    public func get() -> Config {
        return config
    }

    public func validate() throws {
        // Validate JWT secret is set in production
        if config.server.environment == "production" && config.auth.jwtSecret.isEmpty {
            throw ConfigError.missingJWTSecret
        }

        // Validate port range
        guard config.server.port > 0 && config.server.port <= 65535 else {
            throw ConfigError.invalidPort(config.server.port)
        }

        // Validate database path
        if config.database.path.isEmpty {
            throw ConfigError.invalidDatabasePath
        }

        // Validate storage path
        if config.storage.path.isEmpty {
            throw ConfigError.invalidStoragePath
        }
    }

    // MARK: - Private Methods

    private static func loadDefaultConfig() throws -> Config? {
        // Try to load from Resources/Config/default.json
        let possiblePaths = [
            "./Resources/Config/default.json",
            "./config/default.json",
            "./default.json"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                return try JSONDecoder().decode(Config.self, from: data)
            }
        }

        return nil
    }

    private static func applyEnvironmentOverrides(to config: Config) -> Config {
        var mutableConfig = config

        // Server overrides
        if let host = ProcessInfo.processInfo.environment["SWIFTBASE_HOST"] {
            mutableConfig.server.host = host
        }
        if let port = ProcessInfo.processInfo.environment["SWIFTBASE_PORT"],
           let portInt = Int(port) {
            mutableConfig.server.port = portInt
        }
        if let env = ProcessInfo.processInfo.environment["SWIFTBASE_ENV"] {
            mutableConfig.server.environment = env
        }

        // Database overrides
        if let dbPath = ProcessInfo.processInfo.environment["SWIFTBASE_DB_PATH"] {
            mutableConfig.database.path = dbPath
        }

        // Auth overrides
        if let jwtSecret = ProcessInfo.processInfo.environment["SWIFTBASE_JWT_SECRET"] {
            mutableConfig.auth.jwtSecret = jwtSecret
        }

        // Storage overrides
        if let storagePath = ProcessInfo.processInfo.environment["SWIFTBASE_STORAGE_PATH"] {
            mutableConfig.storage.path = storagePath
        }

        return mutableConfig
    }
}

// MARK: - Errors

public enum ConfigError: Error, CustomStringConvertible {
    case missingJWTSecret
    case invalidPort(Int)
    case invalidDatabasePath
    case invalidStoragePath

    public var description: String {
        switch self {
        case .missingJWTSecret:
            return "JWT secret must be set in production environment"
        case .invalidPort(let port):
            return "Invalid port number: \(port). Must be between 1 and 65535"
        case .invalidDatabasePath:
            return "Database path cannot be empty"
        case .invalidStoragePath:
            return "Storage path cannot be empty"
        }
    }
}
