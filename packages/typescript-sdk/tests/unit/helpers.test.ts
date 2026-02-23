import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  deepMerge,
  isBrowser,
  isNode,
  decodeJwtPayload,
  isTokenExpired,
  generateId,
} from '../../src/utils/helpers'

describe('deepMerge', () => {
  it('should merge simple objects', () => {
    const target = { a: 1, b: 2 }
    const source = { b: 3, c: 4 }

    const result = deepMerge(target, source)

    expect(result).toEqual({ a: 1, b: 3, c: 4 })
  })

  it('should deep merge nested objects', () => {
    const target = {
      level1: {
        level2: {
          a: 1,
          b: 2,
        },
      },
    }
    const source = {
      level1: {
        level2: {
          b: 3,
          c: 4,
        },
      },
    }

    const result = deepMerge(target, source)

    expect(result).toEqual({
      level1: {
        level2: {
          a: 1,
          b: 3,
          c: 4,
        },
      },
    })
  })

  it('should not modify original objects', () => {
    const target = { a: 1 }
    const source = { b: 2 }

    deepMerge(target, source)

    expect(target).toEqual({ a: 1 })
    expect(source).toEqual({ b: 2 })
  })

  it('should handle arrays by replacement', () => {
    const target = { arr: [1, 2, 3] }
    const source = { arr: [4, 5] }

    const result = deepMerge(target, source)

    expect(result.arr).toEqual([4, 5])
  })

  it('should handle undefined values in source', () => {
    const target = { a: 1, b: 2 }
    const source = { a: undefined, c: 3 }

    const result = deepMerge(target, source as any)

    expect(result).toEqual({ a: 1, b: 2, c: 3 })
  })

  it('should handle null values', () => {
    const target = { a: { nested: 1 } }
    const source = { a: null }

    const result = deepMerge(target, source as any)

    expect(result.a).toBeNull()
  })
})

describe('isBrowser', () => {
  it('should return false in node environment', () => {
    expect(isBrowser()).toBe(false)
  })
})

describe('isNode', () => {
  it('should return true in node environment', () => {
    expect(isNode()).toBe(true)
  })
})

describe('decodeJwtPayload', () => {
  // Helper to create a JWT token
  function createToken(payload: object): string {
    const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
    const payloadStr = btoa(JSON.stringify(payload))
    const signature = btoa('fake-signature')
    return `${header}.${payloadStr}.${signature}`
  }

  it('should decode valid JWT payload', () => {
    const token = createToken({ sub: 'user123', exp: 1234567890 })

    const payload = decodeJwtPayload(token)

    expect(payload).toEqual({ sub: 'user123', exp: 1234567890 })
  })

  it('should return null for invalid token format', () => {
    expect(decodeJwtPayload('invalid')).toBeNull()
    expect(decodeJwtPayload('only.two')).toBeNull()
    expect(decodeJwtPayload('')).toBeNull()
  })

  it('should return null for invalid base64', () => {
    const result = decodeJwtPayload('header.!!!invalid!!!.signature')
    expect(result).toBeNull()
  })

  it('should handle base64url encoding', () => {
    // JWT uses base64url which replaces + with - and / with _
    const payload = { data: 'test+value/here' }
    const token = createToken(payload)

    const decoded = decodeJwtPayload(token)

    expect(decoded).toEqual(payload)
  })
})

describe('isTokenExpired', () => {
  function createToken(expiresInSeconds: number): string {
    const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
    const payload = btoa(JSON.stringify({
      sub: 'user123',
      exp: Math.floor(Date.now() / 1000) + expiresInSeconds,
    }))
    const signature = btoa('fake-signature')
    return `${header}.${payload}.${signature}`
  }

  it('should return false for valid non-expired token', () => {
    const token = createToken(3600) // Expires in 1 hour

    expect(isTokenExpired(token)).toBe(false)
  })

  it('should return true for expired token', () => {
    const token = createToken(-100) // Expired 100 seconds ago

    expect(isTokenExpired(token)).toBe(true)
  })

  it('should return true when token expires within buffer', () => {
    const token = createToken(20) // Expires in 20 seconds

    expect(isTokenExpired(token, 30)).toBe(true) // Buffer is 30 seconds
  })

  it('should return false when token expires after buffer', () => {
    const token = createToken(60) // Expires in 60 seconds

    expect(isTokenExpired(token, 30)).toBe(false) // Buffer is 30 seconds
  })

  it('should return true for invalid token', () => {
    expect(isTokenExpired('invalid')).toBe(true)
  })

  it('should return true for token without exp claim', () => {
    const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
    const payload = btoa(JSON.stringify({ sub: 'user123' })) // No exp
    const token = `${header}.${payload}.signature`

    expect(isTokenExpired(token)).toBe(true)
  })
})

describe('generateId', () => {
  it('should generate unique IDs', () => {
    const id1 = generateId()
    const id2 = generateId()
    const id3 = generateId()

    expect(id1).not.toBe(id2)
    expect(id2).not.toBe(id3)
    expect(id1).not.toBe(id3)
  })

  it('should generate UUID-like format', () => {
    const id = generateId()

    // UUID format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i)
  })
})
