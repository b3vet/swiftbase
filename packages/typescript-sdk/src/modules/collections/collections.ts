import type { HttpClient } from '../../core/http.js'
import type {
  Collection,
  CreateCollectionRequest,
  UpdateCollectionRequest,
  CollectionStats,
} from '../../types/collections.js'
import { API_ENDPOINTS } from '../../utils/constants.js'
import { NotFoundError, SwiftBaseError, AuthError } from '../../core/errors.js'

/**
 * Internal response types from server
 */
interface ListResponse {
  success: boolean
  collections: Collection[]
}

interface CollectionResponse {
  success: boolean
  collection: Collection
}

interface StatsResponse {
  success: boolean
  stats: CollectionStats
}

interface DeleteResponse {
  success: boolean
  message?: string | undefined
}

/**
 * Collections module for admin collection management
 *
 * @remarks
 * All operations require admin authentication. Make sure to login as admin
 * before using any collection management methods.
 *
 * @example
 * ```typescript
 * // Login as admin first
 * await sb.auth.admin.login({ username: 'admin', password: 'password' })
 *
 * // List all collections
 * const collections = await sb.collections.list()
 *
 * // Create a new collection
 * const orders = await sb.collections.create({
 *   name: 'orders',
 *   schema: {
 *     customerId: { type: 'string', required: true },
 *     total: { type: 'number', required: true },
 *     status: { type: 'string', default: 'pending' }
 *   }
 * })
 * ```
 */
export class Collections {
  private readonly httpClient: HttpClient

  constructor(httpClient: HttpClient) {
    this.httpClient = httpClient
  }

  /**
   * List all collections
   *
   * @returns Array of all collections
   * @throws {AuthError} If not authenticated as admin
   *
   * @example
   * ```typescript
   * const collections = await sb.collections.list()
   * console.log(collections.map(c => c.name))
   * ```
   */
  async list(): Promise<Collection[]> {
    try {
      const response = await this.httpClient.request<ListResponse>({
        method: 'GET',
        url: API_ENDPOINTS.COLLECTIONS,
      })
      return response.collections
    } catch (error) {
      this.handleAuthError(error)
      throw error
    }
  }

  /**
   * Get a single collection by name
   *
   * @param name - The collection name
   * @returns The collection details
   * @throws {NotFoundError} If collection doesn't exist
   * @throws {AuthError} If not authenticated as admin
   *
   * @example
   * ```typescript
   * const products = await sb.collections.get('products')
   * console.log(products.schema)
   * ```
   */
  async get(name: string): Promise<Collection> {
    try {
      const response = await this.httpClient.request<CollectionResponse>({
        method: 'GET',
        url: `${API_ENDPOINTS.COLLECTIONS}/${encodeURIComponent(name)}`,
      })
      return response.collection
    } catch (error) {
      if (error instanceof SwiftBaseError && error.status === 404) {
        throw new NotFoundError(`Collection not found: ${name}`)
      }
      this.handleAuthError(error)
      throw error
    }
  }

  /**
   * Create a new collection
   *
   * @param request - The collection creation request
   * @returns The created collection
   * @throws {AuthError} If not authenticated as admin
   * @throws {SwiftBaseError} If collection already exists or validation fails
   *
   * @example
   * ```typescript
   * const orders = await sb.collections.create({
   *   name: 'orders',
   *   schema: {
   *     customerId: { type: 'string', required: true },
   *     total: { type: 'number', required: true },
   *     items: { type: 'array' },
   *     status: { type: 'string', default: 'pending' }
   *   },
   *   indexes: {
   *     customer_idx: { fields: ['customerId'] },
   *     status_idx: { fields: ['status'] }
   *   }
   * })
   * ```
   */
  async create(request: CreateCollectionRequest): Promise<Collection> {
    try {
      const response = await this.httpClient.request<CollectionResponse>({
        method: 'POST',
        url: API_ENDPOINTS.COLLECTIONS,
        body: request,
      })
      return response.collection
    } catch (error) {
      this.handleAuthError(error)
      throw error
    }
  }

  /**
   * Update an existing collection
   *
   * @param name - The collection name to update
   * @param request - The update request
   * @returns The updated collection
   * @throws {NotFoundError} If collection doesn't exist
   * @throws {AuthError} If not authenticated as admin
   *
   * @example
   * ```typescript
   * const updated = await sb.collections.update('orders', {
   *   schema: {
   *     customerId: { type: 'string', required: true },
   *     total: { type: 'number', required: true },
   *     items: { type: 'array' },
   *     status: { type: 'string', default: 'pending' },
   *     notes: { type: 'string' } // New field
   *   }
   * })
   * ```
   */
  async update(name: string, request: UpdateCollectionRequest): Promise<Collection> {
    try {
      const response = await this.httpClient.request<CollectionResponse>({
        method: 'PATCH',
        url: `${API_ENDPOINTS.COLLECTIONS}/${encodeURIComponent(name)}`,
        body: request,
      })
      return response.collection
    } catch (error) {
      if (error instanceof SwiftBaseError && error.status === 404) {
        throw new NotFoundError(`Collection not found: ${name}`)
      }
      this.handleAuthError(error)
      throw error
    }
  }

  /**
   * Delete a collection
   *
   * @param name - The collection name to delete
   * @throws {NotFoundError} If collection doesn't exist
   * @throws {AuthError} If not authenticated as admin
   *
   * @remarks
   * This will permanently delete the collection and all its documents.
   * Use with caution!
   *
   * @example
   * ```typescript
   * await sb.collections.delete('old_orders')
   * ```
   */
  async delete(name: string): Promise<void> {
    try {
      await this.httpClient.request<DeleteResponse>({
        method: 'DELETE',
        url: `${API_ENDPOINTS.COLLECTIONS}/${encodeURIComponent(name)}`,
      })
    } catch (error) {
      if (error instanceof SwiftBaseError && error.status === 404) {
        throw new NotFoundError(`Collection not found: ${name}`)
      }
      this.handleAuthError(error)
      throw error
    }
  }

  /**
   * Get statistics for a collection
   *
   * @param name - The collection name
   * @returns Collection statistics including document count and storage size
   * @throws {NotFoundError} If collection doesn't exist
   * @throws {AuthError} If not authenticated as admin
   *
   * @example
   * ```typescript
   * const stats = await sb.collections.stats('products')
   * console.log(`Products: ${stats.documentCount}`)
   * console.log(`Storage: ${stats.storageSize} bytes`)
   * console.log(`Avg size: ${stats.avgDocumentSize} bytes`)
   * ```
   */
  async stats(name: string): Promise<CollectionStats> {
    try {
      const response = await this.httpClient.request<StatsResponse>({
        method: 'GET',
        url: `${API_ENDPOINTS.COLLECTIONS}/${encodeURIComponent(name)}/stats`,
      })
      return response.stats
    } catch (error) {
      if (error instanceof SwiftBaseError && error.status === 404) {
        throw new NotFoundError(`Collection not found: ${name}`)
      }
      this.handleAuthError(error)
      throw error
    }
  }

  /**
   * Handle authentication errors
   */
  private handleAuthError(error: unknown): void {
    if (error instanceof SwiftBaseError) {
      if (error.status === 401) {
        throw new AuthError('Admin authentication required', 'UNAUTHORIZED')
      }
      if (error.status === 403) {
        throw new AuthError('Admin access required', 'FORBIDDEN')
      }
    }
  }
}
