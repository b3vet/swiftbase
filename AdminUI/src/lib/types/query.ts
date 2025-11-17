// MongoDB-style Query types
export type QueryAction = 'find' | 'findOne' | 'create' | 'update' | 'delete' | 'count' | 'aggregate' | 'custom'

export interface MongoQuery {
  where?: Record<string, any>
  select?: string[] | Record<string, 0 | 1>
  include?: string[]
  orderBy?: Record<string, 'asc' | 'desc'>
  limit?: number
  offset?: number
  distinct?: string
}

export interface QueryOptions {
  upsert?: boolean
  multi?: boolean
  validate?: boolean
  returnNew?: boolean
}

export interface QueryRequest {
  action: QueryAction
  collection: string
  query?: MongoQuery
  data?: Record<string, any>
  options?: QueryOptions
  custom?: string
  params?: Record<string, any>
}

export interface QueryResult<T = any> {
  success: boolean
  data?: T | T[]
  count?: number
  error?: string
  executionTime?: number
}

// Query Operators
export type ComparisonOperator = '$eq' | '$ne' | '$gt' | '$gte' | '$lt' | '$lte' | '$in' | '$nin'
export type LogicalOperator = '$and' | '$or' | '$not'
export type ElementOperator = '$exists' | '$type'
export type EvaluationOperator = '$regex' | '$mod'
export type ArrayOperator = '$all' | '$elemMatch' | '$size'
export type UpdateOperator = '$set' | '$unset' | '$inc' | '$push' | '$pull' | '$addToSet'

export type QueryOperator =
  | ComparisonOperator
  | LogicalOperator
  | ElementOperator
  | EvaluationOperator
  | ArrayOperator
  | UpdateOperator

// Custom Query
export interface CustomQuery {
  id: string
  name: string
  sql: string
  params?: Record<string, any>
  description?: string
  created_at: string
  updated_at: string
}

export interface SavedQuery {
  id: string
  name: string
  description?: string
  query: QueryRequest
  created_at: string
}
