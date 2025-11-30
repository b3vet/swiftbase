import { NetworkError, parseErrorResponse, SwiftBaseError } from './errors.js'
import {
  createInterceptors,
  type Interceptors,
  type RequestConfig,
  type ResponseWrapper,
} from './interceptors.js'
import { DEFAULT_RETRY_CONFIG, withRetry, type RetryConfig } from './retry.js'

/**
 * HTTP method types
 */
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'

/**
 * HTTP client options
 */
export interface HttpClientOptions {
  /** Base URL for all requests */
  baseUrl: string
  /** Default timeout in ms */
  timeout?: number | undefined
  /** Retry configuration */
  retry?: Partial<RetryConfig> | false | undefined
  /** Default headers */
  headers?: Record<string, string> | undefined
}

/**
 * Request options for individual requests
 */
export interface HttpRequestOptions {
  /** Request timeout in ms */
  timeout?: number
  /** Request headers */
  headers?: Record<string, string>
  /** Abort signal */
  signal?: AbortSignal
  /** Skip retry for this request */
  skipRetry?: boolean
}

/**
 * HTTP client with interceptors, timeout, and retry support
 */
export class HttpClient {
  private baseUrl: string
  private timeout: number
  private retryConfig: Partial<RetryConfig> | false
  private defaultHeaders: Record<string, string>
  public readonly interceptors: Interceptors

  constructor(options: HttpClientOptions) {
    this.baseUrl = options.baseUrl.replace(/\/$/, '')
    this.timeout = options.timeout ?? 30000
    this.retryConfig = options.retry ?? {}
    this.defaultHeaders = options.headers ?? {}
    this.interceptors = createInterceptors()
  }

  /**
   * Set authorization header
   */
  setAuthHeader(token: string | null): void {
    if (token) {
      this.defaultHeaders['Authorization'] = `Bearer ${token}`
    } else {
      delete this.defaultHeaders['Authorization']
    }
  }

  /**
   * Get the current authorization header value
   */
  getAuthHeader(): string | null {
    return this.defaultHeaders['Authorization'] ?? null
  }

  /**
   * Get the base URL
   */
  getBaseUrl(): string {
    return this.baseUrl
  }

  /**
   * Get full URL for a path
   */
  private getUrl(path: string): string {
    const cleanPath = path.startsWith('/') ? path : `/${path}`
    return `${this.baseUrl}${cleanPath}`
  }

  /**
   * Merge headers
   */
  private mergeHeaders(custom?: Record<string, string>): Headers {
    const headers = new Headers()

    // Add default headers
    for (const [key, value] of Object.entries(this.defaultHeaders)) {
      headers.set(key, value)
    }

    // Add custom headers
    if (custom) {
      for (const [key, value] of Object.entries(custom)) {
        headers.set(key, value)
      }
    }

    return headers
  }

  /**
   * Create an abort controller with timeout
   */
  private createAbortController(
    timeout: number,
    signal?: AbortSignal
  ): { controller: AbortController; cleanup: () => void } {
    const controller = new AbortController()

    // Set up timeout
    const timeoutId = setTimeout(() => {
      controller.abort(new Error('Request timeout'))
    }, timeout)

    // Forward external abort signal
    if (signal) {
      if (signal.aborted) {
        controller.abort(signal.reason)
      } else {
        signal.addEventListener('abort', () => {
          controller.abort(signal.reason)
        })
      }
    }

    return {
      controller,
      cleanup: () => clearTimeout(timeoutId),
    }
  }

  /**
   * Execute HTTP request
   */
  private async execute<T>(
    method: HttpMethod,
    path: string,
    body?: unknown,
    options?: HttpRequestOptions
  ): Promise<T> {
    const url = this.getUrl(path)
    const headers = this.mergeHeaders(options?.headers)
    const timeout = options?.timeout ?? this.timeout

    // Set content type for JSON body
    if (body !== undefined && !headers.has('Content-Type')) {
      headers.set('Content-Type', 'application/json')
    }

    // Build request config
    let config: RequestConfig = {
      url,
      method,
      headers,
      body,
      signal: options?.signal,
    }

    // Run request interceptors
    config = await this.interceptors.request.execute(config, async (interceptor, cfg) => {
      return await interceptor(cfg)
    })

    // Create abort controller with timeout
    const { controller, cleanup } = this.createAbortController(timeout, config.signal)

    const doRequest = async (): Promise<ResponseWrapper<T>> => {
      try {
        const response = await fetch(config.url, {
          method: config.method,
          headers: config.headers,
          body: config.body !== undefined ? JSON.stringify(config.body) : null,
          signal: controller.signal,
        })

        // Parse response body
        let data: T
        const contentType = response.headers.get('Content-Type')

        if (contentType?.includes('application/json')) {
          data = await response.json() as T
        } else {
          data = await response.text() as T
        }

        // Build response wrapper
        const wrapper: ResponseWrapper<T> = {
          status: response.status,
          headers: response.headers,
          data,
          ok: response.ok,
        }

        // Run response interceptors
        const processed = await this.interceptors.response.execute(
          wrapper as ResponseWrapper,
          async (interceptor, resp) => {
            return await interceptor(resp)
          }
        ) as ResponseWrapper<T>

        // Check for error status
        if (!processed.ok) {
          throw parseErrorResponse(processed.status, processed.data)
        }

        return processed
      } catch (error) {
        // Handle abort/timeout
        if (error instanceof Error) {
          if (error.name === 'AbortError' || error.message === 'Request timeout') {
            throw new NetworkError(
              error.message === 'Request timeout' ? 'Request timed out' : 'Request aborted',
              error.message === 'Request timeout' ? 'TIMEOUT' : 'ABORTED'
            )
          }

          // Handle network errors
          if (error.message === 'Failed to fetch' || error.message.includes('network')) {
            throw new NetworkError('Network error', 'NETWORK_ERROR')
          }
        }

        // Re-throw SwiftBase errors
        if (error instanceof SwiftBaseError) {
          throw error
        }

        // Wrap unknown errors
        throw new NetworkError(
          error instanceof Error ? error.message : 'Unknown error',
          'NETWORK_ERROR'
        )
      }
    }

    try {
      // Execute with or without retry
      let result: ResponseWrapper<T>

      if (options?.skipRetry || this.retryConfig === false) {
        result = await doRequest()
      } else {
        result = await withRetry(doRequest, {
          ...DEFAULT_RETRY_CONFIG,
          ...(this.retryConfig as Partial<RetryConfig>),
        })
      }

      return result.data
    } finally {
      cleanup()
    }
  }

  /**
   * GET request
   */
  async get<T>(path: string, options?: HttpRequestOptions): Promise<T> {
    return this.execute<T>('GET', path, undefined, options)
  }

  /**
   * POST request
   */
  async post<T>(path: string, body?: unknown, options?: HttpRequestOptions): Promise<T> {
    return this.execute<T>('POST', path, body, options)
  }

  /**
   * PUT request
   */
  async put<T>(path: string, body?: unknown, options?: HttpRequestOptions): Promise<T> {
    return this.execute<T>('PUT', path, body, options)
  }

  /**
   * PATCH request
   */
  async patch<T>(path: string, body?: unknown, options?: HttpRequestOptions): Promise<T> {
    return this.execute<T>('PATCH', path, body, options)
  }

  /**
   * DELETE request
   */
  async delete<T>(path: string, options?: HttpRequestOptions): Promise<T> {
    return this.execute<T>('DELETE', path, undefined, options)
  }

  /**
   * Generic request method - supports FormData for file uploads
   */
  async request<T>(options: {
    method: HttpMethod
    url: string
    body?: unknown | FormData | undefined
    headers?: Record<string, string> | undefined
    signal?: AbortSignal | undefined
    timeout?: number | undefined
  }): Promise<T> {
    const url = this.getUrl(options.url)
    const headers = this.mergeHeaders(options.headers)
    const timeout = options.timeout ?? this.timeout
    const isFormData = options.body instanceof FormData

    // Set content type for JSON body (not FormData)
    if (options.body !== undefined && !isFormData && !headers.has('Content-Type')) {
      headers.set('Content-Type', 'application/json')
    }

    // Remove Content-Type for FormData to let browser set boundary
    if (isFormData) {
      headers.delete('Content-Type')
    }

    const { controller, cleanup } = this.createAbortController(timeout, options.signal)

    try {
      const response = await fetch(url, {
        method: options.method,
        headers,
        body: isFormData
          ? options.body as FormData
          : options.body !== undefined
            ? JSON.stringify(options.body)
            : null,
        signal: controller.signal,
      })

      // Parse response body
      let data: T
      const contentType = response.headers.get('Content-Type')

      if (contentType?.includes('application/json')) {
        data = await response.json() as T
      } else {
        data = await response.text() as T
      }

      // Check for error status
      if (!response.ok) {
        throw parseErrorResponse(response.status, data)
      }

      return data
    } catch (error) {
      // Handle abort/timeout
      if (error instanceof Error) {
        if (error.name === 'AbortError' || error.message === 'Request timeout') {
          throw new NetworkError(
            error.message === 'Request timeout' ? 'Request timed out' : 'Request aborted',
            error.message === 'Request timeout' ? 'TIMEOUT' : 'ABORTED'
          )
        }

        // Handle network errors
        if (error.message === 'Failed to fetch' || error.message.includes('network')) {
          throw new NetworkError('Network error', 'NETWORK_ERROR')
        }
      }

      // Re-throw SwiftBase errors
      if (error instanceof SwiftBaseError) {
        throw error
      }

      // Wrap unknown errors
      throw new NetworkError(
        error instanceof Error ? error.message : 'Unknown error',
        'NETWORK_ERROR'
      )
    } finally {
      cleanup()
    }
  }

  /**
   * Upload file with progress tracking
   */
  async upload<T>(
    path: string,
    file: File | Blob,
    options?: HttpRequestOptions & {
      metadata?: Record<string, unknown>
      onProgress?: (loaded: number, total: number) => void
    }
  ): Promise<T> {
    const url = this.getUrl(path)
    const headers = this.mergeHeaders(options?.headers)
    const timeout = options?.timeout ?? this.timeout

    // Create form data
    const formData = new FormData()
    formData.append('file', file)

    if (options?.metadata) {
      formData.append('metadata', JSON.stringify(options.metadata))
    }

    // Remove content-type to let browser set it with boundary
    headers.delete('Content-Type')

    const { controller, cleanup } = this.createAbortController(timeout, options?.signal)

    try {
      // Use XMLHttpRequest for progress tracking in browser
      if (typeof XMLHttpRequest !== 'undefined' && options?.onProgress) {
        return await new Promise<T>((resolve, reject) => {
          const xhr = new XMLHttpRequest()

          xhr.upload.addEventListener('progress', (event) => {
            if (event.lengthComputable && options.onProgress) {
              options.onProgress(event.loaded, event.total)
            }
          })

          xhr.addEventListener('load', () => {
            if (xhr.status >= 200 && xhr.status < 300) {
              try {
                resolve(JSON.parse(xhr.responseText) as T)
              } catch {
                resolve(xhr.responseText as T)
              }
            } else {
              reject(parseErrorResponse(xhr.status, JSON.parse(xhr.responseText)))
            }
          })

          xhr.addEventListener('error', () => {
            reject(new NetworkError('Upload failed', 'NETWORK_ERROR'))
          })

          xhr.addEventListener('abort', () => {
            reject(new NetworkError('Upload aborted', 'ABORTED'))
          })

          xhr.open('POST', url)

          // Set headers
          headers.forEach((value, key) => {
            xhr.setRequestHeader(key, value)
          })

          xhr.send(formData)

          // Handle abort
          controller.signal.addEventListener('abort', () => {
            xhr.abort()
          })
        })
      }

      // Fallback to fetch (no progress tracking)
      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: formData,
        signal: controller.signal,
      })

      if (!response.ok) {
        const data = await response.json()
        throw parseErrorResponse(response.status, data)
      }

      return await response.json() as T
    } finally {
      cleanup()
    }
  }
}
