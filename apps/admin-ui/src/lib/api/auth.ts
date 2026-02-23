import type {
  ApiResponse,
  LoginCredentials,
  RegisterData,
  AuthResponse,
  RefreshTokenRequest,
  User,
  Admin
} from '@lib/types'
import { apiClient } from './client'

export const authApi = {
  // Admin login
  async adminLogin(username: string, password: string): Promise<ApiResponse<AuthResponse>> {
    return apiClient.post<AuthResponse>('/api/admin/login', { username, password })
  },

  // Admin refresh token
  async adminRefresh(refreshToken: string): Promise<ApiResponse<AuthResponse>> {
    return apiClient.post<AuthResponse>('/api/admin/refresh', { refreshToken })
  },

  // Admin logout
  async adminLogout(): Promise<ApiResponse<void>> {
    return apiClient.post<void>('/api/admin/logout')
  },

  // Get current admin
  async getAdminMe(): Promise<ApiResponse<Admin>> {
    return apiClient.get<Admin>('/api/admin/me')
  },

  // User registration
  async register(data: RegisterData): Promise<ApiResponse<AuthResponse>> {
    return apiClient.post<AuthResponse>('/api/auth/register', data)
  },

  // User login
  async userLogin(email: string, password: string): Promise<ApiResponse<AuthResponse>> {
    return apiClient.post<AuthResponse>('/api/auth/login', { email, password })
  },

  // User refresh token
  async userRefresh(refreshToken: string): Promise<ApiResponse<AuthResponse>> {
    return apiClient.post<AuthResponse>('/api/auth/refresh', { refreshToken })
  },

  // User logout
  async userLogout(): Promise<ApiResponse<void>> {
    return apiClient.post<void>('/api/auth/logout')
  },

  // Get current user
  async getUserMe(): Promise<ApiResponse<User>> {
    return apiClient.get<User>('/api/auth/me')
  },

  // Check authentication status
  isAuthenticated(): boolean {
    return apiClient.isAuthenticated()
  },

  // Clear authentication
  clearAuth(): void {
    apiClient.clearTokens()
  }
}
