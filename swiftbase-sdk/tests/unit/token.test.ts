import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { TokenManager } from '../../src/modules/auth/token'
import { MemoryStorage } from '../../src/modules/auth/storage'
import type { Session } from '../../src/types/auth'

// Helper to create a valid JWT token
function createMockToken(expiresInSeconds: number = 3600): string {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
  const payload = btoa(JSON.stringify({
    sub: 'user_123',
    exp: Math.floor(Date.now() / 1000) + expiresInSeconds,
  }))
  const signature = btoa('fake-signature')
  return `${header}.${payload}.${signature}`
}

function createMockSession(expiresInSeconds: number = 3600): Session {
  return {
    accessToken: createMockToken(expiresInSeconds),
    refreshToken: 'refresh_token_123',
    expiresAt: Date.now() + expiresInSeconds * 1000,
  }
}

describe('TokenManager', () => {
  let storage: MemoryStorage
  let tokenManager: TokenManager

  beforeEach(() => {
    storage = new MemoryStorage()
    tokenManager = new TokenManager(storage)
  })

  afterEach(() => {
    tokenManager.stopRefreshTimer()
  })

  describe('initialize', () => {
    it('should return null when no stored session', async () => {
      const session = await tokenManager.initialize()
      expect(session).toBeNull()
    })

    it('should load valid session from storage', async () => {
      const mockSession = createMockSession()
      storage.set('swiftbase_session', JSON.stringify(mockSession))

      const session = await tokenManager.initialize()

      expect(session).not.toBeNull()
      expect(session?.accessToken).toBe(mockSession.accessToken)
    })

    it('should clear expired session from storage', async () => {
      const expiredSession = createMockSession(-100) // Expired
      storage.set('swiftbase_session', JSON.stringify(expiredSession))

      const session = await tokenManager.initialize()

      expect(session).toBeNull()
      expect(storage.get('swiftbase_session')).toBeNull()
    })

    it('should clear invalid JSON from storage', async () => {
      storage.set('swiftbase_session', 'invalid json')

      const session = await tokenManager.initialize()

      expect(session).toBeNull()
      expect(storage.get('swiftbase_session')).toBeNull()
    })
  })

  describe('getSession', () => {
    it('should return null when no session', () => {
      expect(tokenManager.getSession()).toBeNull()
    })

    it('should return session after setSession', async () => {
      const mockSession = createMockSession()
      await tokenManager.setSession(mockSession)

      expect(tokenManager.getSession()).toEqual(mockSession)
    })
  })

  describe('getAccessToken', () => {
    it('should return null when no session', () => {
      expect(tokenManager.getAccessToken()).toBeNull()
    })

    it('should return access token from session', async () => {
      const mockSession = createMockSession()
      await tokenManager.setSession(mockSession)

      expect(tokenManager.getAccessToken()).toBe(mockSession.accessToken)
    })
  })

  describe('getRefreshToken', () => {
    it('should return null when no session', () => {
      expect(tokenManager.getRefreshToken()).toBeNull()
    })

    it('should return refresh token from session', async () => {
      const mockSession = createMockSession()
      await tokenManager.setSession(mockSession)

      expect(tokenManager.getRefreshToken()).toBe(mockSession.refreshToken)
    })
  })

  describe('setSession', () => {
    it('should store session in memory and storage', async () => {
      const mockSession = createMockSession()
      await tokenManager.setSession(mockSession)

      expect(tokenManager.getSession()).toEqual(mockSession)
      expect(storage.get('swiftbase_session')).toBe(JSON.stringify(mockSession))
    })

    it('should not persist when persist is false', async () => {
      const mockSession = createMockSession()
      await tokenManager.setSession(mockSession, false)

      expect(tokenManager.getSession()).toEqual(mockSession)
      expect(storage.get('swiftbase_session')).toBeNull()
    })
  })

  describe('updateTokens', () => {
    it('should update tokens in existing session', async () => {
      const mockSession = createMockSession()
      await tokenManager.setSession(mockSession)

      const newAccessToken = createMockToken(7200)
      const newRefreshToken = 'new_refresh_token'
      const newExpiresAt = Date.now() + 7200000

      await tokenManager.updateTokens(newAccessToken, newRefreshToken, newExpiresAt)

      const session = tokenManager.getSession()
      expect(session?.accessToken).toBe(newAccessToken)
      expect(session?.refreshToken).toBe(newRefreshToken)
      expect(session?.expiresAt).toBe(newExpiresAt)
    })

    it('should not update when no session exists', async () => {
      await tokenManager.updateTokens('token', 'refresh', Date.now())
      expect(tokenManager.getSession()).toBeNull()
    })
  })

  describe('clear', () => {
    it('should clear session from memory and storage', async () => {
      const mockSession = createMockSession()
      await tokenManager.setSession(mockSession)

      await tokenManager.clear()

      expect(tokenManager.getSession()).toBeNull()
      expect(storage.get('swiftbase_session')).toBeNull()
    })
  })

  describe('isSessionExpired', () => {
    it('should return true when no session', () => {
      expect(tokenManager.isSessionExpired()).toBe(true)
    })

    it('should return false for valid session', async () => {
      const mockSession = createMockSession(3600)
      await tokenManager.setSession(mockSession)

      expect(tokenManager.isSessionExpired()).toBe(false)
    })

    it('should return true for expired session', async () => {
      const mockSession = createMockSession(-100)
      await tokenManager.setSession(mockSession, false)

      expect(tokenManager.isSessionExpired()).toBe(true)
    })

    it('should check provided session instead of current', () => {
      const validSession = createMockSession(3600)
      const expiredSession = createMockSession(-100)

      expect(tokenManager.isSessionExpired(validSession)).toBe(false)
      expect(tokenManager.isSessionExpired(expiredSession)).toBe(true)
    })
  })

  describe('needsRefresh', () => {
    it('should return false when no session', () => {
      expect(tokenManager.needsRefresh()).toBe(false)
    })

    it('should return true when token expires within buffer', async () => {
      const mockSession = createMockSession(30) // Expires in 30 seconds
      await tokenManager.setSession(mockSession)

      expect(tokenManager.needsRefresh(60)).toBe(true) // Buffer is 60 seconds
    })

    it('should return false when token expires after buffer', async () => {
      const mockSession = createMockSession(3600) // Expires in 1 hour
      await tokenManager.setSession(mockSession)

      expect(tokenManager.needsRefresh(60)).toBe(false)
    })
  })

  describe('getTimeUntilExpiry', () => {
    it('should return 0 when no session', () => {
      expect(tokenManager.getTimeUntilExpiry()).toBe(0)
    })

    it('should return time until expiry in milliseconds', async () => {
      const mockSession = createMockSession(3600) // Expires in 1 hour
      await tokenManager.setSession(mockSession)

      const timeUntilExpiry = tokenManager.getTimeUntilExpiry()

      // Should be approximately 3600000ms (1 hour), allow 5 second tolerance
      expect(timeUntilExpiry).toBeGreaterThan(3595000)
      expect(timeUntilExpiry).toBeLessThanOrEqual(3600000)
    })

    it('should return 0 for expired token', async () => {
      const mockSession = createMockSession(-100)
      await tokenManager.setSession(mockSession, false)

      expect(tokenManager.getTimeUntilExpiry()).toBe(0)
    })
  })

  describe('refresh timer', () => {
    it('should start and stop refresh timer', async () => {
      vi.useFakeTimers()

      const mockSession = createMockSession(120) // Expires in 2 minutes
      await tokenManager.setSession(mockSession)

      const onRefresh = vi.fn().mockResolvedValue(undefined)
      tokenManager.startRefreshTimer(onRefresh, 60000) // Refresh 1 minute before expiry

      // Fast forward 1 minute (should trigger refresh)
      await vi.advanceTimersByTimeAsync(60000)

      expect(onRefresh).toHaveBeenCalled()

      tokenManager.stopRefreshTimer()
      vi.useRealTimers()
    })

    it('should not start timer for expired token', async () => {
      const mockSession = createMockSession(-100)
      await tokenManager.setSession(mockSession, false)

      const onRefresh = vi.fn()
      tokenManager.startRefreshTimer(onRefresh, 60000)

      // Timer should not be set for expired tokens
      expect(onRefresh).not.toHaveBeenCalled()
    })
  })
})
