import Foundation
import HummingbirdWebSocket

/// Service for broadcasting realtime events to subscribers
public actor BroadcastService {
    private weak var webSocketHub: WebSocketHub?
    private let subscriptionService: SubscriptionService
    private let logger: LoggerService

    public init(
        subscriptionService: SubscriptionService,
        logger: LoggerService = .shared
    ) {
        self.subscriptionService = subscriptionService
        self.logger = logger
    }

    /// Set the WebSocket hub reference (called during initialization)
    public func setWebSocketHub(_ hub: WebSocketHub) {
        self.webSocketHub = hub
    }

    // MARK: - Event Broadcasting

    /// Broadcast an event to all matching subscribers
    public func broadcast(event: RealtimeEvent) async {
        guard let hub = webSocketHub else {
            logger.warning("WebSocketHub not set, cannot broadcast event")
            return
        }

        // Get all subscriptions that match this event
        let matchingSubscriptions = await subscriptionService.getMatchingSubscriptions(
            collection: event.collection,
            documentId: event.documentId
        )

        guard !matchingSubscriptions.isEmpty else {
            logger.debug("No subscriptions found for collection '\(event.collection)', document '\(event.documentId)'")
            return
        }

        // Convert event to JSON
        let message: String
        do {
            message = try event.toJSON()
        } catch {
            logger.error("Failed to encode event to JSON", error: error)
            return
        }

        // Send to all matching connections
        var sentCount = 0
        for subscription in matchingSubscriptions {
            do {
                try await hub.send(message: message, to: subscription.connectionId)
                sentCount += 1
            } catch {
                logger.error("Failed to send message to connection \(subscription.connectionId)", error: error)
            }
        }

        logger.info("Broadcast \(event.event.rawValue) event for '\(event.collection):\(event.documentId)' to \(sentCount) subscribers")
    }

    /// Broadcast a create event
    public func broadcastCreate(collection: String, documentId: String, document: [String: Any]) async {
        let event = RealtimeEvent(
            event: .create,
            collection: collection,
            documentId: documentId,
            document: document
        )
        await broadcast(event: event)
    }

    /// Broadcast an update event
    public func broadcastUpdate(collection: String, documentId: String, document: [String: Any]) async {
        let event = RealtimeEvent(
            event: .update,
            collection: collection,
            documentId: documentId,
            document: document
        )
        await broadcast(event: event)
    }

    /// Broadcast a delete event
    public func broadcastDelete(collection: String, documentId: String) async {
        let event = RealtimeEvent(
            event: .delete,
            collection: collection,
            documentId: documentId,
            document: nil
        )
        await broadcast(event: event)
    }
}
