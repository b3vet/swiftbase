import Foundation
import Hummingbird
import HummingbirdWebSocket

/// Realtime module that provides WebSocket functionality
public struct RealtimeModule: Sendable {
    public let subscriptionService: SubscriptionService
    public let broadcastService: BroadcastService
    public let webSocketHub: WebSocketHub

    public init(jwtService: JWTService, logger: LoggerService = .shared) async {
        // Initialize services
        self.subscriptionService = SubscriptionService(logger: logger)
        self.broadcastService = BroadcastService(
            subscriptionService: subscriptionService,
            logger: logger
        )

        // Initialize WebSocket hub
        self.webSocketHub = WebSocketHub(
            subscriptionService: subscriptionService,
            broadcastService: broadcastService,
            jwtService: jwtService,
            logger: logger
        )

        // Link services together
        await broadcastService.setWebSocketHub(webSocketHub)

        // Start the hub
        await webSocketHub.start()

        logger.info("Realtime module initialized")
    }

    /// Get statistics about the realtime system
    public func getStatistics() async -> RealtimeStatistics {
        let connectionStats = await webSocketHub.getStatistics()
        return RealtimeStatistics(
            totalConnections: connectionStats.totalConnections,
            authenticatedConnections: connectionStats.authenticatedConnections,
            totalSubscriptions: connectionStats.subscriptionStats.totalSubscriptions,
            subscriptionsByCollection: connectionStats.subscriptionStats.subscriptionsByCollection
        )
    }
}

/// Statistics about the realtime system
public struct RealtimeStatistics: ResponseEncodable {
    public let totalConnections: Int
    public let authenticatedConnections: Int
    public let totalSubscriptions: Int
    public let subscriptionsByCollection: [String: Int]
}
