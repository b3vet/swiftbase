import { NetworkError } from './errors.js'

/**
 * Retry configuration
 */
export interface RetryConfig {
  /** Number of retry attempts (default: 3) */
  attempts: number
  /** Backoff strategy */
  backoff: 'exponential' | 'linear' | 'none'
  /** Base delay in ms (default: 1000) */
  baseDelay: number
  /** Maximum delay in ms (default: 30000) */
  maxDelay: number
  /** Status codes to retry on (default: [408, 429, 500, 502, 503, 504]) */
  retryOn: number[]
}

/**
 * Default retry configuration
 */
export const DEFAULT_RETRY_CONFIG: RetryConfig = {
  attempts: 3,
  backoff: 'exponential',
  baseDelay: 1000,
  maxDelay: 30000,
  retryOn: [408, 429, 500, 502, 503, 504],
}

/**
 * Calculate delay based on backoff strategy
 */
export function calculateDelay(
  attempt: number,
  config: RetryConfig
): number {
  let delay: number

  switch (config.backoff) {
    case 'exponential':
      delay = config.baseDelay * Math.pow(2, attempt)
      break
    case 'linear':
      delay = config.baseDelay * (attempt + 1)
      break
    case 'none':
      delay = config.baseDelay
      break
    default:
      delay = config.baseDelay
  }

  // Add jitter (±10% randomization)
  const jitter = delay * 0.1 * (Math.random() * 2 - 1)
  delay = delay + jitter

  return Math.min(delay, config.maxDelay)
}

/**
 * Check if the error/status should trigger a retry
 */
export function shouldRetry(
  status: number | undefined,
  error: Error | undefined,
  config: RetryConfig
): boolean {
  // Retry on network errors
  if (error instanceof NetworkError) {
    return error.code !== 'ABORTED'
  }

  // Retry on configured status codes
  if (status !== undefined) {
    return config.retryOn.includes(status)
  }

  return false
}

/**
 * Sleep for specified milliseconds
 */
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

/**
 * Execute a function with retry logic
 */
export async function withRetry<T>(
  fn: () => Promise<T>,
  config: Partial<RetryConfig> = {}
): Promise<T> {
  const fullConfig: RetryConfig = { ...DEFAULT_RETRY_CONFIG, ...config }
  let lastError: Error | undefined
  let lastStatus: number | undefined

  for (let attempt = 0; attempt <= fullConfig.attempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error as Error

      // Extract status from error if available
      if (error && typeof error === 'object' && 'status' in error) {
        lastStatus = (error as { status: number }).status
      }

      // Check if we should retry
      const isLastAttempt = attempt === fullConfig.attempts
      if (isLastAttempt || !shouldRetry(lastStatus, lastError, fullConfig)) {
        throw error
      }

      // Wait before retrying
      const delay = calculateDelay(attempt, fullConfig)
      await sleep(delay)
    }
  }

  // Should never reach here, but TypeScript needs this
  throw lastError ?? new Error('Retry failed')
}
