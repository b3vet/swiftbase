import type { HttpClient } from '../../core/http.js'
import type {
  FileMetadata,
  UploadOptions,
  UploadProgress,
  FileListOptions,
  FileListResponse,
} from '../../types/storage.js'
import { API_ENDPOINTS } from '../../utils/constants.js'
import { NetworkError, NotFoundError, SwiftBaseError } from '../../core/errors.js'

/**
 * Type for file input - works in both browser and Node.js
 */
export type FileInput = File | Blob | ArrayBuffer | Uint8Array

/**
 * Raw file metadata from server (snake_case)
 * @internal
 */
interface RawFileMetadata {
  id: string
  filename: string
  original_name: string
  content_type?: string
  size: number
  url: string
  created_at: string
}

/**
 * Transform raw server response to SDK FileMetadata
 */
function transformFileMetadata(raw: RawFileMetadata): FileMetadata {
  return {
    id: raw.id,
    filename: raw.filename,
    originalName: raw.original_name,
    contentType: raw.content_type,
    size: raw.size,
    url: raw.url,
    createdAt: raw.created_at,
  }
}

/**
 * Internal response type from server
 */
interface UploadResponse {
  success: boolean
  data: RawFileMetadata
}

interface FileResponse {
  success: boolean
  data: RawFileMetadata
}

interface ListResponse {
  success: boolean
  data: RawFileMetadata[]
  total: number
}

interface DeleteResponse {
  success: boolean
  message?: string | undefined
}

/**
 * Storage module for file upload/download operations
 */
export class Storage {
  private readonly httpClient: HttpClient
  private readonly baseUrl: string

  constructor(httpClient: HttpClient, baseUrl: string) {
    this.httpClient = httpClient
    this.baseUrl = baseUrl
  }

  /**
   * Upload a file
   *
   * @example
   * // Browser - from file input
   * const file = await sb.storage.upload(fileInput.files[0])
   *
   * // Browser - from Blob
   * const blob = new Blob(['content'], { type: 'text/plain' })
   * const file = await sb.storage.upload(blob, { metadata: { name: 'test.txt' } })
   *
   * // With progress tracking
   * const file = await sb.storage.upload(fileInput.files[0], {
   *   onProgress: (progress) => console.log(`${progress.percentage}%`)
   * })
   *
   * // With abort support
   * const controller = new AbortController()
   * const file = await sb.storage.upload(fileInput.files[0], {
   *   signal: controller.signal
   * })
   * // To abort: controller.abort()
   */
  async upload(file: FileInput, options: UploadOptions = {}): Promise<FileMetadata> {
    const { metadata, onProgress, signal } = options

    // Get filename and content type from File object, or use defaults
    const filename = file instanceof File ? file.name : 'file.bin'
    const contentType = file instanceof File ? (file.type || 'application/octet-stream') :
                        file instanceof Blob ? (file.type || 'application/octet-stream') :
                        'application/octet-stream'

    // Convert input to Blob if needed
    const blob = this.toBlob(file)

    // Build headers for raw binary upload
    const headers: Record<string, string> = {
      'Content-Type': contentType,
      'X-Filename': filename,
    }

    // Add metadata as header if provided
    if (metadata) {
      headers['X-Metadata'] = JSON.stringify(metadata)
    }

    // Use XMLHttpRequest for progress tracking if callback provided
    if (onProgress) {
      return this.uploadWithProgress(blob, filename, contentType, metadata, onProgress, signal)
    }

    // Standard fetch upload - send raw binary
    const response = await this.httpClient.request<UploadResponse>({
      method: 'POST',
      url: API_ENDPOINTS.STORAGE_UPLOAD,
      body: blob,
      signal,
      headers,
    })

    return transformFileMetadata(response.data)
  }

  /**
   * Upload with progress tracking using XMLHttpRequest
   */
  private uploadWithProgress(
    blob: Blob,
    filename: string,
    contentType: string,
    metadata: Record<string, unknown> | undefined,
    onProgress: (progress: UploadProgress) => void,
    signal?: AbortSignal | undefined
  ): Promise<FileMetadata> {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      const url = `${this.baseUrl}${API_ENDPOINTS.STORAGE_UPLOAD}`

      // Handle abort signal
      if (signal) {
        if (signal.aborted) {
          reject(new NetworkError('Upload aborted', 'ABORTED'))
          return
        }
        signal.addEventListener('abort', () => {
          xhr.abort()
        })
      }

      // Track upload progress
      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) {
          onProgress({
            loaded: event.loaded,
            total: event.total,
            percentage: Math.round((event.loaded / event.total) * 100),
          })
        }
      })

      // Handle completion
      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            const response = JSON.parse(xhr.responseText) as UploadResponse
            resolve(transformFileMetadata(response.data))
          } catch {
            reject(new SwiftBaseError('Invalid response from server', xhr.status, 'UPLOAD_ERROR'))
          }
        } else {
          try {
            const error = JSON.parse(xhr.responseText) as { message?: string }
            reject(new SwiftBaseError(error.message || 'Upload failed', xhr.status, 'UPLOAD_ERROR'))
          } catch {
            reject(new SwiftBaseError('Upload failed', xhr.status, 'UPLOAD_ERROR'))
          }
        }
      })

      // Handle errors
      xhr.addEventListener('error', () => {
        reject(new NetworkError('Network error during upload', 'NETWORK_ERROR'))
      })

      xhr.addEventListener('abort', () => {
        reject(new NetworkError('Upload aborted', 'ABORTED'))
      })

      xhr.addEventListener('timeout', () => {
        reject(new NetworkError('Upload timed out', 'TIMEOUT'))
      })

      // Open request
      xhr.open('POST', url)

      // Set auth header if available
      const authHeader = this.httpClient.getAuthHeader()
      if (authHeader) {
        xhr.setRequestHeader('Authorization', authHeader)
      }

      // Set file info headers (backend expects these for raw binary uploads)
      xhr.setRequestHeader('Content-Type', contentType)
      xhr.setRequestHeader('X-Filename', filename)

      // Set metadata header if provided
      if (metadata) {
        xhr.setRequestHeader('X-Metadata', JSON.stringify(metadata))
      }

      // Send raw binary data
      xhr.send(blob)
    })
  }

  /**
   * Get file metadata
   *
   * @example
   * const fileInfo = await sb.storage.getFile('file_123')
   * console.log(fileInfo.filename, fileInfo.size)
   */
  async getFile(fileId: string): Promise<FileMetadata> {
    try {
      const response = await this.httpClient.request<FileResponse>({
        method: 'GET',
        url: `${API_ENDPOINTS.STORAGE_FILES}/${fileId}`,
      })
      return transformFileMetadata(response.data)
    } catch (error) {
      if (error instanceof SwiftBaseError && error.status === 404) {
        throw new NotFoundError(`File not found: ${fileId}`)
      }
      throw error
    }
  }

  /**
   * Get the URL for a file (for direct access)
   *
   * @example
   * const url = sb.storage.getFileUrl('file_123')
   * // Use in img src, download link, etc.
   */
  getFileUrl(fileId: string): string {
    return `${this.baseUrl}${API_ENDPOINTS.STORAGE_FILES}/${fileId}/download`
  }

  /**
   * Download a file
   * Returns Blob in browser, ArrayBuffer in Node.js
   *
   * @example
   * const data = await sb.storage.download('file_123')
   * // Browser: data is Blob
   * // Node.js: data is ArrayBuffer
   */
  async download(fileId: string, signal?: AbortSignal | undefined): Promise<Blob | ArrayBuffer> {
    const url = this.getFileUrl(fileId)
    const authHeader = this.httpClient.getAuthHeader()

    const headers: Record<string, string> = {}
    if (authHeader) {
      headers['Authorization'] = authHeader
    }

    const fetchOptions: RequestInit = {
      method: 'GET',
      headers,
    }

    // Only add signal if provided (avoid undefined in RequestInit)
    if (signal) {
      fetchOptions.signal = signal
    }

    const response = await fetch(url, fetchOptions)

    if (!response.ok) {
      if (response.status === 404) {
        throw new NotFoundError(`File not found: ${fileId}`)
      }
      throw new SwiftBaseError('Download failed', response.status, 'DOWNLOAD_ERROR')
    }

    // Return appropriate type based on environment
    if (typeof Blob !== 'undefined') {
      return response.blob()
    }
    return response.arrayBuffer()
  }

  /**
   * List files with optional search and pagination
   *
   * @example
   * // List all files
   * const { files, total } = await sb.storage.list()
   *
   * // Search files
   * const { files } = await sb.storage.list({ search: 'product' })
   *
   * // Paginate
   * const { files } = await sb.storage.list({ limit: 20, offset: 40 })
   */
  async list(options: FileListOptions = {}): Promise<FileListResponse> {
    const params = new URLSearchParams()

    if (options.search) {
      params.append('search', options.search)
    }
    if (options.limit !== undefined) {
      params.append('limit', options.limit.toString())
    }
    if (options.offset !== undefined) {
      params.append('offset', options.offset.toString())
    }

    const queryString = params.toString()
    const url = queryString
      ? `${API_ENDPOINTS.STORAGE_FILES}?${queryString}`
      : API_ENDPOINTS.STORAGE_FILES

    const response = await this.httpClient.request<ListResponse>({
      method: 'GET',
      url,
    })

    return {
      files: response.data.map(transformFileMetadata),
      total: response.total,
    }
  }

  /**
   * Delete a file
   *
   * @example
   * await sb.storage.delete('file_123')
   */
  async delete(fileId: string): Promise<void> {
    try {
      await this.httpClient.request<DeleteResponse>({
        method: 'DELETE',
        url: `${API_ENDPOINTS.STORAGE_FILES}/${fileId}`,
      })
    } catch (error) {
      if (error instanceof SwiftBaseError && error.status === 404) {
        throw new NotFoundError(`File not found: ${fileId}`)
      }
      throw error
    }
  }

  /**
   * Convert various input types to Blob
   */
  private toBlob(input: FileInput): Blob {
    // Already a Blob or File
    if (input instanceof Blob) {
      return input
    }

    // ArrayBuffer
    if (input instanceof ArrayBuffer) {
      return new Blob([input])
    }

    // Uint8Array - create a copy to avoid SharedArrayBuffer issues
    if (input instanceof Uint8Array) {
      const copy = new Uint8Array(input)
      return new Blob([copy.buffer as ArrayBuffer])
    }

    // Fallback - should not reach here with TypeScript
    return new Blob([input as BlobPart])
  }
}
