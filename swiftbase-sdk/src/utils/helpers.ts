/**
 * Deep merge two objects
 */
export function deepMerge<T extends Record<string, unknown>>(
  target: T,
  source: Partial<T>
): T {
  const result = { ...target }

  for (const key of Object.keys(source) as Array<keyof T>) {
    const sourceValue = source[key]
    const targetValue = target[key]

    if (
      sourceValue !== undefined &&
      typeof sourceValue === 'object' &&
      sourceValue !== null &&
      !Array.isArray(sourceValue) &&
      typeof targetValue === 'object' &&
      targetValue !== null &&
      !Array.isArray(targetValue)
    ) {
      result[key] = deepMerge(
        targetValue as Record<string, unknown>,
        sourceValue as Record<string, unknown>
      ) as T[keyof T]
    } else if (sourceValue !== undefined) {
      result[key] = sourceValue as T[keyof T]
    }
  }

  return result
}

/**
 * Check if running in browser environment
 */
export function isBrowser(): boolean {
  return typeof window !== 'undefined' && typeof window.document !== 'undefined'
}

/**
 * Check if running in Node.js environment
 */
export function isNode(): boolean {
  return typeof process !== 'undefined' && process.versions?.node !== undefined
}

/**
 * Decode JWT payload without verification
 */
export function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.')
    if (parts.length !== 3) {
      return null
    }

    const payload = parts[1]
    if (!payload) {
      return null
    }

    // Handle base64url encoding
    const base64 = payload.replace(/-/g, '+').replace(/_/g, '/')
    const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4)

    let decoded: string
    if (typeof atob !== 'undefined') {
      decoded = atob(padded)
    } else if (typeof Buffer !== 'undefined') {
      decoded = Buffer.from(padded, 'base64').toString('utf8')
    } else {
      return null
    }

    return JSON.parse(decoded) as Record<string, unknown>
  } catch {
    return null
  }
}

/**
 * Check if JWT token is expired
 */
export function isTokenExpired(token: string, bufferSeconds: number = 30): boolean {
  const payload = decodeJwtPayload(token)
  if (!payload || typeof payload.exp !== 'number') {
    return true
  }

  const now = Math.floor(Date.now() / 1000)
  return payload.exp - bufferSeconds <= now
}

/**
 * Generate a unique ID
 */
export function generateId(): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID()
  }

  // Fallback for older environments
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}
