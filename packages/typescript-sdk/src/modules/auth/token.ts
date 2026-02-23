import type { Session, StorageAdapter } from '../../types/auth.js'
import { STORAGE_KEYS } from '../../utils/constants.js'
import { isTokenExpired, decodeJwtPayload } from '../../utils/helpers.js'

/**
 * Token manager handles storage and retrieval of auth tokens
 */
export class TokenManager {
  private storage: StorageAdapter
  private session: Session | null = null
  private refreshTimer: ReturnType<typeof setTimeout> | null = null

  constructor(storage: StorageAdapter) {
    this.storage = storage
  }

  /**
   * Initialize token manager, loading session from storage
   */
  async initialize(): Promise<Session | null> {
    const stored = await this.storage.get(STORAGE_KEYS.SESSION)
    if (stored) {
      try {
        const session = JSON.parse(stored) as Session
        // Validate session is not expired
        if (!this.isSessionExpired(session)) {
          this.session = session
          return session
        }
        // Clear expired session
        await this.clear()
      } catch {
        // Invalid stored session, clear it
        await this.clear()
      }
    }
    return null
  }

  /**
   * Get current session
   */
  getSession(): Session | null {
    return this.session
  }

  /**
   * Get current access token
   */
  getAccessToken(): string | null {
    return this.session?.accessToken ?? null
  }

  /**
   * Get current refresh token
   */
  getRefreshToken(): string | null {
    return this.session?.refreshToken ?? null
  }

  /**
   * Set new session
   */
  async setSession(session: Session, persist: boolean = true): Promise<void> {
    this.session = session
    if (persist) {
      await this.storage.set(STORAGE_KEYS.SESSION, JSON.stringify(session))
    }
  }

  /**
   * Update session with new tokens
   */
  async updateTokens(
    accessToken: string,
    refreshToken: string,
    expiresAt: number
  ): Promise<void> {
    if (this.session) {
      this.session = {
        ...this.session,
        accessToken,
        refreshToken,
        expiresAt,
      }
      await this.storage.set(STORAGE_KEYS.SESSION, JSON.stringify(this.session))
    }
  }

  /**
   * Clear session
   */
  async clear(): Promise<void> {
    this.session = null
    this.stopRefreshTimer()
    await this.storage.remove(STORAGE_KEYS.SESSION)
  }

  /**
   * Check if session is expired
   */
  isSessionExpired(session?: Session | null): boolean {
    const s = session ?? this.session
    if (!s) return true
    return isTokenExpired(s.accessToken)
  }

  /**
   * Check if token needs refresh (within buffer period)
   */
  needsRefresh(bufferSeconds: number = 60): boolean {
    if (!this.session) return false
    return isTokenExpired(this.session.accessToken, bufferSeconds)
  }

  /**
   * Get time until token expires in milliseconds
   */
  getTimeUntilExpiry(): number {
    if (!this.session) return 0

    const payload = decodeJwtPayload(this.session.accessToken)
    if (!payload || typeof payload.exp !== 'number') return 0

    const now = Math.floor(Date.now() / 1000)
    const remaining = payload.exp - now
    return Math.max(0, remaining * 1000)
  }

  /**
   * Start auto-refresh timer
   */
  startRefreshTimer(onRefresh: () => Promise<void>, bufferMs: number = 60000): void {
    this.stopRefreshTimer()

    const timeUntilExpiry = this.getTimeUntilExpiry()
    if (timeUntilExpiry <= 0) return

    // Refresh before expiry (subtract buffer)
    const refreshIn = Math.max(0, timeUntilExpiry - bufferMs)

    this.refreshTimer = setTimeout(async () => {
      try {
        await onRefresh()
        // Restart timer after successful refresh
        this.startRefreshTimer(onRefresh, bufferMs)
      } catch {
        // Refresh failed, timer will not restart
      }
    }, refreshIn)
  }

  /**
   * Stop auto-refresh timer
   */
  stopRefreshTimer(): void {
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer)
      this.refreshTimer = null
    }
  }
}
