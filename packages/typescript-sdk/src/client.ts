import { HttpClient } from './core/http.js'
import type { Interceptors } from './core/interceptors.js'
import { Auth } from './modules/auth/index.js'
import { Collections } from './modules/collections/index.js'
import { QueryBuilder, QueryService } from './modules/query/index.js'
import { RealtimeManager } from './modules/realtime/index.js'
import { Storage } from './modules/storage/index.js'
import type { SwiftBaseConfig, RetryConfig } from './types/client.js'
import { DEFAULT_CONFIG } from './types/client.js'
import type { Document, QueryRequest, QueryResponse } from './types/query.js'
import { deepMerge } from './utils/helpers.js'

/**
 * SwiftBase client for interacting with a SwiftBase backend.
 *
 * This is the main entry point for the SDK. It provides access to all SwiftBase
 * features including authentication, queries, realtime subscriptions, file storage,
 * and collection management.
 *
 * @example Basic Usage
 * ```typescript
 * import { createClient } from '@swiftbase/sdk'
 *
 * const sb = createClient({ url: 'http://localhost:8090' })
 *
 * // Wait for session restoration
 * await sb.ready()
 *
 * // Use the client
 * const products = await sb.collection('products').find()
 * ```
 *
 * @example With Full Configuration
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
 *     retry: { attempts: 3, backoff: 'exponential' },
 *     headers: { 'X-Custom-Header': 'value' }
 *   },
 *   realtime: {
 *     autoConnect: true,
 *     reconnect: true,
 *     reconnectDelay: 1000,
 *     maxReconnectDelay: 30000
 *   }
 * })
 * ```
 */
export class SwiftBaseClient {
  private readonly config: Required<SwiftBaseConfig>
  private readonly httpClient: HttpClient
  private readonly authModule: Auth
  private readonly collectionsModule: Collections
  private readonly queryService: QueryService
  private readonly realtimeManager: RealtimeManager
  private readonly storageModule: Storage
  private initPromise: Promise<void> | null = null

  constructor(config: SwiftBaseConfig) {
    // Validate required config
    if (!config.url) {
      throw new Error('SwiftBase URL is required')
    }

    // Merge with defaults
    this.config = deepMerge(
      { url: config.url, ...DEFAULT_CONFIG },
      config
    ) as Required<SwiftBaseConfig>

    // Initialize HTTP client
    const retryConfig = this.config.request.retry
    this.httpClient = new HttpClient({
      baseUrl: this.config.url,
      timeout: this.config.request.timeout,
      retry: retryConfig === false ? false : retryConfig as Partial<RetryConfig>,
      headers: this.config.request.headers,
    })

    // Initialize auth module
    this.authModule = new Auth(this.httpClient, this.config.auth)

    // Initialize collections module
    this.collectionsModule = new Collections(this.httpClient)

    // Initialize query service
    this.queryService = new QueryService(this.httpClient)

    // Initialize realtime manager
    this.realtimeManager = new RealtimeManager(this.config.url, this.config.realtime)

    // Initialize storage module
    this.storageModule = new Storage(this.httpClient, this.config.url)

    // Sync auth token with realtime manager
    this.authModule.onAuthStateChange((_event, session) => {
      this.realtimeManager.setAuthToken(session?.accessToken ?? null)
    })

    // Auto-initialize auth (lazy)
    this.initPromise = this.authModule.initialize()
  }

  /**
   * Authentication module
   */
  get auth(): Auth {
    return this.authModule
  }

  /**
   * Realtime module for WebSocket subscriptions
   */
  get realtime(): RealtimeManager {
    return this.realtimeManager
  }

  /**
   * Storage module for file upload/download
   */
  get storage(): Storage {
    return this.storageModule
  }

  /**
   * Collections module for admin collection management
   */
  get collections(): Collections {
    return this.collectionsModule
  }

  /**
   * Wait for client initialization (auth session restore)
   */
  async ready(): Promise<void> {
    await this.initPromise
  }

  /**
   * Create a query builder for a collection
   * @example
   * const products = await sb.collection('products')
   *   .where({ price: { $gte: 50 } })
   *   .orderBy('created_at', 'desc')
   *   .limit(20)
   *   .find()
   */
  collection<T = Document>(name: string): QueryBuilder<T> {
    return this.queryService.collection<T>(name)
  }

  /**
   * Execute a raw query request
   * @example
   * const result = await sb.query({
   *   action: 'find',
   *   collection: 'products',
   *   query: { where: { price: { $gte: 50 } } }
   * })
   */
  async query<T = unknown>(request: QueryRequest): Promise<QueryResponse<T>> {
    return this.queryService.query<T>(request)
  }

  /**
   * Execute a custom registered query
   * @example
   * const topSellers = await sb.customQuery('getTopSellingProducts', { limit: 10 })
   */
  async customQuery<T = unknown>(
    name: string,
    params?: Record<string, unknown>
  ): Promise<QueryResponse<T>> {
    return this.queryService.customQuery<T>(name, params)
  }

  /**
   * Get the base URL
   */
  get url(): string {
    return this.config.url
  }

  /**
   * Get request/response interceptors
   */
  get interceptors(): Interceptors {
    return this.httpClient.interceptors
  }

  /**
   * Internal HTTP client (used by modules)
   * @internal
   */
  get _http(): HttpClient {
    return this.httpClient
  }

  /**
   * Get the full configuration
   * @internal
   */
  get _config(): Required<SwiftBaseConfig> {
    return this.config
  }
}

/**
 * Create a new SwiftBase client instance.
 *
 * This is the recommended way to create a client. It returns a fully configured
 * SwiftBaseClient instance ready for use.
 *
 * @param config - Client configuration options
 * @returns A new SwiftBaseClient instance
 *
 * @example Basic
 * ```typescript
 * import { createClient } from '@swiftbase/sdk'
 *
 * const sb = createClient({
 *   url: 'http://localhost:8090'
 * })
 * ```
 *
 * @example With Options
 * ```typescript
 * const sb = createClient({
 *   url: 'http://localhost:8090',
 *   auth: { storage: 'localStorage', autoRefresh: true },
 *   request: { timeout: 30000 },
 *   realtime: { autoConnect: true }
 * })
 * ```
 */
export function createClient(config: SwiftBaseConfig): SwiftBaseClient {
  return new SwiftBaseClient(config)
}
