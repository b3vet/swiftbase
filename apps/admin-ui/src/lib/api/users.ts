import type { ApiResponse, User } from '@lib/types'
import { apiClient } from './client'

export const usersApi = {
  // Get all users (admin only)
  async getAll(params?: {
    limit?: number
    offset?: number
    search?: string
  }): Promise<ApiResponse<User[]>> {
    return apiClient.get<User[]>('/api/admin/users', { params })
  },

  // Get user by ID (admin only)
  async getById(id: string): Promise<ApiResponse<User>> {
    return apiClient.get<User>(`/api/admin/users/${id}`)
  },

  // Create user (admin only)
  async create(data: {
    email: string
    password: string
    metadata?: Record<string, any>
  }): Promise<ApiResponse<User>> {
    return apiClient.post<User>('/api/admin/users', data)
  },

  // Update user (admin only)
  async update(id: string, data: {
    email?: string
    password?: string
    email_verified?: boolean
    metadata?: Record<string, any>
  }): Promise<ApiResponse<User>> {
    return apiClient.put<User>(`/api/admin/users/${id}`, data)
  },

  // Delete user (admin only)
  async delete(id: string): Promise<ApiResponse<void>> {
    return apiClient.delete<void>(`/api/admin/users/${id}`)
  },

  // Verify user email (admin only)
  async verifyEmail(id: string): Promise<ApiResponse<User>> {
    return apiClient.post<User>(`/api/admin/users/${id}/verify-email`)
  },

  // Revoke all user sessions (admin only)
  async revokeSessions(id: string): Promise<ApiResponse<void>> {
    return apiClient.post<void>(`/api/admin/users/${id}/revoke-sessions`)
  },

  // Get user statistics (admin only)
  async getStats(): Promise<ApiResponse<{
    total_users: number
    verified_users: number
    active_users: number
    recent_registrations: number
  }>> {
    return apiClient.get('/api/admin/users/stats')
  }
}
