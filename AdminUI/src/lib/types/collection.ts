// Collection types
export interface Collection {
  id: string
  name: string
  schema?: Record<string, any>
  indexes?: string[]
  options?: Record<string, any>
  metadata?: Record<string, any>
  documentCount?: number
  createdAt: string
  updatedAt: string
}

export interface CollectionStats {
  collection: string
  documentCount: number
  totalSize: number  // Size in bytes
  averageDocumentSize: number  // Average size per document in bytes
  indexCount: number
  oldestDocument?: string
  newestDocument?: string
}

export interface CreateCollectionRequest {
  name: string
  schema?: Record<string, any>
  indexes?: Record<string, any>
  options?: Record<string, any>
}

export interface UpdateCollectionRequest {
  schema?: Record<string, any>
  indexes?: Record<string, any>
  options?: Record<string, any>
}

export interface BulkOperation {
  action: 'create' | 'update' | 'delete'
  data?: Record<string, any>
  query?: Record<string, any>
}

export interface BulkOperationRequest {
  operations: BulkOperation[]
}

export interface BulkOperationResponse {
  success: boolean
  results: Array<{
    success: boolean
    data?: any
    error?: string
  }>
  total: number
  successful: number
  failed: number
}
