import type {
  ApiResponse,
  QueryRequest,
  QueryResult,
  CustomQuery
} from '@lib/types'
import { apiClient } from './client'

export const queryApi = {
  // Execute query
  async execute<T = any>(query: QueryRequest): Promise<ApiResponse<QueryResult<T>>> {
    return apiClient.post<QueryResult<T>>('/api/query', query)
  },

  // Find documents
  async find<T = any>(
    collection: string,
    where?: Record<string, any>,
    options?: {
      select?: string[] | Record<string, 0 | 1>
      orderBy?: Record<string, 'asc' | 'desc'>
      limit?: number
      offset?: number
      include?: string[]
    }
  ): Promise<ApiResponse<QueryResult<T[]>>> {
    return this.execute<T[]>({
      action: 'find',
      collection,
      query: {
        where,
        ...options
      }
    })
  },

  // Find one document
  async findOne<T = any>(
    collection: string,
    where: Record<string, any>
  ): Promise<ApiResponse<QueryResult<T>>> {
    return this.execute<T>({
      action: 'findOne',
      collection,
      query: { where }
    })
  },

  // Create document
  async create<T = any>(
    collection: string,
    data: Record<string, any>
  ): Promise<ApiResponse<QueryResult<T>>> {
    return this.execute<T>({
      action: 'create',
      collection,
      data
    })
  },

  // Update documents
  async update<T = any>(
    collection: string,
    where: Record<string, any>,
    data: Record<string, any>,
    options?: { multi?: boolean; returnNew?: boolean }
  ): Promise<ApiResponse<QueryResult<T>>> {
    return this.execute<T>({
      action: 'update',
      collection,
      query: { where },
      data,
      options
    })
  },

  // Delete documents
  async delete(
    collection: string,
    where: Record<string, any>,
    options?: { multi?: boolean }
  ): Promise<ApiResponse<QueryResult>> {
    return this.execute({
      action: 'delete',
      collection,
      query: { where },
      options
    })
  },

  // Count documents
  async count(
    collection: string,
    where?: Record<string, any>
  ): Promise<ApiResponse<QueryResult<number>>> {
    return this.execute<number>({
      action: 'count',
      collection,
      query: { where }
    })
  },

  // Execute custom query
  async executeCustom<T = any>(
    queryName: string,
    params?: Record<string, any>
  ): Promise<ApiResponse<QueryResult<T>>> {
    return this.execute<T>({
      action: 'custom',
      collection: '',
      custom: queryName,
      params
    })
  },

  // Get all custom queries (admin only)
  async getCustomQueries(): Promise<ApiResponse<CustomQuery[]>> {
    return apiClient.get<CustomQuery[]>('/api/admin/custom-queries')
  },

  // Create custom query (admin only)
  async createCustomQuery(query: Omit<CustomQuery, 'id' | 'created_at' | 'updated_at'>): Promise<ApiResponse<CustomQuery>> {
    return apiClient.post<CustomQuery>('/api/admin/custom-queries', query)
  },

  // Delete custom query (admin only)
  async deleteCustomQuery(id: string): Promise<ApiResponse<void>> {
    return apiClient.delete<void>(`/api/admin/custom-queries/${id}`)
  }
}
