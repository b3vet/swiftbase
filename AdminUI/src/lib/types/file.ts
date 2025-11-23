// File Storage types
export interface FileMetadata {
  id: string
  filename: string
  original_name: string
  content_type: string
  size: number
  url: string
  created_at: string
}

export interface UploadFileRequest {
  file: File
  metadata?: Record<string, any>
}

export interface UploadFileResponse {
  success: boolean
  data?: FileMetadata
  error?: string
}

export interface FileListQuery {
  limit?: number
  offset?: number
  search?: string
  content_type?: string
}
