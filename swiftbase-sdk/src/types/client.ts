import type { StorageAdapter } from './auth.js'

/**
 * Authentication configuration
 */
export interface AuthConfig {
  /** Storage adapter for tokens */
  storage?: 'localStorage' | 'sessionStorage' | 'memory' | StorageAdapter
  /** Auto-refresh tokens before expiry (default: true) */
  autoRefresh?: boolean
  /** Persist session across page reloads (default: true) */
  persistSession?: boolean
}

/**
 * Retry configuration for requests
 */
export interface RetryConfig {
  /** Number of retry attempts (default: 3) */
  attempts?: number
  /** Backoff strategy (default: 'exponential') */
  backoff?: 'exponential' | 'linear' | 'none'
  /** Status codes to retry on */
  retryOn?: number[]
}

/**
 * Request configuration
 */
export interface RequestConfig {
  /** Request timeout in ms (default: 30000) */
  timeout?: number
  /** Retry configuration or false to disable */
  retry?: RetryConfig | false
  /** Custom headers for all requests */
  headers?: Record<string, string>
}

/**
 * Realtime/WebSocket configuration
 */
export interface RealtimeConfig {
  /** Auto-connect on first subscription (default: false) */
  autoConnect?: boolean
  /** Auto-reconnect on disconnect (default: true) */
  reconnect?: boolean
  /** Initial reconnect delay in ms (default: 1000) */
  reconnectDelay?: number
  /** Maximum reconnect delay in ms (default: 30000) */
  maxReconnectDelay?: number
}

/**
 * Main SwiftBase client configuration
 */
export interface SwiftBaseConfig {
  /** SwiftBase server URL */
  url: string
  /** Authentication configuration */
  auth?: AuthConfig
  /** Request configuration */
  request?: RequestConfig
  /** Realtime configuration */
  realtime?: RealtimeConfig
}

/**
 * Default configuration values
 */
export const DEFAULT_CONFIG: Required<Omit<SwiftBaseConfig, 'url'>> = {
  auth: {
    storage: 'memory',
    autoRefresh: true,
    persistSession: true,
  },
  request: {
    timeout: 30000,
    retry: {
      attempts: 3,
      backoff: 'exponential',
    },
    headers: {},
  },
  realtime: {
    autoConnect: false,
    reconnect: true,
    reconnectDelay: 1000,
    maxReconnectDelay: 30000,
  },
}
