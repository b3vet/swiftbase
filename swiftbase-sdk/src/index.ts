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
