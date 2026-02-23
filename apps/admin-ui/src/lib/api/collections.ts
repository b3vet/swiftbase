import type {
  ApiResponse,
  Collection,
  CollectionStats,
  CreateCollectionRequest,
  UpdateCollectionRequest,
  BulkOperationRequest,
  BulkOperationResponse
} from '@lib/types'
import { apiClient } from './client'

export const collectionsApi = {
  // Get all collections
  async getAll(): Promise<ApiResponse<Collection[]>> {
    return apiClient.get<Collection[]>('/api/admin/collections')
  },

  // Get collection by name
  async getByName(name: string): Promise<ApiResponse<Collection>> {
    return apiClient.get<Collection>(`/api/admin/collections/${name}`)
  },

  // Create collection
  async create(data: CreateCollectionRequest): Promise<ApiResponse<Collection>> {
    return apiClient.post<Collection>('/api/admin/collections', data)
  },

  // Update collection
  async update(name: string, data: UpdateCollectionRequest): Promise<ApiResponse<Collection>> {
    return apiClient.put<Collection>(`/api/admin/collections/${name}`, data)
  },

  // Delete collection
  async delete(name: string): Promise<ApiResponse<void>> {
    return apiClient.delete<void>(`/api/admin/collections/${name}`)
  },

  // Get collection statistics
  async getStats(name: string): Promise<ApiResponse<CollectionStats>> {
    return apiClient.get<CollectionStats>(`/api/admin/collections/${name}/stats`)
  },

  // Bulk operations
  async bulkOperation(
    collection: string,
    operations: BulkOperationRequest
  ): Promise<ApiResponse<BulkOperationResponse>> {
    return apiClient.post<BulkOperationResponse>(
      `/api/bulk`,
      operations
    )
  }
}
