import type { HttpClient } from '../../core/http.js'
import type {
  WhereClause,
  OrderByClause,
  OrderDirection,
  QueryOptions,
  QueryRequest,
  QueryResponse,
  UpdateOperators,
  BulkOperation,
  BulkResult,
  Document,
} from '../../types/query.js'
import { API_ENDPOINTS } from '../../utils/constants.js'

/**
 * Fluent query builder for constructing and executing queries
 */
export class QueryBuilder<T = Document> {
  private http: HttpClient
  private collectionName: string
  private whereClause: WhereClause = {}
  private orderByClause: OrderByClause = {}
  private limitValue: number | undefined
  private offsetValue: number | undefined
  private selectFields: string[] | undefined

  constructor(http: HttpClient, collection: string) {
    this.http = http
    this.collectionName = collection
  }

  /**
   * Add where conditions (MongoDB-style operators)
   * @example
   * .where({ price: { $gte: 50 }, active: true })
   * .where({ $or: [{ status: 'pending' }, { status: 'active' }] })
   */
  where(conditions: WhereClause): QueryBuilder<T> {
    this.whereClause = { ...this.whereClause, ...conditions }
    return this
  }

  /**
   * Add order by clause
   * @example
   * .orderBy('created_at', 'desc')
   * .orderBy({ created_at: 'desc', name: 'asc' })
   */
  orderBy(field: string | OrderByClause, direction?: OrderDirection): QueryBuilder<T> {
    if (typeof field === 'string') {
      this.orderByClause[field] = direction ?? 'asc'
    } else {
      this.orderByClause = { ...this.orderByClause, ...field }
    }
    return this
  }

  /**
   * Limit number of results
   */
  limit(count: number): QueryBuilder<T> {
    this.limitValue = count
    return this
  }

  /**
   * Skip number of results (for pagination)
   */
  offset(count: number): QueryBuilder<T> {
    this.offsetValue = count
    return this
  }

  /**
   * Select specific fields to return
   * @example
   * .select(['id', 'name', 'price'])
   */
  select(fields: string[]): QueryBuilder<T> {
    this.selectFields = fields
    return this
  }

  /**
   * Build query options object
   */
  private buildQueryOptions(): QueryOptions {
    const options: QueryOptions = {}

    if (Object.keys(this.whereClause).length > 0) {
      options.where = this.whereClause
    }

    if (Object.keys(this.orderByClause).length > 0) {
      options.orderBy = this.orderByClause
    }

    if (this.limitValue !== undefined) {
      options.limit = this.limitValue
    }

    if (this.offsetValue !== undefined) {
      options.offset = this.offsetValue
    }

    if (this.selectFields !== undefined) {
      options.select = this.selectFields
    }

    return options
  }

  /**
   * Execute query and return multiple documents
   */
  async find(): Promise<T[]> {
    const request: QueryRequest = {
      action: 'find',
      collection: this.collectionName,
      query: this.buildQueryOptions(),
    }

    const response = await this.http.post<QueryResponse<T[]>>(
      API_ENDPOINTS.QUERY,
      request
    )

    return response.data
  }

  /**
   * Execute query and return single document
   */
  async findOne(): Promise<T | null> {
    const request: QueryRequest = {
      action: 'findOne',
      collection: this.collectionName,
      query: this.buildQueryOptions(),
    }

    const response = await this.http.post<QueryResponse<T | null>>(
      API_ENDPOINTS.QUERY,
      request
    )

    return response.data
  }

  /**
   * Create a new document
   */
  async create(data: Omit<T, 'id' | 'createdAt' | 'updatedAt'>): Promise<T> {
    const request: QueryRequest = {
      action: 'create',
      collection: this.collectionName,
      data: data as Record<string, unknown>,
    }

    const response = await this.http.post<QueryResponse<T>>(
      API_ENDPOINTS.QUERY,
      request
    )

    return response.data
  }

  /**
   * Update documents matching the where clause
   * @example
   * .where({ _id: 'doc_123' })
   * .update({ $set: { price: 149.99 } })
   */
  async update(data: UpdateOperators | Partial<T>): Promise<{ modified: number }> {
    const request: QueryRequest = {
      action: 'update',
      collection: this.collectionName,
      query: this.buildQueryOptions(),
      data: data as Record<string, unknown>,
    }

    const response = await this.http.post<QueryResponse<{ modified: number }>>(
      API_ENDPOINTS.QUERY,
      request
    )

    return response.data
  }

  /**
   * Delete documents matching the where clause
   */
  async delete(): Promise<{ deleted: number }> {
    const request: QueryRequest = {
      action: 'delete',
      collection: this.collectionName,
      query: this.buildQueryOptions(),
    }

    const response = await this.http.post<QueryResponse<{ deleted: number }>>(
      API_ENDPOINTS.QUERY,
      request
    )

    return response.data
  }

  /**
   * Count documents matching the where clause
   */
  async count(): Promise<number> {
    const request: QueryRequest = {
      action: 'count',
      collection: this.collectionName,
      query: this.buildQueryOptions(),
    }

    const response = await this.http.post<QueryResponse<{ count: number }>>(
      API_ENDPOINTS.QUERY,
      request
    )

    return response.data.count
  }

  /**
   * Execute bulk operations
   * @example
   * .bulk([
   *   { action: 'create', data: { name: 'Product 1' } },
   *   { action: 'update', where: { _id: 'x' }, data: { $set: { active: false } } }
   * ])
   */
  async bulk(operations: BulkOperation[]): Promise<BulkResult> {
    const request = {
      action: 'bulk',
      collection: this.collectionName,
      operations,
    }

    const response = await this.http.post<BulkResult>(
      API_ENDPOINTS.QUERY,
      request
    )

    return response
  }
}

/**
 * Query service for direct query execution
 */
export class QueryService {
  private http: HttpClient

  constructor(http: HttpClient) {
    this.http = http
  }

  /**
   * Create a query builder for a collection
   */
  collection<T = Document>(name: string): QueryBuilder<T> {
    return new QueryBuilder<T>(this.http, name)
  }

  /**
   * Execute a raw query request
   * @example
   * await sb.query({
   *   action: 'find',
   *   collection: 'products',
   *   query: { where: { price: { $gte: 50 } } }
   * })
   */
  async query<T = unknown>(request: QueryRequest): Promise<QueryResponse<T>> {
    return this.http.post<QueryResponse<T>>(API_ENDPOINTS.QUERY, request)
  }

  /**
   * Execute a custom registered query
   * @example
   * await sb.customQuery('getTopSellingProducts', { limit: 10 })
   */
  async customQuery<T = unknown>(
    name: string,
    params?: Record<string, unknown>
  ): Promise<QueryResponse<T>> {
    const request: QueryRequest = {
      action: 'custom',
      collection: '',
      custom: name,
      params,
    }

    return this.http.post<QueryResponse<T>>(API_ENDPOINTS.QUERY, request)
  }
}
