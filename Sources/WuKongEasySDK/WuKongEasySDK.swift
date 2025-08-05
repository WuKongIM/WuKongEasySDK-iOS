//
//  WuKongEasySDK.swift
//  WuKongEasySDK
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation

/// Main SDK class for WuKongIM Easy SDK
/// Provides a simple interface for real-time messaging functionality
@available(iOS 15.0, macOS 12.0, *)
public class WuKongEasySDK {
    
    // MARK: - Properties
    
    private let config: WuKongConfig
    private let eventManager: WuKongEventManager
    private let webSocket: WuKongWebSocket
    
    /// Current connection status
    public var isConnected: Bool {
        return webSocket.isConnected
    }
    
    /// SDK configuration
    public var configuration: WuKongConfig {
        return config
    }
    
    // MARK: - Initialization
    
    /// Initialize WuKongEasySDK with configuration
    /// - Parameter config: SDK configuration
    public init(config: WuKongConfig) {
        self.config = config
        self.eventManager = WuKongEventManager(config: config)
        self.webSocket = WuKongWebSocket(config: config, eventManager: eventManager)
        
        logInfo("WuKongEasySDK initialized with server: \(config.serverUrl)")
    }
    
    // MARK: - Connection Management
    
    /// Connect to the WuKongIM server
    /// - Throws: WuKongError if connection fails
    public func connect() async throws {
        logInfo("Connecting to WuKongIM server...")
        try await webSocket.connect()
        logInfo("Successfully connected to WuKongIM server")
    }
    
    /// Disconnect from the WuKongIM server
    public func disconnect() {
        logInfo("Disconnecting from WuKongIM server...")
        webSocket.disconnect()
        logInfo("Disconnected from WuKongIM server")
    }
    
    // MARK: - Message Sending
    
    /// Send a message to a specific channel
    /// - Parameters:
    ///   - channelId: Target channel ID
    ///   - channelType: Target channel type
    ///   - payload: Message payload
    /// - Returns: SendResult containing message ID and sequence number
    /// - Throws: WuKongError if sending fails
    public func send(channelId: String, channelType: ChannelType, payload: MessagePayload) async throws -> SendResult {
        guard !channelId.isEmpty else {
            throw WuKongError.invalidChannel("Channel ID cannot be empty")
        }
        
        let payloadDict = payload.toDictionary()
        
        logDebug("Sending message to channel: \(channelId), type: \(channelType)")
        let result = try await webSocket.send(channelId: channelId, channelType: channelType, payload: payloadDict)
        logDebug("Message sent successfully: \(result.messageId)")
        
        return result
    }
    
    /// Send a message with additional options
    /// - Parameters:
    ///   - channelId: Target channel ID
    ///   - channelType: Target channel type
    ///   - payload: Message payload
    ///   - options: Additional sending options
    /// - Returns: SendResult containing message ID and sequence number
    /// - Throws: WuKongError if sending fails
    public func send(channelId: String, channelType: ChannelType, payload: MessagePayload, options: [String: Any]) async throws -> SendResult {
        guard !channelId.isEmpty else {
            throw WuKongError.invalidChannel("Channel ID cannot be empty")
        }
        
        let payloadDict = payload.toDictionary()
        
        logDebug("Sending message with options to channel: \(channelId), type: \(channelType)")
        let result = try await webSocket.send(channelId: channelId, channelType: channelType, payload: payloadDict, options: options)
        logDebug("Message sent successfully: \(result.messageId)")
        
        return result
    }
    
    // MARK: - Event Listeners
    
    /// Add a connect event listener
    /// - Parameter callback: Callback to execute when connected
    /// - Returns: EventListener that can be used to remove the listener
    @discardableResult
    public func onConnect(_ callback: @escaping (ConnectResult) -> Void) -> EventListener {
        logDebug("Added connect event listener")
        return eventManager.onConnect(callback)
    }
    
    /// Add a disconnect event listener
    /// - Parameter callback: Callback to execute when disconnected
    /// - Returns: EventListener that can be used to remove the listener
    @discardableResult
    public func onDisconnect(_ callback: @escaping (DisconnectInfo) -> Void) -> EventListener {
        logDebug("Added disconnect event listener")
        return eventManager.onDisconnect(callback)
    }
    
    /// Add a message event listener
    /// - Parameter callback: Callback to execute when a message is received
    /// - Returns: EventListener that can be used to remove the listener
    @discardableResult
    public func onMessage(_ callback: @escaping (Message) -> Void) -> EventListener {
        logDebug("Added message event listener")
        return eventManager.onMessage(callback)
    }
    
    /// Add an error event listener
    /// - Parameter callback: Callback to execute when an error occurs
    /// - Returns: EventListener that can be used to remove the listener
    @discardableResult
    public func onError(_ callback: @escaping (Error) -> Void) -> EventListener {
        logDebug("Added error event listener")
        return eventManager.onError(callback)
    }
    
    /// Add a send acknowledgment event listener
    /// - Parameter callback: Callback to execute when a send acknowledgment is received
    /// - Returns: EventListener that can be used to remove the listener
    @discardableResult
    public func onSendAck(_ callback: @escaping (SendResult) -> Void) -> EventListener {
        logDebug("Added send acknowledgment event listener")
        return eventManager.onSendAck(callback)
    }
    
    /// Add a reconnecting event listener
    /// - Parameter callback: Callback to execute when reconnection is attempted
    /// - Returns: EventListener that can be used to remove the listener
    @discardableResult
    public func onReconnecting(_ callback: @escaping ([String: Any]) -> Void) -> EventListener {
        logDebug("Added reconnecting event listener")
        return eventManager.onReconnecting(callback)
    }

    /// Add a JSON data log event listener for debugging and monitoring
    /// - Parameter callback: Callback to execute when JSON data is logged
    /// - Returns: EventListener that can be used to remove the listener
    @discardableResult
    public func onJsonDataLog(_ callback: @escaping (JSONDataLogEvent) -> Void) -> EventListener {
        logDebug("Added JSON data log event listener")
        return eventManager.onJsonDataLog(callback)
    }
    
    // MARK: - Event Listener Management
    
    /// Remove a specific event listener
    /// - Parameter listener: The listener to remove
    public func removeListener(_ listener: EventListener) {
        logDebug("Removing event listener: \(listener.id)")
        eventManager.removeListener(listener)
    }
    
    /// Remove all listeners for a specific event
    /// - Parameter event: The event to remove listeners for
    public func removeAllListeners(for event: WuKongEvent) {
        logDebug("Removing all listeners for event: \(event.rawValue)")
        eventManager.removeAllListeners(for: event)
    }
    
    /// Remove all event listeners
    public func removeAllListeners() {
        logDebug("Removing all event listeners")
        eventManager.removeAllListeners()
    }
    
    // MARK: - Utility Methods
    
    /// Get the number of listeners for a specific event
    /// - Parameter event: The event to count listeners for
    /// - Returns: Number of active listeners
    public func listenerCount(for event: WuKongEvent) -> Int {
        return eventManager.listenerCount(for: event)
    }
    
    /// Get the total number of listeners across all events
    /// - Returns: Total number of active listeners
    public func totalListenerCount() -> Int {
        return eventManager.totalListenerCount()
    }
    
    // MARK: - Logging
    
    private func logDebug(_ message: String) {
        guard config.logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        print("[WuKongEasySDK][DEBUG] \(message)")
    }
    
    private func logInfo(_ message: String) {
        guard config.logLevel.rawValue >= LogLevel.info.rawValue else { return }
        print("[WuKongEasySDK][INFO] \(message)")
    }
    
    private func logError(_ message: String) {
        guard config.logLevel.rawValue >= LogLevel.error.rawValue else { return }
        print("[WuKongEasySDK][ERROR] \(message)")
    }
}



// MARK: - Static Factory Methods

@available(iOS 15.0, macOS 12.0, *)
extension WuKongEasySDK {
    
    /// Create WuKongEasySDK instance with basic configuration
    /// - Parameters:
    ///   - serverUrl: WebSocket server URL
    ///   - uid: User ID
    ///   - token: Authentication token
    ///   - deviceId: Optional device ID
    ///   - deviceFlag: Device flag (default: .app)
    /// - Returns: Configured WuKongEasySDK instance
    /// - Throws: WuKongError if configuration is invalid
    public static func create(
        serverUrl: String,
        uid: String,
        token: String,
        deviceId: String? = nil,
        deviceFlag: DeviceFlag = .app
    ) throws -> WuKongEasySDK {
        let config = try WuKongConfig(
            serverUrl: serverUrl,
            uid: uid,
            token: token,
            deviceId: deviceId,
            deviceFlag: deviceFlag
        )
        return WuKongEasySDK(config: config)
    }
    
    /// Create WuKongEasySDK instance with configuration builder
    /// - Parameter builder: Configuration builder block
    /// - Returns: Configured WuKongEasySDK instance
    /// - Throws: WuKongError if configuration is invalid
    public static func create(configBuilder: (WuKongConfigBuilder) throws -> WuKongConfig) throws -> WuKongEasySDK {
        let builder = WuKongConfigBuilder()
        let config = try configBuilder(builder)
        return WuKongEasySDK(config: config)
    }
}
