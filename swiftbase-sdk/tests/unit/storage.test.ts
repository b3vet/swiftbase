import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  MemoryStorage,
  LocalStorageAdapter,
  SessionStorageAdapter,
  createStorageAdapter,
} from '../../src/modules/auth/storage'

describe('MemoryStorage', () => {
  let storage: MemoryStorage

  beforeEach(() => {
    storage = new MemoryStorage()
  })

  it('should store and retrieve values', () => {
    storage.set('key1', 'value1')
    expect(storage.get('key1')).toBe('value1')
  })

  it('should return null for non-existent keys', () => {
    expect(storage.get('nonexistent')).toBeNull()
  })

  it('should overwrite existing values', () => {
    storage.set('key', 'value1')
    storage.set('key', 'value2')
    expect(storage.get('key')).toBe('value2')
  })

  it('should remove values', () => {
    storage.set('key', 'value')
    storage.remove('key')
    expect(storage.get('key')).toBeNull()
  })

  it('should handle removing non-existent keys', () => {
    // Should not throw
    storage.remove('nonexistent')
  })

  it('should clear all values', () => {
    storage.set('key1', 'value1')
    storage.set('key2', 'value2')
    storage.set('key3', 'value3')

    storage.clear()

    expect(storage.get('key1')).toBeNull()
    expect(storage.get('key2')).toBeNull()
    expect(storage.get('key3')).toBeNull()
  })
})

describe('LocalStorageAdapter', () => {
  let adapter: LocalStorageAdapter
  let mockLocalStorage: { [key: string]: string }

  beforeEach(() => {
    adapter = new LocalStorageAdapter()
    mockLocalStorage = {}

    // Mock localStorage in Node environment
    vi.stubGlobal('window', {
      document: {},
    })
    vi.stubGlobal('localStorage', {
      getItem: vi.fn((key: string) => mockLocalStorage[key] ?? null),
      setItem: vi.fn((key: string, value: string) => { mockLocalStorage[key] = value }),
      removeItem: vi.fn((key: string) => { delete mockLocalStorage[key] }),
    })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('should store and retrieve values', () => {
    adapter.set('key', 'value')
    expect(localStorage.setItem).toHaveBeenCalledWith('key', 'value')

    mockLocalStorage['key'] = 'value'
    expect(adapter.get('key')).toBe('value')
  })

  it('should return null for non-existent keys', () => {
    expect(adapter.get('nonexistent')).toBeNull()
  })

  it('should remove values', () => {
    adapter.remove('key')
    expect(localStorage.removeItem).toHaveBeenCalledWith('key')
  })
})

describe('SessionStorageAdapter', () => {
  let adapter: SessionStorageAdapter
  let mockSessionStorage: { [key: string]: string }

  beforeEach(() => {
    adapter = new SessionStorageAdapter()
    mockSessionStorage = {}

    // Mock sessionStorage in Node environment
    vi.stubGlobal('window', {
      document: {},
    })
    vi.stubGlobal('sessionStorage', {
      getItem: vi.fn((key: string) => mockSessionStorage[key] ?? null),
      setItem: vi.fn((key: string, value: string) => { mockSessionStorage[key] = value }),
      removeItem: vi.fn((key: string) => { delete mockSessionStorage[key] }),
    })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('should store and retrieve values', () => {
    adapter.set('key', 'value')
    expect(sessionStorage.setItem).toHaveBeenCalledWith('key', 'value')

    mockSessionStorage['key'] = 'value'
    expect(adapter.get('key')).toBe('value')
  })

  it('should return null for non-existent keys', () => {
    expect(adapter.get('nonexistent')).toBeNull()
  })

  it('should remove values', () => {
    adapter.remove('key')
    expect(sessionStorage.removeItem).toHaveBeenCalledWith('key')
  })
})

describe('createStorageAdapter', () => {
  beforeEach(() => {
    vi.stubGlobal('window', { document: {} })
    vi.stubGlobal('localStorage', {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
    })
    vi.stubGlobal('sessionStorage', {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
    })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('should create MemoryStorage for "memory"', () => {
    const adapter = createStorageAdapter('memory')
    expect(adapter).toBeInstanceOf(MemoryStorage)
  })

  it('should create LocalStorageAdapter for "localStorage"', () => {
    const adapter = createStorageAdapter('localStorage')
    expect(adapter).toBeInstanceOf(LocalStorageAdapter)
  })

  it('should create SessionStorageAdapter for "sessionStorage"', () => {
    const adapter = createStorageAdapter('sessionStorage')
    expect(adapter).toBeInstanceOf(SessionStorageAdapter)
  })

  it('should return custom adapter when passed as object', () => {
    const customAdapter = {
      get: vi.fn(),
      set: vi.fn(),
      remove: vi.fn(),
    }

    const adapter = createStorageAdapter(customAdapter)
    expect(adapter).toBe(customAdapter)
  })
})
