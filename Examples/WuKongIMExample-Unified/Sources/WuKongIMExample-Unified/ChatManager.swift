//
//  ChatManager.swift
//  WuKongIMExample
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation
import WuKongEasySDK

/// Main chat manager that handles WuKongEasySDK integration
@MainActor
class ChatManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionStatus = "Disconnected"
    @Published var messages: [ChatMessage] = []
    @Published var eventLogs: [EventLog] = []
    @Published var lastError: String?
    
    // MARK: - Configuration Properties
    
    @Published var serverUrl = "ws://localhost:5200"
    @Published var uid = "testUser"
    @Published var token = "testToken"
    
    // MARK: - Messaging Properties
    
    @Published var targetChannelId = "friendUser"
    @Published var selectedChannelType: ChannelType = .person
    @Published var messageContent = ""
    @Published var customPayloadJson = """
{"type":1, "content":"Hello!"}
"""
    
    // MARK: - Private Properties
    
    private var easySDK: WuKongEasySDK?
    private var eventListeners: [EventListener] = []
    
    // MARK: - Initialization
    
    init() {
        addInitialLog("Example loaded. Enter connection details and click Connect.")
    }
    
    deinit {
        // Clean up will be handled by the system
        // Cannot access @MainActor properties from deinit
    }
    
    // MARK: - Connection Management
    
    /// Connect to WuKongIM server
    func connect() async {
        guard !isConnecting else { return }
        
        // Validate inputs
        guard !serverUrl.isEmpty, !uid.isEmpty, !token.isEmpty else {
            setError("Server URL, User ID, and Token are required")
            return
        }
        
        isConnecting = true
        connectionStatus = "Connecting..."
        lastError = nil
        
        addLog("Attempting to connect to \(serverUrl) with user: \(uid)")
        
        do {
            // Create configuration
            let config = try WuKongConfig(
                serverUrl: serverUrl,
                uid: uid,
                token: token,
                deviceFlag: .app
            )
            
            // Initialize SDK
            easySDK = WuKongEasySDK(config: config)
            
            // Setup event listeners
            setupEventListeners()
            
            // Attempt connection
            try await easySDK?.connect()
            
        } catch {
            handleConnectionError(error)
        }
    }
    
    /// Disconnect from WuKongIM server
    func disconnect() {
        guard isConnected || isConnecting else { return }
        
        addLog("Disconnecting from server...")
        
        // Remove event listeners
        eventListeners.forEach { listener in
            easySDK?.removeListener(listener)
        }
        eventListeners.removeAll()
        
        // Disconnect
        easySDK?.disconnect()
        easySDK = nil
        
        // Update state
        isConnected = false
        isConnecting = false
        connectionStatus = "Disconnected"
    }
    
    // MARK: - Message Sending
    
    /// Send a simple text message
    func sendTextMessage() async {
        guard let _ = easySDK, isConnected else {
            setError("Not connected to server")
            return
        }
        
        guard !targetChannelId.isEmpty, !messageContent.isEmpty else {
            setError("Channel ID and message content are required")
            return
        }
        
        // Create simple text message payload using dictionary literal
        let payload: MessagePayload = [
            "type": 1,
            "content": messageContent,
            "timestamp": Date().timeIntervalSince1970,
            "platform": "iOS",
            "app_version": "1.0.0"
        ]
        
        await sendMessageInternal(payload: payload)
    }

    /// Send a custom JSON message
    func sendCustomMessage() async {
        guard let _ = easySDK, isConnected else {
            setError("Not connected to server")
            return
        }
        
        guard !targetChannelId.isEmpty, !customPayloadJson.isEmpty else {
            setError("Channel ID and custom payload are required")
            return
        }
        
        do {
            // Parse JSON string to dictionary
            guard let jsonData = customPayloadJson.data(using: .utf8),
                  let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                setError("Invalid JSON format in custom payload")
                return
            }
            
            // Create payload using dictionary literal
            let payload: MessagePayload = MessagePayload(jsonObject)
            
            await sendMessageInternal(payload: payload)

        } catch {
            setError("Failed to parse custom JSON: \(error.localizedDescription)")
        }
    }
    
    /// Send message with different payload types for demonstration
    func sendExampleMessages() async {
        guard isConnected else {
            setError("Not connected to server")
            return
        }
        
        let examples: [(String, MessagePayload)] = [
            // Simple text message
            ("Simple Text", MessagePayload(content: "Hello from iOS!")),
            
            // Rich text with metadata
            ("Rich Text", [
                "type": 1,
                "content": "Hello with metadata! 🎉",
                "metadata": [
                    "platform": "iOS",
                    "timestamp": Date().timeIntervalSince1970,
                    "version": "1.0.0"
                ]
            ]),
            
            // Image message simulation
            ("Image Message", [
                "type": 2,
                "content": "Check out this image!",
                "image": [
                    "url": "https://example.com/image.jpg",
                    "width": 1920,
                    "height": 1080,
                    "size": 245760
                ]
            ]),
            
            // Location message simulation
            ("Location Message", [
                "type": 3,
                "content": "I'm here!",
                "location": [
                    "latitude": 37.7749,
                    "longitude": -122.4194,
                    "address": "San Francisco, CA"
                ]
            ]),
            
            // Custom action message
            ("Custom Action", [
                "type": 100,
                "action": "user_typing",
                "user_id": uid,
                "timestamp": Date().timeIntervalSince1970
            ])
        ]
        
        for (description, payload) in examples {
            addLog("Sending \(description) message...")
            await sendMessageInternal(payload: payload)

            // Small delay between messages
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }
    
    // MARK: - Public Message Sending

    /// Send a message with a custom payload
    func sendMessage(payload: MessagePayload) async {
        await sendMessageInternal(payload: payload)
    }

    /// Send a simple text message
    func sendMessage(_ text: String) async {
        let payload = MessagePayload(["text": text, "type": 1])
        await sendMessage(payload: payload)
    }

    // MARK: - Private Methods

    private func sendMessageInternal(payload: MessagePayload) async {
        guard let easySDK = easySDK else { return }
        
        do {
            addLog("Sending message to \(targetChannelId) (\(selectedChannelType))...")
            addLog("Payload: \(payload.toDictionary())")
            
            let result = try await easySDK.send(
                channelId: targetChannelId,
                channelType: selectedChannelType,
                payload: payload
            )
            
            addLog("✅ Message sent successfully!")
            addLog("Message ID: \(result.messageId)")
            addLog("Message Seq: \(result.messageSeq)")
            
            // Add to local message history
            let chatMessage = ChatMessage(
                id: result.messageId,
                content: payload.content ?? "Custom message",
                fromUserId: uid,
                channelId: targetChannelId,
                channelType: selectedChannelType,
                timestamp: Date(),
                payload: payload.toDictionary(),
                isOutgoing: true
            )
            messages.append(chatMessage)
            
            // Clear message content after sending
            messageContent = ""
            
        } catch {
            addLog("❌ Failed to send message: \(error.localizedDescription)")
            setError("Failed to send message: \(error.localizedDescription)")
        }
    }

    private func setupEventListeners() {
        guard let easySDK = easySDK else { return }

        // Connection events
        let connectListener = easySDK.onConnect { [weak self] result in
            Task { @MainActor in
                self?.handleConnectEvent(result)
            }
        }

        let disconnectListener = easySDK.onDisconnect { [weak self] info in
            Task { @MainActor in
                self?.handleDisconnectEvent(info)
            }
        }

        // Message events
        let messageListener = easySDK.onMessage { [weak self] message in
            Task { @MainActor in
                self?.handleMessageEvent(message)
            }
        }

        // Error events
        let errorListener = easySDK.onError { [weak self] error in
            Task { @MainActor in
                self?.handleErrorEvent(error)
            }
        }

        // Send acknowledgment events
        let sendAckListener = easySDK.onSendAck { [weak self] result in
            Task { @MainActor in
                self?.handleSendAckEvent(result)
            }
        }

        // Reconnection events
        let reconnectingListener = easySDK.onReconnecting { [weak self] info in
            Task { @MainActor in
                self?.handleReconnectingEvent(info)
            }
        }

        // Store listeners for cleanup
        eventListeners = [
            connectListener,
            disconnectListener,
            messageListener,
            errorListener,
            sendAckListener,
            reconnectingListener
        ]
    }

    // MARK: - Event Handlers

    private func handleConnectEvent(_ result: ConnectResult) {
        isConnected = true
        isConnecting = false
        connectionStatus = "Connected"
        lastError = nil

        addLog("🟢 Connected successfully!")
        addLog("Server Key: \(result.serverKey)")
        addLog("Time Diff: \(result.timeDiff)")
        addLog("Reason Code: \(result.reasonCode)")

        if let serverVersion = result.serverVersion {
            addLog("Server Version: \(serverVersion)")
        }

        if let nodeId = result.nodeId {
            addLog("Node ID: \(nodeId)")
        }
    }

    private func handleDisconnectEvent(_ info: DisconnectInfo) {
        isConnected = false
        isConnecting = false
        connectionStatus = "Disconnected"

        addLog("🔴 Disconnected from server")
        addLog("Code: \(info.code)")
        addLog("Reason: \(info.reason)")
    }

    private func handleMessageEvent(_ message: Message) {
        addLog("📨 Message received!")
        addLog("From: \(message.fromUid)")
        addLog("Channel: \(message.channelId)")
        addLog("Type: \(message.channelType)")
        addLog("Content: \(message.payload)")

        // Add to message history
        let chatMessage = ChatMessage(
            id: message.messageId,
            content: message.payload["content"] as? String ?? "Unknown message",
            fromUserId: message.fromUid,
            channelId: message.channelId,
            channelType: ChannelType(rawValue: message.channelType) ?? .person,
            timestamp: Date(timeIntervalSince1970: TimeInterval(message.timestamp / 1000)),
            payload: message.payload,
            isOutgoing: false
        )
        messages.append(chatMessage)
    }

    private func handleErrorEvent(_ error: Error) {
        addLog("⚠️ Error occurred: \(error.localizedDescription)")

        if let wkError = error as? WuKongError {
            addLog("Error Code: \(wkError.code)")
            addLog("Is Recoverable: \(wkError.isRecoverable)")

            if let suggestion = wkError.recoverySuggestion {
                addLog("Recovery Suggestion: \(suggestion)")
            }
        }

        setError(error.localizedDescription)
    }

    private func handleSendAckEvent(_ result: SendResult) {
        addLog("✅ Send acknowledgment received")
        addLog("Message ID: \(result.messageId)")
        addLog("Message Seq: \(result.messageSeq)")
    }

    private func handleReconnectingEvent(_ info: [String: Any]) {
        let attempt = info["attempt"] as? Int ?? 0
        let delay = info["delay"] as? TimeInterval ?? 0

        connectionStatus = "Reconnecting (attempt \(attempt))..."
        addLog("🔄 Reconnecting... Attempt \(attempt), delay: \(delay)s")
    }

    private func handleConnectionError(_ error: Error) {
        isConnected = false
        isConnecting = false
        connectionStatus = "Connection Failed"

        addLog("❌ Connection failed: \(error.localizedDescription)")
        setError("Connection failed: \(error.localizedDescription)")
    }

    // MARK: - Utility Methods

    private func addLog(_ message: String) {
        let log = EventLog(
            timestamp: Date(),
            message: message,
            type: .info
        )
        eventLogs.append(log)

        // Keep only last 100 logs to prevent memory issues
        if eventLogs.count > 100 {
            eventLogs.removeFirst(eventLogs.count - 100)
        }
    }

    private func addInitialLog(_ message: String) {
        let log = EventLog(
            timestamp: Date(),
            message: message,
            type: .system
        )
        eventLogs.append(log)
    }

    private func setError(_ message: String) {
        lastError = message
        let log = EventLog(
            timestamp: Date(),
            message: "ERROR: \(message)",
            type: .error
        )
        eventLogs.append(log)
    }

    // MARK: - Public Utility Methods

    func clearLogs() {
        eventLogs.removeAll()
        addInitialLog("Logs cleared")
    }

    func clearMessages() {
        messages.removeAll()
        addLog("Message history cleared")
    }

    func clearError() {
        lastError = nil
    }
}
