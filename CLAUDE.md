# CLAUDE.md - SwiftBase Project Guide

## Important Instructions for Claude

- **DO NOT** build, run, or test the application yourself
- **ONLY** use typechecking commands when needed: `swift build` (for type checking)
- The user will handle all building, running, and testing
- When completing an implementation, provide a **brief summary** of changes and tell the user what commands to run to test

## Project Overview

SwiftBase is a **single-binary backend platform** similar to PocketBase, built entirely in Swift. It provides database, API, authentication, file storage, and realtime capabilities as a self-contained executable.

**Current Status:** ~58% complete (Phases 1-11 done, Phases 12-14 pending)

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| HTTP Server | Hummingbird 2.0+ | Lightweight async HTTP framework |
| Database | GRDB.swift 6.29+ | SQLite wrapper with JSON support |
| WebSocket | HummingbirdWebSocket 2.0+ | Realtime subscriptions |
| Auth | SwiftJWT 4.0+ | JWT token generation/validation |
| Crypto | Swift Crypto 3.10+ | Password hashing |
| CLI | ArgumentParser 1.5+ | Command-line interface |
| Admin UI | Svelte 5 + Vite | Embedded web dashboard |

## Commands (for user reference)

```bash
# Build
swift build

# Run server
swift run swiftbase serve --port 8090

# Database
swift run swiftbase migrate
swift run swiftbase seed
swift run swiftbase dump --output backup.db

# Admin UI (from AdminUI/ directory)
cd AdminUI && pnpm install && pnpm run build
```

## Project Structure

```
Sources/SwiftBase/
├── App.swift              # Main application, route definitions
├── main.swift             # Entry point
├── CLI/Commands/          # serve, migrate, seed, dump
├── Core/
│   ├── Errors/            # AppError, DatabaseError, ValidationError
│   ├── Handlers/          # AdminUIHandler
│   ├── Middleware/        # CORS, Error, Logging, Validation, Versioning, Compression
│   └── Services/          # ConfigService, DatabaseService, LoggerService
├── Database/
│   ├── Migrations/        # Database migrations (001-005)
│   └── Seeds/             # DefaultSeeder
├── Modules/
│   ├── Auth/              # User/Admin authentication, JWT, Sessions
│   ├── Collections/       # Dynamic collection management
│   ├── Query/             # MongoDB-style query engine
│   ├── Realtime/          # WebSocket subscriptions
│   └── Storage/           # File upload/download
└── Resources/
    ├── Config/            # default.json, production.json
    └── Public/            # Compiled Svelte admin UI
```

## Architecture

### Module Pattern
Each module has: **Controllers** (HTTP handlers), **Services** (business logic), **Models** (GRDB records)

### Route Protection
```swift
// Public
router.post("/api/auth/login", use: controller.login)

// Protected (requires JWT)
router.group()
    .add(middleware: JWTMiddleware(jwtService: jwtService))
    .get("/api/auth/me", use: controller.getCurrentUser)

// Admin-only
router.group()
    .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
    .get("/api/admin/users", use: controller.listUsers)
```

## API Endpoints

- **Auth:** `/api/auth/register`, `/api/auth/login`, `/api/auth/refresh`, `/api/auth/logout`, `/api/auth/me`
- **Admin Auth:** `/api/admin/login`, `/api/admin/me`
- **Query:** `POST /api/query` (MongoDB-style queries)
- **Collections:** `/api/admin/collections`
- **Storage:** `/api/storage/upload`, `/api/storage/files/:id`
- **WebSocket:** `ws://localhost:8090/api/realtime`
- **Admin UI:** `/admin`

## Query DSL (MongoDB-style)

```json
{
  "action": "find",
  "collection": "products",
  "query": {
    "where": { "price": { "$gte": 50 }, "active": true },
    "orderBy": { "created_at": "desc" },
    "limit": 20
  }
}
```

**Operators:** `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin`, `$exists`, `$and`, `$or`, `$not`, `$regex`

## Database

- SQLite with GRDB.swift
- System tables: `_users`, `_admins`, `_collections`, `_documents`, `_files`
- Default admin credentials: `admin` / `admin123`

## Key Files

| File | Purpose |
|------|---------|
| `App.swift` | Routes, middleware, service initialization |
| `Core/Services/DatabaseService.swift` | GRDB connection, migrations |
| `Modules/Query/Services/QueryService.swift` | Query execution |
| `Modules/Auth/Services/JWTService.swift` | Token handling |
| `Modules/Realtime/WebSocketHub.swift` | WebSocket connections |

## Code Conventions

- Swift 6.0 with strict concurrency
- Actors for thread-safe state
- async/await throughout
- GRDB records: `Codable`, `FetchableRecord`, `PersistableRecord`

## SOW Document

See `SOW.md` for full implementation plan and progress tracking.
