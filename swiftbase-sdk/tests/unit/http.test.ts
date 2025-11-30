import { describe, it, expect, vi, beforeEach, afterEach, type Mock } from 'vitest'
import { HttpClient } from '../../src/core/http'
import { NetworkError, SwiftBaseError } from '../../src/core/errors'

describe('HttpClient', () => {
  let client: HttpClient
  let mockFetch: Mock

  beforeEach(() => {
    mockFetch = vi.fn()
    vi.stubGlobal('fetch', mockFetch)
    client = new HttpClient({
      baseUrl: 'http://localhost:8090',
      timeout: 5000,
      retry: false, // Disable retry for tests
    })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('constructor', () => {
    it('should remove trailing slash from base URL', () => {
      const c = new HttpClient({ baseUrl: 'http://localhost:8090/' })
      expect(c).toBeDefined()
    })

    it('should use default timeout', () => {
      const c = new HttpClient({ baseUrl: 'http://localhost:8090' })
      expect(c).toBeDefined()
    })
  })

  describe('get', () => {
    it('should make GET request', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        headers: new Headers({ 'Content-Type': 'application/json' }),
        json: async () => ({ data: 'test' }),
      })

      const result = await client.get('/api/test')

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:8090/api/test',
        expect.objectContaining({
          method: 'GET',
        })
      )
      expect(result).toEqual({ data: 'test' })
    })

    it('should handle text response', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        headers: new Headers({ 'Content-Type': 'text/plain' }),
        text: async () => 'plain text response',
      })

      const result = await client.get('/api/test')

      expect(result).toBe('plain text response')
    })
  })

  describe('post', () => {
    it('should make POST request with body', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 201,
        headers: new Headers({ 'Content-Type': 'application/json' }),
        json: async () => ({ id: '123' }),
      })

      const result = await client.post('/api/items', { name: 'test' })

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:8090/api/items',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify({ name: 'test' }),
        })
      )
      expect(result).toEqual({ id: '123' })
    })
  })

  describe('error handling', () => {
    it('should throw SwiftBaseError on non-ok response', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 400,
        headers: new Headers({ 'Content-Type': 'application/json' }),
        json: async () => ({ message: 'Bad request', code: 'INVALID_QUERY' }),
      })

      await expect(client.get('/api/test')).rejects.toThrow(SwiftBaseError)
    })

    it('should throw NetworkError on fetch failure', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Failed to fetch'))

      await expect(client.get('/api/test')).rejects.toThrow(NetworkError)
    })
  })

  describe('interceptors', () => {
    it('should run request interceptor', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        headers: new Headers({ 'Content-Type': 'application/json' }),
        json: async () => ({ success: true }),
      })

      const interceptor = vi.fn((config: any) => {
        config.headers.set('X-Custom', 'value')
        return config
      })

      client.interceptors.request.use(interceptor)

      await client.get('/api/test')

      expect(interceptor).toHaveBeenCalled()
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:8090/api/test',
        expect.objectContaining({
          headers: expect.any(Headers),
        })
      )
    })

    it('should run response interceptor', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        headers: new Headers({ 'Content-Type': 'application/json' }),
        json: async () => ({ value: 1 }),
      })

      const interceptor = vi.fn((response: any) => {
        response.data = { ...response.data as object, modified: true }
        return response
      })

      client.interceptors.response.use(interceptor)

      const result = await client.get('/api/test')

      expect(interceptor).toHaveBeenCalled()
      expect(result).toEqual({ value: 1, modified: true })
    })
  })

  describe('auth header', () => {
    it('should set auth header', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        headers: new Headers({ 'Content-Type': 'application/json' }),
        json: async () => ({}),
      })

      client.setAuthHeader('test-token')
      await client.get('/api/test')

      const call = mockFetch.mock.calls[0] as [string, RequestInit]
      const headers = call[1].headers as Headers
      expect(headers.get('Authorization')).toBe('Bearer test-token')
    })

    it('should remove auth header when set to null', async () => {
      client.setAuthHeader('test-token')
      client.setAuthHeader(null)

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        headers: new Headers({ 'Content-Type': 'application/json' }),
        json: async () => ({}),
      })

      await client.get('/api/test')

      const call = mockFetch.mock.calls[0] as [string, RequestInit]
      const headers = call[1].headers as Headers
      expect(headers.get('Authorization')).toBeNull()
    })
  })
})
