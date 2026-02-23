/**
 * @swiftbase/sdk - TypeScript SDK for SwiftBase
 *
 * A lightweight, type-safe client library for interacting with SwiftBase backends
 * from any JavaScript/TypeScript environment.
 *
 * @packageDocumentation
 *
 * @example Quick Start
 * ```typescript
 * import { createClient } from '@swiftbase/sdk'
 *
 * // Create client
 * const sb = createClient({
 *   url: 'http://localhost:8090'
 * })
 *
 * // Authenticate
 * await sb.auth.login({ email: 'user@example.com', password: 'password' })
 *
 * // Query data
 * const products = await sb.collection('products')
 *   .where({ active: true })
 *   .orderBy('created_at', 'desc')
 *   .limit(10)
 *   .find()
 *
 * // Subscribe to realtime changes
 * sb.realtime.subscribe('products', (event) => {
 *   console.log('Product changed:', event.type, event.document)
 * })
 * ```
 *
 * @example Full Configuration
 * ```typescript
 * const sb = createClient({
 *   url: 'http://localhost:8090',
 *   auth: {
 *     storage: 'localStorage',
 *     autoRefresh: true,
 *     persistSession: true
 *   },
 *   request: {
 *     timeout: 30000,
 *     retry: { attempts: 3, backoff: 'exponential' }
 *   },
 *   realtime: {
 *     autoConnect: true,
 *     reconnect: true
 *   }
 * })
 * ```
 */

// Client
export { SwiftBaseClient, createClient } from './client.js'

// Auth module
export { Auth, AdminAuth } from './modules/auth/index.js'
export {
  MemoryStorage,
  LocalStorageAdapter,
  SessionStorageAdapter,
} from './modules/auth/index.js'

// Query module
export { QueryBuilder, QueryService } from './modules/query/index.js'

// Realtime module
export { RealtimeManager, RealtimeChannel } from './modules/realtime/index.js'

// Storage module
export { Storage, type FileInput } from './modules/storage/index.js'

// Collections module
export { Collections } from './modules/collections/index.js'

// Types
export type {
  // Client config
  SwiftBaseConfig,
  AuthConfig,
  RequestConfig,
  RetryConfig,
  RealtimeConfig,
  // Auth
  StorageAdapter,
  User,
  Admin,
  Session,
  AuthResponse,
  AdminAuthResponse,
  AuthEvent,
  AuthStateChangeCallback,
  RegisterRequest,
  LoginRequest,
  AdminLoginRequest,
  // Query
  ComparisonOperators,
  LogicalOperators,
  WhereClause,
  OrderDirection,
  OrderByClause,
  QueryOptions,
  UpdateOperators,
  QueryAction,
  QueryRequest,
  QueryResponse,
  BulkOperation,
  BulkResult,
  Document,
  // Realtime
  RealtimeStatus,
  EventType,
  RealtimeEvent,
  RealtimeCallback,
  StatusCallback,
  Unsubscribe,
  SubscriptionOptions,
  ChannelHandlers,
  // Storage
  FileMetadata,
  UploadProgress,
  UploadOptions,
  FileListOptions,
  FileListResponse,
  // Collections
  CollectionSchema,
  CollectionIndex,
  Collection,
  CreateCollectionRequest,
  UpdateCollectionRequest,
  CollectionStats,
} from './types/index.js'

// Errors
export {
  SwiftBaseError,
  AuthError,
  QueryError,
  NetworkError,
  NotFoundError,
  ValidationError,
  type AuthErrorCode,
  type QueryErrorCode,
  type NetworkErrorCode,
  type ValidationFieldError,
} from './core/errors.js'
