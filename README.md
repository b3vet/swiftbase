# SwiftBase

A single-binary backend platform built entirely in Swift, providing database, API, authentication, file storage, and realtime capabilities.

## Project Status

### Phase 1: Foundation & Core Infrastructure ✅ COMPLETED

- ✅ Swift package structure initialized with Swift 6.0+ support
- ✅ Package.swift configured with all required dependencies
- ✅ CLI structure implemented with ArgumentParser
  - `swiftbase serve` - Start server
  - `swiftbase migrate` - Run migrations
  - `swiftbase seed` - Seed database
  - `swiftbase dump` - Backup database
- ✅ ConfigService for JSON/ENV configuration loading
- ✅ LoggerService with structured JSON logging
- ✅ Error handling framework with custom error types
- ✅ Basic Hummingbird HTTP server with health check endpoint
- ✅ Complete project directory structure
- ✅ Development and production configuration files

## Quick Start

### Build

```bash
swift build
```

### Run

```bash
# Start the server (default command)
.build/debug/swiftbase

# Or explicitly use the serve command
.build/debug/swiftbase serve

# With custom port
.build/debug/swiftbase serve --port 9000

# With verbose logging
.build/debug/swiftbase serve --verbose
```

### Available Commands

```bash
# Show help
.build/debug/swiftbase --help

# Show version
.build/debug/swiftbase --version

# Command-specific help
.build/debug/swiftbase serve --help
.build/debug/swiftbase migrate --help
.build/debug/swiftbase seed --help
.build/debug/swiftbase dump --help
```

## Project Structure

```
swiftbase/
├── Package.swift
├── Sources/SwiftBase/
│   ├── App.swift                    # Main application
│   ├── CLI/
│   │   ├── SwiftBaseCLI.swift      # CLI entry point
│   │   └── Commands/                # CLI commands
│   ├── Core/
│   │   ├── Services/                # Core services
│   │   │   ├── ConfigService.swift
│   │   │   ├── LoggerService.swift
│   │   │   └── DatabaseService.swift (stub)
│   │   ├── Errors/                  # Error types
│   │   └── Middleware/              # HTTP middleware (pending)
│   ├── Modules/                     # Feature modules (pending)
│   ├── Database/                    # Migrations & seeds (pending)
│   └── Resources/
│       └── Config/                  # Configuration files
└── Tests/
```

## Configuration

Configuration files are located in `Sources/SwiftBase/Resources/Config/`:

- `default.json` - Development configuration
- `production.json` - Production configuration

Configuration can be overridden via environment variables:
- `SWIFTBASE_HOST`
- `SWIFTBASE_PORT`
- `SWIFTBASE_ENV`
- `SWIFTBASE_DB_PATH`
- `SWIFTBASE_JWT_SECRET`
- `SWIFTBASE_STORAGE_PATH`

## Development Status

**Current Phase:** Phase 1 Complete ✅

**Next Phase:** Phase 2 - Database Layer
- GRDB.swift integration
- Migration system
- Database service implementation
- SQLite setup with all required tables

## Technology Stack

- **Language:** Swift 6.0+
- **HTTP Server:** Hummingbird 2.0+
- **Database:** GRDB.swift 6.29+ (SQLite)
- **Authentication:** SwiftJWT 4.0+
- **CLI:** Swift Argument Parser 1.5+
- **WebSocket:** Hummingbird WebSocket 2.0+ (pending)
- **Cryptography:** Swift Crypto 3.10+ (pending)

## Requirements

- Swift 6.0+
- macOS 14.0+ (for development)
- Deployment: macOS/Linux VPS

## License

TBD

## Contributing

This project is currently in active development. Phase 1 (Foundation) is complete.
