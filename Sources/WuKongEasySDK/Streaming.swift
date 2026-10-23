import Foundation

/// Flags for a message's persisted stream parent.
public struct MessageSetting: Codable {
    /// True only for a persisted parent whose updates arrive as online events.
    public let stream: Bool
    public init(stream: Bool = false) { self.stream = stream }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stream = try container.decodeIfPresent(Bool.self, forKey: .stream) ?? false
    }
    private enum CodingKeys: String, CodingKey { case stream }
}

/// Typed send options. Keep clientMsgNo stable when reconciling a retried send.
public struct SendOptions {
    /// Application-owned stable identity, reused when reconciling a send.
    public let clientMsgNo: String?
    /// Optional parent settings; transient stream parents are rejected.
    public let setting: MessageSetting?
    public let header: Header?
    public let topic: String?

    public init(clientMsgNo: String? = nil, setting: MessageSetting? = nil,
                header: Header? = nil, topic: String? = nil) {
        self.clientMsgNo = clientMsgNo
        self.setting = setting
        self.header = header
        self.topic = topic
    }

    internal var dictionary: [String: Any] {
        var result: [String: Any] = [:]
        if let clientMsgNo { result["clientMsgNo"] = clientMsgNo }
        if let setting { result["setting"] = ["stream": setting.stream] }
        if let topic { result["topic"] = topic }
        if let header {
            var fields: [String: Any] = [:]
            fields["noPersist"] = header.noPersist
            fields["syncOnce"] = header.syncOnce
            fields["redDot"] = header.redDot
            fields["dup"] = header.dup
            result["header"] = fields
        }
        return result
    }
}

/// Best-effort online notification. The application owns projection and recovery.
public struct EventNotification: Codable, CustomStringConvertible, CustomDebugStringConvertible {
    /// Stable server event ID for application-side deduplication.
    public let id: String
    /// Public event type, for example stream.delta or stream.finish.
    public let type: String
    /// Server event timestamp, preserved without changing its wire units.
    public let timestamp: Int64
    /// JSON data, with a JSON-string envelope decoded once for consumers.
    public let data: Any

    public init(id: String, type: String, timestamp: Int64, data: Any) {
        self.id = id; self.type = type; self.timestamp = timestamp; self.data = data
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        timestamp = try c.decode(Int64.self, forKey: .timestamp)
        let value = try c.decodeIfPresent(AnyCodable.self, forKey: .data)?.value ?? NSNull()
        if let text = value as? String, let bytes = text.data(using: .utf8),
           let decoded = try? JSONSerialization.jsonObject(with: bytes, options: [.fragmentsAllowed]) {
            data = decoded
        } else { data = value }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encode(AnyCodable(data), forKey: .data)
    }

    private enum CodingKeys: String, CodingKey { case id, type, timestamp, data }
    public var description: String { "EventNotification(<redacted>)" }
    public var debugDescription: String { description }
}
