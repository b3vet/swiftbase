/**
 * Storage adapter interface for auth tokens
 */
export interface StorageAdapter {
  get(key: string): string | null | Promise<string | null>
  set(key: string, value: string): void | Promise<void>
  remove(key: string): void | Promise<void>
}

/**
 * User object
 */
export interface User {
  id: string
  email: string
  emailVerified: boolean
  metadata: Record<string, unknown>
  createdAt: string
  updatedAt: string
}

/**
 * Admin object
 */
export interface Admin {
  id: string
  username: string
  createdAt: string
  updatedAt: string
}

/**
 * Session object containing tokens and user/admin info
 */
export interface Session {
  accessToken: string
  refreshToken: string
  expiresAt: number
  user?: User
  admin?: Admin
}

/**
 * Auth response for login/register
 */
export interface AuthResponse {
  user: User
  session: Session
}

/**
 * Admin auth response
 */
export interface AdminAuthResponse {
  admin: Admin
  session: Session
}

/**
 * Auth event types
 */
export type AuthEvent = 'SIGNED_IN' | 'SIGNED_OUT' | 'TOKEN_REFRESHED' | 'SESSION_EXPIRED'

/**
 * Auth state change callback
 */
export type AuthStateChangeCallback = (event: AuthEvent, session: Session | null) => void

/**
 * Register request payload
 */
export interface RegisterRequest {
  email: string
  password: string
  metadata?: Record<string, unknown>
}

/**
 * Login request payload
 */
export interface LoginRequest {
  email: string
  password: string
}

/**
 * Admin login request payload
 */
export interface AdminLoginRequest {
  username: string
  password: string
}
