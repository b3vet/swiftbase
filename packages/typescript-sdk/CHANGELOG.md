# Changelog

All notable changes to `@swiftbase/sdk` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-11-30

### Added

- Initial release of the SwiftBase TypeScript SDK
- **Client** - `createClient()` function for initializing the SDK
- **Authentication**
  - User registration, login, and logout
  - Admin authentication
  - Auto token refresh
  - Session persistence with pluggable storage adapters
  - Auth state change events
- **Query Builder**
  - Fluent API for building MongoDB-style queries
  - CRUD operations (find, findOne, create, update, delete)
  - Query operators ($eq, $ne, $gt, $gte, $lt, $lte, $in, $nin, $exists, $regex)
  - Logical operators ($and, $or, $not)
  - Sorting, pagination, and field selection
  - Bulk operations
  - Custom registered queries
- **Realtime**
  - WebSocket subscriptions for collections and documents
  - Callback and event emitter subscription patterns
  - Auto-reconnect with exponential backoff
  - Connection status tracking
- **File Storage**
  - File upload with progress tracking
  - Upload cancellation via AbortController
  - File download and metadata retrieval
  - File listing with search and pagination
- **Collections Management**
  - Admin-only collection CRUD operations
  - Schema and index management
  - Collection statistics
- **Error Handling**
  - Typed error classes (AuthError, QueryError, NetworkError, etc.)
  - Field-level validation errors
- **Request Features**
  - Request/response interceptors
  - Configurable timeout and retry
  - Custom headers

### Environment Support

- Browsers (Chrome, Firefox, Safari, Edge)
- Node.js 18+
- Edge runtimes (Cloudflare Workers, Vercel Edge, Deno)
