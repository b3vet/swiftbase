import Foundation

/// Represents a WebSocket subscription to a collection or document
public struct Subscription: Sendable {
    /// Unique identifier for the subscription
    public let id: String

    /// WebSocket connection identifier
    public let connectionId: String

    /// Collection being subscribed to
    public let collection: String

    /// Optional document ID for document-level subscriptions
    public let documentId: String?

    /// Optional query filter for the subscription
    public let query: [String: AnyCodable]?

    /// Timestamp when the subscription was created
    public let createdAt: Date

    /// User ID associated with this subscription (if authenticated)
    public let userId: String?

    public init(
        id: String = UUID().uuidString,
        connectionId: String,
        collection: String,
        documentId: String? = nil,
        query: [String: AnyCodable]? = nil,
        userId: String? = nil
    ) {
        self.id = id
        self.connectionId = connectionId
        self.collection = collection
        self.documentId = documentId
        self.query = query
        self.createdAt = Date()
        self.userId = userId
    }

    /// Check if this subscription matches a given document
    public func matches(documentId: String, in collection: String) -> Bool {
        // Must match collection
        guard self.collection == collection else {
            return false
        }

        // If we have a specific document ID, check if it matches
        if let subscribedDocId = self.documentId {
            return subscribedDocId == documentId
        }

        // Collection-level subscription matches all documents in the collection
        return true
    }
}

extension Subscription: Equatable {
    public static func == (lhs: Subscription, rhs: Subscription) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Subscription: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
