# CLAUDE.md - SwiftBase Project Guide

## Important Instructions for Claude

- **DO NOT** build, run, or test the application yourself
- **ONLY** use typechecking commands when needed: `swift build` (for type checking)
- The user will handle all building, running, and testing
- When completing an implementation, provide a **brief summary** of changes and tell the user what commands to run to test

## Project Overview

SwiftBase is a **single-binary backend platform** similar to PocketBase, built entirely in Swift. It provides database, API, authentication, file storage, and realtime capabilities as a self-contained executable.

This is a **Turborepo monorepo** with the following structure:
- `apps/backend` - Swift backend server
- `apps/admin-ui` - Svelte 5 admin dashboard
- `packages/typescript-sdk` - TypeScript SDK (`@swiftbase/sdk`)

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
| SDK | TypeScript | Client SDK for JavaScript/TypeScript |
| Monorepo | Turborepo + pnpm | Build system and package management |

## Commands (for user reference)

```bash
# Install all dependencies (from root)
pnpm install

# Build all packages
pnpm build

# Run all tests
pnpm test

# TypeScript type checking
pnpm typecheck

# Swift backend (from apps/backend)
cd apps/backend
swift build
swift run swiftbase serve --port 8090
swift run swiftbase migrate
swift run swiftbase seed

# Admin UI development (from apps/admin-ui)
cd apps/admin-ui
pnpm dev

# SDK development (from packages/typescript-sdk)
cd packages/typescript-sdk
pnpm dev
pnpm test
```

## Project Structure

```
swiftbase/
├── apps/
│   ├── admin-ui/              # Svelte 5 Admin Dashboard
│   │   ├── src/
│   │   ├── package.json
│   │   └── vite.config.ts
│   └── backend/               # Swift Backend
│       ├── Sources/SwiftBase/
│       │   ├── App.swift
│       │   ├── main.swift
│       │   ├── CLI/Commands/
│       │   ├── Core/
│       │   ├── Database/
│       │   ├── Modules/
│       │   └── Resources/
│       ├── Tests/
│       └── Package.swift
├── packages/
│   └── typescript-sdk/        # TypeScript SDK (@swiftbase/sdk)
│       ├── src/
│       ├── tests/
│       ├── package.json
│       └── tsup.config.ts
├── package.json               # Root workspace
├── pnpm-workspace.yaml
├── turbo.json
└── CLAUDE.md
```

## Architecture

### Module Pattern (Swift Backend)
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
| `apps/backend/Sources/SwiftBase/App.swift` | Routes, middleware, service initialization |
| `apps/backend/Sources/SwiftBase/Core/Services/DatabaseService.swift` | GRDB connection, migrations |
| `apps/backend/Sources/SwiftBase/Modules/Query/Services/QueryService.swift` | Query execution |
| `apps/backend/Sources/SwiftBase/Modules/Auth/Services/JWTService.swift` | Token handling |
| `apps/backend/Sources/SwiftBase/Modules/Realtime/WebSocketHub.swift` | WebSocket connections |
| `packages/typescript-sdk/src/client.ts` | SDK main client |
| `packages/typescript-sdk/src/modules/` | SDK modules (auth, query, realtime, storage, collections) |

## Code Conventions

### Swift (Backend)
- Swift 6.0 with strict concurrency
- Actors for thread-safe state
- async/await throughout
- GRDB records: `Codable`, `FetchableRecord`, `PersistableRecord`

### TypeScript (SDK)
- Strict mode with `exactOptionalPropertyTypes`
- ESM primary, CJS for compatibility
- Vitest for testing
- tsup for building

## SOW Documents

- `SOW.md` - Swift backend implementation plan
- `SOW_TS_SDK.md` - TypeScript SDK implementation plan
