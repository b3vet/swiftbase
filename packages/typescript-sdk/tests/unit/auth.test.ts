import { describe, it, expect, vi, beforeEach, afterEach, type Mock } from 'vitest'
import { Auth } from '../../src/modules/auth/auth'
import { MemoryStorage } from '../../src/modules/auth/storage'
import { HttpClient } from '../../src/core/http'
import type { AuthResponse, AdminAuthResponse } from '../../src/types/auth'

// Mock HTTP client
function createMockHttpClient() {
  return {
    post: vi.fn(),
    get: vi.fn(),
    setAuthHeader: vi.fn(),
  } as unknown as HttpClient
}

// Create a valid JWT token for testing (expires in 1 hour)
function createMockToken(expiresInSeconds: number = 3600): string {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
  const payload = btoa(JSON.stringify({
    sub: 'user_123',
    exp: Math.floor(Date.now() / 1000) + expiresInSeconds,
  }))
  const signature = btoa('fake-signature')
  return `${header}.${payload}.${signature}`
}

describe('Auth', () => {
  let auth: Auth
  let mockHttp: ReturnType<typeof createMockHttpClient>

  beforeEach(() => {
    mockHttp = createMockHttpClient()
    auth = new Auth(mockHttp, {
      storage: 'memory',
      autoRefresh: false,
      persistSession: true,
    })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('register', () => {
    it('should register a new user', async () => {
      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: false,
          metadata: {},
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)

      const result = await auth.register({
        email: 'test@example.com',
        password: 'password123',
      })

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/auth/register',
        { email: 'test@example.com', password: 'password123' }
      )
      expect(result.user.email).toBe('test@example.com')
      expect(mockHttp.setAuthHeader).toHaveBeenCalledWith(mockResponse.session.accessToken)
    })
  })

  describe('login', () => {
    it('should login a user', async () => {
      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: true,
          metadata: { name: 'Test User' },
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)

      const result = await auth.login({
        email: 'test@example.com',
        password: 'password123',
      })

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/auth/login',
        { email: 'test@example.com', password: 'password123' }
      )
      expect(result.user.id).toBe('user_123')
      expect(auth.getSession()).not.toBeNull()
    })
  })

  describe('logout', () => {
    it('should logout and clear session', async () => {
      // First login
      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: true,
          metadata: {},
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)
      await auth.login({ email: 'test@example.com', password: 'password123' })

      // Then logout
      ;(mockHttp.post as Mock).mockResolvedValueOnce({})
      await auth.logout()

      expect(auth.getSession()).toBeNull()
      expect(mockHttp.setAuthHeader).toHaveBeenLastCalledWith(null)
    })
  })

  describe('getSession', () => {
    it('should return null when not logged in', () => {
      expect(auth.getSession()).toBeNull()
    })

    it('should return session after login', async () => {
      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: true,
          metadata: {},
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)
      await auth.login({ email: 'test@example.com', password: 'password123' })

      const session = auth.getSession()
      expect(session).not.toBeNull()
      expect(session?.accessToken).toBe(mockResponse.session.accessToken)
    })
  })

  describe('isAuthenticated', () => {
    it('should return false when not logged in', () => {
      expect(auth.isAuthenticated()).toBe(false)
    })

    it('should return true after login', async () => {
      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: true,
          metadata: {},
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)
      await auth.login({ email: 'test@example.com', password: 'password123' })

      expect(auth.isAuthenticated()).toBe(true)
    })
  })

  describe('onAuthStateChange', () => {
    it('should call listener on login', async () => {
      const listener = vi.fn()
      auth.onAuthStateChange(listener)

      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: true,
          metadata: {},
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)
      await auth.login({ email: 'test@example.com', password: 'password123' })

      expect(listener).toHaveBeenCalledWith('SIGNED_IN', expect.any(Object))
    })

    it('should call listener on logout', async () => {
      const listener = vi.fn()
      auth.onAuthStateChange(listener)

      // Login first
      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: true,
          metadata: {},
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)
      await auth.login({ email: 'test@example.com', password: 'password123' })

      // Logout
      ;(mockHttp.post as Mock).mockResolvedValueOnce({})
      await auth.logout()

      expect(listener).toHaveBeenCalledWith('SIGNED_OUT', null)
    })

    it('should unsubscribe when calling returned function', async () => {
      const listener = vi.fn()
      const unsubscribe = auth.onAuthStateChange(listener)

      unsubscribe()

      const mockResponse: AuthResponse = {
        user: {
          id: 'user_123',
          email: 'test@example.com',
          emailVerified: true,
          metadata: {},
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)
      await auth.login({ email: 'test@example.com', password: 'password123' })

      expect(listener).not.toHaveBeenCalled()
    })
  })

  describe('admin', () => {
    it('should login as admin', async () => {
      const mockResponse: AdminAuthResponse = {
        admin: {
          id: 'admin_123',
          username: 'admin',
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
        session: {
          accessToken: createMockToken(),
          refreshToken: 'refresh_token',
          expiresAt: Date.now() + 3600000,
        },
      }

      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)

      const result = await auth.admin.login({
        username: 'admin',
        password: 'admin123',
      })

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/admin/login',
        { username: 'admin', password: 'admin123' }
      )
      expect(result.admin.username).toBe('admin')
    })
  })
})

describe('MemoryStorage', () => {
  let storage: MemoryStorage

  beforeEach(() => {
    storage = new MemoryStorage()
  })

  it('should store and retrieve values', () => {
    storage.set('key', 'value')
    expect(storage.get('key')).toBe('value')
  })

  it('should return null for missing keys', () => {
    expect(storage.get('missing')).toBeNull()
  })

  it('should remove values', () => {
    storage.set('key', 'value')
    storage.remove('key')
    expect(storage.get('key')).toBeNull()
  })

  it('should clear all values', () => {
    storage.set('key1', 'value1')
    storage.set('key2', 'value2')
    storage.clear()
    expect(storage.get('key1')).toBeNull()
    expect(storage.get('key2')).toBeNull()
  })
})
