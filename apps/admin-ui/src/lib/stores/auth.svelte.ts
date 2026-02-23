import type { Admin, AuthResponse } from '@lib/types'
import { authApi, apiClient } from '@lib/api'

interface AuthState {
  admin: Admin | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
}

// Create auth store with Svelte 5 runes
function createAuthStore() {
  let state = $state<AuthState>({
    admin: null,
    isAuthenticated: false,
    isLoading: true,
    error: null
  })

  // Derived values
  const isAuthenticated = $derived(state.isAuthenticated)
  const admin = $derived(state.admin)
  const isLoading = $derived(state.isLoading)
  const error = $derived(state.error)

  // Track if initialized
  let initialized = false

  async function initAuth() {
    if (initialized) return
    initialized = true
    state.isLoading = true
    state.error = null

    if (apiClient.isAuthenticated()) {
      try {
        const response = await authApi.getAdminMe()

        if (response.success && response.data) {
          state.admin = response.data
          state.isAuthenticated = true
        } else {
          // Token is invalid, clear it
          apiClient.clearTokens()
          state.admin = null
          state.isAuthenticated = false
        }
      } catch (err) {
        console.error('Failed to verify authentication:', err)
        apiClient.clearTokens()
        state.admin = null
        state.isAuthenticated = false
      }
    } else {
      state.admin = null
      state.isAuthenticated = false
    }

    state.isLoading = false
  }

  async function login(username: string, password: string): Promise<boolean> {
    state.isLoading = true
    state.error = null

    try {
      const response = await authApi.adminLogin(username, password)

      if (response.success && response.data) {
        const { admin: adminData, tokens } = response.data

        // Store tokens
        apiClient.setTokens(tokens.accessToken, tokens.refreshToken)

        // Update state
        state.admin = adminData!
        state.isAuthenticated = true
        state.error = null

        return true
      } else {
        state.error = response.error || 'Login failed'
        return false
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Login failed'
      state.error = message
      return false
    } finally {
      state.isLoading = false
    }
  }

  async function logout(): Promise<void> {
    state.isLoading = true

    try {
      await authApi.adminLogout()
    } catch (err) {
      console.error('Logout error:', err)
    } finally {
      // Clear tokens and state regardless of API response
      apiClient.clearTokens()
      state.admin = null
      state.isAuthenticated = false
      state.error = null
      state.isLoading = false

      // Redirect to login
      window.location.hash = '#/login'
    }
  }

  async function refreshAuth(): Promise<boolean> {
    const refreshToken = apiClient.getRefreshToken()

    if (!refreshToken) {
      return false
    }

    try {
      const response = await authApi.adminRefresh(refreshToken)

      if (response.success && response.data) {
        const { admin: adminData, tokens } = response.data

        // Update tokens
        apiClient.setTokens(tokens.accessToken, tokens.refreshToken)

        // Update state
        state.admin = adminData!
        state.isAuthenticated = true

        return true
      }

      return false
    } catch (err) {
      console.error('Token refresh failed:', err)
      return false
    }
  }

  function clearError() {
    state.error = null
  }

  return {
    // Getters (using $derived)
    get admin() {
      return admin
    },
    get isAuthenticated() {
      return isAuthenticated
    },
    get isLoading() {
      return isLoading
    },
    get error() {
      return error
    },

    // Actions
    login,
    logout,
    refreshAuth,
    clearError,
    initAuth
  }
}

// Export singleton instance
export const authStore = createAuthStore()
