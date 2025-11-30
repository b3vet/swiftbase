import type { HttpClient } from '../../core/http.js'
import type {
  User,
  Admin,
  Session,
  AuthResponse,
  AdminAuthResponse,
  AuthEvent,
  AuthStateChangeCallback,
  RegisterRequest,
  LoginRequest,
  AdminLoginRequest,
} from '../../types/auth.js'
import type { AuthConfig } from '../../types/client.js'
import { API_ENDPOINTS } from '../../utils/constants.js'
import { createStorageAdapter } from './storage.js'
import { TokenManager } from './token.js'

/**
 * Admin authentication methods
 */
export class AdminAuth {
  private auth: Auth

  constructor(auth: Auth) {
    this.auth = auth
  }

  /**
   * Login as admin
   */
  async login(credentials: AdminLoginRequest): Promise<AdminAuthResponse> {
    return this.auth.adminLogin(credentials)
  }

  /**
   * Get current admin
   */
  async getAdmin(): Promise<Admin | null> {
    return this.auth.getAdmin()
  }
}

/**
 * Authentication module
 */
export class Auth {
  private http: HttpClient
  private config: AuthConfig
  private tokenManager: TokenManager
  private listeners: Set<AuthStateChangeCallback> = new Set()
  private initialized: boolean = false
  private currentUser: User | null = null
  private currentAdmin: Admin | null = null

  public readonly admin: AdminAuth

  constructor(http: HttpClient, config: AuthConfig) {
    this.http = http
    this.config = config

    const storage = createStorageAdapter(config.storage ?? 'memory')
    this.tokenManager = new TokenManager(storage)
    this.admin = new AdminAuth(this)
  }

  /**
   * Initialize auth module (load session from storage)
   */
  async initialize(): Promise<void> {
    if (this.initialized) return

    const session = await this.tokenManager.initialize()
    if (session) {
      // Set auth header
      this.http.setAuthHeader(session.accessToken)

      // Restore user/admin from session
      if (session.user) {
        this.currentUser = session.user
      }
      if (session.admin) {
        this.currentAdmin = session.admin
      }

      // Start auto-refresh if enabled
      if (this.config.autoRefresh) {
        this.startAutoRefresh()
      }
    }

    this.initialized = true
  }

  /**
   * Register a new user
   */
  async register(data: RegisterRequest): Promise<AuthResponse> {
    const response = await this.http.post<AuthResponse>(
      API_ENDPOINTS.AUTH_REGISTER,
      data
    )

    await this.handleAuthResponse(response)
    this.emitEvent('SIGNED_IN', response.session)

    return response
  }

  /**
   * Login with email and password
   */
  async login(credentials: LoginRequest): Promise<AuthResponse> {
    const response = await this.http.post<AuthResponse>(
      API_ENDPOINTS.AUTH_LOGIN,
      credentials
    )

    await this.handleAuthResponse(response)
    this.emitEvent('SIGNED_IN', response.session)

    return response
  }

  /**
   * Login as admin
   */
  async adminLogin(credentials: AdminLoginRequest): Promise<AdminAuthResponse> {
    const response = await this.http.post<AdminAuthResponse>(
      API_ENDPOINTS.ADMIN_LOGIN,
      credentials
    )

    await this.handleAdminAuthResponse(response)
    this.emitEvent('SIGNED_IN', response.session)

    return response
  }

  /**
   * Logout current user/admin
   */
  async logout(): Promise<void> {
    try {
      // Call server logout endpoint
      await this.http.post(API_ENDPOINTS.AUTH_LOGOUT)
    } catch {
      // Ignore errors, clear session anyway
    }

    await this.clearSession()
    this.emitEvent('SIGNED_OUT', null)
  }

  /**
   * Get current user from server
   */
  async getUser(): Promise<User | null> {
    if (!this.tokenManager.getAccessToken()) {
      return null
    }

    try {
      const user = await this.http.get<User>(API_ENDPOINTS.AUTH_ME)
      this.currentUser = user
      return user
    } catch {
      return this.currentUser
    }
  }

  /**
   * Get current admin from server
   */
  async getAdmin(): Promise<Admin | null> {
    if (!this.tokenManager.getAccessToken()) {
      return null
    }

    try {
      const admin = await this.http.get<Admin>(API_ENDPOINTS.ADMIN_ME)
      this.currentAdmin = admin
      return admin
    } catch {
      return this.currentAdmin
    }
  }

  /**
   * Get current session (synchronous)
   */
  getSession(): Session | null {
    return this.tokenManager.getSession()
  }

  /**
   * Refresh the current session
   */
  async refreshSession(): Promise<Session | null> {
    const refreshToken = this.tokenManager.getRefreshToken()
    if (!refreshToken) {
      return null
    }

    try {
      const response = await this.http.post<{
        accessToken: string
        refreshToken: string
        expiresAt: number
      }>(API_ENDPOINTS.AUTH_REFRESH, { refreshToken })

      await this.tokenManager.updateTokens(
        response.accessToken,
        response.refreshToken,
        response.expiresAt
      )

      this.http.setAuthHeader(response.accessToken)
      this.emitEvent('TOKEN_REFRESHED', this.tokenManager.getSession())

      return this.tokenManager.getSession()
    } catch {
      // Refresh failed, clear session
      await this.clearSession()
      this.emitEvent('SESSION_EXPIRED', null)
      return null
    }
  }

  /**
   * Subscribe to auth state changes
   */
  onAuthStateChange(callback: AuthStateChangeCallback): () => void {
    this.listeners.add(callback)

    // Return unsubscribe function
    return () => {
      this.listeners.delete(callback)
    }
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return this.tokenManager.getSession() !== null &&
      !this.tokenManager.isSessionExpired()
  }

  /**
   * Handle auth response (user login/register)
   */
  private async handleAuthResponse(response: AuthResponse): Promise<void> {
    this.currentUser = response.user
    this.currentAdmin = null

    await this.tokenManager.setSession(
      {
        ...response.session,
        user: response.user,
      },
      this.config.persistSession ?? true
    )

    this.http.setAuthHeader(response.session.accessToken)

    if (this.config.autoRefresh) {
      this.startAutoRefresh()
    }
  }

  /**
   * Handle admin auth response
   */
  private async handleAdminAuthResponse(response: AdminAuthResponse): Promise<void> {
    this.currentAdmin = response.admin
    this.currentUser = null

    await this.tokenManager.setSession(
      {
        ...response.session,
        admin: response.admin,
      },
      this.config.persistSession ?? true
    )

    this.http.setAuthHeader(response.session.accessToken)

    if (this.config.autoRefresh) {
      this.startAutoRefresh()
    }
  }

  /**
   * Clear current session
   */
  private async clearSession(): Promise<void> {
    this.tokenManager.stopRefreshTimer()
    await this.tokenManager.clear()
    this.http.setAuthHeader(null)
    this.currentUser = null
    this.currentAdmin = null
  }

  /**
   * Start auto-refresh timer
   */
  private startAutoRefresh(): void {
    this.tokenManager.startRefreshTimer(
      () => this.refreshSession().then(() => {}),
      60000 // Refresh 60 seconds before expiry
    )
  }

  /**
   * Emit auth state change event
   */
  private emitEvent(event: AuthEvent, session: Session | null): void {
    for (const listener of this.listeners) {
      try {
        listener(event, session)
      } catch {
        // Ignore listener errors
      }
    }
  }
}
