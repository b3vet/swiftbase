import { describe, it, expect } from 'vitest'
import {
  SwiftBaseError,
  AuthError,
  QueryError,
  NetworkError,
  NotFoundError,
  ValidationError,
  parseErrorResponse,
} from '../../src/core/errors'

describe('SwiftBaseError', () => {
  it('should create error with all properties', () => {
    const error = new SwiftBaseError('Test error', 500, 'TEST_ERROR', { foo: 'bar' })

    expect(error.message).toBe('Test error')
    expect(error.status).toBe(500)
    expect(error.code).toBe('TEST_ERROR')
    expect(error.details).toEqual({ foo: 'bar' })
    expect(error.name).toBe('SwiftBaseError')
    expect(error).toBeInstanceOf(Error)
  })
})

describe('AuthError', () => {
  it('should create auth error with code', () => {
    const error = new AuthError('Invalid credentials', 'INVALID_CREDENTIALS')

    expect(error.message).toBe('Invalid credentials')
    expect(error.code).toBe('INVALID_CREDENTIALS')
    expect(error.status).toBe(401)
    expect(error.name).toBe('AuthError')
    expect(error).toBeInstanceOf(SwiftBaseError)
  })

  it('should support custom status', () => {
    const error = new AuthError('Forbidden', 'FORBIDDEN', 403)

    expect(error.status).toBe(403)
  })
})

describe('QueryError', () => {
  it('should create query error', () => {
    const error = new QueryError('Invalid query', 'INVALID_QUERY')

    expect(error.message).toBe('Invalid query')
    expect(error.code).toBe('INVALID_QUERY')
    expect(error.status).toBe(400)
    expect(error.name).toBe('QueryError')
  })
})

describe('NetworkError', () => {
  it('should create network error', () => {
    const error = new NetworkError('Connection refused', 'CONNECTION_REFUSED')

    expect(error.message).toBe('Connection refused')
    expect(error.code).toBe('CONNECTION_REFUSED')
    expect(error.status).toBe(0)
    expect(error.name).toBe('NetworkError')
  })
})

describe('NotFoundError', () => {
  it('should create not found error', () => {
    const error = new NotFoundError('Resource not found')

    expect(error.message).toBe('Resource not found')
    expect(error.code).toBe('NOT_FOUND')
    expect(error.status).toBe(404)
    expect(error.name).toBe('NotFoundError')
  })
})

describe('ValidationError', () => {
  it('should create validation error with field errors', () => {
    const errors = [
      { field: 'email', message: 'Invalid email format' },
      { field: 'password', message: 'Password too short' },
    ]
    const error = new ValidationError('Validation failed', errors)

    expect(error.message).toBe('Validation failed')
    expect(error.code).toBe('VALIDATION_ERROR')
    expect(error.status).toBe(400)
    expect(error.errors).toEqual(errors)
    expect(error.name).toBe('ValidationError')
  })
})

describe('parseErrorResponse', () => {
  it('should parse 401 as AuthError', () => {
    const error = parseErrorResponse(401, { message: 'Unauthorized' })

    expect(error).toBeInstanceOf(AuthError)
    expect(error.code).toBe('UNAUTHORIZED')
  })

  it('should parse 401 with TOKEN_EXPIRED code', () => {
    const error = parseErrorResponse(401, { message: 'Token expired', code: 'TOKEN_EXPIRED' })

    expect(error).toBeInstanceOf(AuthError)
    expect(error.code).toBe('TOKEN_EXPIRED')
  })

  it('should parse 403 as AuthError with FORBIDDEN', () => {
    const error = parseErrorResponse(403, { message: 'Forbidden' })

    expect(error).toBeInstanceOf(AuthError)
    expect(error.code).toBe('FORBIDDEN')
  })

  it('should parse 404 as NotFoundError', () => {
    const error = parseErrorResponse(404, { message: 'Not found' })

    expect(error).toBeInstanceOf(NotFoundError)
    expect(error.code).toBe('NOT_FOUND')
  })

  it('should parse 400 with INVALID_QUERY as QueryError', () => {
    const error = parseErrorResponse(400, { message: 'Invalid query', code: 'INVALID_QUERY' })

    expect(error).toBeInstanceOf(QueryError)
    expect(error.code).toBe('INVALID_QUERY')
  })

  it('should parse 400 with validation errors as ValidationError', () => {
    const details = [
      { field: 'email', message: 'Required' },
    ]
    const error = parseErrorResponse(400, {
      message: 'Validation failed',
      code: 'VALIDATION_ERROR',
      details,
    })

    expect(error).toBeInstanceOf(ValidationError)
    expect((error as ValidationError).errors).toEqual(details)
  })

  it('should handle missing message', () => {
    const error = parseErrorResponse(500, {})

    expect(error.message).toBe('An error occurred')
  })
})
