// Document types
export interface Document {
  id: string
  collection_id: string
  data: Record<string, any>
  version: number
  created_at: string
  updated_at: string
  created_by?: string
  updated_by?: string
}

export interface DocumentData {
  _id?: string
  [key: string]: any
}

export interface CreateDocumentRequest {
  data: DocumentData
}

export interface UpdateDocumentRequest {
  data: Record<string, any>
}

export interface DeleteDocumentRequest {
  id: string
}
