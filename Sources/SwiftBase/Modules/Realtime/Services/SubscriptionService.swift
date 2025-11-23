import Foundation

/// Service for managing WebSocket subscriptions
public actor SubscriptionService {
    private var subscriptions: [String: Subscription] = [:]
    private var connectionSubscriptions: [String: Set<String>] = [:]
    private let logger: LoggerService

    public init(logger: LoggerService = .shared) {
        self.logger = logger
    }

    // MARK: - Subscription Management

    /// Add a new subscription
    public func addSubscription(_ subscription: Subscription) {
        subscriptions[subscription.id] = subscription

        // Track subscriptions by connection ID
        var connectionSubs = connectionSubscriptions[subscription.connectionId] ?? Set<String>()
        connectionSubs.insert(subscription.id)
        connectionSubscriptions[subscription.connectionId] = connectionSubs

        logger.info("Added subscription: \(subscription.id) for collection '\(subscription.collection)' on connection \(subscription.connectionId)")
    }

    /// Remove a subscription by ID
    public func removeSubscription(id: String) {
        guard let subscription = subscriptions.removeValue(forKey: id) else {
            return
        }

        // Remove from connection tracking
        if var connectionSubs = connectionSubscriptions[subscription.connectionId] {
            connectionSubs.remove(id)
            if connectionSubs.isEmpty {
                connectionSubscriptions.removeValue(forKey: subscription.connectionId)
            } else {
                connectionSubscriptions[subscription.connectionId] = connectionSubs
            }
        }

        logger.info("Removed subscription: \(id)")
    }

    /// Remove all subscriptions for a connection
    public func removeAllSubscriptions(connectionId: String) {
        guard let subscriptionIds = connectionSubscriptions[connectionId] else {
            return
        }

        for subscriptionId in subscriptionIds {
            subscriptions.removeValue(forKey: subscriptionId)
        }

        connectionSubscriptions.removeValue(forKey: connectionId)
        logger.info("Removed all subscriptions for connection: \(connectionId)")
    }

    /// Get all subscriptions for a connection
    public func getSubscriptions(connectionId: String) -> [Subscription] {
        guard let subscriptionIds = connectionSubscriptions[connectionId] else {
            return []
        }

        return subscriptionIds.compactMap { subscriptions[$0] }
    }

    /// Get subscriptions that match a specific collection and document
    public func getMatchingSubscriptions(collection: String, documentId: String) -> [Subscription] {
        return subscriptions.values.filter { subscription in
            subscription.matches(documentId: documentId, in: collection)
        }
    }

    /// Get subscriptions for a specific collection (any document)
    public func getSubscriptions(collection: String) -> [Subscription] {
        return subscriptions.values.filter { $0.collection == collection }
    }

    /// Get total subscription count
    public func getSubscriptionCount() -> Int {
        return subscriptions.count
    }

    /// Get connection count
    public func getConnectionCount() -> Int {
        return connectionSubscriptions.count
    }

    /// Get statistics
    public func getStatistics() -> SubscriptionStatistics {
        let collectionCounts = Dictionary(grouping: subscriptions.values, by: { $0.collection })
            .mapValues { $0.count }

        return SubscriptionStatistics(
            totalSubscriptions: subscriptions.count,
            totalConnections: connectionSubscriptions.count,
            subscriptionsByCollection: collectionCounts
        )
    }
}

/// Statistics about current subscriptions
public struct SubscriptionStatistics: Codable, Sendable {
    public let totalSubscriptions: Int
    public let totalConnections: Int
    public let subscriptionsByCollection: [String: Int]
}
