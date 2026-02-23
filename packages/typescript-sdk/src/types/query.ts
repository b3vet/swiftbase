/**
 * MongoDB-style comparison operators
 */
export interface ComparisonOperators<T = unknown> {
  $eq?: T
  $ne?: T
  $gt?: T
  $gte?: T
  $lt?: T
  $lte?: T
  $in?: T[]
  $nin?: T[]
  $exists?: boolean
  $regex?: string
}

/**
 * Logical operators for where clause
 */
export interface LogicalOperators {
  $and?: WhereClause[]
  $or?: WhereClause[]
  $not?: WhereClause
}

/**
 * Where clause with field conditions and operators
 */
export type WhereClause = {
  [field: string]: unknown | ComparisonOperators
} & LogicalOperators

/**
 * Order by direction
 */
export type OrderDirection = 'asc' | 'desc'

/**
 * Order by clause
 */
export type OrderByClause = Record<string, OrderDirection>

/**
 * Query options for find operations
 */
export interface QueryOptions {
  where?: WhereClause
  orderBy?: OrderByClause
  limit?: number
  offset?: number
  select?: string[]
}

/**
 * Update operators for modify operations
 */
export interface UpdateOperators {
  $set?: Record<string, unknown>
  $unset?: Record<string, true>
  $inc?: Record<string, number>
  $push?: Record<string, unknown>
  $pull?: Record<string, unknown>
  $addToSet?: Record<string, unknown>
}

/**
 * Query action types
 */
export type QueryAction = 'find' | 'findOne' | 'create' | 'update' | 'delete' | 'count' | 'custom'

/**
 * Query request structure (matches server API)
 */
export interface QueryRequest {
  action: QueryAction
  collection: string
  query?: QueryOptions | undefined
  data?: Record<string, unknown> | UpdateOperators | undefined
  custom?: string | undefined
  params?: Record<string, unknown> | undefined
}

/**
 * Query response structure
 */
export interface QueryResponse<T = unknown> {
  success: boolean
  data: T
  count?: number
}

/**
 * Bulk operation item
 */
export interface BulkOperation {
  action: 'create' | 'update' | 'delete'
  data?: Record<string, unknown> | UpdateOperators
  where?: WhereClause
}

/**
 * Bulk operation result
 */
export interface BulkResult {
  success: boolean
  results: Array<{
    success: boolean
    data?: unknown
    error?: string
  }>
}

/**
 * Document with standard fields
 */
export interface Document {
  id: string
  createdAt: string
  updatedAt: string
  [key: string]: unknown
}
