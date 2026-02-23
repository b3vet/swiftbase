// Client types
export type {
  SwiftBaseConfig,
  AuthConfig,
  RequestConfig,
  RetryConfig,
  RealtimeConfig,
} from './client.js'
export { DEFAULT_CONFIG } from './client.js'

// Auth types
export type {
  StorageAdapter,
  User,
  Admin,
  Session,
  TokenPair,
  AuthResponse,
  AdminAuthResponse,
  AuthEvent,
  AuthStateChangeCallback,
  RegisterRequest,
  LoginRequest,
  AdminLoginRequest,
} from './auth.js'

// Query types
export type {
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
} from './query.js'

// Realtime types
export type {
  RealtimeStatus,
  EventType,
  RealtimeEvent,
  RealtimeCallback,
  StatusCallback,
  Unsubscribe,
  SubscriptionOptions,
  ChannelHandlers,
} from './realtime.js'

// Storage types
export type {
  FileMetadata,
  UploadProgress,
  UploadOptions,
  FileListOptions,
  FileListResponse,
} from './storage.js'

// Collections types
export type {
  CollectionSchema,
  CollectionIndex,
  Collection,
  CreateCollectionRequest,
  UpdateCollectionRequest,
  CollectionStats,
} from './collections.js'
