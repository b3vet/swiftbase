import { describe, it, expect, vi } from 'vitest'
import {
  InterceptorManager,
  createInterceptors,
  type RequestConfig,
  type ResponseWrapper,
} from '../../src/core/interceptors'

describe('InterceptorManager', () => {
  describe('use', () => {
    it('should add interceptor and return id', () => {
      const manager = new InterceptorManager<(v: number) => number>()

      const id1 = manager.use((v) => v + 1)
      const id2 = manager.use((v) => v * 2)

      expect(id1).toBe(0)
      expect(id2).toBe(1)
    })

    it('should add interceptor with error handler', () => {
      const manager = new InterceptorManager<(v: number) => number>()

      const errorHandler = vi.fn((err) => err)
      const id = manager.use((v) => v + 1, errorHandler)

      expect(id).toBe(0)
    })
  })

  describe('eject', () => {
    it('should remove interceptor by id', async () => {
      const manager = new InterceptorManager<(v: number) => number>()

      const id = manager.use((v) => v + 10)
      manager.eject(id)

      const result = await manager.execute(5, async (handler, value) => handler(value))
      expect(result).toBe(5) // Interceptor was ejected, no change
    })

    it('should handle ejecting non-existent id', () => {
      const manager = new InterceptorManager<(v: number) => number>()

      // Should not throw
      manager.eject(999)
    })
  })

  describe('clear', () => {
    it('should remove all interceptors', async () => {
      const manager = new InterceptorManager<(v: number) => number>()

      manager.use((v) => v + 1)
      manager.use((v) => v * 2)
      manager.clear()

      const result = await manager.execute(5, async (handler, value) => handler(value))
      expect(result).toBe(5) // All interceptors cleared
    })
  })

  describe('execute', () => {
    it('should execute interceptors in order', async () => {
      const manager = new InterceptorManager<(v: number) => number>()

      manager.use((v) => v + 1)  // 5 + 1 = 6
      manager.use((v) => v * 2)  // 6 * 2 = 12

      const result = await manager.execute(5, async (handler, value) => handler(value))
      expect(result).toBe(12)
    })

    it('should handle async interceptors', async () => {
      const manager = new InterceptorManager<(v: number) => Promise<number>>()

      manager.use(async (v) => {
        await new Promise((r) => setTimeout(r, 10))
        return v + 1
      })

      const result = await manager.execute(5, async (handler, value) => handler(value))
      expect(result).toBe(6)
    })

    it('should call error handler on interceptor error', async () => {
      const manager = new InterceptorManager<(v: number) => number>()
      const errorHandler = vi.fn((err: Error) => new Error('handled'))

      manager.use(
        () => { throw new Error('test error') },
        errorHandler
      )

      await expect(
        manager.execute(5, async (handler, value) => handler(value))
      ).rejects.toThrow('handled')

      expect(errorHandler).toHaveBeenCalled()
    })

    it('should throw original error if no error handler', async () => {
      const manager = new InterceptorManager<(v: number) => number>()

      manager.use(() => { throw new Error('original error') })

      await expect(
        manager.execute(5, async (handler, value) => handler(value))
      ).rejects.toThrow('original error')
    })

    it('should skip null handlers (ejected)', async () => {
      const manager = new InterceptorManager<(v: number) => number>()

      manager.use((v) => v + 1)
      const id = manager.use((v) => v + 100)
      manager.use((v) => v * 2)

      manager.eject(id)

      const result = await manager.execute(5, async (handler, value) => handler(value))
      expect(result).toBe(12) // (5 + 1) * 2 = 12, skipping the +100
    })
  })

  describe('getHandlers', () => {
    it('should return all non-null handlers', () => {
      const manager = new InterceptorManager<(v: number) => number>()

      manager.use((v) => v + 1)
      const id = manager.use((v) => v + 2)
      manager.use((v) => v + 3)

      manager.eject(id)

      const handlers = manager.getHandlers()
      expect(handlers).toHaveLength(2)
    })
  })
})

describe('createInterceptors', () => {
  it('should create request and response interceptor managers', () => {
    const interceptors = createInterceptors()

    expect(interceptors.request).toBeInstanceOf(InterceptorManager)
    expect(interceptors.response).toBeInstanceOf(InterceptorManager)
  })

  it('should work with request interceptors', async () => {
    const interceptors = createInterceptors()

    interceptors.request.use((config) => ({
      ...config,
      headers: new Headers({ 'X-Custom': 'value' }),
    }))

    const config: RequestConfig = {
      url: 'http://test.com',
      method: 'GET',
      headers: new Headers(),
    }

    const result = await interceptors.request.execute(
      config,
      async (handler, cfg) => handler(cfg)
    )

    expect(result.headers.get('X-Custom')).toBe('value')
  })

  it('should work with response interceptors', async () => {
    const interceptors = createInterceptors()

    interceptors.response.use((response) => ({
      ...response,
      data: { ...response.data as object, modified: true },
    }))

    const response: ResponseWrapper = {
      status: 200,
      headers: new Headers(),
      data: { value: 1 },
      ok: true,
    }

    const result = await interceptors.response.execute(
      response,
      async (handler, resp) => handler(resp)
    )

    expect(result.data).toEqual({ value: 1, modified: true })
  })
})
