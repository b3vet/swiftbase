import { describe, it, expect } from 'vitest'
import { SwiftBaseClient, createClient } from '../../src/client'

describe('SwiftBaseClient', () => {
  describe('constructor', () => {
    it('should create client with URL', () => {
      const client = new SwiftBaseClient({
        url: 'http://localhost:8090',
      })

      expect(client.url).toBe('http://localhost:8090')
    })

    it('should throw error without URL', () => {
      expect(() => {
        new SwiftBaseClient({ url: '' })
      }).toThrow('SwiftBase URL is required')
    })

    it('should merge config with defaults', () => {
      const client = new SwiftBaseClient({
        url: 'http://localhost:8090',
        request: {
          timeout: 10000,
        },
      })

      expect(client._config.request.timeout).toBe(10000)
      expect(client._config.auth.autoRefresh).toBe(true) // default value
    })

    it('should expose interceptors', () => {
      const client = new SwiftBaseClient({
        url: 'http://localhost:8090',
      })

      expect(client.interceptors).toBeDefined()
      expect(client.interceptors.request).toBeDefined()
      expect(client.interceptors.response).toBeDefined()
    })
  })

  describe('createClient', () => {
    it('should create SwiftBaseClient instance', () => {
      const client = createClient({
        url: 'http://localhost:8090',
      })

      expect(client).toBeInstanceOf(SwiftBaseClient)
    })

    it('should accept full configuration', () => {
      const client = createClient({
        url: 'http://localhost:8090',
        auth: {
          storage: 'memory',
          autoRefresh: false,
          persistSession: false,
        },
        request: {
          timeout: 60000,
          retry: {
            attempts: 5,
            backoff: 'linear',
          },
          headers: {
            'X-Custom': 'header',
          },
        },
        realtime: {
          autoConnect: true,
          reconnect: false,
        },
      })

      expect(client._config.auth.autoRefresh).toBe(false)
      expect(client._config.request.timeout).toBe(60000)
      expect(client._config.realtime.autoConnect).toBe(true)
    })
  })
})
