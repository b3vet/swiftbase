import type {
  ApiResponse,
  FileMetadata,
  UploadFileResponse,
  FileListQuery
} from '@lib/types'
import { apiClient } from './client'

export const filesApi = {
  // Upload file
  async upload(
    file: File,
    metadata?: Record<string, any>,
    onProgress?: (progress: number) => void
  ): Promise<ApiResponse<FileMetadata>> {
    return apiClient.upload<FileMetadata>(
      '/api/storage/upload',
      file,
      metadata,
      onProgress
    )
  },

  // Get all files
  async getAll(query?: FileListQuery): Promise<ApiResponse<FileMetadata[]>> {
    return apiClient.get<FileMetadata[]>('/api/storage/files', { params: query })
  },

  // Get file by ID
  async getById(id: string): Promise<ApiResponse<FileMetadata>> {
    return apiClient.get<FileMetadata>(`/api/storage/files/${id}`)
  },

  // Download file (returns download URL)
  getDownloadUrl(id: string): string {
    const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8090'
    const token = apiClient.getAccessToken()
    return `${baseURL}/api/storage/files/${id}?token=${token}`
  },

  // Delete file
  async delete(id: string): Promise<ApiResponse<void>> {
    return apiClient.delete<void>(`/api/storage/files/${id}`)
  },

  // Update file metadata
  async updateMetadata(
    id: string,
    metadata: Record<string, any>
  ): Promise<ApiResponse<FileMetadata>> {
    return apiClient.put<FileMetadata>(`/api/storage/files/${id}/metadata`, { metadata })
  },

  // Get storage statistics
  async getStats(): Promise<ApiResponse<{
    fileCount: number
    totalSize: number
    quota?: number
    usedPercentage?: number
  }>> {
    return apiClient.get('/api/storage/stats')
  }
}
