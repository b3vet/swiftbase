import type { StorageAdapter } from '../../types/auth.js'
import { isBrowser } from '../../utils/helpers.js'

/**
 * Memory storage adapter - works in all environments
 * Data is lost on page refresh/process restart
 */
export class MemoryStorage implements StorageAdapter {
  private store: Map<string, string> = new Map()

  get(key: string): string | null {
    return this.store.get(key) ?? null
  }

  set(key: string, value: string): void {
    this.store.set(key, value)
  }

  remove(key: string): void {
    this.store.delete(key)
  }

  clear(): void {
    this.store.clear()
  }
}

/**
 * LocalStorage adapter - browser only, persists across sessions
 */
export class LocalStorageAdapter implements StorageAdapter {
  get(key: string): string | null {
    if (!isBrowser()) return null
    try {
      return localStorage.getItem(key)
    } catch {
      return null
    }
  }

  set(key: string, value: string): void {
    if (!isBrowser()) return
    try {
      localStorage.setItem(key, value)
    } catch {
      // Storage might be full or disabled
    }
  }

  remove(key: string): void {
    if (!isBrowser()) return
    try {
      localStorage.removeItem(key)
    } catch {
      // Ignore errors
    }
  }
}

/**
 * SessionStorage adapter - browser only, cleared when tab closes
 */
export class SessionStorageAdapter implements StorageAdapter {
  get(key: string): string | null {
    if (!isBrowser()) return null
    try {
      return sessionStorage.getItem(key)
    } catch {
      return null
    }
  }

  set(key: string, value: string): void {
    if (!isBrowser()) return
    try {
      sessionStorage.setItem(key, value)
    } catch {
      // Storage might be full or disabled
    }
  }

  remove(key: string): void {
    if (!isBrowser()) return
    try {
      sessionStorage.removeItem(key)
    } catch {
      // Ignore errors
    }
  }
}

/**
 * Create a storage adapter based on configuration
 */
export function createStorageAdapter(
  storage: 'localStorage' | 'sessionStorage' | 'memory' | StorageAdapter
): StorageAdapter {
  if (typeof storage === 'object') {
    return storage
  }

  switch (storage) {
    case 'localStorage':
      return new LocalStorageAdapter()
    case 'sessionStorage':
      return new SessionStorageAdapter()
    case 'memory':
    default:
      return new MemoryStorage()
  }
}
