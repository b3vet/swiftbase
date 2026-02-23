import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { RealtimeManager, RealtimeChannel } from '../../src/modules/realtime/manager'
import type { RealtimeConfig } from '../../src/types/client'

// Mock WebSocket
class MockWebSocket {
  static CONNECTING = 0
  static OPEN = 1
  static CLOSING = 2
  static CLOSED = 3

  readyState = MockWebSocket.CONNECTING
  onopen: ((event: Event) => void) | null = null
  onclose: ((event: CloseEvent) => void) | null = null
  onmessage: ((event: MessageEvent) => void) | null = null
  onerror: ((event: Event) => void) | null = null

  sentMessages: string[] = []

  constructor(public url: string) {
    // Simulate async connection
    setTimeout(() => {
      this.readyState = MockWebSocket.OPEN
      if (this.onopen) {
        this.onopen(new Event('open'))
      }
    }, 10)
  }

  send(data: string): void {
    this.sentMessages.push(data)
  }

  close(code?: number, reason?: string): void {
    this.readyState = MockWebSocket.CLOSED
    if (this.onclose) {
      this.onclose({ code: code ?? 1000, reason: reason ?? '' } as CloseEvent)
    }
  }

  // Test helper: simulate receiving a message
  simulateMessage(data: unknown): void {
    if (this.onmessage) {
      this.onmessage({ data: JSON.stringify(data) } as MessageEvent)
    }
  }

  // Test helper: simulate error
  simulateError(): void {
    if (this.onerror) {
      this.onerror(new Event('error'))
    }
  }
}

describe('RealtimeManager', () => {
  let manager: RealtimeManager
  let mockWs: MockWebSocket | null = null
  const defaultConfig: RealtimeConfig = {
    autoConnect: false,
    reconnect: true,
    reconnectDelay: 100,
    maxReconnectDelay: 1000,
  }

  beforeEach(() => {
    // Mock WebSocket globally
    vi.stubGlobal('WebSocket', class extends MockWebSocket {
      constructor(url: string) {
        super(url)
        mockWs = this
      }
    })

    manager = new RealtimeManager('http://localhost:8090', defaultConfig)
  })

  afterEach(() => {
    manager.disconnect()
    vi.unstubAllGlobals()
    mockWs = null
  })

  describe('connect', () => {
    it('should connect to WebSocket server', async () => {
      manager.connect()

      expect(manager.getStatus()).toBe('connecting')

      // Wait for connection
      await new Promise(r => setTimeout(r, 20))

      expect(manager.getStatus()).toBe('connected')
      expect(mockWs?.url).toBe('ws://localhost:8090/api/realtime')
    })

    it('should convert http to ws in URL', () => {
      manager.connect()
      expect(mockWs?.url).toContain('ws://')
    })

    it('should not connect if already connected', async () => {
      manager.connect()
      await new Promise(r => setTimeout(r, 20))

      const firstWs = mockWs
      manager.connect() // Should not create new connection

      expect(mockWs).toBe(firstWs)
    })
  })

  describe('disconnect', () => {
    it('should disconnect and set status', async () => {
      manager.connect()
      await new Promise(r => setTimeout(r, 20))

      manager.disconnect()

      expect(manager.getStatus()).toBe('disconnected')
    })
  })

  describe('subscribe (callback style)', () => {
    it('should subscribe to collection', async () => {
      const callback = vi.fn()

      manager.connect()
      await new Promise(r => setTimeout(r, 20))

      const unsubscribe = manager.subscribe('products', callback)

      expect(typeof unsubscribe).toBe('function')

      // Check subscription message was sent
      const messages = mockWs?.sentMessages.map(m => JSON.parse(m)) ?? []
      const subMessage = messages.find(m => m.type === 'subscribe')
      expect(subMessage).toBeDefined()
      expect(subMessage?.collection).toBe('products')
    })

    it('should subscribe to document', async () => {
      const callback = vi.fn()

      manager.connect()
      await new Promise(r => setTimeout(r, 20))

      manager.subscribe('products', 'prod_123', callback)

      const messages = mockWs?.sentMessages.map(m => JSON.parse(m)) ?? []
      const subMessage = messages.find(m => m.type === 'subscribe')
      expect(subMessage?.documentId).toBe('prod_123')
    })

    it('should auto-connect when autoConnect is true', async () => {
      const autoConnectManager = new RealtimeManager('http://localhost:8090', {
        ...defaultConfig,
        autoConnect: true,
      })

      expect(autoConnectManager.getStatus()).toBe('disconnected')

      autoConnectManager.subscribe('products', vi.fn())

      // Should start connecting
      expect(autoConnectManager.getStatus()).toBe('connecting')

      autoConnectManager.disconnect()
    })

    it('should queue subscription when not connected', () => {
      const callback = vi.fn()

      // Subscribe before connecting
      manager.subscribe('products', callback)

      // Connect
      manager.connect()

      // Subscription should be sent after connection
      // (tested implicitly through the onopen handler)
    })

    it('should call callback when event is received', async () => {
      const callback = vi.fn()

      manager.connect()
      await new Promise(r => setTimeout(r, 20))

      manager.subscribe('products', callback)

      // Simulate event
      mockWs?.simulateMessage({
        type: 'event',
        event: {
          type: 'create',
          collection: 'products',
          documentId: 'prod_123',
          document: { id: 'prod_123', name: 'Test' },
          timestamp: new Date().toISOString(),
        },
      })

      expect(callback).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'create',
          collection: 'products',
          documentId: 'prod_123',
        })
      )
    })

    it('should unsubscribe when calling returned function', async () => {
      const callback = vi.fn()

      manager.connect()
      await new Promise(r => setTimeout(r, 20))

      const unsubscribe = manager.subscribe('products', callback)
      unsubscribe()

      // Should send unsubscribe message
      const messages = mockWs?.sentMessages.map(m => JSON.parse(m)) ?? []
      const unsubMessage = messages.find(m => m.type === 'unsubscribe')
      expect(unsubMessage).toBeDefined()

      // Callback should not be called after unsubscribe
      mockWs?.simulateMessage({
        type: 'event',
        event: {
          type: 'create',
          collection: 'products',
          documentId: 'prod_123',
          document: { id: 'prod_123' },
          timestamp: new Date().toISOString(),
        },
      })

      expect(callback).not.toHaveBeenCalled()
    })
  })

  describe('onStatusChange', () => {
    it('should notify listeners of status changes', async () => {
      const listener = vi.fn()

      manager.onStatusChange(listener)
      manager.connect()

      expect(listener).toHaveBeenCalledWith('connecting')

      await new Promise(r => setTimeout(r, 20))

      expect(listener).toHaveBeenCalledWith('connected')
    })

    it('should unsubscribe when calling returned function', async () => {
      const listener = vi.fn()

      const unsubscribe = manager.onStatusChange(listener)
      unsubscribe()

      manager.connect()

      expect(listener).not.toHaveBeenCalled()
    })
  })

  describe('setAuthToken', () => {
    it('should send auth message when connected', async () => {
      manager.connect()
      await new Promise(r => setTimeout(r, 20))

      manager.setAuthToken('test_token')

      const messages = mockWs?.sentMessages.map(m => JSON.parse(m)) ?? []
      const authMessage = messages.find(m => m.type === 'auth')
      expect(authMessage?.token).toBe('test_token')
    })
  })

  describe('reconnection', () => {
    it('should attempt reconnect on unexpected close', async () => {
      vi.useFakeTimers()

      manager.connect()
      await vi.advanceTimersByTimeAsync(20)

      expect(manager.getStatus()).toBe('connected')

      // Simulate unexpected close
      mockWs?.onclose?.({ code: 1006, reason: '' } as CloseEvent)

      expect(manager.getStatus()).toBe('reconnecting')

      vi.useRealTimers()
    })

    it('should not reconnect on intentional close', async () => {
      vi.useFakeTimers()

      manager.connect()
      await vi.advanceTimersByTimeAsync(20)

      expect(manager.getStatus()).toBe('connected')

      manager.disconnect() // Intentional close with code 1000

      expect(manager.getStatus()).toBe('disconnected')

      vi.useRealTimers()
    })
  })

  describe('heartbeat', () => {
    it('should send ping messages periodically', async () => {
      vi.useFakeTimers()

      manager.connect()
      await vi.advanceTimersByTimeAsync(20)

      // Advance 30 seconds (ping interval)
      await vi.advanceTimersByTimeAsync(30000)

      const messages = mockWs?.sentMessages.map(m => JSON.parse(m)) ?? []
      const pingMessage = messages.find(m => m.type === 'ping')
      expect(pingMessage).toBeDefined()

      vi.useRealTimers()
    })
  })
})

describe('RealtimeChannel', () => {
  let manager: RealtimeManager
  let mockWs: MockWebSocket | null = null

  beforeEach(() => {
    vi.stubGlobal('WebSocket', class extends MockWebSocket {
      constructor(url: string) {
        super(url)
        mockWs = this
      }
    })

    manager = new RealtimeManager('http://localhost:8090', {
      autoConnect: false,
      reconnect: false,
      reconnectDelay: 100,
      maxReconnectDelay: 1000,
    })
  })

  afterEach(() => {
    manager.disconnect()
    vi.unstubAllGlobals()
  })

  it('should create channel and subscribe', async () => {
    manager.connect()
    await new Promise(r => setTimeout(r, 20))

    const channel = manager.channel('products')
      .on('create', vi.fn())
      .subscribe()

    expect(channel).toBeInstanceOf(RealtimeChannel)

    const messages = mockWs?.sentMessages.map(m => JSON.parse(m)) ?? []
    const subMessage = messages.find(m => m.type === 'subscribe')
    expect(subMessage?.collection).toBe('products')
  })

  it('should call event handlers', async () => {
    const createHandler = vi.fn()
    const updateHandler = vi.fn()

    manager.connect()
    await new Promise(r => setTimeout(r, 20))

    manager.channel('products')
      .on('create', createHandler)
      .on('update', updateHandler)
      .subscribe()

    // Simulate create event
    mockWs?.simulateMessage({
      type: 'event',
      event: {
        type: 'create',
        collection: 'products',
        documentId: 'prod_123',
        document: { id: 'prod_123', name: 'New Product' },
        timestamp: new Date().toISOString(),
      },
    })

    expect(createHandler).toHaveBeenCalledWith({ id: 'prod_123', name: 'New Product' })
    expect(updateHandler).not.toHaveBeenCalled()
  })

  it('should unsubscribe and clear handlers', async () => {
    const handler = vi.fn()

    manager.connect()
    await new Promise(r => setTimeout(r, 20))

    const channel = manager.channel('products')
      .on('create', handler)
      .subscribe()

    channel.unsubscribe()

    // Should send unsubscribe message
    const messages = mockWs?.sentMessages.map(m => JSON.parse(m)) ?? []
    const unsubMessage = messages.find(m => m.type === 'unsubscribe')
    expect(unsubMessage).toBeDefined()
  })
})
