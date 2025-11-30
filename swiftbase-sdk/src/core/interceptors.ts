/**
 * Request configuration passed to interceptors
 */
export interface RequestConfig {
  url: string
  method: string
  headers: Headers
  body?: unknown | undefined
  signal?: AbortSignal | undefined
}

/**
 * Response wrapper for interceptors
 */
export interface ResponseWrapper<T = unknown> {
  status: number
  headers: Headers
  data: T
  ok: boolean
}

/**
 * Request interceptor function
 */
export type RequestInterceptor = (
  config: RequestConfig
) => RequestConfig | Promise<RequestConfig>

/**
 * Response interceptor function
 */
export type ResponseInterceptor<T = unknown> = (
  response: ResponseWrapper<T>
) => ResponseWrapper<T> | Promise<ResponseWrapper<T>>

/**
 * Error interceptor function
 */
export type ErrorInterceptor = (
  error: Error
) => Error | Promise<Error>

/**
 * Interceptor manager for request/response pipeline
 */
export class InterceptorManager<T> {
  private handlers: Array<{
    fulfilled: T
    rejected?: ErrorInterceptor | undefined
  }> = []

  /**
   * Add a new interceptor
   * @param fulfilled - Success handler
   * @param rejected - Error handler (optional)
   * @returns ID to use for removing the interceptor
   */
  use(fulfilled: T, rejected?: ErrorInterceptor): number {
    this.handlers.push({ fulfilled, rejected })
    return this.handlers.length - 1
  }

  /**
   * Remove an interceptor by ID
   */
  eject(id: number): void {
    if (this.handlers[id]) {
      // @ts-expect-error - Setting to null to maintain indices
      this.handlers[id] = null
    }
  }

  /**
   * Clear all interceptors
   */
  clear(): void {
    this.handlers = []
  }

  /**
   * Execute all interceptors in sequence
   */
  async execute<V>(
    initial: V,
    transform: (handler: T, value: V) => V | Promise<V>
  ): Promise<V> {
    let result = initial

    for (const handler of this.handlers) {
      if (handler) {
        try {
          result = await transform(handler.fulfilled, result)
        } catch (error) {
          if (handler.rejected) {
            throw await handler.rejected(error as Error)
          }
          throw error
        }
      }
    }

    return result
  }

  /**
   * Get all handlers (for iteration)
   */
  getHandlers(): Array<{ fulfilled: T; rejected?: ErrorInterceptor | undefined }> {
    return this.handlers.filter(Boolean)
  }
}

/**
 * Interceptors container for the HTTP client
 */
export interface Interceptors {
  request: InterceptorManager<RequestInterceptor>
  response: InterceptorManager<ResponseInterceptor>
}

/**
 * Create a new interceptors container
 */
export function createInterceptors(): Interceptors {
  return {
    request: new InterceptorManager<RequestInterceptor>(),
    response: new InterceptorManager<ResponseInterceptor>(),
  }
}
