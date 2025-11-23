import type { ApiResponse, ApiError, RequestConfig } from '@lib/types'
import { storage } from '@lib/utils'

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8090'
const DEFAULT_TIMEOUT = 30000

// Token storage keys
const ACCESS_TOKEN_KEY = 'access_token'
const REFRESH_TOKEN_KEY = 'refresh_token'

class ApiClient {
  private baseURL: string
  private defaultTimeout: number
  private refreshPromise: Promise<string> | null = null

  constructor(baseURL: string = API_BASE_URL, timeout: number = DEFAULT_TIMEOUT) {
    this.baseURL = baseURL
    this.defaultTimeout = timeout
  }

  // Get access token
  getAccessToken(): string | null {
    return storage.get<string>(ACCESS_TOKEN_KEY)
  }

  // Get refresh token
  getRefreshToken(): string | null {
    return storage.get<string>(REFRESH_TOKEN_KEY)
  }

  // Set tokens
  setTokens(accessToken: string, refreshToken: string): void {
    storage.set(ACCESS_TOKEN_KEY, accessToken)
    storage.set(REFRESH_TOKEN_KEY, refreshToken)
  }

  // Clear tokens
  clearTokens(): void {
    storage.remove(ACCESS_TOKEN_KEY)
    storage.remove(REFRESH_TOKEN_KEY)
  }

  // Check if user is authenticated
  isAuthenticated(): boolean {
    return !!this.getAccessToken()
  }

  // Refresh access token
  private async refreshAccessToken(): Promise<string> {
    // Prevent multiple simultaneous refresh requests
    if (this.refreshPromise) {
      return this.refreshPromise
    }

    this.refreshPromise = (async () => {
      const refreshToken = this.getRefreshToken()
      if (!refreshToken) {
        this.clearTokens()
        throw new Error('No refresh token available')
      }

      try {
        const response = await fetch(`${this.baseURL}/api/admin/refresh`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ refreshToken })
        })

        if (!response.ok) {
          throw new Error('Token refresh failed')
        }

        const data = await response.json()

        // Backend returns TokenPair directly: { accessToken, refreshToken, expiresIn }
        if (data.accessToken && data.refreshToken) {
          this.setTokens(data.accessToken, data.refreshToken)
          return data.accessToken
        }

        // Fallback: check if wrapped in success/data structure
        if (data.success && data.data?.accessToken) {
          this.setTokens(data.data.accessToken, data.data.refreshToken)
          return data.data.accessToken
        }

        throw new Error('Invalid refresh response')
      } catch (error) {
        this.clearTokens()
        throw error
      } finally {
        this.refreshPromise = null
      }
    })()

    return this.refreshPromise
  }

  // Make HTTP request
  async request<T = any>(
    endpoint: string,
    options: RequestInit & RequestConfig = {}
  ): Promise<ApiResponse<T>> {
    const {
      headers = {},
      params,
      timeout = this.defaultTimeout,
      ...fetchOptions
    } = options

    // Build URL with query parameters
    let url = `${this.baseURL}${endpoint}`
    if (params) {
      const queryString = new URLSearchParams(params).toString()
      url += `?${queryString}`
    }

    // Build headers - convert HeadersInit to Record<string, string>
    const requestHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(headers as Record<string, string>)
    }

    // Add authorization header if authenticated
    const accessToken = this.getAccessToken()
    if (accessToken) {
      requestHeaders['Authorization'] = `Bearer ${accessToken}`
    }

    // Create abort controller for timeout
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), timeout)

    try {
      const response = await fetch(url, {
        ...fetchOptions,
        headers: requestHeaders,
        signal: controller.signal
      })

      clearTimeout(timeoutId)

      // Handle 401 Unauthorized - attempt token refresh
      if (response.status === 401 && this.getRefreshToken()) {
        try {
          const newAccessToken = await this.refreshAccessToken()

          // Retry request with new token
          requestHeaders['Authorization'] = `Bearer ${newAccessToken}`
          const retryResponse = await fetch(url, {
            ...fetchOptions,
            headers: requestHeaders
          })

          return this.handleResponse<T>(retryResponse)
        } catch (refreshError) {
          // Refresh failed, redirect to login
          window.location.hash = '#/login'
          throw new Error('Session expired. Please login again.')
        }
      }

      return this.handleResponse<T>(response)
    } catch (error) {
      clearTimeout(timeoutId)

      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('Request timeout')
      }

      throw error
    }
  }

  // Handle response
  private async handleResponse<T>(response: Response): Promise<ApiResponse<T>> {
    const contentType = response.headers.get('content-type')
    const isJson = contentType?.includes('application/json')

    if (!response.ok) {
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`

      if (isJson) {
        try {
          const errorData = await response.json()
          errorMessage = errorData.error || errorData.message || errorMessage
        } catch {
          // Failed to parse error JSON
        }
      }

      return {
        success: false,
        error: errorMessage
      }
    }

    if (isJson) {
      const data = await response.json()

      // Check if response is already wrapped (has success property)
      if (data.hasOwnProperty('success')) {
        // If it has both success and data, return as-is
        if (data.hasOwnProperty('data')) {
          return data
        }

        // If it has success but data is in other properties (like 'collections', 'admin', etc.)
        // Extract the actual data by removing 'success' property
        const { success, ...actualData } = data
        return {
          success: success,
          data: actualData as T
        }
      }

      // Response is completely unwrapped, wrap it
      return {
        success: true,
        data: data as T
      }
    }

    return {
      success: true,
      data: await response.text() as any
    }
  }

  // HTTP Methods
  async get<T = any>(endpoint: string, config?: RequestConfig): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'GET', ...config })
  }

  async post<T = any>(
    endpoint: string,
    data?: any,
    config?: RequestConfig
  ): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
      ...config
    })
  }

  async put<T = any>(
    endpoint: string,
    data?: any,
    config?: RequestConfig
  ): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
      ...config
    })
  }

  async patch<T = any>(
    endpoint: string,
    data?: any,
    config?: RequestConfig
  ): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'PATCH',
      body: data ? JSON.stringify(data) : undefined,
      ...config
    })
  }

  async delete<T = any>(endpoint: string, config?: RequestConfig): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'DELETE', ...config })
  }

  // Upload file as raw binary with headers
  async upload<T = any>(
    endpoint: string,
    file: File,
    metadata?: Record<string, any>,
    onProgress?: (progress: number) => void
  ): Promise<ApiResponse<T>> {
    const accessToken = this.getAccessToken()

    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()

      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable && onProgress) {
          const progress = (event.loaded / event.total) * 100
          onProgress(progress)
        }
      })

      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            const response = JSON.parse(xhr.responseText)
            resolve(response)
          } catch {
            resolve({ success: true, data: xhr.responseText as any })
          }
        } else {
          reject(new Error(`Upload failed: ${xhr.statusText}`))
        }
      })

      xhr.addEventListener('error', () => {
        reject(new Error('Upload failed'))
      })

      xhr.addEventListener('abort', () => {
        reject(new Error('Upload cancelled'))
      })

      xhr.open('POST', `${this.baseURL}${endpoint}`)

      // Set headers
      if (accessToken) {
        xhr.setRequestHeader('Authorization', `Bearer ${accessToken}`)
      }

      // Send filename and content type as headers (backend expects these)
      xhr.setRequestHeader('X-Filename', file.name)
      xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream')

      // Send metadata as header if provided
      if (metadata) {
        xhr.setRequestHeader('X-Metadata', JSON.stringify(metadata))
      }

      // Send raw file data
      xhr.send(file)
    })
  }
}

// Export singleton instance
export const apiClient = new ApiClient()

// Export class for testing or custom instances
export { ApiClient }
