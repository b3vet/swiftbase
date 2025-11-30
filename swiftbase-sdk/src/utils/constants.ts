/**
 * API endpoints
 */
export const API_ENDPOINTS = {
  // Auth
  AUTH_REGISTER: '/api/auth/register',
  AUTH_LOGIN: '/api/auth/login',
  AUTH_LOGOUT: '/api/auth/logout',
  AUTH_REFRESH: '/api/auth/refresh',
  AUTH_ME: '/api/auth/me',

  // Admin Auth
  ADMIN_LOGIN: '/api/admin/login',
  ADMIN_ME: '/api/admin/me',

  // Query
  QUERY: '/api/query',

  // Collections
  COLLECTIONS: '/api/admin/collections',

  // Storage
  STORAGE_UPLOAD: '/api/storage/upload',
  STORAGE_FILES: '/api/storage/files',

  // Realtime
  REALTIME: '/api/realtime',
} as const

/**
 * Storage keys
 */
export const STORAGE_KEYS = {
  SESSION: 'swiftbase_session',
  USER: 'swiftbase_user',
} as const

/**
 * Default timeouts
 */
export const TIMEOUTS = {
  DEFAULT: 30000,
  UPLOAD: 120000,
  REALTIME_RECONNECT: 1000,
  REALTIME_MAX_RECONNECT: 30000,
} as const
