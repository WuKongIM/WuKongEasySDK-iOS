//
//  WuKongWebSocket.swift
//  WuKongEasySDK
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation
import Network
import Starscream

// MARK: - Constants and Configuration

/// WebSocket connection constants
private enum WebSocketConstants {
    /// JSON-RPC protocol version
    static let jsonRpcVersion = "2.0"

    /// Connection timing constants
    static let connectionEstablishmentDelay: TimeInterval = 1.0
    static let reconnectExponent: Double = 2.0

    /// Default disconnect codes
    static let normalClosureCode = 1000
    static let serverDisconnectCode = 1000

    /// Timestamp conversion factor (seconds to milliseconds)
    static let timestampMultiplier: Int64 = 1000

    /// JSON logging constants
    static let maxJsonLogLength = 2000
    static let tokenMaskString = "***MASKED***"
    static let sensitiveFields = ["token", "password", "secret", "key"]
}

/// JSON-RPC method names
internal enum JSONRPCMethod: String, CaseIterable {
    case connect = "connect"
    case send = "send"
    case ping = "ping"
    case pong = "pong"
    case recv = "recv"
    case recvack = "recvack"
    case disconnect = "disconnect"
}

/// Error messages for consistent error handling
private enum ErrorMessages {
    static let alreadyConnecting = "Already connected or connecting"
    static let notConnected = "Cannot authenticate - not connected"
    static let invalidResponseFormat = "Invalid response format"
    static let noResultOrError = "No result or error in response"
    static let invalidNotificationFormat = "Invalid notification format"
    static let unknownMessageType = "Unknown message type received"
    static let failedToParseMessage = "Failed to parse received message"
    static let unknownRequestId = "Received response for unknown request ID"
    static let maxReconnectAttempts = "Max reconnect attempts reached"
    static let noNetworkConnection = "No network connection"
    static let pingTimeout = "Ping timeout"
}

/// Log message templates for consistent logging
private enum LogMessages {
    static let networkAvailable = "Network became available - attempting reconnection"
    static let initiatingConnection = "Initiating connection to %@"
    static let startingAuthentication = "Starting authentication process"
    static let authenticationSuccessful = "Authentication successful - connection fully established"
    static let authenticationFailed = "Authentication failed: %@"
    static let disconnectionInitiated = "Initiating WebSocket disconnection and cleanup"
    static let cancelledRequests = "Cancelled %d pending requests"
    static let disconnectionCompleted = "WebSocket disconnection completed"
    static let sendingMessage = "Sending message to channel %@ (type: %@)"
    static let messageSentSuccessfully = "Message sent successfully - ID: %@, Seq: %lld"
    static let failedToParseResult = "Failed to parse send result: %@"
    static let failedToSendMessage = "Failed to send message: %@"
    static let sentJsonRpcRequest = "Sent JSON-RPC request: %@ (ID: %@)"
    static let failedToSendNotification = "Failed to send notification '%@': %@"
    static let sentJsonRpcNotification = "Sent JSON-RPC notification: %@"
    static let failedToEncodeNotification = "Failed to encode notification '%@': %@"
    static let receivedNotification = "Received notification: %@"
    static let unhandledNotificationMethod = "Unhandled notification method: %@"
    static let serverInitiatedDisconnect = "Server initiated disconnect: %@"
    static let webSocketError = "WebSocket error: %@"
    static let pingTimerFiredNotAuthenticated = "Ping timer fired but not authenticated - stopping timer"
    static let pingTimerFiredNotRunning = "Ping timer fired but WebSocket not running - stopping timer"
    static let startedPingTimer = "Started ping timer with interval: %.1fs"
    static let stoppedPingTimer = "Stopped ping timer"
    static let skippingPingNotAuthenticated = "Skipping ping - not authenticated (state: %@)"
    static let skippingPingNotRunning = "Skipping ping - WebSocket not running"
    static let sendingPingRequest = "Sending ping request (timeout: %.1fs)"
    static let pingSuccessful = "Ping successful - pong received"
    static let pingFailed = "Ping failed or timed out: %@"
    static let initiatingReconnection = "Initiating reconnection due to ping failure"
    static let failedToSendPingRequest = "Failed to send ping request: %@"
    static let sentPingRequest = "Sent ping request with ID: %@"
    static let failedToEncodePingRequest = "Failed to encode ping request: %@"
    static let pongReceived = "Pong notification received from server"
    static let resolvedPingRequest = "Resolved ping request %@ with pong notification"
    static let pongWithoutPendingPing = "Received pong notification but no pending ping request found"
    static let attemptingReconnect = "Attempting reconnect %d/%d in %.1fs"
    static let reconnectionSuccessful = "Reconnection successful"
    static let reconnectionFailed = "Reconnection failed: %@"
    static let webSocketOpened = "WebSocket connection opened"
    static let webSocketClosed = "WebSocket connection closed with code: %d, reason: %@"

    // JSON Data Logging Messages
    static let jsonDataSent = "📤 SENT %@ | %@"
    static let jsonDataReceived = "📥 RECEIVED %@ | %@"
    static let jsonDataTruncated = " ...(truncated, total: %d chars)"
    static let jsonDataMalformed = "⚠️ Malformed JSON data: %@"
}

// MARK: - JSON-RPC Protocol Support

/// A flexible coding key that supports both string and integer keys for dynamic JSON encoding/decoding
internal struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Dynamic JSON Decoding Extensions

extension KeyedDecodingContainer where Key == AnyCodingKey {
    /// Decodes a dictionary with arbitrary key-value pairs from JSON
    /// Supports nested dictionaries and arrays with type safety
    func decodeAnyDictionary() throws -> [String: Any] {
        var dictionary: [String: Any] = [:]

        for key in allKeys {
            let keyString = key.stringValue

            // Try to decode different value types in order of specificity
            if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[keyString] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[keyString] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[keyString] = doubleValue
            } else if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[keyString] = boolValue
            } else if let nestedContainer = try? nestedContainer(keyedBy: AnyCodingKey.self, forKey: key) {
                // Recursively decode nested dictionaries
                dictionary[keyString] = try nestedContainer.decodeAnyDictionary()
            } else if var nestedArray = try? nestedUnkeyedContainer(forKey: key) {
                // Recursively decode nested arrays
                dictionary[keyString] = try nestedArray.decodeAnyArray()
            }
        }

        return dictionary
    }
}

extension UnkeyedDecodingContainer {
    /// Decodes an array with arbitrary element types from JSON
    /// Supports nested dictionaries and arrays with type safety
    mutating func decodeAnyArray() throws -> [Any] {
        var array: [Any] = []

        while !isAtEnd {
            // Try to decode different value types in order of specificity
            if let stringValue = try? decode(String.self) {
                array.append(stringValue)
            } else if let intValue = try? decode(Int.self) {
                array.append(intValue)
            } else if let doubleValue = try? decode(Double.self) {
                array.append(doubleValue)
            } else if let boolValue = try? decode(Bool.self) {
                array.append(boolValue)
            } else if let nestedContainer = try? nestedContainer(keyedBy: AnyCodingKey.self) {
                // Recursively decode nested dictionaries
                array.append(try nestedContainer.decodeAnyDictionary())
            } else if var nestedArray = try? nestedUnkeyedContainer() {
                // Recursively decode nested arrays
                array.append(try nestedArray.decodeAnyArray())
            }
        }

        return array
    }
}

// MARK: - Dynamic JSON Encoding Extensions

extension KeyedEncodingContainer where Key == AnyCodingKey {
    /// Encodes a dictionary with arbitrary key-value pairs to JSON
    /// Supports nested dictionaries and arrays with type safety
    mutating func encodeAnyDictionary(_ dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            guard let codingKey = AnyCodingKey(stringValue: key) else {
                continue // Skip invalid keys
            }

            // Encode different value types with proper type checking
            if let stringValue = value as? String {
                try encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try encode(doubleValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try encode(boolValue, forKey: codingKey)
            } else if let dictValue = value as? [String: Any] {
                // Recursively encode nested dictionaries
                var nestedContainer = nestedContainer(keyedBy: AnyCodingKey.self, forKey: codingKey)
                try nestedContainer.encodeAnyDictionary(dictValue)
            } else if let arrayValue = value as? [Any] {
                // Recursively encode nested arrays
                var nestedContainer = nestedUnkeyedContainer(forKey: codingKey)
                try nestedContainer.encodeAnyArray(arrayValue)
            }
        }
    }
}

extension UnkeyedEncodingContainer {
    /// Encodes an array with arbitrary element types to JSON
    /// Supports nested dictionaries and arrays with type safety
    mutating func encodeAnyArray(_ array: [Any]) throws {
        for value in array {
            // Encode different value types with proper type checking
            if let stringValue = value as? String {
                try encode(stringValue)
            } else if let intValue = value as? Int {
                try encode(intValue)
            } else if let doubleValue = value as? Double {
                try encode(doubleValue)
            } else if let boolValue = value as? Bool {
                try encode(boolValue)
            } else if let dictValue = value as? [String: Any] {
                // Recursively encode nested dictionaries
                var nestedContainer = nestedContainer(keyedBy: AnyCodingKey.self)
                try nestedContainer.encodeAnyDictionary(dictValue)
            } else if let arrayValue = value as? [Any] {
                // Recursively encode nested arrays
                var nestedContainer = nestedUnkeyedContainer()
                try nestedContainer.encodeAnyArray(arrayValue)
            }
        }
    }
}

// MARK: - JSON-RPC Protocol Structures

/// Represents a JSON-RPC 2.0 request with dynamic parameters
internal struct JsonRpcRequest: Codable {
    /// JSON-RPC protocol version (always "2.0")
    let jsonrpc: String
    /// The method name to invoke on the server
    let method: String
    /// Parameters to pass to the method (flexible dictionary)
    let params: [String: Any]
    /// Unique identifier for this request
    let id: String

    /// Creates a new JSON-RPC request
    /// - Parameters:
    ///   - method: The method name to invoke
    ///   - params: Parameters dictionary
    ///   - id: Unique identifier (auto-generated if not provided)
    init(method: JSONRPCMethod, params: [String: Any], id: String = UUID().uuidString) {
        self.jsonrpc = WebSocketConstants.jsonRpcVersion
        self.method = method.rawValue
        self.params = params
        self.id = id
    }

    /// Creates a new JSON-RPC request with string method (for backward compatibility)
    /// - Parameters:
    ///   - method: The method name to invoke
    ///   - params: Parameters dictionary
    ///   - id: Unique identifier (auto-generated if not provided)
    init(method: String, params: [String: Any], id: String = UUID().uuidString) {
        self.jsonrpc = WebSocketConstants.jsonRpcVersion
        self.method = method
        self.params = params
        self.id = id
    }

    // MARK: - Custom Codable Implementation

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try container.decode(String.self, forKey: .method)
        id = try container.decode(String.self, forKey: .id)

        // Decode params as a flexible dictionary
        if let paramsContainer = try? container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .params) {
            params = try paramsContainer.decodeAnyDictionary()
        } else {
            params = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method, forKey: .method)
        try container.encode(id, forKey: .id)

        // Encode params as a flexible dictionary
        var paramsContainer = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .params)
        try paramsContainer.encodeAnyDictionary(params)
    }

    private enum CodingKeys: String, CodingKey {
        case jsonrpc, method, params, id
    }
}

/// Represents a JSON-RPC 2.0 response with dynamic result data
internal struct JsonRpcResponse: Codable {
    /// JSON-RPC protocol version (optional in responses)
    let jsonrpc: String?
    /// Success result data (mutually exclusive with error)
    let result: [String: Any]?
    /// Error information (mutually exclusive with result)
    let error: JsonRpcError?
    /// Request identifier that this response corresponds to
    let id: String

    // MARK: - Custom Codable Implementation

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        jsonrpc = try container.decodeIfPresent(String.self, forKey: .jsonrpc)
        id = try container.decode(String.self, forKey: .id)
        error = try container.decodeIfPresent(JsonRpcError.self, forKey: .error)

        // Decode result as a flexible dictionary
        if let resultContainer = try? container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .result) {
            result = try resultContainer.decodeAnyDictionary()
        } else {
            result = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(error, forKey: .error)

        // Encode result as a flexible dictionary
        if let result = result {
            var resultContainer = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .result)
            try resultContainer.encodeAnyDictionary(result)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case jsonrpc, result, error, id
    }
}

/// Represents a JSON-RPC 2.0 notification (one-way message without response)
internal struct JsonRpcNotification: Codable {
    /// JSON-RPC protocol version (always "2.0")
    let jsonrpc: String
    /// The method name to invoke on the server
    let method: String
    /// Parameters to pass to the method (flexible dictionary)
    let params: [String: Any]

    /// Creates a new JSON-RPC notification
    /// - Parameters:
    ///   - method: The method name to invoke
    ///   - params: Parameters dictionary
    init(method: JSONRPCMethod, params: [String: Any]) {
        self.jsonrpc = WebSocketConstants.jsonRpcVersion
        self.method = method.rawValue
        self.params = params
    }

    /// Creates a new JSON-RPC notification with string method (for backward compatibility)
    /// - Parameters:
    ///   - method: The method name to invoke
    ///   - params: Parameters dictionary
    init(method: String, params: [String: Any]) {
        self.jsonrpc = WebSocketConstants.jsonRpcVersion
        self.method = method
        self.params = params
    }

    // MARK: - Custom Codable Implementation

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try container.decode(String.self, forKey: .method)

        // Decode params as a flexible dictionary
        if let paramsContainer = try? container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .params) {
            params = try paramsContainer.decodeAnyDictionary()
        } else {
            params = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(method, forKey: .method)

        // Encode params as a flexible dictionary
        var paramsContainer = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .params)
        try paramsContainer.encodeAnyDictionary(params)
    }

    private enum CodingKeys: String, CodingKey {
        case jsonrpc, method, params
    }
}

/// Represents a JSON-RPC 2.0 error with optional additional data
internal struct JsonRpcError: Codable {
    /// Error code (standard JSON-RPC error codes or custom codes)
    let code: Int
    /// Human-readable error message
    let message: String
    /// Optional additional error data
    let data: [String: Any]?

    // MARK: - Custom Codable Implementation

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        code = try container.decode(Int.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)

        // Decode optional data field using JSONSerialization for flexibility
        if let dataValue = try container.decodeIfPresent(Data.self, forKey: .data) {
            data = try JSONSerialization.jsonObject(with: dataValue, options: []) as? [String: Any]
        } else {
            data = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)

        // Encode optional data field using JSONSerialization for flexibility
        if let data = data {
            let dataValue = try JSONSerialization.data(withJSONObject: data, options: [])
            try container.encode(dataValue, forKey: .data)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case code, message, data
    }
}

// MARK: - JSON Data Logging

/// Represents the direction of JSON data flow
public enum JSONDataDirection: String {
    case sent = "SENT"
    case received = "RECEIVED"
}

/// Represents the type of JSON data
public enum JSONDataType: String {
    case request = "REQUEST"
    case response = "RESPONSE"
    case notification = "NOTIFICATION"
    case error = "ERROR"
}

/// JSON data log event for UI integration
public struct JSONDataLogEvent {
    public let timestamp: Date
    public let direction: JSONDataDirection
    public let type: JSONDataType
    public let method: String?
    public let requestId: String?
    public let jsonString: String
    public let originalLength: Int
    public let isTruncated: Bool

    public init(
        timestamp: Date = Date(),
        direction: JSONDataDirection,
        type: JSONDataType,
        method: String? = nil,
        requestId: String? = nil,
        jsonString: String,
        originalLength: Int,
        isTruncated: Bool = false
    ) {
        self.timestamp = timestamp
        self.direction = direction
        self.type = type
        self.method = method
        self.requestId = requestId
        self.jsonString = jsonString
        self.originalLength = originalLength
        self.isTruncated = isTruncated
    }
}

// MARK: - Timer Management

/// Manages WebSocket timers with consistent lifecycle handling
internal class TimerManager {
    private var timers: [String: Timer] = [:]
    private let queue = DispatchQueue.main

    /// Schedules a timer with the given identifier
    /// - Parameters:
    ///   - identifier: Unique identifier for the timer
    ///   - interval: Timer interval in seconds
    ///   - repeats: Whether the timer should repeat
    ///   - block: Block to execute when timer fires
    func scheduleTimer(identifier: String, interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) {
        cancelTimer(identifier: identifier)

        queue.async { [weak self] in
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { _ in
                block()
            }
            self?.timers[identifier] = timer
        }
    }

    /// Cancels a timer with the given identifier
    /// - Parameter identifier: Timer identifier to cancel
    func cancelTimer(identifier: String) {
        queue.async { [weak self] in
            self?.timers[identifier]?.invalidate()
            self?.timers.removeValue(forKey: identifier)
        }
    }

    /// Cancels all timers
    func cancelAllTimers() {
        queue.async { [weak self] in
            self?.timers.values.forEach { $0.invalidate() }
            self?.timers.removeAll()
        }
    }
}

// MARK: - Logging Management

/// Manages consistent logging with formatting and level checking
internal class LogManager {
    private let logLevel: LogLevel
    private let component: String
    private let enableJsonLogging: Bool
    private weak var eventManager: WuKongEventManager?

    init(logLevel: LogLevel, component: String = "WebSocket", enableJsonLogging: Bool = true, eventManager: WuKongEventManager? = nil) {
        self.logLevel = logLevel
        self.component = component
        self.enableJsonLogging = enableJsonLogging
        self.eventManager = eventManager
    }

    /// Logs a debug message with optional formatting
    /// - Parameters:
    ///   - template: Message template with format specifiers
    ///   - args: Arguments for string formatting
    func debug(_ template: String, _ args: CVarArg...) {
        guard logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        let message = String(format: template, arguments: args)
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("[\(timestamp)][WuKongEasySDK][\(component)][DEBUG] \(message)")
    }

    /// Logs an error message with optional formatting
    /// - Parameters:
    ///   - template: Message template with format specifiers
    ///   - args: Arguments for string formatting
    func error(_ template: String, _ args: CVarArg...) {
        guard logLevel.rawValue >= LogLevel.error.rawValue else { return }
        let message = String(format: template, arguments: args)
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("[\(timestamp)][WuKongEasySDK][\(component)][ERROR] \(message)")
    }

    /// Logs JSON data with proper formatting and masking
    /// - Parameters:
    ///   - direction: Data direction (sent/received)
    ///   - type: Data type (request/response/notification/error)
    ///   - data: Raw JSON data
    ///   - method: JSON-RPC method name (if applicable)
    ///   - requestId: Request ID (if applicable)
    func logJsonData(
        direction: JSONDataDirection,
        type: JSONDataType,
        data: Data,
        method: String? = nil,
        requestId: String? = nil
    ) {
        // guard enableJsonLogging && logLevel.rawValue >= LogLevel.debug.rawValue else { return }

        do {
            // Parse and format JSON
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let maskedJsonObject = maskSensitiveData(jsonObject)
            let prettyData = try JSONSerialization.data(withJSONObject: maskedJsonObject, options: [.prettyPrinted, .sortedKeys])

            var jsonString = String(data: prettyData, encoding: .utf8) ?? "Invalid UTF-8"
            let originalLength = jsonString.count
            var isTruncated = false

            // Truncate if too long
            if jsonString.count > WebSocketConstants.maxJsonLogLength {
                let truncateIndex = jsonString.index(jsonString.startIndex, offsetBy: WebSocketConstants.maxJsonLogLength)
                jsonString = String(jsonString[..<truncateIndex])
                jsonString += String(format: LogMessages.jsonDataTruncated, originalLength)
                isTruncated = true
            }

            // Create type description
            let typeDescription = createTypeDescription(type: type, method: method, requestId: requestId)

            // Log to console
            let message = String(format: direction == .sent ? LogMessages.jsonDataSent : LogMessages.jsonDataReceived, typeDescription, jsonString)
            let timestamp = DateFormatter.logTimestamp.string(from: Date())
            print("[\(timestamp)][WuKongEasySDK][\(component)][JSON] \(message)")

            // Create and emit log event for UI
            let logEvent = JSONDataLogEvent(
                direction: direction,
                type: type,
                method: method,
                requestId: requestId,
                jsonString: jsonString,
                originalLength: originalLength,
                isTruncated: isTruncated
            )

            eventManager?.emitJsonDataLog(logEvent)

        } catch {
            // Handle malformed JSON
            let rawString = String(data: data, encoding: .utf8) ?? "Invalid UTF-8"
            let message = String(format: LogMessages.jsonDataMalformed, rawString)
            let timestamp = DateFormatter.logTimestamp.string(from: Date())
            print("[\(timestamp)][WuKongEasySDK][\(component)][JSON] \(message)")
        }
    }

    /// Creates a descriptive string for the JSON data type
    private func createTypeDescription(type: JSONDataType, method: String?, requestId: String?) -> String {
        var description = type.rawValue

        if let method = method {
            description += "[\(method)]"
        }

        if let requestId = requestId {
            description += "(ID:\(requestId))"
        }

        return description
    }

    /// Masks sensitive data in JSON objects
    private func maskSensitiveData(_ jsonObject: Any) -> Any {
        if let dictionary = jsonObject as? [String: Any] {
            var maskedDict = dictionary
            for (key, value) in dictionary {
                if WebSocketConstants.sensitiveFields.contains(where: { key.lowercased().contains($0) }) {
                    maskedDict[key] = WebSocketConstants.tokenMaskString
                } else if let nestedDict = value as? [String: Any] {
                    maskedDict[key] = maskSensitiveData(nestedDict)
                } else if let nestedArray = value as? [Any] {
                    maskedDict[key] = maskSensitiveData(nestedArray)
                }
            }
            return maskedDict
        } else if let array = jsonObject as? [Any] {
            return array.map { maskSensitiveData($0) }
        }

        return jsonObject
    }
}

// MARK: - Request Management

/// Manages a pending JSON-RPC request with timeout handling
internal class PendingRequest {
    /// Unique identifier for the request
    let id: String
    /// Success callback to invoke when response is received
    let resolve: (Any) -> Void
    /// Error callback to invoke when request fails or times out
    let reject: (Error) -> Void
    /// Timer that triggers timeout if no response is received
    let timeoutTimer: Timer

    /// Creates a new pending request with automatic timeout handling
    /// - Parameters:
    ///   - id: Unique request identifier
    ///   - resolve: Success callback
    ///   - reject: Error callback
    ///   - timeout: Timeout interval in seconds
    init(id: String, resolve: @escaping (Any) -> Void, reject: @escaping (Error) -> Void, timeout: TimeInterval) {
        self.id = id
        self.resolve = resolve
        self.reject = reject

        // Set up automatic timeout handling
        self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            reject(WuKongError.sendTimeout)
        }
    }

    /// Completes the request by invalidating the timeout timer
    func complete() {
        timeoutTimer.invalidate()
    }
}

// MARK: - Connection State Management

/// Represents the current state of the WebSocket connection
internal enum WebSocketState: String, CaseIterable {
    /// Not connected to the server
    case disconnected = "disconnected"
    /// Attempting to establish WebSocket connection
    case connecting = "connecting"
    /// WebSocket connection established but not authenticated
    case connected = "connected"
    /// Sending authentication credentials to server
    case authenticating = "authenticating"
    /// Fully connected and authenticated, ready for messaging
    case authenticated = "authenticated"
    /// Attempting to reconnect after connection loss
    case reconnecting = "reconnecting"

    /// Whether the connection is in a usable state for sending messages
    var isUsable: Bool {
        return self == .authenticated
    }

    /// Whether the connection is in a transitional state
    var isTransitional: Bool {
        return [.connecting, .authenticating, .reconnecting].contains(self)
    }
}

// MARK: - WebSocket Manager

/// Main WebSocket manager that handles connection, authentication, and messaging
/// Implements JSON-RPC 2.0 protocol for communication with WuKong server
internal class WuKongWebSocket: NSObject, @unchecked Sendable {

    // MARK: - Core Properties

    /// Configuration settings for the WebSocket connection
    private let config: WuKongConfig
    /// Event manager for emitting connection and message events
    private let eventManager: WuKongEventManager
    /// Serial queue for thread-safe WebSocket operations
    private let queue = DispatchQueue(label: "com.wukongim.easysdk.websocket", qos: .userInitiated)

    // MARK: - Managers

    /// Timer manager for handling all WebSocket timers
    private let timerManager = TimerManager()
    /// Log manager for consistent logging
    private lazy var logger: LogManager = LogManager(
        logLevel: config.logLevel,
        enableJsonLogging: config.enableJsonLogging,
        eventManager: eventManager
    )

    // MARK: - Connection Properties

    /// The underlying Starscream WebSocket
    private var webSocket: WebSocket?
    /// Current connection state
    private var state: WebSocketState = .disconnected
    /// Flag indicating if disconnect was initiated by user
    private var isManualDisconnect = false

    // MARK: - Request Management

    /// Dictionary of pending JSON-RPC requests awaiting responses
    private var pendingRequests: [String: PendingRequest] = [:]

    /// Connection completion handler for async connection
    private var connectionCompletion: ((Result<Void, Error>) -> Void)?

    // MARK: - Ping/Pong Management

    /// ID of the current ping request (if any)
    private var currentPingRequestId: String?

    // MARK: - Reconnection Management

    /// Number of reconnection attempts made
    private var reconnectAttempts = 0

    // MARK: - Network Monitoring

    /// Network path monitor for detecting connectivity changes
    private var networkMonitor: NWPathMonitor?
    /// Flag indicating if network is currently available
    private var isNetworkAvailable = true
    
    // MARK: - Initialization

    /// Initializes the WebSocket manager with configuration and event handling
    /// - Parameters:
    ///   - config: WebSocket configuration settings
    ///   - eventManager: Event manager for emitting events
    init(config: WuKongConfig, eventManager: WuKongEventManager) {
        self.config = config
        self.eventManager = eventManager
        super.init()

        setupNetworkMonitoring()
    }

    /// Cleanup when the WebSocket manager is deallocated
    deinit {
        disconnect()
        networkMonitor?.cancel()
        timerManager.cancelAllTimers()
    }
    
    // MARK: - Public API

    /// Establishes connection to the WebSocket server and authenticates
    /// - Throws: WuKongError if connection or authentication fails
    nonisolated func connect() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let strongSelf = self else {
                    continuation.resume(throwing: WuKongError.connectionFailed("WebSocket instance was deallocated"))
                    return
                }
                strongSelf.connectInternal { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Disconnects from the WebSocket server and stops all timers
    func disconnect() {
        queue.async {
            self.isManualDisconnect = true
            self.disconnectInternal()
        }
    }

    /// Sends a message to a specific channel using JSON-RPC protocol
    /// - Parameters:
    ///   - channelId: Target channel identifier
    ///   - channelType: Type of channel (personal, group, etc.)
    ///   - payload: Message content as flexible dictionary
    ///   - options: Additional options (clientMsgNo, header, etc.)
    /// - Returns: SendResult containing message ID and sequence number
    /// - Throws: WuKongError if not connected or send fails
    nonisolated func send(channelId: String, channelType: ChannelType, payload: [String: Any], options: [String: Any] = [:]) async throws -> SendResult {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let strongSelf = self else {
                    continuation.resume(throwing: WuKongError.connectionFailed("WebSocket instance was deallocated"))
                    return
                }
                strongSelf.sendInternal(channelId: channelId, channelType: channelType, payload: payload, options: options) { result in
                    switch result {
                    case .success(let sendResult):
                        continuation.resume(returning: sendResult)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// Checks if the WebSocket is currently connected and authenticated
    /// - Returns: true if ready to send messages, false otherwise
    var isConnected: Bool {
        return queue.sync {
            return state.isUsable
        }
    }
    
    // MARK: - Setup Methods

    /// Creates and configures a Starscream WebSocket instance
    private func createWebSocket(url: URL) -> WebSocket {
        var request = URLRequest(url: url)
        request.timeoutInterval = config.connectionTimeout

        let webSocket = WebSocket(request: request)
        webSocket.delegate = self

        // Configure WebSocket options
        webSocket.callbackQueue = queue

        return webSocket
    }

    /// Sets up network monitoring to detect connectivity changes
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()

        networkMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let wasAvailable = self.isNetworkAvailable
            let isNowAvailable = path.status == .satisfied
            self.isNetworkAvailable = isNowAvailable

            // If network became available and we're disconnected (not manually), try to reconnect
            if !wasAvailable && isNowAvailable {
                self.queue.async {
                    if self.state == .disconnected && !self.isManualDisconnect {
                        self.logDebug("Network became available - attempting reconnection")
                        self.tryReconnect()
                    }
                }
            }
        }

        let networkQueue = DispatchQueue(label: "com.wukongim.easysdk.network")
        networkMonitor?.start(queue: networkQueue)
    }
    
    // MARK: - Connection Management

    /// Internal method to establish WebSocket connection
    /// - Parameter completion: Callback with connection result
    private func connectInternal(completion: @escaping (Result<Void, Error>) -> Void) {
        // Validate current state
        guard state == .disconnected || state == .reconnecting else {
            let errorMessage = "Already connected or connecting (current state: \(state.rawValue))"
            completion(.failure(WuKongError.invalidConfiguration(errorMessage)))
            return
        }

        // Validate server URL
        guard let url = config.serverURL else {
            completion(.failure(WuKongError.invalidServerURL))
            return
        }

        // Check network availability
        guard isNetworkAvailable else {
            completion(.failure(WuKongError.networkError("No network connection")))
            return
        }

        logger.debug(LogMessages.initiatingConnection, url.absoluteString)

        // Update state and reset manual disconnect flag
        state = .connecting
        isManualDisconnect = false

        // Create and connect WebSocket
        webSocket = createWebSocket(url: url)
        webSocket?.connect()

        // Store completion handler for use in delegate methods
        self.connectionCompletion = completion
    }
    
    /// Authenticates with the WuKong server using configured credentials
    /// - Parameter completion: Callback with authentication result
    private func authenticate(completion: @escaping (Result<Void, Error>) -> Void) {
        // Validate connection state
        guard state == .connected else {
            completion(.failure(WuKongError.connectionFailed("Cannot authenticate - not connected")))
            return
        }

        logger.debug(LogMessages.startingAuthentication)
        state = .authenticating

        // Prepare authentication parameters
        let authParams: [String: Any] = [
            "uid": config.uid,
            "token": config.token,
            "deviceId": config.deviceId,
            "deviceFlag": config.deviceFlag.rawValue,
            "clientTimestamp": Int64(Date().timeIntervalSince1970 * Double(WebSocketConstants.timestampMultiplier))
        ]

        // Send authentication request
        sendRequest(method: JSONRPCMethod.connect, params: authParams, timeout: config.requestTimeout) { [weak self] result in
            switch result {
            case .success(let response):
                self?.handleAuthenticationSuccess(response: response, completion: completion)
            case .failure(let error):
                self?.handleAuthenticationFailure(error: error, completion: completion)
            }
        }
    }
    
    /// Handles successful authentication response
    /// - Parameters:
    ///   - response: Server response containing connection details
    ///   - completion: Callback to invoke with final result
    private func handleAuthenticationSuccess(response: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            // Parse server response into structured result
            let connectResult = try parseConnectResult(from: response)

            // Update state and reset reconnection counter
            state = .authenticated
            reconnectAttempts = 0

            logDebug("Authentication successful - connection fully established")

            // Start keep-alive ping mechanism
            startPingTimer()

            // Notify listeners of successful connection
            eventManager.emitConnect(connectResult)
            completion(.success(()))

            logDebug("Ping timer started with interval: \(config.pingInterval)s")
        } catch {
            // If parsing fails, treat as authentication failure
            handleAuthenticationFailure(error: error, completion: completion)
        }
    }

    /// Handles authentication failure
    /// - Parameters:
    ///   - error: The authentication error
    ///   - completion: Callback to invoke with failure result
    private func handleAuthenticationFailure(error: Error, completion: @escaping (Result<Void, Error>) -> Void) {
        logError("Authentication failed: \(error)")

        // Reset state and notify of failure
        state = .disconnected
        eventManager.emitError(error)
        completion(.failure(error))

        // Clean up connection
        disconnectInternal()
    }

    /// Internal method to disconnect and clean up all resources
    private func disconnectInternal() {
        logDebug("Initiating WebSocket disconnection and cleanup")

        // Stop all timers
        timerManager.cancelAllTimers()

        // Cancel all pending requests with appropriate error
        let pendingRequestCount = pendingRequests.count
        for (_, request) in pendingRequests {
            request.complete()
            request.reject(WuKongError.cancelled)
        }
        pendingRequests.removeAll()

        if pendingRequestCount > 0 {
            logDebug("Cancelled \(pendingRequestCount) pending requests")
        }

        // Close WebSocket connection gracefully
        webSocket?.disconnect(closeCode: CloseCode.normal.rawValue)
        webSocket = nil

        // Update state and emit disconnect event if needed
        let previousState = state
        state = .disconnected

        if previousState != .disconnected {
            let disconnectInfo = DisconnectInfo(code: WebSocketConstants.normalClosureCode, reason: "Client disconnected")
            eventManager.emitDisconnect(disconnectInfo)
            logger.debug(LogMessages.disconnectionCompleted)
        }
    }

    // MARK: - Message Sending

    /// Internal method to send a message to a specific channel
    /// - Parameters:
    ///   - channelId: Target channel identifier
    ///   - channelType: Type of channel (personal, group, etc.)
    ///   - payload: Message content as flexible dictionary
    ///   - options: Additional options (clientMsgNo, header, etc.)
    ///   - completion: Callback with send result
    private func sendInternal(channelId: String, channelType: ChannelType, payload: [String: Any], options: [String: Any], completion: @escaping (Result<SendResult, Error>) -> Void) {
        // Validate connection state
        guard state.isUsable else {
            completion(.failure(WuKongError.notConnected))
            return
        }

        // Extract or generate client message number
        let clientMsgNo = options["clientMsgNo"] as? String ?? UUID().uuidString
        // Extract or use default header
        let header = options["header"] as? [String: Any] ?? ["redDot": true]

        // Prepare message parameters
        let messageParams: [String: Any] = [
            "clientMsgNo": clientMsgNo,
            "channelId": channelId,
            "channelType": channelType.rawValue,
            "payload": payload,
            "header": header
        ]

        logDebug("Sending message to channel \(channelId) (type: \(channelType.rawValue))")

        // Send message request and handle response
        sendRequest(method: JSONRPCMethod.send, params: messageParams, timeout: config.requestTimeout) { result in
            switch result {
            case .success(let response):
                do {
                    let sendResult = try self.parseSendResult(from: response)
                    self.logDebug("Message sent successfully - ID: \(sendResult.messageId), Seq: \(sendResult.messageSeq)")
                    completion(.success(sendResult))
                } catch {
                    self.logError("Failed to parse send result: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                self.logError("Failed to send message: \(error)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - JSON-RPC Protocol Implementation

    /// Sends a JSON-RPC request and waits for response
    /// - Parameters:
    ///   - method: RPC method name
    ///   - params: Method parameters
    ///   - timeout: Request timeout in seconds
    ///   - completion: Callback with response or error
    private func sendRequest(method: JSONRPCMethod, params: [String: Any], timeout: TimeInterval, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // Create JSON-RPC request with unique ID
        let request = JsonRpcRequest(method: method, params: params)

        do {
            // Encode request to JSON data
            let requestData = try JSONEncoder().encode(request)

            // Log JSON data being sent
            logger.logJsonData(
                direction: .sent,
                type: .request,
                data: requestData,
                method: method.rawValue,
                requestId: request.id
            )

            // Create pending request with timeout handling
            let pendingRequest = PendingRequest(
                id: request.id,
                resolve: { response in
                    if let responseDict = response as? [String: Any] {
                        completion(.success(responseDict))
                    } else {
                        completion(.failure(WuKongError.unexpectedResponse("Invalid response format")))
                    }
                },
                reject: { error in
                    completion(.failure(error))
                },
                timeout: timeout
            )

            // Store pending request for response matching
            pendingRequests[request.id] = pendingRequest

            // Send message over WebSocket using Starscream
            webSocket?.write(data: requestData) {
                // Message sent successfully - no action needed
                // Errors will be handled through the WebSocketDelegate
            }

            logDebug("Sent JSON-RPC request: \(method) (ID: \(request.id))")

        } catch {
            completion(.failure(WuKongError.invalidJSON(error.localizedDescription)))
        }
    }

    /// Sends a JSON-RPC notification (one-way message without response)
    /// - Parameters:
    ///   - method: RPC method name
    ///   - params: Method parameters
    private func sendNotification(method: JSONRPCMethod, params: [String: Any]) {
        // Create JSON-RPC notification (no ID, no response expected)
        let notification = JsonRpcNotification(method: method, params: params)

        do {
            // Encode notification to JSON data
            let notificationData = try JSONEncoder().encode(notification)

            // Log JSON data being sent
            logger.logJsonData(
                direction: .sent,
                type: .notification,
                data: notificationData,
                method: method.rawValue
            )

            // Send notification over WebSocket using Starscream
            webSocket?.write(data: notificationData) {
                // Notification sent successfully - no action needed
                // Errors will be handled through the WebSocketDelegate
            }

            logDebug("Sent JSON-RPC notification: \(method)")

        } catch {
            logError("Failed to encode notification '\(method)': \(error)")
        }
    }

    // MARK: - Message Processing (called from Starscream delegate)

    private func processReceivedData(_ data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let dict = json as? [String: Any] {
                // Determine the type and log the received data
                let (dataType, method, requestId) = determineReceivedDataType(dict)

                logger.logJsonData(
                    direction: .received,
                    type: dataType,
                    data: data,
                    method: method,
                    requestId: requestId
                )

                if dict["id"] != nil {
                    // It's a response
                    handleJsonRpcResponse(dict)
                } else if dict["method"] != nil {
                    // It's a notification
                    handleJsonRpcNotification(dict)
                }
            }
        } catch {
            // Log malformed JSON data
            logger.logJsonData(
                direction: .received,
                type: .error,
                data: data
            )

            logError("Failed to parse received message: \(error)")
            eventManager.emitError(WuKongError.invalidJSON(error.localizedDescription))
        }
    }

    /// Determines the type of received JSON-RPC data
    /// - Parameter dict: Parsed JSON dictionary
    /// - Returns: Tuple containing data type, method name, and request ID
    private func determineReceivedDataType(_ dict: [String: Any]) -> (JSONDataType, String?, String?) {
        let requestId = dict["id"] as? String
        let method = dict["method"] as? String

        if dict["error"] != nil {
            return (.error, method, requestId)
        } else if requestId != nil {
            return (.response, method, requestId)
        } else if method != nil {
            return (.notification, method, nil)
        } else {
            return (.error, nil, nil)
        }
    }

    private func handleJsonRpcResponse(_ dict: [String: Any]) {
        guard let id = dict["id"] as? String else { return }

        guard let pendingRequest = pendingRequests.removeValue(forKey: id) else {
            logError("Received response for unknown request ID: \(id)")
            return
        }

        pendingRequest.complete()

        if let error = dict["error"] as? [String: Any] {
            let code = error["code"] as? Int ?? -1
            let message = error["message"] as? String ?? "Unknown error"
            pendingRequest.reject(WuKongError.protocolError(code, message))
        } else if let result = dict["result"] as? [String: Any] {
            pendingRequest.resolve(result)
        } else {
            pendingRequest.resolve({})
        }
    }

    private func handleJsonRpcNotification(_ dict: [String: Any]) {
        guard let method = dict["method"] as? String,
              let params = dict["params"] as? [String: Any] else {
            logError("Invalid notification format")
            return
        }

        logDebug("Received notification: \(method)")

        switch method {
        case "recv":
            handleReceivedMessage(params)
        case "pong":
            handlePong()
        case "disconnect":
            handleServerDisconnect(params)
        default:
            logDebug("Unhandled notification method: \(method)")
        }
    }

    private func handleReceivedMessage(_ params: [String: Any]) {
        do {
            let messageData = try JSONSerialization.data(withJSONObject: params, options: [])
            let message = try JSONDecoder().decode(Message.self, from: messageData)

            eventManager.emitMessage(message)

            // Send acknowledgment
            sendRecvAck(messageId: message.messageId, messageSeq: message.messageSeq)

        } catch {
            logError("Failed to parse received message: \(error)")
            eventManager.emitError(WuKongError.invalidJSON(error.localizedDescription))
        }
    }

    private func sendRecvAck(messageId: String, messageSeq: Int64) {
        let params: [String: Any] = [
            "messageId": messageId,
            "messageSeq": messageSeq
        ]
        sendNotification(method: JSONRPCMethod.recvack, params: params)
    }

    private func handleServerDisconnect(_ params: [String: Any]) {
        let code = params["reasonCode"] as? Int ?? WebSocketConstants.serverDisconnectCode
        let reason = params["reason"] as? String ?? "Server disconnected"

        logger.debug(LogMessages.serverInitiatedDisconnect, reason)

        let disconnectInfo = createDisconnectInfo(code: code, reason: reason)
        eventManager.emitDisconnect(disconnectInfo)

        disconnectInternal()
    }



    // MARK: - Ping/Pong Management

    // MARK: - Timer Management Constants

    private enum TimerIdentifiers {
        static let ping = "ping"
        static let reconnect = "reconnect"
    }

    private func startPingTimer() {
        stopPingTimer()

        timerManager.scheduleTimer(
            identifier: TimerIdentifiers.ping,
            interval: config.pingInterval,
            repeats: true
        ) { [weak self] in
            self?.queue.async {
                self?.handlePingTimerFired()
            }
        }

        logger.debug(LogMessages.startedPingTimer, config.pingInterval)
    }

    private func stopPingTimer() {
        timerManager.cancelTimer(identifier: TimerIdentifiers.ping)
        currentPingRequestId = nil
        logger.debug(LogMessages.stoppedPingTimer)
    }

    private func handlePingTimerFired() {
        guard state == .authenticated else {
            logger.debug(LogMessages.pingTimerFiredNotAuthenticated)
            stopPingTimer()
            return
        }

        guard state == .authenticated else {
            logger.debug(LogMessages.pingTimerFiredNotRunning)
            stopPingTimer()
            return
        }

        sendPing()
    }

    private func sendPing() {
        guard validatePingConditions() else { return }

        logger.debug(LogMessages.sendingPingRequest, config.pongTimeout)

        let request = createPingRequest()
        currentPingRequestId = request.id

        do {
            try sendPingRequest(request)
            logger.debug(LogMessages.sentPingRequest, request.id)
        } catch {
            handlePingError(error)
        }
    }

    private func validatePingConditions() -> Bool {
        guard state == .authenticated else {
            logger.debug(LogMessages.skippingPingNotAuthenticated, state.rawValue)
            return false
        }

        guard webSocket != nil else {
            logger.debug(LogMessages.skippingPingNotRunning)
            return false
        }

        return true
    }

    private func createPingRequest() -> JsonRpcRequest {
        return JsonRpcRequest(method: JSONRPCMethod.ping, params: [:])
    }

    private func sendPingRequest(_ request: JsonRpcRequest) throws {
        let data = try JSONEncoder().encode(request)

        let pendingRequest = createPingPendingRequest(for: request.id)
        pendingRequests[request.id] = pendingRequest

        logger.logJsonData(
            direction: .sent,
            type: .request,
            data: data,
            method: request.method,
            requestId: request.id
        )

        // Send ping using Starscream
        webSocket?.write(data: data) {
            // Ping sent successfully - no action needed
            // Errors will be handled through the WebSocketDelegate
        }
    }

    private func createPingPendingRequest(for requestId: String) -> PendingRequest {
        return PendingRequest(
            id: requestId,
            resolve: { [weak self] _ in
                self?.handlePingSuccess()
            },
            reject: { [weak self] error in
                self?.handlePingFailure(error)
            },
            timeout: config.pongTimeout
        )
    }

    private func handlePingSuccess() {
        logger.debug(LogMessages.pingSuccessful)
        currentPingRequestId = nil
    }

    private func handlePingFailure(_ error: Error) {
        logger.error(LogMessages.pingFailed, error.localizedDescription)
        currentPingRequestId = nil

        // Emit error event for ping timeout (matches JS SDK behavior)
        eventManager.emitError(WuKongError.networkError(ErrorMessages.pingTimeout))

        if !isManualDisconnect {
            logger.debug(LogMessages.initiatingReconnection)
            tryReconnect()
        }
    }

    private func handlePingSendError(_ error: Error, requestId: String, pendingRequest: PendingRequest) {
        pendingRequests.removeValue(forKey: requestId)
        pendingRequest.complete()
        logger.error(LogMessages.failedToSendPingRequest, error.localizedDescription)
        currentPingRequestId = nil
    }

    private func handlePingError(_ error: Error) {
        logger.error(LogMessages.failedToEncodePingRequest, error.localizedDescription)
        currentPingRequestId = nil
    }

    private func handlePong() {
        logDebug("Pong notification received from server")

        // Resolve the pending ping request (matches JavaScript SDK pattern)
        if let pingRequestId = currentPingRequestId,
           let pendingRequest = pendingRequests.removeValue(forKey: pingRequestId) {
            pendingRequest.complete()
            pendingRequest.resolve([:]) // Resolve with empty result
            currentPingRequestId = nil
            logDebug("Resolved ping request \(pingRequestId) with pong notification")
        } else {
            logDebug("Received pong notification but no pending ping request found")
        }
    }

    // MARK: - Reconnection Management

    private func tryReconnect() {
        guard config.autoReconnect && !isManualDisconnect else { return }
        guard reconnectAttempts < config.maxReconnectAttempts else {
            logError("Max reconnect attempts reached")
            eventManager.emitError(WuKongError.connectionFailed("Max reconnect attempts reached"))
            return
        }

        state = .reconnecting
        reconnectAttempts += 1

        let delay = min(config.initialReconnectDelay * pow(WebSocketConstants.reconnectExponent, Double(reconnectAttempts - 1)), config.maxReconnectDelay)

        logger.debug(LogMessages.attemptingReconnect, reconnectAttempts, config.maxReconnectAttempts, delay)
        eventManager.emitReconnecting(attempt: reconnectAttempts, delay: delay)

        timerManager.scheduleTimer(
            identifier: TimerIdentifiers.reconnect,
            interval: delay,
            repeats: false
        ) { [weak self] in
            self?.queue.async {
                self?.connectInternal { result in
                    switch result {
                    case .success:
                        self?.logger.debug(LogMessages.reconnectionSuccessful)
                    case .failure(let error):
                        self?.logger.error(LogMessages.reconnectionFailed, error.localizedDescription)
                        self?.tryReconnect()
                    }
                }
            }
        }
    }

    private func stopReconnectTimer() {
        timerManager.cancelTimer(identifier: TimerIdentifiers.reconnect)
    }

    // MARK: - Error Handling Helpers

    /// Handles JSON-RPC request errors consistently
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - requestId: The request ID (if available)
    ///   - completion: Completion handler to call with the error
    private func handleRequestError(_ error: Error, requestId: String?, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        if let requestId = requestId {
            pendingRequests.removeValue(forKey: requestId)?.complete()
        }

        let wukongError: WuKongError
        if let urlError = error as? URLError {
            wukongError = WuKongError.from(urlError: urlError)
        } else {
            wukongError = WuKongError.networkError(error.localizedDescription)
        }

        logger.error("Request failed: %@", error.localizedDescription)
        completion(.failure(wukongError))
    }

    /// Validates connection state for operations that require authentication
    /// - Throws: WuKongError if not in a usable state
    private func validateConnectionState() throws {
        guard state.isUsable else {
            throw WuKongError.notConnected
        }
    }

    /// Creates a standardized disconnect info object
    /// - Parameters:
    ///   - code: Disconnect code
    ///   - reason: Disconnect reason
    /// - Returns: DisconnectInfo object
    private func createDisconnectInfo(code: Int, reason: String) -> DisconnectInfo {
        return DisconnectInfo(code: code, reason: reason)
    }

    // MARK: - Data Parsing Helpers

    private func parseConnectResult(from response: [String: Any]) throws -> ConnectResult {
        let serverKey = response["serverKey"] as? String ?? ""
        let salt = response["salt"] as? String ?? ""
        let timeDiff = response["timeDiff"] as? Int64 ?? 0
        let reasonCode = response["reasonCode"] as? Int ?? 0
        let serverVersion = response["serverVersion"] as? Int
        let nodeId = response["nodeId"] as? Int

        return ConnectResult(
            serverKey: serverKey,
            salt: salt,
            timeDiff: timeDiff,
            reasonCode: reasonCode,
            serverVersion: serverVersion,
            nodeId: nodeId
        )
    }

    private func parseSendResult(from response: [String: Any]) throws -> SendResult {
        guard let messageId = response["messageId"] as? String,
              let messageSeq = response["messageSeq"] as? Int64 else {
            throw WuKongError.unexpectedResponse("Invalid send result format")
        }

        return SendResult(messageId: messageId, messageSeq: messageSeq)
    }

    // MARK: - Legacy Logging Support (for backward compatibility)

    /// Legacy debug logging method - use logger.debug() for new code
    /// - Parameter message: The debug message to log
    private func logDebug(_ message: String) {
        logger.debug("%@", message)
    }

    /// Legacy error logging method - use logger.error() for new code
    /// - Parameter message: The error message to log
    private func logError(_ message: String) {
        logger.error("%@", message)
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    /// Shared date formatter for log timestamps
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Starscream WebSocketDelegate

extension WuKongWebSocket: WebSocketDelegate {

    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            handleWebSocketConnected(headers: headers)
        case .disconnected(let reason, let code):
            handleWebSocketDisconnected(reason: reason, code: code)
        case .text(let string):
            handleWebSocketText(string: string)
        case .binary(let data):
            handleWebSocketBinary(data: data)
        case .ping(_):
            // Starscream handles pong automatically
            break
        case .pong(_):
            // Pong received - handled automatically by Starscream
            break
        case .viabilityChanged(let isViable):
            handleWebSocketViabilityChanged(viable: isViable)
        case .reconnectSuggested(let shouldReconnect):
            handleWebSocketReconnectSuggested(suggest: shouldReconnect)
        case .cancelled:
            handleWebSocketCancelled()
        case .error(let error):
            handleWebSocketError(error)
        case .peerClosed:
            handleWebSocketPeerClosed()
        }
    }

    // MARK: - WebSocket Event Handlers

    private func handleWebSocketConnected(headers: [String: String]) {
        logger.debug(LogMessages.webSocketOpened)

        // Update state and start authentication
        state = .connected

        // Call the stored completion handler for authentication
        if let completion = connectionCompletion {
            authenticate(completion: completion)
            connectionCompletion = nil
        }
    }

    private func handleWebSocketDisconnected(reason: String, code: UInt16) {
        let reasonString = reason.isEmpty ? "Unknown reason" : reason
        logger.debug(LogMessages.webSocketClosed, Int(code), reasonString)

        let disconnectInfo = createDisconnectInfo(code: Int(code), reason: reasonString)
        eventManager.emitDisconnect(disconnectInfo)

        // Clear connection state
        state = .disconnected

        // Handle reconnection if not manually disconnected
        if !isManualDisconnect {
            tryReconnect()
        }
    }

    private func handleWebSocketText(string: String) {
        if let data = string.data(using: .utf8) {
            processReceivedData(data)
        }
    }

    private func handleWebSocketBinary(data: Data) {
        processReceivedData(data)
    }

    private func handleWebSocketViabilityChanged(viable: Bool) {
        logger.debug("WebSocket viability changed: \(viable)")
    }

    private func handleWebSocketReconnectSuggested(suggest: Bool) {
        if suggest && !isManualDisconnect {
            logger.debug("WebSocket suggests reconnection")
            tryReconnect()
        }
    }

    private func handleWebSocketCancelled() {
        logger.debug("WebSocket connection cancelled")
        state = .disconnected
    }

    private func handleWebSocketError(_ error: Error?) {
        guard let error = error else { return }

        logger.error(LogMessages.webSocketError, error.localizedDescription)

        // Convert to WuKongError and emit
        let wukongError: WuKongError
        if let wsError = error as? WSError {
            wukongError = WuKongError.from(wsError: wsError)
        } else {
            wukongError = WuKongError.networkError(error.localizedDescription)
        }

        eventManager.emitError(wukongError)

        // Handle connection failure
        if let completion = connectionCompletion {
            completion(.failure(wukongError))
            connectionCompletion = nil
        }

        // Trigger reconnection if appropriate
        if !isManualDisconnect && state != .disconnected {
            state = .disconnected
            tryReconnect()
        }
    }

    private func handleWebSocketPeerClosed() {
        logger.debug("WebSocket peer closed connection")
        state = .disconnected

        if !isManualDisconnect {
            tryReconnect()
        }
    }
}
