/**
 * Base error class for all SwiftBase SDK errors.
 *
 * All SDK errors extend this class, making it easy to catch any SwiftBase-related
 * error in a single catch block.
 *
 * @example
 * ```typescript
 * import { SwiftBaseError, AuthError, QueryError } from '@swiftbase/sdk'
 *
 * try {
 *   await sb.collection('products').find()
 * } catch (error) {
 *   if (error instanceof AuthError) {
 *     // Handle authentication errors
 *     console.log('Auth error:', error.code)
 *   } else if (error instanceof QueryError) {
 *     // Handle query errors
 *     console.log('Query error:', error.code)
 *   } else if (error instanceof SwiftBaseError) {
 *     // Handle any other SwiftBase error
 *     console.log('Error:', error.message, error.status)
 *   }
 * }
 * ```
 */
export class SwiftBaseError extends Error {
  /** HTTP status code (0 for network errors) */
  public readonly status: number
  /** Error code identifying the type of error */
  public readonly code: string
  /** Additional error details from the server */
  public readonly details?: unknown

  constructor(message: string, status: number, code: string, details?: unknown) {
    super(message)
    this.name = 'SwiftBaseError'
    this.status = status
    this.code = code
    this.details = details
    Object.setPrototypeOf(this, new.target.prototype)
  }
}

/**
 * Possible error codes for authentication errors.
 * - `INVALID_CREDENTIALS` - Wrong email/password combination
 * - `TOKEN_EXPIRED` - JWT token has expired
 * - `UNAUTHORIZED` - No valid authentication provided
 * - `FORBIDDEN` - User lacks required permissions
 */
export type AuthErrorCode = 'INVALID_CREDENTIALS' | 'TOKEN_EXPIRED' | 'UNAUTHORIZED' | 'FORBIDDEN'

/**
 * Authentication error (HTTP 401/403).
 *
 * Thrown when authentication fails or the user lacks required permissions.
 *
 * @example
 * ```typescript
 * try {
 *   await sb.auth.login({ email: 'wrong@email.com', password: 'wrong' })
 * } catch (error) {
 *   if (error instanceof AuthError) {
 *     if (error.code === 'INVALID_CREDENTIALS') {
 *       console.log('Wrong email or password')
 *     } else if (error.code === 'TOKEN_EXPIRED') {
 *       console.log('Please log in again')
 *     }
 *   }
 * }
 * ```
 */
export class AuthError extends SwiftBaseError {
  public override readonly code: AuthErrorCode

  constructor(message: string, code: AuthErrorCode, status: number = 401, details?: unknown) {
    super(message, status, code, details)
    this.name = 'AuthError'
    this.code = code
  }
}

/**
 * Possible error codes for query errors.
 * - `INVALID_QUERY` - Malformed query syntax
 * - `COLLECTION_NOT_FOUND` - Collection doesn't exist
 * - `VALIDATION_ERROR` - Data validation failed
 */
export type QueryErrorCode = 'INVALID_QUERY' | 'COLLECTION_NOT_FOUND' | 'VALIDATION_ERROR'

/**
 * Query error (HTTP 400).
 *
 * Thrown when a query fails due to invalid syntax, missing collection, or validation.
 *
 * @example
 * ```typescript
 * try {
 *   await sb.collection('nonexistent').find()
 * } catch (error) {
 *   if (error instanceof QueryError) {
 *     if (error.code === 'COLLECTION_NOT_FOUND') {
 *       console.log('Collection does not exist')
 *     }
 *   }
 * }
 * ```
 */
export class QueryError extends SwiftBaseError {
  public override readonly code: QueryErrorCode

  constructor(message: string, code: QueryErrorCode, details?: unknown) {
    super(message, 400, code, details)
    this.name = 'QueryError'
    this.code = code
  }
}

/**
 * Possible error codes for network errors.
 * - `TIMEOUT` - Request timed out
 * - `CONNECTION_REFUSED` - Server not reachable
 * - `NETWORK_ERROR` - General network failure
 * - `ABORTED` - Request was cancelled
 */
export type NetworkErrorCode = 'TIMEOUT' | 'CONNECTION_REFUSED' | 'NETWORK_ERROR' | 'ABORTED'

/**
 * Network error (no HTTP response).
 *
 * Thrown when the request fails due to network issues, timeout, or cancellation.
 * The `status` will be 0 for these errors.
 *
 * @example
 * ```typescript
 * try {
 *   await sb.collection('products').find()
 * } catch (error) {
 *   if (error instanceof NetworkError) {
 *     if (error.code === 'TIMEOUT') {
 *       console.log('Request timed out, please try again')
 *     } else if (error.code === 'NETWORK_ERROR') {
 *       console.log('Check your internet connection')
 *     }
 *   }
 * }
 * ```
 */
export class NetworkError extends SwiftBaseError {
  public override readonly code: NetworkErrorCode

  constructor(message: string, code: NetworkErrorCode, details?: unknown) {
    super(message, 0, code, details)
    this.name = 'NetworkError'
    this.code = code
  }
}

/**
 * Not found error (HTTP 404).
 *
 * Thrown when a requested resource doesn't exist.
 *
 * @example
 * ```typescript
 * try {
 *   await sb.storage.getFile('nonexistent_id')
 * } catch (error) {
 *   if (error instanceof NotFoundError) {
 *     console.log('File not found')
 *   }
 * }
 * ```
 */
export class NotFoundError extends SwiftBaseError {
  public override readonly code: 'NOT_FOUND' = 'NOT_FOUND'

  constructor(message: string, details?: unknown) {
    super(message, 404, 'NOT_FOUND', details)
    this.name = 'NotFoundError'
  }
}

/**
 * Field-level validation error detail.
 */
export interface ValidationFieldError {
  /** The field that failed validation */
  field: string
  /** Description of what failed */
  message: string
}

/**
 * Validation error (HTTP 400).
 *
 * Thrown when data validation fails. Contains field-level error details.
 *
 * @example
 * ```typescript
 * try {
 *   await sb.collection('users').create({ email: 'invalid' })
 * } catch (error) {
 *   if (error instanceof ValidationError) {
 *     for (const fieldError of error.errors) {
 *       console.log(`${fieldError.field}: ${fieldError.message}`)
 *     }
 *   }
 * }
 * ```
 */
export class ValidationError extends SwiftBaseError {
  public override readonly code: 'VALIDATION_ERROR' = 'VALIDATION_ERROR'
  /** Array of field-level validation errors */
  public readonly errors: ValidationFieldError[]

  constructor(message: string, errors: ValidationFieldError[], details?: unknown) {
    super(message, 400, 'VALIDATION_ERROR', details)
    this.name = 'ValidationError'
    this.errors = errors
  }
}

/**
 * Parse error response from server and throw appropriate error
 */
export function parseErrorResponse(
  status: number,
  body: unknown
): SwiftBaseError {
  const message = typeof body === 'object' && body !== null && 'message' in body
    ? String((body as { message: unknown }).message)
    : 'An error occurred'

  const code = typeof body === 'object' && body !== null && 'code' in body
    ? String((body as { code: unknown }).code)
    : undefined

  const details = typeof body === 'object' && body !== null && 'details' in body
    ? (body as { details: unknown }).details
    : undefined

  // Handle authentication errors
  if (status === 401) {
    const authCode: AuthErrorCode = code === 'TOKEN_EXPIRED' ? 'TOKEN_EXPIRED' : 'UNAUTHORIZED'
    return new AuthError(message, authCode, status, details)
  }

  if (status === 403) {
    return new AuthError(message, 'FORBIDDEN', status, details)
  }

  // Handle not found
  if (status === 404) {
    return new NotFoundError(message, details)
  }

  // Handle validation errors
  if (status === 400) {
    if (code === 'VALIDATION_ERROR' && Array.isArray(details)) {
      return new ValidationError(message, details as ValidationFieldError[], details)
    }
    if (code === 'INVALID_QUERY' || code === 'COLLECTION_NOT_FOUND') {
      return new QueryError(message, code, details)
    }
    return new SwiftBaseError(message, status, code ?? 'BAD_REQUEST', details)
  }

  // Generic error
  return new SwiftBaseError(message, status, code ?? 'UNKNOWN_ERROR', details)
}
