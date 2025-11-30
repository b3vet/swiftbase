import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { Collections } from '../../src/modules/collections/collections'
import { HttpClient } from '../../src/core/http'
import { NotFoundError, AuthError, SwiftBaseError } from '../../src/core/errors'
import type { Collection, CollectionStats } from '../../src/types/collections'

// Mock HttpClient
const createMockHttpClient = () => {
  return {
    request: vi.fn(),
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
    getAuthHeader: vi.fn(() => 'Bearer admin_token'),
  } as unknown as HttpClient
}

describe('Collections', () => {
  let collections: Collections
  let mockHttpClient: ReturnType<typeof createMockHttpClient>

  beforeEach(() => {
    mockHttpClient = createMockHttpClient()
    collections = new Collections(mockHttpClient as HttpClient)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('list', () => {
    it('should list all collections', async () => {
      const mockCollections: Collection[] = [
        {
          id: 'col_1',
          name: 'products',
          schema: {
            name: { type: 'string', required: true },
            price: { type: 'number' },
          },
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
        {
          id: 'col_2',
          name: 'orders',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ]

      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        collections: mockCollections,
      })

      const result = await collections.list()

      expect(result).toEqual(mockCollections)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/admin/collections',
        })
      )
    })

    it('should throw AuthError for 401', async () => {
      const error = new SwiftBaseError('Unauthorized', 401)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.list()).rejects.toThrow(AuthError)
    })

    it('should throw AuthError for 403', async () => {
      const error = new SwiftBaseError('Forbidden', 403)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.list()).rejects.toThrow(AuthError)
    })
  })

  describe('get', () => {
    it('should get a single collection', async () => {
      const mockCollection: Collection = {
        id: 'col_1',
        name: 'products',
        schema: {
          name: { type: 'string', required: true },
          price: { type: 'number' },
        },
        indexes: {
          name_idx: { fields: ['name'], unique: true },
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        collection: mockCollection,
      })

      const result = await collections.get('products')

      expect(result).toEqual(mockCollection)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/admin/collections/products',
        })
      )
    })

    it('should URL-encode collection name', async () => {
      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        collection: { id: '1', name: 'my collection', createdAt: '', updatedAt: '' },
      })

      await collections.get('my collection')

      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          url: '/api/admin/collections/my%20collection',
        })
      )
    })

    it('should throw NotFoundError for 404', async () => {
      const error = new SwiftBaseError('Not found', 404)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.get('nonexistent')).rejects.toThrow(NotFoundError)
    })

    it('should throw AuthError for 401', async () => {
      const error = new SwiftBaseError('Unauthorized', 401)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.get('products')).rejects.toThrow(AuthError)
    })
  })

  describe('create', () => {
    it('should create a new collection', async () => {
      const mockCollection: Collection = {
        id: 'col_new',
        name: 'orders',
        schema: {
          customerId: { type: 'string', required: true },
          total: { type: 'number', required: true },
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        collection: mockCollection,
      })

      const result = await collections.create({
        name: 'orders',
        schema: {
          customerId: { type: 'string', required: true },
          total: { type: 'number', required: true },
        },
      })

      expect(result).toEqual(mockCollection)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'POST',
          url: '/api/admin/collections',
          body: expect.objectContaining({
            name: 'orders',
            schema: expect.any(Object),
          }),
        })
      )
    })

    it('should create collection with indexes', async () => {
      const mockCollection: Collection = {
        id: 'col_new',
        name: 'orders',
        indexes: {
          customer_idx: { fields: ['customerId'] },
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        collection: mockCollection,
      })

      await collections.create({
        name: 'orders',
        indexes: {
          customer_idx: { fields: ['customerId'] },
        },
      })

      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          body: expect.objectContaining({
            indexes: {
              customer_idx: { fields: ['customerId'] },
            },
          }),
        })
      )
    })

    it('should throw AuthError for 401', async () => {
      const error = new SwiftBaseError('Unauthorized', 401)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.create({ name: 'test' })).rejects.toThrow(AuthError)
    })
  })

  describe('update', () => {
    it('should update an existing collection', async () => {
      const mockCollection: Collection = {
        id: 'col_1',
        name: 'products',
        schema: {
          name: { type: 'string', required: true },
          price: { type: 'number' },
          description: { type: 'string' },
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        collection: mockCollection,
      })

      const result = await collections.update('products', {
        schema: {
          name: { type: 'string', required: true },
          price: { type: 'number' },
          description: { type: 'string' },
        },
      })

      expect(result).toEqual(mockCollection)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'PATCH',
          url: '/api/admin/collections/products',
          body: expect.objectContaining({
            schema: expect.any(Object),
          }),
        })
      )
    })

    it('should throw NotFoundError for 404', async () => {
      const error = new SwiftBaseError('Not found', 404)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.update('nonexistent', {})).rejects.toThrow(NotFoundError)
    })

    it('should throw AuthError for 403', async () => {
      const error = new SwiftBaseError('Forbidden', 403)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.update('products', {})).rejects.toThrow(AuthError)
    })
  })

  describe('delete', () => {
    it('should delete a collection', async () => {
      mockHttpClient.request = vi.fn().mockResolvedValue({ success: true })

      await collections.delete('old_collection')

      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'DELETE',
          url: '/api/admin/collections/old_collection',
        })
      )
    })

    it('should throw NotFoundError for 404', async () => {
      const error = new SwiftBaseError('Not found', 404)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.delete('nonexistent')).rejects.toThrow(NotFoundError)
    })

    it('should throw AuthError for 401', async () => {
      const error = new SwiftBaseError('Unauthorized', 401)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.delete('products')).rejects.toThrow(AuthError)
    })
  })

  describe('stats', () => {
    it('should get collection statistics', async () => {
      const mockStats: CollectionStats = {
        documentCount: 1000,
        storageSize: 524288,
        avgDocumentSize: 524,
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        stats: mockStats,
      })

      const result = await collections.stats('products')

      expect(result).toEqual(mockStats)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/admin/collections/products/stats',
        })
      )
    })

    it('should throw NotFoundError for 404', async () => {
      const error = new SwiftBaseError('Not found', 404)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.stats('nonexistent')).rejects.toThrow(NotFoundError)
    })

    it('should throw AuthError for 401', async () => {
      const error = new SwiftBaseError('Unauthorized', 401)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.stats('products')).rejects.toThrow(AuthError)
    })
  })

  describe('error handling', () => {
    it('should rethrow non-auth/non-404 errors', async () => {
      const error = new SwiftBaseError('Server error', 500)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(collections.list()).rejects.toThrow(SwiftBaseError)
      await expect(collections.get('test')).rejects.toThrow(SwiftBaseError)
      await expect(collections.create({ name: 'test' })).rejects.toThrow(SwiftBaseError)
      await expect(collections.update('test', {})).rejects.toThrow(SwiftBaseError)
      await expect(collections.delete('test')).rejects.toThrow(SwiftBaseError)
      await expect(collections.stats('test')).rejects.toThrow(SwiftBaseError)
    })
  })
})
