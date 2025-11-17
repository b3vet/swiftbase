import type {
  SubscriptionRequest,
  UnsubscribeRequest,
  RealtimeEvent,
  WebSocketMessage
} from '@lib/types'
import { ConnectionStatus } from '@lib/types'

type EventCallback = (event: RealtimeEvent) => void
type StatusCallback = (status: ConnectionStatus) => void

class RealtimeClient {
  private ws: WebSocket | null = null
  private url: string
  private reconnectAttempts = 0
  private maxReconnectAttempts = 5
  private reconnectDelay = 1000
  private heartbeatInterval: number | null = null
  private eventCallbacks: Map<string, Set<EventCallback>> = new Map()
  private statusCallbacks: Set<StatusCallback> = new Set()
  private status: ConnectionStatus = ConnectionStatus.DISCONNECTED

  constructor(url?: string) {
    const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = import.meta.env.VITE_API_URL?.replace(/^https?:\/\//, '') || 'localhost:8090'
    this.url = url || `${wsProtocol}//${host}/api/realtime`
  }

  // Connect to WebSocket server
  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      return
    }

    this.updateStatus(ConnectionStatus.CONNECTING)

    try {
      this.ws = new WebSocket(this.url)

      this.ws.onopen = this.handleOpen.bind(this)
      this.ws.onmessage = this.handleMessage.bind(this)
      this.ws.onerror = this.handleError.bind(this)
      this.ws.onclose = this.handleClose.bind(this)
    } catch (error) {
      console.error('WebSocket connection error:', error)
      this.updateStatus(ConnectionStatus.ERROR)
      this.scheduleReconnect()
    }
  }

  // Disconnect from WebSocket server
  disconnect(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
      this.heartbeatInterval = null
    }

    if (this.ws) {
      this.ws.close()
      this.ws = null
    }

    this.updateStatus(ConnectionStatus.DISCONNECTED)
    this.reconnectAttempts = 0
  }

  // Subscribe to collection changes
  subscribe(collection: string, callback: EventCallback, query?: Record<string, any>): void {
    const subscriptionKey = this.getSubscriptionKey(collection)

    if (!this.eventCallbacks.has(subscriptionKey)) {
      this.eventCallbacks.set(subscriptionKey, new Set())
    }

    this.eventCallbacks.get(subscriptionKey)!.add(callback)

    if (this.isConnected()) {
      this.send({
        action: 'subscribe',
        collection,
        query
      })
    }
  }

  // Subscribe to specific document changes
  subscribeToDocument(
    collection: string,
    documentId: string,
    callback: EventCallback
  ): void {
    const subscriptionKey = this.getSubscriptionKey(collection, documentId)

    if (!this.eventCallbacks.has(subscriptionKey)) {
      this.eventCallbacks.set(subscriptionKey, new Set())
    }

    this.eventCallbacks.get(subscriptionKey)!.add(callback)

    if (this.isConnected()) {
      this.send({
        action: 'subscribe',
        collection,
        documentId
      })
    }
  }

  // Unsubscribe from collection
  unsubscribe(collection: string, callback?: EventCallback): void {
    const subscriptionKey = this.getSubscriptionKey(collection)

    if (callback) {
      this.eventCallbacks.get(subscriptionKey)?.delete(callback)
    } else {
      this.eventCallbacks.delete(subscriptionKey)
    }

    if (this.isConnected()) {
      this.send({
        action: 'unsubscribe',
        collection
      })
    }
  }

  // Unsubscribe from document
  unsubscribeFromDocument(
    collection: string,
    documentId: string,
    callback?: EventCallback
  ): void {
    const subscriptionKey = this.getSubscriptionKey(collection, documentId)

    if (callback) {
      this.eventCallbacks.get(subscriptionKey)?.delete(callback)
    } else {
      this.eventCallbacks.delete(subscriptionKey)
    }

    if (this.isConnected()) {
      this.send({
        action: 'unsubscribe',
        collection,
        documentId
      })
    }
  }

  // Listen to connection status changes
  onStatusChange(callback: StatusCallback): () => void {
    this.statusCallbacks.add(callback)
    callback(this.status) // Call immediately with current status

    // Return unsubscribe function
    return () => {
      this.statusCallbacks.delete(callback)
    }
  }

  // Get current connection status
  getStatus(): ConnectionStatus {
    return this.status
  }

  // Check if connected
  isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN
  }

  // Send message to server
  private send(message: WebSocketMessage): void {
    if (this.isConnected()) {
      this.ws!.send(JSON.stringify(message))
    }
  }

  // Handle WebSocket open
  private handleOpen(): void {
    console.log('WebSocket connected')
    this.updateStatus(ConnectionStatus.CONNECTED)
    this.reconnectAttempts = 0

    // Start heartbeat
    this.startHeartbeat()

    // Resubscribe to all active subscriptions
    this.resubscribeAll()
  }

  // Handle WebSocket message
  private handleMessage(event: MessageEvent): void {
    try {
      const message = JSON.parse(event.data) as WebSocketMessage

      // Handle pong
      if (message.action === 'pong') {
        return
      }

      // Handle realtime event
      if (message.event) {
        this.dispatchEvent(message.event)
      }
    } catch (error) {
      console.error('Failed to parse WebSocket message:', error)
    }
  }

  // Handle WebSocket error
  private handleError(event: Event): void {
    console.error('WebSocket error:', event)
    this.updateStatus(ConnectionStatus.ERROR)
  }

  // Handle WebSocket close
  private handleClose(): void {
    console.log('WebSocket disconnected')
    this.updateStatus(ConnectionStatus.DISCONNECTED)

    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
      this.heartbeatInterval = null
    }

    this.scheduleReconnect()
  }

  // Schedule reconnection attempt
  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnection attempts reached')
      this.updateStatus(ConnectionStatus.ERROR)
      return
    }

    this.reconnectAttempts++
    this.updateStatus(ConnectionStatus.RECONNECTING)

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1)
    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`)

    setTimeout(() => {
      this.connect()
    }, delay)
  }

  // Start heartbeat to keep connection alive
  private startHeartbeat(): void {
    this.heartbeatInterval = window.setInterval(() => {
      if (this.isConnected()) {
        this.send({ action: 'ping' })
      }
    }, 30000) // 30 seconds
  }

  // Resubscribe to all active subscriptions
  private resubscribeAll(): void {
    this.eventCallbacks.forEach((_, key) => {
      const [collection, documentId] = key.split(':')

      if (documentId) {
        this.send({
          action: 'subscribe',
          collection,
          documentId
        })
      } else {
        this.send({
          action: 'subscribe',
          collection
        })
      }
    })
  }

  // Dispatch event to callbacks
  private dispatchEvent(event: RealtimeEvent): void {
    const collectionKey = this.getSubscriptionKey(event.collection)
    const documentKey = event.documentId
      ? this.getSubscriptionKey(event.collection, event.documentId)
      : null

    // Notify collection subscribers
    this.eventCallbacks.get(collectionKey)?.forEach((callback) => {
      try {
        callback(event)
      } catch (error) {
        console.error('Error in event callback:', error)
      }
    })

    // Notify document subscribers
    if (documentKey) {
      this.eventCallbacks.get(documentKey)?.forEach((callback) => {
        try {
          callback(event)
        } catch (error) {
          console.error('Error in event callback:', error)
        }
      })
    }
  }

  // Update connection status
  private updateStatus(status: ConnectionStatus): void {
    this.status = status
    this.statusCallbacks.forEach((callback) => {
      try {
        callback(status)
      } catch (error) {
        console.error('Error in status callback:', error)
      }
    })
  }

  // Get subscription key
  private getSubscriptionKey(collection: string, documentId?: string): string {
    return documentId ? `${collection}:${documentId}` : collection
  }
}

// Export singleton instance
export const realtimeClient = new RealtimeClient()

// Export class for testing or custom instances
export { RealtimeClient }
