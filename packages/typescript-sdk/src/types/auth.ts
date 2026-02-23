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
  lastLogin?: string | undefined
  createdAt: string
}

/**
 * Admin object
 */
export interface Admin {
  id: string
  username: string
  lastLogin?: string | undefined
  createdAt: string
}

/**
 * Token pair from server
 */
export interface TokenPair {
  accessToken: string
  refreshToken: string
  expiresIn: number // seconds until expiry
}

/**
 * Session object containing tokens and user/admin info
 */
export interface Session {
  accessToken: string
  refreshToken: string
  expiresAt: number // timestamp
  user?: User | undefined
  admin?: Admin | undefined
}

/**
 * Raw auth response from server (user login/register)
 * @internal
 */
export interface RawAuthResponse {
  user: RawUser
  tokens: TokenPair
}

/**
 * Raw admin auth response from server
 * @internal
 */
export interface RawAdminAuthResponse {
  admin: RawAdmin
  tokens: TokenPair
}

/**
 * Raw user from server (snake_case)
 * @internal
 */
export interface RawUser {
  id: string
  email: string
  email_verified: boolean
  metadata: Record<string, unknown>
  last_login?: string
  created_at: string
}

/**
 * Raw admin from server (snake_case)
 * @internal
 */
export interface RawAdmin {
  id: string
  username: string
  last_login?: string
  created_at: string
}

/**
 * Auth response for login/register (transformed)
 */
export interface AuthResponse {
  user: User
  session: Session
}

/**
 * Admin auth response (transformed)
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
