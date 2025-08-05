//
//  WuKongTypes.swift
//  WuKongEasySDK
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation

// MARK: - Helper Types

/// Helper type to decode Any values from JSON
internal struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Channel Type Enum

/// Channel Type Enum based on WuKongIM protocol
public enum ChannelType: Int, CaseIterable, Codable, Sendable {
    /// Person channel
    case person = 1
    /// Group channel
    case group = 2
    /// Customer Service channel (Consider using Visitors channel instead)
    case customerService = 3
    /// Community channel
    case community = 4
    /// Community Topic channel
    case communityTopic = 5
    /// Info channel (with concept of temporary subscribers)
    case info = 6
    /// Data channel
    case data = 7
    /// Temporary channel
    case temp = 8
    /// Live channel (does not save recent session data)
    case live = 9
    /// Visitors channel (replaces CustomerService for new implementations)
    case visitors = 10
}

// MARK: - Device Flag Enum

/// Device flag enum for identifying device types
public enum DeviceFlag: Int, CaseIterable, Codable {
    /// Mobile app
    case app = 1
    /// Web browser
    case web = 2
    /// Desktop application
    case desktop = 3
    /// Other device types
    case other = 4
}

// MARK: - Event Types

/// SDK Event Names Enum
public enum WuKongEvent: String, CaseIterable {
    /// Connection successfully established and authenticated
    case connect = "connect"
    /// Disconnected from server
    case disconnect = "disconnect"
    /// Received a message
    case message = "message"
    /// An error occurred (WebSocket error, connection error, etc.)
    case error = "error"
    /// Received acknowledgment for a sent message
    case sendAck = "sendack"
    /// The SDK is attempting to reconnect
    case reconnecting = "reconnecting"
    /// JSON data log event for debugging and monitoring
    case jsonDataLog = "jsondatalog"
}

// MARK: - Data Structures

/// Authentication options for connecting to WuKongIM server
public struct AuthOptions: Codable {
    /// User ID
    public let uid: String
    /// Authentication token
    public let token: String
    /// Optional device ID
    public let deviceId: String?
    /// Device flag (default: .app)
    public let deviceFlag: DeviceFlag
    
    public init(uid: String, token: String, deviceId: String? = nil, deviceFlag: DeviceFlag = .app) {
        self.uid = uid
        self.token = token
        self.deviceId = deviceId
        self.deviceFlag = deviceFlag
    }
}

/// Result returned after successful connection
public struct ConnectResult: Codable {
    /// Server key for encryption
    public let serverKey: String
    /// Salt for encryption
    public let salt: String
    /// Time difference between client and server
    public let timeDiff: Int64
    /// Reason code for connection result
    public let reasonCode: Int
    /// Optional server version
    public let serverVersion: Int?
    /// Optional node ID
    public let nodeId: Int?
    
    public init(serverKey: String, salt: String, timeDiff: Int64, reasonCode: Int, serverVersion: Int? = nil, nodeId: Int? = nil) {
        self.serverKey = serverKey
        self.salt = salt
        self.timeDiff = timeDiff
        self.reasonCode = reasonCode
        self.serverVersion = serverVersion
        self.nodeId = nodeId
    }
}

/// Result returned after sending a message
public struct SendResult: Codable {
    /// Unique message ID assigned by server
    public let messageId: String
    /// Message sequence number
    public let messageSeq: Int64
    
    public init(messageId: String, messageSeq: Int64) {
        self.messageId = messageId
        self.messageSeq = messageSeq
    }
}

/// Message header containing metadata
public struct Header: Codable {
    /// Whether to persist the message
    public let noPersist: Bool?
    /// Whether to show red dot notification
    public let redDot: Bool?
    /// Whether to sync only once
    public let syncOnce: Bool?
    /// Whether this is a duplicate message
    public let dup: Bool?
    
    public init(noPersist: Bool? = nil, redDot: Bool? = nil, syncOnce: Bool? = nil, dup: Bool? = nil) {
        self.noPersist = noPersist
        self.redDot = redDot
        self.syncOnce = syncOnce
        self.dup = dup
    }
}

/// Received message structure
public struct Message: Codable {
    /// Message header
    public let header: Header
    /// Unique message ID
    public let messageId: String
    /// Message sequence number
    public let messageSeq: Int64
    /// Message timestamp
    public let timestamp: Int64
    /// Channel ID where message was sent
    public let channelId: String
    /// Channel type
    public let channelType: Int
    /// Sender's user ID
    public let fromUid: String
    /// Message payload (business-defined)
    public let payload: [String: Any]
    
    // Optional fields based on protocol version/settings
    /// Client message number
    public let clientMsgNo: String?
    /// Stream number
    public let streamNo: String?
    /// Stream ID
    public let streamId: String?
    /// Stream flag
    public let streamFlag: Int?
    /// Topic for community channels
    public let topic: String?
    
    public init(header: Header, messageId: String, messageSeq: Int64, timestamp: Int64, 
                channelId: String, channelType: Int, fromUid: String, payload: [String: Any],
                clientMsgNo: String? = nil, streamNo: String? = nil, streamId: String? = nil,
                streamFlag: Int? = nil, topic: String? = nil) {
        self.header = header
        self.messageId = messageId
        self.messageSeq = messageSeq
        self.timestamp = timestamp
        self.channelId = channelId
        self.channelType = channelType
        self.fromUid = fromUid
        self.payload = payload
        self.clientMsgNo = clientMsgNo
        self.streamNo = streamNo
        self.streamId = streamId
        self.streamFlag = streamFlag
        self.topic = topic
    }
    
    // Custom Codable implementation to handle [String: Any] payload
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        header = try container.decode(Header.self, forKey: .header)
        messageId = try container.decode(String.self, forKey: .messageId)
        messageSeq = try container.decode(Int64.self, forKey: .messageSeq)
        timestamp = try container.decode(Int64.self, forKey: .timestamp)
        channelId = try container.decode(String.self, forKey: .channelId)
        channelType = try container.decode(Int.self, forKey: .channelType)
        fromUid = try container.decode(String.self, forKey: .fromUid)
        
        // Decode payload as [String: Any] directly from the JSON
        if let payloadDict = try container.decodeIfPresent([String: AnyCodable].self, forKey: .payload) {
            payload = payloadDict.mapValues { $0.value }
        } else {
            payload = [:]
        }
        
        clientMsgNo = try container.decodeIfPresent(String.self, forKey: .clientMsgNo)
        streamNo = try container.decodeIfPresent(String.self, forKey: .streamNo)
        streamId = try container.decodeIfPresent(String.self, forKey: .streamId)
        streamFlag = try container.decodeIfPresent(Int.self, forKey: .streamFlag)
        topic = try container.decodeIfPresent(String.self, forKey: .topic)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(header, forKey: .header)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(messageSeq, forKey: .messageSeq)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(channelId, forKey: .channelId)
        try container.encode(channelType, forKey: .channelType)
        try container.encode(fromUid, forKey: .fromUid)
        
        // Encode payload as dictionary
        let payloadCodable = payload.mapValues { AnyCodable($0) }
        try container.encode(payloadCodable, forKey: .payload)
        
        try container.encodeIfPresent(clientMsgNo, forKey: .clientMsgNo)
        try container.encodeIfPresent(streamNo, forKey: .streamNo)
        try container.encodeIfPresent(streamId, forKey: .streamId)
        try container.encodeIfPresent(streamFlag, forKey: .streamFlag)
        try container.encodeIfPresent(topic, forKey: .topic)
    }
    
    private enum CodingKeys: String, CodingKey {
        case header, messageId, messageSeq, timestamp, channelId, channelType, fromUid, payload
        case clientMsgNo, streamNo, streamId, streamFlag, topic
    }
}

/// Disconnect information
public struct DisconnectInfo {
    /// Disconnect code
    public let code: Int
    /// Disconnect reason
    public let reason: String
    
    public init(code: Int, reason: String) {
        self.code = code
        self.reason = reason
    }
}

/// Message payload structure for sending messages
/// Flexible dictionary-based approach that can hold arbitrary key-value pairs
public struct MessagePayload: Codable, ExpressibleByDictionaryLiteral {
    /// Internal storage for the payload data
    private var payload: [String: Any]

    // MARK: - Initializers

    /// Initialize with a dictionary of key-value pairs
    /// - Parameter payload: Dictionary containing the message payload data
    public init(_ payload: [String: Any] = [:]) {
        self.payload = payload
    }

    /// Convenience initializer for common message structure
    /// - Parameters:
    ///   - type: Message type (stored as "type" key)
    ///   - content: Message content (stored as "content" key)
    ///   - data: Additional key-value pairs to include (merged with type and content)
    public init(type: Int, content: String, data: [String: Any]? = nil) {
        var payload: [String: Any] = ["type": type, "content": content]
        if let data = data {
            payload.merge(data) { _, new in new }
        }
        self.payload = payload
    }

    /// Convenience initializer for text-only messages
    /// - Parameter content: Message content (stored as "content" key with type 1)
    public init(content: String) {
        self.payload = ["type": 1, "content": content]
    }

    /// ExpressibleByDictionaryLiteral initializer
    /// Allows initialization using dictionary literal syntax: ["key": value, ...]
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.payload = Dictionary(uniqueKeysWithValues: elements)
    }

    // MARK: - Subscript Access

    /// Access payload values using subscript notation
    /// - Parameter key: The key to access
    /// - Returns: The value for the given key, or nil if not found
    public subscript(key: String) -> Any? {
        get { payload[key] }
        set { payload[key] = newValue }
    }

    // MARK: - Convenient Accessors

    /// Get the message type (commonly used field)
    public var type: Int? {
        get { payload["type"] as? Int }
        set { payload["type"] = newValue }
    }

    /// Get the message content (commonly used field)
    public var content: String? {
        get { payload["content"] as? String }
        set { payload["content"] = newValue }
    }

    /// Get all keys in the payload
    public var keys: Dictionary<String, Any>.Keys {
        return payload.keys
    }

    /// Get all values in the payload
    public var values: Dictionary<String, Any>.Values {
        return payload.values
    }

    /// Check if the payload is empty
    public var isEmpty: Bool {
        return payload.isEmpty
    }

    /// Get the number of key-value pairs
    public var count: Int {
        return payload.count
    }

    // MARK: - Dictionary Operations

    /// Set a value for a given key
    /// - Parameters:
    ///   - value: The value to set
    ///   - key: The key to associate with the value
    public mutating func setValue(_ value: Any?, forKey key: String) {
        payload[key] = value
    }

    /// Get a value for a given key with type casting
    /// - Parameters:
    ///   - key: The key to look up
    ///   - type: The expected type of the value
    /// - Returns: The value cast to the specified type, or nil if not found or wrong type
    public func getValue<T>(forKey key: String, as type: T.Type) -> T? {
        return payload[key] as? T
    }

    /// Remove a value for a given key
    /// - Parameter key: The key to remove
    /// - Returns: The removed value, or nil if the key was not present
    @discardableResult
    public mutating func removeValue(forKey key: String) -> Any? {
        return payload.removeValue(forKey: key)
    }

    /// Merge another payload into this one
    /// - Parameter other: The other payload to merge
    public mutating func merge(_ other: MessagePayload) {
        payload.merge(other.payload) { _, new in new }
    }

    /// Create a new payload by merging with another
    /// - Parameter other: The other payload to merge
    /// - Returns: A new MessagePayload with merged data
    public func merging(_ other: MessagePayload) -> MessagePayload {
        var result = self
        result.merge(other)
        return result
    }

    /// Convert to dictionary representation
    /// - Returns: Dictionary representation of the payload
    public func toDictionary() -> [String: Any] {
        return payload
    }

    // MARK: - Codable Implementation

    /// Custom Codable implementation to handle [String: Any] payload
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)

        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected dictionary but got different type"
                )
            )
        }

        self.payload = jsonObject
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        try container.encode(data)
    }
}

// MARK: - MessagePayload Extensions

extension MessagePayload: CustomStringConvertible {
    public var description: String {
        return "MessagePayload(\(payload))"
    }
}

extension MessagePayload: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "MessagePayload(payload: \(payload))"
    }
}

extension MessagePayload: Equatable {
    public static func == (lhs: MessagePayload, rhs: MessagePayload) -> Bool {
        return NSDictionary(dictionary: lhs.payload).isEqual(to: rhs.payload)
    }
}
