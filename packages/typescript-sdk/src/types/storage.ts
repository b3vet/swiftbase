/**
 * File metadata from server
 */
export interface FileMetadata {
  id: string
  filename: string
  originalName: string
  contentType?: string | undefined
  size: number
  url: string
  createdAt: string
}

/**
 * Upload progress information
 */
export interface UploadProgress {
  loaded: number
  total: number
  percentage: number
}

/**
 * Upload options
 */
export interface UploadOptions {
  /** Custom metadata for the file */
  metadata?: Record<string, unknown>
  /** Progress callback */
  onProgress?: (progress: UploadProgress) => void
  /** Abort signal */
  signal?: AbortSignal
}

/**
 * File list options
 */
export interface FileListOptions {
  /** Search query */
  search?: string
  /** Maximum number of files to return */
  limit?: number
  /** Offset for pagination */
  offset?: number
}

/**
 * File list response
 */
export interface FileListResponse {
  files: FileMetadata[]
  total: number
}
