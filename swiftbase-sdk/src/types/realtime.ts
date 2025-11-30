/**
 * Realtime connection status
 */
export type RealtimeStatus = 'connecting' | 'connected' | 'disconnected' | 'reconnecting' | 'error'

/**
 * Event types for document changes
 */
export type EventType = 'create' | 'update' | 'delete'

/**
 * Realtime event for document changes
 */
export interface RealtimeEvent<T = unknown> {
  type: EventType
  collection: string
  documentId: string
  document: T
  timestamp: string
}

/**
 * Callback for realtime events
 */
export type RealtimeCallback<T = unknown> = (event: RealtimeEvent<T>) => void

/**
 * Callback for status changes
 */
export type StatusCallback = (status: RealtimeStatus) => void

/**
 * Unsubscribe function
 */
export type Unsubscribe = () => void

/**
 * Subscription options
 */
export interface SubscriptionOptions {
  /** Filter events by type */
  events?: EventType[]
}

/**
 * Channel event handlers
 */
export interface ChannelHandlers<T = unknown> {
  create?: (document: T) => void
  update?: (document: T) => void
  delete?: (document: T) => void
  error?: (error: Error) => void
}
