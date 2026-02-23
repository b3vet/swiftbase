// Realtime WebSocket types
export type RealtimeAction = 'subscribe' | 'unsubscribe' | 'ping' | 'pong'
export type RealtimeEventType = 'create' | 'update' | 'delete'

export interface SubscriptionRequest {
  action: 'subscribe'
  collection: string
  documentId?: string
  query?: Record<string, any>
}

export interface UnsubscribeRequest {
  action: 'unsubscribe'
  collection: string
  documentId?: string
}

export interface RealtimeEvent {
  event: RealtimeEventType
  collection: string
  document: Record<string, any>
  documentId?: string
  timestamp: string
}

export interface WebSocketMessage {
  action: RealtimeAction
  collection?: string
  documentId?: string
  query?: Record<string, any>
  event?: RealtimeEvent
}

export interface Subscription {
  id: string
  collection: string
  documentId?: string
  query?: Record<string, any>
  createdAt: Date
}

export enum ConnectionStatus {
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  DISCONNECTED = 'disconnected',
  RECONNECTING = 'reconnecting',
  ERROR = 'error'
}
