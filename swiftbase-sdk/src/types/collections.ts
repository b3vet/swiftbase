/**
 * Collection schema definition
 */
export interface CollectionSchema {
  [field: string]: {
    type: 'string' | 'number' | 'boolean' | 'object' | 'array'
    required?: boolean
    default?: unknown
  }
}

/**
 * Collection index definition
 */
export interface CollectionIndex {
  fields: string[]
  unique?: boolean
}

/**
 * Collection definition
 */
export interface Collection {
  id: string
  name: string
  schema?: CollectionSchema
  indexes?: Record<string, CollectionIndex>
  createdAt: string
  updatedAt: string
}

/**
 * Create collection request
 */
export interface CreateCollectionRequest {
  name: string
  schema?: CollectionSchema
  indexes?: Record<string, CollectionIndex>
}

/**
 * Update collection request
 */
export interface UpdateCollectionRequest {
  schema?: CollectionSchema
  indexes?: Record<string, CollectionIndex>
}

/**
 * Collection statistics
 */
export interface CollectionStats {
  documentCount: number
  storageSize: number
  avgDocumentSize: number
}
