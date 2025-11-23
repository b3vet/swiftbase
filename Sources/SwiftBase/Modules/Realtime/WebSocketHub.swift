import Foundation
import Hummingbird
import HummingbirdWebSocket
import NIOCore
import NIOWebSocket
import NIOHTTP1
@_spi(WSInternal) import WSCore

/// Manages WebSocket connections and message routing
public actor WebSocketHub {
    // MARK: - Types

    private struct Connection: Sendable {
        let id: String
        let outbound: WebSocketOutboundWriter
        let userId: String?
        let connectedAt: Date
        var lastHeartbeat: Date

        init(
            id: String = UUID().uuidString,
            outbound: WebSocketOutboundWriter,
            userId: String? = nil
        ) {
            self.id = id
            self.outbound = outbound
            self.userId = userId
            self.connectedAt = Date()
            self.lastHeartbeat = Date()
        }
    }

    private struct IncomingMessage: Codable {
        let action: String
        let collection: String?
        let documentId: String?
        let query: [String: AnyCodable]?
    }

    // MARK: - Properties

    private var connections: [String: Connection] = [:]
    private let subscriptionService: SubscriptionService
    private let broadcastService: BroadcastService
    private let jwtService: JWTService
    private let logger: LoggerService
    private let heartbeatInterval: TimeInterval = 30.0
    private let connectionTimeout: TimeInterval = 60.0
    private var heartbeatTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(
        subscriptionService: SubscriptionService,
        broadcastService: BroadcastService,
        jwtService: JWTService,
        logger: LoggerService = .shared
    ) {
        self.subscriptionService = subscriptionService
        self.broadcastService = broadcastService
        self.jwtService = jwtService
        self.logger = logger
    }

    // MARK: - Lifecycle

    /// Start the WebSocket hub (starts heartbeat monitoring)
    public func start() {
        logger.info("Starting WebSocket Hub")
        startHeartbeatMonitor()
    }

    /// Stop the WebSocket hub (stops heartbeat monitoring)
    public func stop() {
        logger.info("Stopping WebSocket Hub")
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    // MARK: - Connection Management

    /// Handle a new WebSocket connection
    public func handleConnection(
        inbound: WebSocketInboundStream,
        outbound: WebSocketOutboundWriter,
        context: WebSocketContext
    ) async {
        let connectionId = UUID().uuidString

        // Extract token from query parameters or headers
        let token = extractToken(from: context)

        // Authenticate if token is provided
        var userId: String?
        if let token = token {
            do {
                let claims = try await jwtService.validateAccessToken(token)
                userId = claims.sub
                logger.info("Authenticated WebSocket connection: \(connectionId) for user: \(userId ?? "unknown")")
            } catch {
                logger.warning("Failed to authenticate WebSocket connection: \(error)")
                // Continue with unauthenticated connection
            }
        }

        // Register connection
        let connection = Connection(
            id: connectionId,
            outbound: outbound,
            userId: userId
        )
        connections[connectionId] = connection
        logger.info("New WebSocket connection established: \(connectionId)")

        // Send welcome message
        await sendWelcome(to: connectionId)

        // Handle incoming messages
        do {
            for try await frame in inbound {
                await handleFrame(frame, connectionId: connectionId, userId: userId)
            }
        } catch {
            logger.error("WebSocket connection error: \(connectionId)", error: error)
        }

        // Clean up on disconnect
        await handleDisconnect(connectionId: connectionId)
    }

    /// Handle a WebSocket frame
    private func handleFrame(_ frame: WebSocketDataFrame, connectionId: String, userId: String?) async {
        switch frame.opcode {
        case .text:
            var data = frame.data
            if let text = data.readString(length: data.readableBytes) {
                await handleTextMessage(text, connectionId: connectionId, userId: userId)
            }

        case .binary, .continuation:
            // Ignore binary and continuation frames for now
            break
        }

        // Update heartbeat on any data frame
        await updateHeartbeat(for: connectionId)
    }

    /// Handle text message from client
    private func handleTextMessage(_ text: String, connectionId: String, userId: String?) async {
        logger.debug("Received message from \(connectionId): \(text)")

        guard let data = text.data(using: .utf8) else {
            await sendError(to: connectionId, message: "Invalid message format")
            return
        }

        do {
            let message = try JSONDecoder().decode(IncomingMessage.self, from: data)
            await handleAction(message, connectionId: connectionId, userId: userId)
        } catch {
            logger.error("Failed to decode message", error: error)
            await sendError(to: connectionId, message: "Failed to parse message: \(error.localizedDescription)")
        }
    }

    /// Handle a specific action from the client
    private func handleAction(_ message: IncomingMessage, connectionId: String, userId: String?) async {
        switch message.action {
        case "subscribe":
            await handleSubscribe(message: message, connectionId: connectionId, userId: userId)

        case "unsubscribe":
            await handleUnsubscribe(message: message, connectionId: connectionId)

        case "ping":
            await sendPong(to: connectionId)

        default:
            await sendError(to: connectionId, message: "Unknown action: \(message.action)")
        }
    }

    /// Handle subscribe action
    private func handleSubscribe(message: IncomingMessage, connectionId: String, userId: String?) async {
        guard let collection = message.collection else {
            await sendError(to: connectionId, message: "Collection name required for subscription")
            return
        }

        let subscription = Subscription(
            connectionId: connectionId,
            collection: collection,
            documentId: message.documentId,
            query: message.query,
            userId: userId
        )

        await subscriptionService.addSubscription(subscription)
        await sendResponse(
            to: connectionId,
            response: [
                "type": "subscribed",
                "subscriptionId": subscription.id,
                "collection": collection,
                "documentId": message.documentId ?? NSNull()
            ]
        )
    }

    /// Handle unsubscribe action
    private func handleUnsubscribe(message: IncomingMessage, connectionId: String) async {
        // Remove all subscriptions for this connection
        await subscriptionService.removeAllSubscriptions(connectionId: connectionId)
        await sendResponse(
            to: connectionId,
            response: ["type": "unsubscribed"]
        )
    }

    /// Handle connection disconnect
    private func handleDisconnect(connectionId: String) async {
        connections.removeValue(forKey: connectionId)
        await subscriptionService.removeAllSubscriptions(connectionId: connectionId)
        logger.info("WebSocket connection closed: \(connectionId)")
    }

    // MARK: - Message Sending

    /// Send a message to a specific connection
    public func send(message: String, to connectionId: String) throws {
        guard let connection = connections[connectionId] else {
            throw NSError(domain: "WebSocketHub", code: 404, userInfo: [NSLocalizedDescriptionKey: "Connection not found"])
        }

        Task {
            do {
                try await connection.outbound.write(.text(message))
            } catch {
                logger.error("Failed to send message to connection \(connectionId)", error: error)
            }
        }
    }

    /// Send welcome message
    private func sendWelcome(to connectionId: String) async {
        await sendResponse(
            to: connectionId,
            response: [
                "type": "welcome",
                "connectionId": connectionId,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
    }

    /// Send pong message
    private func sendPong(to connectionId: String) async {
        guard let connection = connections[connectionId] else { return }

        do {
            try await connection.outbound.write(.pong)
        } catch {
            logger.error("Failed to send pong to connection \(connectionId)", error: error)
        }
    }

    /// Send error message
    private func sendError(to connectionId: String, message: String) async {
        await sendResponse(
            to: connectionId,
            response: [
                "type": "error",
                "message": message
            ]
        )
    }

    /// Send generic response
    private func sendResponse(to connectionId: String, response: [String: Any]) async {
        guard let connection = connections[connectionId] else { return }

        do {
            let data = try JSONSerialization.data(withJSONObject: response)
            guard let jsonString = String(data: data, encoding: .utf8) else { return }

            try await connection.outbound.write(.text(jsonString))
        } catch {
            logger.error("Failed to send response to connection \(connectionId)", error: error)
        }
    }

    // MARK: - Heartbeat

    /// Update heartbeat timestamp for a connection
    private func updateHeartbeat(for connectionId: String) async {
        guard var connection = connections[connectionId] else { return }
        connection.lastHeartbeat = Date()
        connections[connectionId] = connection
    }

    /// Start heartbeat monitor task
    private func startHeartbeatMonitor() {
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
                await checkHeartbeats()
            }
        }
    }

    /// Check all connections for heartbeat timeout
    private func checkHeartbeats() async {
        let now = Date()
        let timedOutConnections = connections.filter { _, connection in
            now.timeIntervalSince(connection.lastHeartbeat) > connectionTimeout
        }

        for (connectionId, _) in timedOutConnections {
            logger.warning("Connection timed out: \(connectionId)")
            await handleDisconnect(connectionId: connectionId)
        }

        // Send ping to all active connections (using custom frame)
        for (connectionId, connection) in connections {
            do {
                try await connection.outbound.write(.custom(WebSocketFrame(fin: true, opcode: .ping, data: ByteBuffer())))
            } catch {
                logger.error("Failed to send ping to connection \(connectionId)", error: error)
            }
        }
    }

    // MARK: - Helpers

    /// Extract JWT token from WebSocket context
    private func extractToken(from context: WebSocketContext) -> String? {
        // Try to get token from query parameter
        if let queryToken = context.request.uri.queryParameters["token"] {
            return String(queryToken)
        }

        // Try to get token from Authorization header
        if let authHeader = context.request.headers[.authorization],
           authHeader.hasPrefix("Bearer ") {
            return String(authHeader.dropFirst(7))
        }

        return nil
    }

    // MARK: - Statistics

    /// Get connection statistics
    public func getStatistics() async -> ConnectionStatistics {
        return ConnectionStatistics(
            totalConnections: connections.count,
            authenticatedConnections: connections.values.filter { $0.userId != nil }.count,
            subscriptionStats: await subscriptionService.getStatistics()
        )
    }
}

/// Statistics about current connections
public struct ConnectionStatistics: Codable, Sendable {
    public let totalConnections: Int
    public let authenticatedConnections: Int
    public let subscriptionStats: SubscriptionStatistics
}

/// WebSocket context (simplified for this implementation)
public struct WebSocketContext: Sendable {
    public let request: Request
}
