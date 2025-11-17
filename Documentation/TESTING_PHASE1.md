# Phase 1 Testing Guide

This guide will help you verify that Phase 1 is complete and working correctly.

## Prerequisites

- Swift 6.0+ installed
- macOS 14.0+ (for development)

## 1. Build the Project

```bash
# Clean build (recommended for first time)
rm -rf .build
swift build

# You should see:
# Build complete! (XX.XXs)
```

**Expected Output:** Build completes successfully with no errors.

## 2. Test CLI Help Commands

```bash
# Main help
.build/debug/swiftbase --help

# Expected output:
# OVERVIEW: SwiftBase - A single-binary backend platform
# USAGE: swiftbase <subcommand>
# ...
```

```bash
# Version
.build/debug/swiftbase --version

# Expected output:
# 0.1.0
```

```bash
# Serve command help
.build/debug/swiftbase serve --help

# Expected output shows:
# - Port option (default: 8090)
# - Host option (default: 127.0.0.1)
# - Config option
# - Verbose flag
```

```bash
# Other command helps
.build/debug/swiftbase migrate --help
.build/debug/swiftbase seed --help
.build/debug/swiftbase dump --help
```

**Expected:** All commands show proper help text with options.

## 3. Test Server Startup

### 3.1 Basic Server Start

```bash
# Start server with default settings
.build/debug/swiftbase serve
```

**Expected Output:**
```json
{"timestamp":"2024-11-16T...","level":"INFO","message":"Starting SwiftBase server...","source":{...}}
{"timestamp":"2024-11-16T...","level":"INFO","message":"Host: 127.0.0.1","source":{...}}
{"timestamp":"2024-11-16T...","level":"INFO","message":"Port: 8090","source":{...}}
{"timestamp":"2024-11-16T...","level":"INFO","message":"SwiftBase application configured on 127.0.0.1:8090","source":{...}}
{"timestamp":"2024-11-16T...","level":"INFO","message":"Starting SwiftBase server on 127.0.0.1:8090","source":{...}}
```

Server should start and wait for connections. Keep this running for the next tests.

### 3.2 Test Health Check Endpoint

In a **new terminal window**, test the health endpoint:

```bash
curl http://localhost:8090/health
```

**Expected Output:**
```json
{
  "status": "healthy",
  "timestamp": "2024-11-16T...",
  "version": "0.1.0"
}
```

### 3.3 Test API Info Endpoint

```bash
curl http://localhost:8090/api
```

**Expected Output:**
```json
{
  "name": "SwiftBase API",
  "version": "0.1.0",
  "description": "Single-binary backend platform"
}
```

### 3.4 Test with Custom Port

Stop the server (Ctrl+C) and restart with a custom port:

```bash
.build/debug/swiftbase serve --port 9000
```

Then test:

```bash
curl http://localhost:9000/health
```

**Expected:** Health check responds on port 9000.

### 3.5 Test Verbose Logging

Stop the server and restart with verbose logging:

```bash
.build/debug/swiftbase serve --verbose
```

**Expected Output:** You should see DEBUG level logs in addition to INFO logs:
```json
{"timestamp":"...","level":"DEBUG","message":"Incoming request","metadata":{...}}
```

## 4. Test Configuration System

### 4.1 Test Default Configuration

```bash
# The server uses default config from Sources/SwiftBase/Resources/Config/default.json
cat Sources/SwiftBase/Resources/Config/default.json
```

**Expected:** Should show development configuration with:
- host: "127.0.0.1"
- port: 8090
- environment: "development"
- logging level: "debug"

### 4.2 Test Environment Variable Override

```bash
# Override port via environment variable
SWIFTBASE_PORT=9999 .build/debug/swiftbase serve
```

**Expected:** Server should start on port 9999 instead of 8090.

Test it:
```bash
curl http://localhost:9999/health
```

### 4.3 Test Custom Config File

Create a test config:

```bash
cat > /tmp/test-config.json << 'EOF'
{
  "server": {
    "host": "127.0.0.1",
    "port": 7777,
    "environment": "test"
  },
  "database": {
    "path": "./data/test.db",
    "maxConnections": 5,
    "enableWAL": true
  },
  "auth": {
    "jwtSecret": "test-secret",
    "accessTokenExpiry": 15,
    "refreshTokenExpiry": 7,
    "bcryptCost": 10
  },
  "storage": {
    "path": "./data/test-storage",
    "maxFileSize": 104857600
  },
  "cache": {
    "enabled": true,
    "ttl": 300,
    "maxSize": 500
  },
  "logging": {
    "level": "info",
    "format": "json"
  }
}
EOF
```

Run with custom config:

```bash
.build/debug/swiftbase serve --config /tmp/test-config.json
```

**Expected:** Server starts on port 7777.

## 5. Test Stub Commands

These commands don't have full functionality yet but should run without errors:

```bash
# Migrate command (stub)
.build/debug/swiftbase migrate
# Expected: Prints "Running migrations (stub)..."

# Seed command (stub)
.build/debug/swiftbase seed
# Expected: Prints "Running all seeders, fresh: false (stub)..."

# Dump command (stub)
.build/debug/swiftbase dump
# Expected: Prints "Backing up database to swiftbase_backup_..., compress: false (stub)..."
```

## 6. Verify Project Structure

```bash
# Check that all directories were created
find Sources/SwiftBase -type d | sort
```

**Expected directories:**
- Sources/SwiftBase/CLI
- Sources/SwiftBase/CLI/Commands
- Sources/SwiftBase/Core
- Sources/SwiftBase/Core/Errors
- Sources/SwiftBase/Core/Extensions
- Sources/SwiftBase/Core/Middleware
- Sources/SwiftBase/Core/Services
- Sources/SwiftBase/Database
- Sources/SwiftBase/Database/Migrations
- Sources/SwiftBase/Database/Seeds
- Sources/SwiftBase/Modules
- Sources/SwiftBase/Modules/Auth
- Sources/SwiftBase/Modules/Collection
- Sources/SwiftBase/Modules/Query
- Sources/SwiftBase/Modules/Realtime
- Sources/SwiftBase/Modules/Storage
- Sources/SwiftBase/Resources
- Sources/SwiftBase/Resources/Config
- Sources/SwiftBase/Resources/Public
- Sources/SwiftBase/Utils

## 7. Verify Core Services

### 7.1 Logger Service Test

The logger should be producing JSON-formatted logs. When you run:

```bash
.build/debug/swiftbase serve --verbose 2>&1 | head -5
```

**Expected:** JSON logs with these fields:
- `timestamp` (ISO8601 format)
- `level` (DEBUG, INFO, WARNING, ERROR)
- `message`
- `source` (file, function, line)

### 7.2 Error Handling Test

Try an invalid command:

```bash
.build/debug/swiftbase invalid-command
```

**Expected:** Proper error message showing available commands.

## 8. Check Dependencies

```bash
# List resolved dependencies
cat Package.resolved | grep -A 2 "identity"
```

**Expected packages:**
- hummingbird
- hummingbird-websocket
- GRDB.swift
- swift-argument-parser
- Swift-JWT
- swift-crypto
- async-http-client

## Success Criteria

✅ **Phase 1 is complete if:**

1. Project builds without errors
2. All CLI commands show help text correctly
3. Server starts successfully on default and custom ports
4. Health check endpoint returns valid JSON
5. API info endpoint returns valid JSON
6. Verbose logging shows DEBUG level logs
7. Configuration can be loaded from file and environment variables
8. All project directories exist
9. JSON-formatted logs are produced
10. All dependencies are resolved correctly

## Troubleshooting

### Build fails with dependency errors
```bash
# Clear package cache and rebuild
rm -rf .build
swift package reset
swift build
```

### Port already in use
```bash
# Check what's using the port
lsof -i :8090

# Use a different port
.build/debug/swiftbase serve --port 8091
```

### Server doesn't respond
```bash
# Check server is running
ps aux | grep swiftbase

# Check logs for errors
.build/debug/swiftbase serve --verbose
```

## Next Steps

Once Phase 1 is verified, proceed to Phase 2: Database Layer, which will implement:
- GRDB.swift integration
- Migration system
- All database tables
- Database seeding
