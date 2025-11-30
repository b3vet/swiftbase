import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { Storage } from '../../src/modules/storage/storage'
import { HttpClient } from '../../src/core/http'
import { NotFoundError, NetworkError, SwiftBaseError } from '../../src/core/errors'

// Type definition for tests
interface FileMetadata {
  id: string
  filename: string
  originalName: string
  contentType: string
  size: number
  metadata: Record<string, unknown>
  createdAt: string
}

// Mock HttpClient
const createMockHttpClient = () => {
  return {
    request: vi.fn(),
    get: vi.fn(),
    post: vi.fn(),
    delete: vi.fn(),
    getAuthHeader: vi.fn(() => 'Bearer test_token'),
    getBaseUrl: vi.fn(() => 'http://localhost:8090'),
  } as unknown as HttpClient
}

describe('Storage (File Storage)', () => {
  let storage: Storage
  let mockHttpClient: ReturnType<typeof createMockHttpClient>

  beforeEach(() => {
    mockHttpClient = createMockHttpClient()
    storage = new Storage(mockHttpClient as HttpClient, 'http://localhost:8090')
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('upload', () => {
    it('should upload a file', async () => {
      const mockFile: FileMetadata = {
        id: 'file_123',
        filename: 'test.txt',
        originalName: 'test.txt',
        contentType: 'text/plain',
        size: 100,
        metadata: {},
        createdAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({ success: true, file: mockFile })

      const blob = new Blob(['test content'], { type: 'text/plain' })
      const result = await storage.upload(blob)

      expect(result).toEqual(mockFile)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'POST',
          url: '/api/storage/upload',
        })
      )
    })

    it('should upload with metadata', async () => {
      const mockFile: FileMetadata = {
        id: 'file_123',
        filename: 'test.txt',
        originalName: 'test.txt',
        contentType: 'text/plain',
        size: 100,
        metadata: { description: 'Test file' },
        createdAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({ success: true, file: mockFile })

      const blob = new Blob(['test content'], { type: 'text/plain' })
      const result = await storage.upload(blob, {
        metadata: { description: 'Test file' },
      })

      expect(result).toEqual(mockFile)
    })

    it('should handle upload with progress callback using XHR', async () => {
      // Create a proper mock XMLHttpRequest class
      let mockXhrInstance: MockXHR
      class MockXHR {
        open = vi.fn()
        send = vi.fn()
        setRequestHeader = vi.fn()
        upload = { addEventListener: vi.fn() }
        addEventListener = vi.fn()
        readyState = 4
        status = 200
        responseText = JSON.stringify({
          success: true,
          file: {
            id: 'file_123',
            filename: 'test.txt',
            originalName: 'test.txt',
            contentType: 'text/plain',
            size: 100,
            metadata: {},
            createdAt: new Date().toISOString(),
          },
        })
        constructor() {
          mockXhrInstance = this
        }
      }

      vi.stubGlobal('XMLHttpRequest', MockXHR)

      const progressCallback = vi.fn()
      const blob = new Blob(['test content'], { type: 'text/plain' })

      // Start upload - will use XHR for progress
      const uploadPromise = storage.upload(blob, {
        onProgress: progressCallback,
      })

      // Simulate load event
      const loadHandler = mockXhrInstance!.addEventListener.mock.calls.find(
        (call: [string, unknown]) => call[0] === 'load'
      )?.[1] as () => void

      if (loadHandler) {
        loadHandler()
      }

      const result = await uploadPromise

      expect(result.id).toBe('file_123')
      expect(mockXhrInstance!.open).toHaveBeenCalledWith(
        'POST',
        'http://localhost:8090/api/storage/upload'
      )
    })

    it('should call progress callback during upload', async () => {
      let mockXhrInstance: MockXHR
      class MockXHR {
        open = vi.fn()
        send = vi.fn()
        setRequestHeader = vi.fn()
        upload = { addEventListener: vi.fn() }
        addEventListener = vi.fn()
        readyState = 4
        status = 200
        responseText = JSON.stringify({
          success: true,
          file: {
            id: 'file_123',
            filename: 'test.txt',
            originalName: 'test.txt',
            contentType: 'text/plain',
            size: 100,
            metadata: {},
            createdAt: new Date().toISOString(),
          },
        })
        constructor() {
          mockXhrInstance = this
        }
      }

      vi.stubGlobal('XMLHttpRequest', MockXHR)

      const progressCallback = vi.fn()
      const blob = new Blob(['test content'], { type: 'text/plain' })

      const uploadPromise = storage.upload(blob, {
        onProgress: progressCallback,
      })

      // Simulate progress event
      const progressHandler = mockXhrInstance!.upload.addEventListener.mock.calls.find(
        (call: [string, unknown]) => call[0] === 'progress'
      )?.[1] as (event: { lengthComputable: boolean; loaded: number; total: number }) => void

      if (progressHandler) {
        progressHandler({ lengthComputable: true, loaded: 50, total: 100 })
      }

      // Simulate load event
      const loadHandler = mockXhrInstance!.addEventListener.mock.calls.find(
        (call: [string, unknown]) => call[0] === 'load'
      )?.[1] as () => void

      if (loadHandler) {
        loadHandler()
      }

      await uploadPromise

      expect(progressCallback).toHaveBeenCalledWith({
        loaded: 50,
        total: 100,
        percentage: 50,
      })
    })

    it('should handle abort signal when already aborted', async () => {
      const controller = new AbortController()
      controller.abort()

      class MockXHR {
        open = vi.fn()
        send = vi.fn()
        setRequestHeader = vi.fn()
        abort = vi.fn()
        upload = { addEventListener: vi.fn() }
        addEventListener = vi.fn()
      }

      vi.stubGlobal('XMLHttpRequest', MockXHR)

      const blob = new Blob(['test content'], { type: 'text/plain' })

      await expect(
        storage.upload(blob, {
          signal: controller.signal,
          onProgress: vi.fn(),
        })
      ).rejects.toThrow(NetworkError)
    })

    it('should convert ArrayBuffer to Blob', async () => {
      const mockFile: FileMetadata = {
        id: 'file_123',
        filename: 'test.bin',
        originalName: 'test.bin',
        contentType: 'application/octet-stream',
        size: 4,
        metadata: {},
        createdAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({ success: true, file: mockFile })

      const buffer = new ArrayBuffer(4)
      const result = await storage.upload(buffer)

      expect(result).toEqual(mockFile)
    })

    it('should convert Uint8Array to Blob', async () => {
      const mockFile: FileMetadata = {
        id: 'file_123',
        filename: 'test.bin',
        originalName: 'test.bin',
        contentType: 'application/octet-stream',
        size: 4,
        metadata: {},
        createdAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({ success: true, file: mockFile })

      const uint8 = new Uint8Array([1, 2, 3, 4])
      const result = await storage.upload(uint8)

      expect(result).toEqual(mockFile)
    })

    it('should handle XHR error during upload', async () => {
      let mockXhrInstance: MockXHR
      class MockXHR {
        open = vi.fn()
        send = vi.fn()
        setRequestHeader = vi.fn()
        upload = { addEventListener: vi.fn() }
        addEventListener = vi.fn()
        constructor() {
          mockXhrInstance = this
        }
      }

      vi.stubGlobal('XMLHttpRequest', MockXHR)

      const blob = new Blob(['test content'], { type: 'text/plain' })

      const uploadPromise = storage.upload(blob, {
        onProgress: vi.fn(),
      })

      // Simulate error event
      const errorHandler = mockXhrInstance!.addEventListener.mock.calls.find(
        (call: [string, unknown]) => call[0] === 'error'
      )?.[1] as () => void

      if (errorHandler) {
        errorHandler()
      }

      await expect(uploadPromise).rejects.toThrow(NetworkError)
    })

    it('should handle XHR abort during upload', async () => {
      let mockXhrInstance: MockXHR
      class MockXHR {
        open = vi.fn()
        send = vi.fn()
        setRequestHeader = vi.fn()
        upload = { addEventListener: vi.fn() }
        addEventListener = vi.fn()
        constructor() {
          mockXhrInstance = this
        }
      }

      vi.stubGlobal('XMLHttpRequest', MockXHR)

      const blob = new Blob(['test content'], { type: 'text/plain' })

      const uploadPromise = storage.upload(blob, {
        onProgress: vi.fn(),
      })

      // Simulate abort event
      const abortHandler = mockXhrInstance!.addEventListener.mock.calls.find(
        (call: [string, unknown]) => call[0] === 'abort'
      )?.[1] as () => void

      if (abortHandler) {
        abortHandler()
      }

      await expect(uploadPromise).rejects.toThrow(NetworkError)
    })

    it('should handle XHR timeout during upload', async () => {
      let mockXhrInstance: MockXHR
      class MockXHR {
        open = vi.fn()
        send = vi.fn()
        setRequestHeader = vi.fn()
        upload = { addEventListener: vi.fn() }
        addEventListener = vi.fn()
        constructor() {
          mockXhrInstance = this
        }
      }

      vi.stubGlobal('XMLHttpRequest', MockXHR)

      const blob = new Blob(['test content'], { type: 'text/plain' })

      const uploadPromise = storage.upload(blob, {
        onProgress: vi.fn(),
      })

      // Simulate timeout event
      const timeoutHandler = mockXhrInstance!.addEventListener.mock.calls.find(
        (call: [string, unknown]) => call[0] === 'timeout'
      )?.[1] as () => void

      if (timeoutHandler) {
        timeoutHandler()
      }

      await expect(uploadPromise).rejects.toThrow(NetworkError)
    })

    it('should handle XHR non-success status', async () => {
      let mockXhrInstance: MockXHR
      class MockXHR {
        open = vi.fn()
        send = vi.fn()
        setRequestHeader = vi.fn()
        upload = { addEventListener: vi.fn() }
        addEventListener = vi.fn()
        readyState = 4
        status = 400
        responseText = JSON.stringify({ message: 'Bad request' })
        constructor() {
          mockXhrInstance = this
        }
      }

      vi.stubGlobal('XMLHttpRequest', MockXHR)

      const blob = new Blob(['test content'], { type: 'text/plain' })

      const uploadPromise = storage.upload(blob, {
        onProgress: vi.fn(),
      })

      // Simulate load event with error status
      const loadHandler = mockXhrInstance!.addEventListener.mock.calls.find(
        (call: [string, unknown]) => call[0] === 'load'
      )?.[1] as () => void

      if (loadHandler) {
        loadHandler()
      }

      await expect(uploadPromise).rejects.toThrow(SwiftBaseError)
    })
  })

  describe('getFile', () => {
    it('should get file metadata', async () => {
      const mockFile: FileMetadata = {
        id: 'file_123',
        filename: 'test.txt',
        originalName: 'test.txt',
        contentType: 'text/plain',
        size: 100,
        metadata: {},
        createdAt: new Date().toISOString(),
      }

      mockHttpClient.request = vi.fn().mockResolvedValue({ success: true, file: mockFile })

      const result = await storage.getFile('file_123')

      expect(result).toEqual(mockFile)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/storage/files/file_123',
        })
      )
    })

    it('should throw NotFoundError for missing file', async () => {
      const error = new SwiftBaseError('Not found', 404)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(storage.getFile('missing_file')).rejects.toThrow(NotFoundError)
    })

    it('should rethrow other errors', async () => {
      const error = new SwiftBaseError('Server error', 500)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(storage.getFile('file_123')).rejects.toThrow(SwiftBaseError)
    })
  })

  describe('getFileUrl', () => {
    it('should return correct file URL', () => {
      const url = storage.getFileUrl('file_123')
      expect(url).toBe('http://localhost:8090/api/storage/files/file_123/download')
    })

    it('should handle different base URLs', () => {
      const customStorage = new Storage(mockHttpClient as HttpClient, 'https://api.example.com')
      const url = customStorage.getFileUrl('abc_456')
      expect(url).toBe('https://api.example.com/api/storage/files/abc_456/download')
    })
  })

  describe('download', () => {
    it('should download file as Blob', async () => {
      const mockBlob = new Blob(['file content'], { type: 'text/plain' })
      const mockResponse = {
        ok: true,
        status: 200,
        blob: vi.fn().mockResolvedValue(mockBlob),
      }

      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      const result = await storage.download('file_123')

      expect(result).toBe(mockBlob)
      expect(fetch).toHaveBeenCalledWith(
        'http://localhost:8090/api/storage/files/file_123/download',
        expect.objectContaining({
          method: 'GET',
          headers: expect.objectContaining({
            Authorization: 'Bearer test_token',
          }),
        })
      )
    })

    it('should throw NotFoundError for missing file', async () => {
      const mockResponse = {
        ok: false,
        status: 404,
      }

      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      await expect(storage.download('missing_file')).rejects.toThrow(NotFoundError)
    })

    it('should throw SwiftBaseError for other errors', async () => {
      const mockResponse = {
        ok: false,
        status: 500,
      }

      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      await expect(storage.download('file_123')).rejects.toThrow(SwiftBaseError)
    })

    it('should support abort signal', async () => {
      const controller = new AbortController()
      const mockBlob = new Blob(['file content'], { type: 'text/plain' })
      const mockResponse = {
        ok: true,
        status: 200,
        blob: vi.fn().mockResolvedValue(mockBlob),
      }

      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      await storage.download('file_123', controller.signal)

      expect(fetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          signal: controller.signal,
        })
      )
    })

    it('should not add auth header when no token', async () => {
      mockHttpClient.getAuthHeader = vi.fn(() => null)
      const storageNoAuth = new Storage(mockHttpClient as HttpClient, 'http://localhost:8090')

      const mockBlob = new Blob(['file content'], { type: 'text/plain' })
      const mockResponse = {
        ok: true,
        status: 200,
        blob: vi.fn().mockResolvedValue(mockBlob),
      }

      vi.stubGlobal('fetch', vi.fn().mockResolvedValue(mockResponse))

      await storageNoAuth.download('file_123')

      expect(fetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: {},
        })
      )
    })
  })

  describe('list', () => {
    it('should list files', async () => {
      const mockFiles: FileMetadata[] = [
        {
          id: 'file_1',
          filename: 'test1.txt',
          originalName: 'test1.txt',
          contentType: 'text/plain',
          size: 100,
          metadata: {},
          createdAt: new Date().toISOString(),
        },
        {
          id: 'file_2',
          filename: 'test2.txt',
          originalName: 'test2.txt',
          contentType: 'text/plain',
          size: 200,
          metadata: {},
          createdAt: new Date().toISOString(),
        },
      ]

      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        files: mockFiles,
        total: 2,
      })

      const result = await storage.list()

      expect(result.files).toEqual(mockFiles)
      expect(result.total).toBe(2)
      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/storage/files',
        })
      )
    })

    it('should list files with search', async () => {
      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        files: [],
        total: 0,
      })

      await storage.list({ search: 'product' })

      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/storage/files?search=product',
        })
      )
    })

    it('should list files with pagination', async () => {
      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        files: [],
        total: 100,
      })

      await storage.list({ limit: 20, offset: 40 })

      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/storage/files?limit=20&offset=40',
        })
      )
    })

    it('should list files with all options', async () => {
      mockHttpClient.request = vi.fn().mockResolvedValue({
        success: true,
        files: [],
        total: 0,
      })

      await storage.list({ search: 'image', limit: 10, offset: 0 })

      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          url: '/api/storage/files?search=image&limit=10&offset=0',
        })
      )
    })
  })

  describe('delete', () => {
    it('should delete a file', async () => {
      mockHttpClient.request = vi.fn().mockResolvedValue({ success: true })

      await storage.delete('file_123')

      expect(mockHttpClient.request).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'DELETE',
          url: '/api/storage/files/file_123',
        })
      )
    })

    it('should throw NotFoundError for missing file', async () => {
      const error = new SwiftBaseError('Not found', 404)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(storage.delete('missing_file')).rejects.toThrow(NotFoundError)
    })

    it('should rethrow other errors', async () => {
      const error = new SwiftBaseError('Server error', 500)
      mockHttpClient.request = vi.fn().mockRejectedValue(error)

      await expect(storage.delete('file_123')).rejects.toThrow(SwiftBaseError)
    })
  })
})
