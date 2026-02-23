import { describe, it, expect, vi } from 'vitest'
import {
  calculateDelay,
  shouldRetry,
  sleep,
  withRetry,
  DEFAULT_RETRY_CONFIG,
} from '../../src/core/retry'
import { NetworkError } from '../../src/core/errors'

describe('calculateDelay', () => {
  it('should calculate exponential backoff', () => {
    const config = { ...DEFAULT_RETRY_CONFIG, backoff: 'exponential' as const, baseDelay: 1000 }

    // Attempt 0: 1000 * 2^0 = 1000ms (±10% jitter)
    const delay0 = calculateDelay(0, config)
    expect(delay0).toBeGreaterThanOrEqual(900)
    expect(delay0).toBeLessThanOrEqual(1100)

    // Attempt 1: 1000 * 2^1 = 2000ms (±10% jitter)
    const delay1 = calculateDelay(1, config)
    expect(delay1).toBeGreaterThanOrEqual(1800)
    expect(delay1).toBeLessThanOrEqual(2200)

    // Attempt 2: 1000 * 2^2 = 4000ms (±10% jitter)
    const delay2 = calculateDelay(2, config)
    expect(delay2).toBeGreaterThanOrEqual(3600)
    expect(delay2).toBeLessThanOrEqual(4400)
  })

  it('should calculate linear backoff', () => {
    const config = { ...DEFAULT_RETRY_CONFIG, backoff: 'linear' as const, baseDelay: 1000 }

    // Attempt 0: 1000 * 1 = 1000ms
    const delay0 = calculateDelay(0, config)
    expect(delay0).toBeGreaterThanOrEqual(900)
    expect(delay0).toBeLessThanOrEqual(1100)

    // Attempt 1: 1000 * 2 = 2000ms
    const delay1 = calculateDelay(1, config)
    expect(delay1).toBeGreaterThanOrEqual(1800)
    expect(delay1).toBeLessThanOrEqual(2200)
  })

  it('should use constant delay with none backoff', () => {
    const config = { ...DEFAULT_RETRY_CONFIG, backoff: 'none' as const, baseDelay: 1000 }

    const delay0 = calculateDelay(0, config)
    const delay1 = calculateDelay(1, config)
    const delay2 = calculateDelay(2, config)

    // All should be around 1000ms (±10% jitter)
    expect(delay0).toBeGreaterThanOrEqual(900)
    expect(delay0).toBeLessThanOrEqual(1100)
    expect(delay1).toBeGreaterThanOrEqual(900)
    expect(delay1).toBeLessThanOrEqual(1100)
    expect(delay2).toBeGreaterThanOrEqual(900)
    expect(delay2).toBeLessThanOrEqual(1100)
  })

  it('should respect maxDelay', () => {
    const config = { ...DEFAULT_RETRY_CONFIG, backoff: 'exponential' as const, baseDelay: 10000, maxDelay: 5000 }

    const delay = calculateDelay(5, config)
    expect(delay).toBeLessThanOrEqual(5500) // maxDelay + jitter
  })
})

describe('shouldRetry', () => {
  it('should retry on configured status codes', () => {
    const config = DEFAULT_RETRY_CONFIG

    expect(shouldRetry(500, undefined, config)).toBe(true)
    expect(shouldRetry(502, undefined, config)).toBe(true)
    expect(shouldRetry(503, undefined, config)).toBe(true)
    expect(shouldRetry(504, undefined, config)).toBe(true)
    expect(shouldRetry(408, undefined, config)).toBe(true)
    expect(shouldRetry(429, undefined, config)).toBe(true)
  })

  it('should not retry on non-configured status codes', () => {
    const config = DEFAULT_RETRY_CONFIG

    expect(shouldRetry(400, undefined, config)).toBe(false)
    expect(shouldRetry(401, undefined, config)).toBe(false)
    expect(shouldRetry(403, undefined, config)).toBe(false)
    expect(shouldRetry(404, undefined, config)).toBe(false)
  })

  it('should retry on NetworkError except ABORTED', () => {
    const config = DEFAULT_RETRY_CONFIG

    expect(shouldRetry(undefined, new NetworkError('timeout', 'TIMEOUT'), config)).toBe(true)
    expect(shouldRetry(undefined, new NetworkError('network', 'NETWORK_ERROR'), config)).toBe(true)
    expect(shouldRetry(undefined, new NetworkError('refused', 'CONNECTION_REFUSED'), config)).toBe(true)
  })

  it('should not retry on ABORTED NetworkError', () => {
    const config = DEFAULT_RETRY_CONFIG

    expect(shouldRetry(undefined, new NetworkError('aborted', 'ABORTED'), config)).toBe(false)
  })

  it('should not retry when status is undefined and no error', () => {
    const config = DEFAULT_RETRY_CONFIG

    expect(shouldRetry(undefined, undefined, config)).toBe(false)
  })
})

describe('sleep', () => {
  it('should sleep for specified duration', async () => {
    const start = Date.now()
    await sleep(50)
    const elapsed = Date.now() - start

    expect(elapsed).toBeGreaterThanOrEqual(45)
    expect(elapsed).toBeLessThan(100)
  })
})

describe('withRetry', () => {
  it('should return result on success', async () => {
    const fn = vi.fn().mockResolvedValue('success')

    const result = await withRetry(fn, { attempts: 3 })

    expect(result).toBe('success')
    expect(fn).toHaveBeenCalledTimes(1)
  })

  it('should retry on failure and succeed', async () => {
    const fn = vi.fn()
      .mockRejectedValueOnce({ status: 500 })
      .mockRejectedValueOnce({ status: 503 })
      .mockResolvedValue('success')

    const result = await withRetry(fn, { attempts: 3, baseDelay: 10 })

    expect(result).toBe('success')
    expect(fn).toHaveBeenCalledTimes(3)
  })

  it('should throw after max attempts', async () => {
    const error = { status: 500, message: 'Server error' }
    const fn = vi.fn().mockRejectedValue(error)

    await expect(withRetry(fn, { attempts: 2, baseDelay: 10 })).rejects.toEqual(error)
    expect(fn).toHaveBeenCalledTimes(3) // initial + 2 retries
  })

  it('should not retry non-retryable errors', async () => {
    const error = { status: 400, message: 'Bad request' }
    const fn = vi.fn().mockRejectedValue(error)

    await expect(withRetry(fn, { attempts: 3, baseDelay: 10 })).rejects.toEqual(error)
    expect(fn).toHaveBeenCalledTimes(1) // no retries
  })

  it('should retry NetworkError', async () => {
    const fn = vi.fn()
      .mockRejectedValueOnce(new NetworkError('timeout', 'TIMEOUT'))
      .mockResolvedValue('success')

    const result = await withRetry(fn, { attempts: 3, baseDelay: 10 })

    expect(result).toBe('success')
    expect(fn).toHaveBeenCalledTimes(2)
  })
})
