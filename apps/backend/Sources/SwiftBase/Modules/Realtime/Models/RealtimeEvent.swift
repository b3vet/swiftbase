import Foundation

/// Event types for realtime notifications
public enum EventType: String, Codable, Sendable {
    case create
    case update
    case delete
}

/// Represents a realtime event to be broadcast to subscribers
public struct RealtimeEvent: Codable, Sendable {
    /// Type of event (create, update, delete)
    public let event: EventType

    /// Collection where the event occurred
    public let collection: String

    /// Document ID affected by the event
    public let documentId: String

    /// Document data (for create/update events)
    public let document: [String: AnyCodable]?

    /// Timestamp of the event
    public let timestamp: String

    public init(
        event: EventType,
        collection: String,
        documentId: String,
        document: [String: Any]? = nil
    ) {
        self.event = event
        self.collection = collection
        self.documentId = documentId
        self.document = document?.mapValues { AnyCodable($0) }
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }

    /// Convert to JSON string for transmission over WebSocket
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "RealtimeEvent", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode event to JSON"])
        }
        return json
    }
}
