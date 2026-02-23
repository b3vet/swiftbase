import type {
  RealtimeStatus,
  RealtimeEvent,
  RealtimeCallback,
  StatusCallback,
  Unsubscribe,
  EventType,
} from '../../types/realtime.js'
import type { RealtimeConfig } from '../../types/client.js'
import { API_ENDPOINTS } from '../../utils/constants.js'

/**
 * Subscription entry in the registry
 */
interface Subscription {
  id: string
  collection: string
  documentId?: string | undefined
  callback: RealtimeCallback
  events?: EventType[] | undefined
}

/**
 * Outgoing message types (uses 'action' field for backend compatibility)
 */
interface WSOutgoingMessage {
  action: 'subscribe' | 'unsubscribe' | 'ping'
  subscriptionId?: string | undefined
  collection?: string | undefined
  documentId?: string | undefined
}

/**
 * Incoming protocol messages from server (uses 'type' field)
 */
interface WSProtocolMessage {
  type: 'subscribed' | 'unsubscribed' | 'pong' | 'welcome' | 'error'
  subscriptionId?: string | undefined
  collection?: string | undefined
  documentId?: string | undefined
  message?: string | undefined
  connectionId?: string | undefined
}

/**
 * Incoming data event from server (uses 'event' field for event type)
 */
interface WSDataEvent {
  event: 'create' | 'update' | 'delete'
  collection: string
  documentId: string
  document?: unknown
  timestamp?: string
}

/**
 * Union type for all incoming WebSocket messages
 */
type WSIncomingMessage = WSProtocolMessage | WSDataEvent

/**
 * WebSocket manager for realtime subscriptions
 */
export class RealtimeManager {
  private baseUrl: string
  private config: RealtimeConfig
  private ws: WebSocket | null = null
  private status: RealtimeStatus = 'disconnected'
  private subscriptions: Map<string, Subscription> = new Map()
  private statusListeners: Set<StatusCallback> = new Set()
  private reconnectAttempts: number = 0
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null
  private pingTimer: ReturnType<typeof setInterval> | null = null
  private authToken: string | null = null
  private pendingSubscriptions: Subscription[] = []

  constructor(baseUrl: string, config: RealtimeConfig) {
    this.baseUrl = baseUrl.replace(/^http/, 'ws')
    this.config = config
  }

  /**
   * Set authentication token for WebSocket
   * Token is passed via URL query parameter at connection time
   */
  setAuthToken(token: string | null): void {
    const tokenChanged = this.authToken !== token
    this.authToken = token
    // Reconnect if token changed and we're currently connected
    if (tokenChanged && this.status === 'connected') {
      this.disconnect()
      this.connect()
    }
  }

  /**
   * Get current connection status
   */
  getStatus(): RealtimeStatus {
    return this.status
  }

  /**
   * Connect to WebSocket server
   */
  connect(): void {
    if (this.ws && (this.status === 'connected' || this.status === 'connecting')) {
      return
    }

    this.setStatus('connecting')

    // Build WebSocket URL with optional token
    let wsUrl = `${this.baseUrl}${API_ENDPOINTS.REALTIME}`
    if (this.authToken) {
      wsUrl += `?token=${encodeURIComponent(this.authToken)}`
    }

    try {
      this.ws = new WebSocket(wsUrl)
      this.setupEventHandlers()
    } catch (error) {
      this.setStatus('error')
      this.scheduleReconnect()
    }
  }

  /**
   * Disconnect from WebSocket server
   */
  disconnect(): void {
    this.stopReconnectTimer()
    this.stopPingTimer()

    if (this.ws) {
      this.ws.close(1000, 'Client disconnect')
      this.ws = null
    }

    this.setStatus('disconnected')
  }

  /**
   * Subscribe to collection events (callback style)
   */
  subscribe<T = unknown>(
    collection: string,
    callback: RealtimeCallback<T>
  ): Unsubscribe

  /**
   * Subscribe to document events (callback style)
   */
  subscribe<T = unknown>(
    collection: string,
    documentId: string,
    callback: RealtimeCallback<T>
  ): Unsubscribe

  subscribe<T = unknown>(
    collection: string,
    documentIdOrCallback: string | RealtimeCallback<T>,
    maybeCallback?: RealtimeCallback<T>
  ): Unsubscribe {
    const documentId = typeof documentIdOrCallback === 'string' ? documentIdOrCallback : undefined
    const callback = (typeof documentIdOrCallback === 'function'
      ? documentIdOrCallback
      : maybeCallback) as RealtimeCallback

    const id = this.generateSubscriptionId()
    const subscription: Subscription = {
      id,
      collection,
      documentId,
      callback,
    }

    this.subscriptions.set(id, subscription)

    // Auto-connect if configured
    if (this.config.autoConnect && this.status === 'disconnected') {
      this.connect()
    }

    // Send subscription if connected, otherwise queue it
    if (this.status === 'connected') {
      this.sendSubscription(subscription)
    } else {
      this.pendingSubscriptions.push(subscription)
    }

    // Return unsubscribe function
    return () => this.unsubscribe(id)
  }

  /**
   * Create a channel for event emitter style subscriptions
   */
  channel<T = unknown>(collection: string, documentId?: string): RealtimeChannel<T> {
    return new RealtimeChannel<T>(this, collection, documentId)
  }

  /**
   * Listen to connection status changes
   */
  onStatusChange(callback: StatusCallback): Unsubscribe {
    this.statusListeners.add(callback)
    return () => this.statusListeners.delete(callback)
  }

  /**
   * Unsubscribe by ID
   */
  private unsubscribe(id: string): void {
    const subscription = this.subscriptions.get(id)
    if (!subscription) return

    this.subscriptions.delete(id)

    // Remove from pending if not yet subscribed
    this.pendingSubscriptions = this.pendingSubscriptions.filter(s => s.id !== id)

    // Send unsubscribe message if connected
    if (this.status === 'connected' && this.ws) {
      this.sendMessage({
        action: 'unsubscribe',
        subscriptionId: id,
      })
    }
  }

  /**
   * Set up WebSocket event handlers
   */
  private setupEventHandlers(): void {
    if (!this.ws) return

    this.ws.onopen = () => {
      this.setStatus('connected')
      this.reconnectAttempts = 0

      // Send pending subscriptions
      for (const subscription of this.pendingSubscriptions) {
        this.sendSubscription(subscription)
      }
      this.pendingSubscriptions = []

      // Re-subscribe existing subscriptions (after reconnect)
      for (const subscription of this.subscriptions.values()) {
        this.sendSubscription(subscription)
      }

      // Start ping timer
      this.startPingTimer()
    }

    this.ws.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data as string) as WSIncomingMessage
        this.handleMessage(message)
      } catch {
        // Ignore invalid messages
      }
    }

    this.ws.onerror = () => {
      this.setStatus('error')
    }

    this.ws.onclose = (event) => {
      this.ws = null
      this.stopPingTimer()

      // Don't reconnect if closed intentionally
      if (event.code === 1000) {
        this.setStatus('disconnected')
        return
      }

      // Attempt reconnect if configured
      if (this.config.reconnect) {
        this.scheduleReconnect()
      } else {
        this.setStatus('disconnected')
      }
    }
  }

  /**
   * Handle incoming WebSocket message
   */
  private handleMessage(message: WSIncomingMessage): void {
    // Check if it's a data event (has 'event' field with create/update/delete)
    if ('event' in message && (message.event === 'create' || message.event === 'update' || message.event === 'delete')) {
      const dataEvent = message as WSDataEvent
      this.dispatchEvent({
        type: dataEvent.event,
        collection: dataEvent.collection,
        documentId: dataEvent.documentId,
        document: dataEvent.document,
        timestamp: dataEvent.timestamp,
      })
      return
    }

    // Handle protocol messages (has 'type' field)
    const protocolMessage = message as WSProtocolMessage
    switch (protocolMessage.type) {
      case 'welcome':
        // Connection acknowledged
        break

      case 'subscribed':
        // Subscription confirmed
        break

      case 'unsubscribed':
        // Unsubscription confirmed
        break

      case 'pong':
        // Heartbeat acknowledged
        break

      case 'error':
        console.error('WebSocket error:', protocolMessage.message)
        break
    }
  }

  /**
   * Dispatch event to matching subscriptions
   */
  private dispatchEvent(event: RealtimeEvent): void {
    for (const subscription of this.subscriptions.values()) {
      // Match collection
      if (subscription.collection !== event.collection) continue

      // Match document ID if specified
      if (subscription.documentId && subscription.documentId !== event.documentId) continue

      // Match event type if filtered
      if (subscription.events && !subscription.events.includes(event.type)) continue

      try {
        subscription.callback(event)
      } catch {
        // Ignore callback errors
      }
    }
  }

  /**
   * Send subscription message
   */
  private sendSubscription(subscription: Subscription): void {
    this.sendMessage({
      action: 'subscribe',
      subscriptionId: subscription.id,
      collection: subscription.collection,
      documentId: subscription.documentId,
    })
  }

  /**
   * Send message through WebSocket
   */
  private sendMessage(message: WSOutgoingMessage): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message))
    }
  }

  /**
   * Set status and notify listeners
   */
  private setStatus(status: RealtimeStatus): void {
    if (this.status === status) return
    this.status = status

    for (const listener of this.statusListeners) {
      try {
        listener(status)
      } catch {
        // Ignore listener errors
      }
    }
  }

  /**
   * Schedule reconnection with exponential backoff
   */
  private scheduleReconnect(): void {
    this.stopReconnectTimer()
    this.setStatus('reconnecting')

    const delay = Math.min(
      this.config.reconnectDelay! * Math.pow(2, this.reconnectAttempts),
      this.config.maxReconnectDelay!
    )

    this.reconnectTimer = setTimeout(() => {
      this.reconnectAttempts++
      this.connect()
    }, delay)
  }

  /**
   * Stop reconnect timer
   */
  private stopReconnectTimer(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer)
      this.reconnectTimer = null
    }
  }

  /**
   * Start ping timer for heartbeat
   */
  private startPingTimer(): void {
    this.stopPingTimer()
    this.pingTimer = setInterval(() => {
      this.sendMessage({ action: 'ping' })
    }, 30000) // Ping every 30 seconds
  }

  /**
   * Stop ping timer
   */
  private stopPingTimer(): void {
    if (this.pingTimer) {
      clearInterval(this.pingTimer)
      this.pingTimer = null
    }
  }

  /**
   * Generate unique subscription ID
   */
  private generateSubscriptionId(): string {
    return `sub_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`
  }
}

/**
 * Channel class for event emitter style subscriptions
 */
export class RealtimeChannel<T = unknown> {
  private manager: RealtimeManager
  private collection: string
  private documentId: string | undefined
  private handlers: Map<EventType | 'error', Set<(data: T | Error) => void>> = new Map()
  private unsubscribeFn: Unsubscribe | null = null

  constructor(manager: RealtimeManager, collection: string, documentId?: string | undefined) {
    this.manager = manager
    this.collection = collection
    this.documentId = documentId
  }

  /**
   * Register handler for event type
   */
  on(event: EventType, handler: (document: T) => void): RealtimeChannel<T>
  on(event: 'error', handler: (error: Error) => void): RealtimeChannel<T>
  on(event: EventType | 'error', handler: ((document: T) => void) | ((error: Error) => void)): RealtimeChannel<T> {
    if (!this.handlers.has(event)) {
      this.handlers.set(event, new Set())
    }
    this.handlers.get(event)!.add(handler as (data: T | Error) => void)
    return this
  }

  /**
   * Subscribe to the channel
   */
  subscribe(): RealtimeChannel<T> {
    if (this.unsubscribeFn) return this

    if (this.documentId) {
      this.unsubscribeFn = this.manager.subscribe(
        this.collection,
        this.documentId,
        (event: RealtimeEvent<T>) => {
          this.dispatchEvent(event)
        }
      )
    } else {
      this.unsubscribeFn = this.manager.subscribe(
        this.collection,
        (event: RealtimeEvent<T>) => {
          this.dispatchEvent(event)
        }
      )
    }

    return this
  }

  /**
   * Dispatch event to handlers
   */
  private dispatchEvent(event: RealtimeEvent<T>): void {
    const handlers = this.handlers.get(event.type)
    if (handlers) {
      for (const handler of handlers) {
        try {
          // Document may be undefined for delete events
          (handler as (doc: T | undefined) => void)(event.document)
        } catch (error) {
          this.emitError(error as Error)
        }
      }
    }
  }

  /**
   * Unsubscribe from the channel
   */
  unsubscribe(): void {
    if (this.unsubscribeFn) {
      this.unsubscribeFn()
      this.unsubscribeFn = null
    }
    this.handlers.clear()
  }

  /**
   * Emit error to error handlers
   */
  private emitError(error: Error): void {
    const handlers = this.handlers.get('error')
    if (handlers) {
      for (const handler of handlers) {
        try {
          (handler as (err: Error) => void)(error)
        } catch {
          // Ignore error handler errors
        }
      }
    }
  }
}
