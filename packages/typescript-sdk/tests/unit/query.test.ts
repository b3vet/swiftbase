import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest'
import { QueryBuilder, QueryService } from '../../src/modules/query/builder'
import { HttpClient } from '../../src/core/http'

// Mock HTTP client
function createMockHttpClient() {
  return {
    post: vi.fn(),
    get: vi.fn(),
  } as unknown as HttpClient
}

describe('QueryBuilder', () => {
  let mockHttp: ReturnType<typeof createMockHttpClient>
  let builder: QueryBuilder

  beforeEach(() => {
    mockHttp = createMockHttpClient()
    builder = new QueryBuilder(mockHttp, 'products')
  })

  describe('where', () => {
    it('should build simple where clause', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.where({ active: true }).find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          action: 'find',
          collection: 'products',
          query: { where: { active: true } },
        })
      )
    })

    it('should build where clause with operators', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.where({ price: { $gte: 50, $lte: 100 } }).find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { where: { price: { $gte: 50, $lte: 100 } } },
        })
      )
    })

    it('should chain multiple where calls', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder
        .where({ active: true })
        .where({ category: 'electronics' })
        .find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { where: { active: true, category: 'electronics' } },
        })
      )
    })
  })

  describe('orderBy', () => {
    it('should build orderBy with string and direction', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.orderBy('created_at', 'desc').find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { orderBy: { created_at: 'desc' } },
        })
      )
    })

    it('should build orderBy with object', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.orderBy({ created_at: 'desc', name: 'asc' }).find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { orderBy: { created_at: 'desc', name: 'asc' } },
        })
      )
    })

    it('should default to asc direction', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.orderBy('name').find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { orderBy: { name: 'asc' } },
        })
      )
    })
  })

  describe('limit and offset', () => {
    it('should build limit', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.limit(20).find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { limit: 20 },
        })
      )
    })

    it('should build offset', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.offset(10).find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { offset: 10 },
        })
      )
    })

    it('should build pagination with limit and offset', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.limit(20).offset(40).find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { limit: 20, offset: 40 },
        })
      )
    })
  })

  describe('select', () => {
    it('should build select fields', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder.select(['id', 'name', 'price']).find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          query: { select: ['id', 'name', 'price'] },
        })
      )
    })
  })

  describe('find', () => {
    it('should return array of documents', async () => {
      const mockData = [
        { id: '1', name: 'Product 1' },
        { id: '2', name: 'Product 2' },
      ]
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: mockData })

      const result = await builder.find()

      expect(result).toEqual(mockData)
    })
  })

  describe('findOne', () => {
    it('should return single document', async () => {
      const mockData = { id: '1', name: 'Product 1' }
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: mockData })

      const result = await builder.where({ id: '1' }).findOne()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          action: 'findOne',
        })
      )
      expect(result).toEqual(mockData)
    })

    it('should return null when not found', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: null })

      const result = await builder.where({ id: 'nonexistent' }).findOne()

      expect(result).toBeNull()
    })
  })

  describe('create', () => {
    it('should create document and return it', async () => {
      const newDoc = { name: 'New Product', price: 99.99 }
      const createdDoc = { id: '123', ...newDoc, createdAt: '2024-01-01', updatedAt: '2024-01-01' }
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: createdDoc })

      const result = await builder.create(newDoc)

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          action: 'create',
          collection: 'products',
          data: newDoc,
        })
      )
      expect(result).toEqual(createdDoc)
    })
  })

  describe('update', () => {
    it('should update with $set operator', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: { modified: 1 } })

      const result = await builder
        .where({ id: '123' })
        .update({ $set: { price: 149.99 } })

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          action: 'update',
          query: { where: { id: '123' } },
          data: { $set: { price: 149.99 } },
        })
      )
      expect(result.modified).toBe(1)
    })

    it('should update with partial data', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: { modified: 1 } })

      await builder.where({ id: '123' }).update({ price: 149.99 })

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          data: { price: 149.99 },
        })
      )
    })
  })

  describe('delete', () => {
    it('should delete matching documents', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: { deleted: 5 } })

      const result = await builder.where({ active: false }).delete()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          action: 'delete',
          query: { where: { active: false } },
        })
      )
      expect(result.deleted).toBe(5)
    })
  })

  describe('count', () => {
    it('should return count of matching documents', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: { count: 42 } })

      const result = await builder.where({ active: true }).count()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          action: 'count',
          query: { where: { active: true } },
        })
      )
      expect(result).toBe(42)
    })
  })

  describe('bulk', () => {
    it('should execute bulk operations', async () => {
      const operations = [
        { action: 'create' as const, data: { name: 'Product 1' } },
        { action: 'create' as const, data: { name: 'Product 2' } },
      ]
      const mockResponse = {
        success: true,
        results: [
          { success: true, data: { id: '1' } },
          { success: true, data: { id: '2' } },
        ],
      }
      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)

      const result = await builder.bulk(operations)

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        expect.objectContaining({
          action: 'bulk',
          collection: 'products',
          operations,
        })
      )
      expect(result.results).toHaveLength(2)
    })
  })

  describe('chaining', () => {
    it('should chain all methods together', async () => {
      ;(mockHttp.post as Mock).mockResolvedValueOnce({ success: true, data: [] })

      await builder
        .where({ category: 'electronics' })
        .where({ price: { $gte: 100 } })
        .orderBy('price', 'asc')
        .select(['id', 'name', 'price'])
        .limit(10)
        .offset(20)
        .find()

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        {
          action: 'find',
          collection: 'products',
          query: {
            where: { category: 'electronics', price: { $gte: 100 } },
            orderBy: { price: 'asc' },
            select: ['id', 'name', 'price'],
            limit: 10,
            offset: 20,
          },
        }
      )
    })
  })
})

describe('QueryService', () => {
  let mockHttp: ReturnType<typeof createMockHttpClient>
  let service: QueryService

  beforeEach(() => {
    mockHttp = createMockHttpClient()
    service = new QueryService(mockHttp)
  })

  describe('collection', () => {
    it('should return a QueryBuilder', () => {
      const builder = service.collection('products')
      expect(builder).toBeInstanceOf(QueryBuilder)
    })
  })

  describe('query', () => {
    it('should execute raw query', async () => {
      const mockResponse = { success: true, data: [{ id: '1' }] }
      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)

      const result = await service.query({
        action: 'find',
        collection: 'products',
        query: { where: { active: true } },
      })

      expect(result).toEqual(mockResponse)
    })
  })

  describe('customQuery', () => {
    it('should execute custom query', async () => {
      const mockResponse = { success: true, data: [{ id: '1', sales: 1000 }] }
      ;(mockHttp.post as Mock).mockResolvedValueOnce(mockResponse)

      const result = await service.customQuery('getTopSellers', { limit: 10 })

      expect(mockHttp.post).toHaveBeenCalledWith(
        '/api/query',
        {
          action: 'custom',
          collection: '',
          custom: 'getTopSellers',
          params: { limit: 10 },
        }
      )
      expect(result).toEqual(mockResponse)
    })
  })
})
