/**
 * Base error class for all SwiftBase SDK errors
 */
export class SwiftBaseError extends Error {
  public readonly status: number
  public readonly code: string
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
 * Authentication errors (401, 403)
 */
export type AuthErrorCode = 'INVALID_CREDENTIALS' | 'TOKEN_EXPIRED' | 'UNAUTHORIZED' | 'FORBIDDEN'

export class AuthError extends SwiftBaseError {
  public override readonly code: AuthErrorCode

  constructor(message: string, code: AuthErrorCode, status: number = 401, details?: unknown) {
    super(message, status, code, details)
    this.name = 'AuthError'
    this.code = code
  }
}

/**
 * Query errors (400)
 */
export type QueryErrorCode = 'INVALID_QUERY' | 'COLLECTION_NOT_FOUND' | 'VALIDATION_ERROR'

export class QueryError extends SwiftBaseError {
  public override readonly code: QueryErrorCode

  constructor(message: string, code: QueryErrorCode, details?: unknown) {
    super(message, 400, code, details)
    this.name = 'QueryError'
    this.code = code
  }
}

/**
 * Network errors (timeout, connection refused, etc.)
 */
export type NetworkErrorCode = 'TIMEOUT' | 'CONNECTION_REFUSED' | 'NETWORK_ERROR' | 'ABORTED'

export class NetworkError extends SwiftBaseError {
  public override readonly code: NetworkErrorCode

  constructor(message: string, code: NetworkErrorCode, details?: unknown) {
    super(message, 0, code, details)
    this.name = 'NetworkError'
    this.code = code
  }
}

/**
 * Not found errors (404)
 */
export class NotFoundError extends SwiftBaseError {
  public override readonly code: 'NOT_FOUND' = 'NOT_FOUND'

  constructor(message: string, details?: unknown) {
    super(message, 404, 'NOT_FOUND', details)
    this.name = 'NotFoundError'
  }
}

/**
 * Validation errors with field-level details
 */
export interface ValidationFieldError {
  field: string
  message: string
}

export class ValidationError extends SwiftBaseError {
  public override readonly code: 'VALIDATION_ERROR' = 'VALIDATION_ERROR'
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
