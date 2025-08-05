//
//  BasicExample.swift
//  WuKongEasySDK Examples
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import Foundation
import WuKongEasySDK

/// Basic example demonstrating how to use WuKongEasySDK
class BasicExample {
    
    private var easySDK: WuKongEasySDK?
    private var messageListener: EventListener?
    private var connectListener: EventListener?
    private var disconnectListener: EventListener?
    private var errorListener: EventListener?
    
    /// Initialize and connect to WuKongIM server
    func run() async {
        do {
            // 1. Create configuration
            let config = try WuKongConfig(
                serverUrl: "ws://localhost:5200",  // Replace with your server URL
                uid: "user_123",                   // Replace with actual user ID
                token: "auth_token_123",           // Replace with actual auth token
                deviceId: nil,                     // Optional: will auto-generate if nil
                deviceFlag: .app                   // Device type
            )
            
            // 2. Initialize SDK
            easySDK = WuKongEasySDK(config: config)
            
            // 3. Set up event listeners
            setupEventListeners()
            
            // 4. Connect to server
            print("🔄 Connecting to WuKongIM server...")
            try await easySDK?.connect()
            
            // 5. Wait a bit for connection to establish
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // 6. Send a test message
            await sendTestMessage()
            
            // 7. Keep running for a while to receive messages
            print("📱 Listening for messages... (Press Ctrl+C to stop)")
            try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Set up event listeners
    private func setupEventListeners() {
        guard let easySDK = easySDK else { return }
        
        // Connection events
        connectListener = easySDK.onConnect { result in
            print("✅ Connected successfully!")
            print("   Server Key: \(result.serverKey)")
            print("   Time Diff: \(result.timeDiff)")
            print("   Reason Code: \(result.reasonCode)")
        }
        
        disconnectListener = easySDK.onDisconnect { disconnectInfo in
            print("❌ Disconnected from server")
            print("   Code: \(disconnectInfo.code)")
            print("   Reason: \(disconnectInfo.reason)")
        }
        
        // Message events
        messageListener = easySDK.onMessage { message in
            print("📨 Received message:")
            print("   From: \(message.fromUid)")
            print("   Channel: \(message.channelId)")
            print("   Content: \(message.payload)")
            print("   Timestamp: \(Date(timeIntervalSince1970: TimeInterval(message.timestamp / 1000)))")
        }
        
        // Error events
        errorListener = easySDK.onError { error in
            print("⚠️ Error occurred: \(error.localizedDescription)")
            
            if let wkError = error as? WuKongError {
                switch wkError {
                case .authFailed(let message):
                    print("   Authentication failed: \(message)")
                case .networkError(let message):
                    print("   Network error: \(message)")
                case .connectionFailed(let message):
                    print("   Connection failed: \(message)")
                default:
                    print("   Other error: \(wkError)")
                }
            }
        }
        
        // Reconnection events
        easySDK.onReconnecting { info in
            let attempt = info["attempt"] as? Int ?? 0
            let delay = info["delay"] as? TimeInterval ?? 0
            print("🔄 Reconnecting... Attempt \(attempt), delay: \(delay)s")
        }
        
        // Send acknowledgment events
        easySDK.onSendAck { result in
            print("✅ Message sent successfully:")
            print("   Message ID: \(result.messageId)")
            print("   Sequence: \(result.messageSeq)")
        }
    }
    
    /// Send a test message
    private func sendTestMessage() async {
        guard let easySDK = easySDK, easySDK.isConnected else {
            print("❌ Cannot send message: not connected")
            return
        }
        
        do {
            // Example 1: Using dictionary literal syntax (most flexible)
            let payload: MessagePayload = [
                "type": 1,
                "content": "Hello from iOS WuKongEasySDK! 🎉",
                "timestamp": Date().timeIntervalSince1970,
                "platform": "iOS",
                "version": "1.0.0",
                "metadata": [
                    "device": "iPhone",
                    "app_version": "1.0.0"
                ]
            ]
            
            print("📤 Sending test message...")
            let result = try await easySDK.send(
                channelId: "test_channel",  // Replace with actual channel ID
                channelType: .person,       // Or .group for group messages
                payload: payload
            )
            
            print("✅ Message queued for sending:")
            print("   Message ID: \(result.messageId)")
            print("   Sequence: \(result.messageSeq)")
            
        } catch {
            print("❌ Failed to send message: \(error)")
        }
    }
    
    /// Clean up resources
    func cleanup() {
        print("🧹 Cleaning up...")
        
        // Remove event listeners
        if let listener = messageListener {
            easySDK?.removeListener(listener)
        }
        if let listener = connectListener {
            easySDK?.removeListener(listener)
        }
        if let listener = disconnectListener {
            easySDK?.removeListener(listener)
        }
        if let listener = errorListener {
            easySDK?.removeListener(listener)
        }
        
        // Disconnect
        easySDK?.disconnect()
        
        print("✅ Cleanup completed")
    }
    
    deinit {
        cleanup()
    }
}

/// Advanced example with configuration builder
class AdvancedExample {
    
    private var easySDK: WuKongEasySDK?
    
    func run() async {
        do {
            // Create SDK with configuration builder
            easySDK = try WuKongEasySDK.create { builder in
                try builder
                    .serverUrl("ws://localhost:5200")
                    .uid("advanced_user_123")
                    .token("advanced_token_123")
                    .deviceFlag(.app)
                    .connectionTimeout(30)
                    .requestTimeout(15)
                    .pingInterval(25)
                    .maxReconnectAttempts(5)
                    .autoReconnect(true)
                    .enableDebugLogging(true)
                    .logLevel(.debug)
                    .build()
            }
            
            guard let easySDK = easySDK else { return }
            
            // Set up listeners with more detailed handling
            setupAdvancedListeners()
            
            // Connect
            print("🔄 Connecting with advanced configuration...")
            try await easySDK.connect()
            
            // Send multiple messages
            await sendMultipleMessages()
            
            // Keep running
            try await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
            
        } catch {
            print("❌ Advanced example error: \(error)")
        }
    }
    
    private func setupAdvancedListeners() {
        guard let easySDK = easySDK else { return }
        
        easySDK.onConnect { result in
            print("🚀 Advanced connection established!")
            print("   Server Version: \(result.serverVersion ?? 0)")
            print("   Node ID: \(result.nodeId ?? 0)")
        }
        
        easySDK.onMessage { message in
            print("📨 Advanced message received:")
            print("   Channel Type: \(ChannelType(rawValue: message.channelType) ?? .person)")
            print("   Has Topic: \(message.topic != nil)")
            print("   Stream Info: \(message.streamId ?? "none")")
        }
        
        easySDK.onError { error in
            print("⚠️ Advanced error handling:")
            if let wkError = error as? WuKongError {
                print("   Error Code: \(wkError.code)")
                print("   Is Recoverable: \(wkError.isRecoverable)")
                print("   Recovery Suggestion: \(wkError.recoverySuggestion ?? "none")")
            }
        }
    }
    
    private func sendMultipleMessages() async {
        guard let easySDK = easySDK else { return }

        // Demonstrate different ways to create message payloads
        let examples: [(String, MessagePayload, ChannelType)] = [
            // Example 1: Dictionary literal (most flexible)
            ("user1", [
                "type": 1,
                "content": "Hello user1! 👋",
                "priority": "high",
                "metadata": ["source": "advanced_example"]
            ], .person),

            // Example 2: Convenience initializer
            ("user2", MessagePayload(content: "Hello user2! 🎉"), .person),

            // Example 3: Structured initializer with additional data
            ("user3", MessagePayload(type: 2, content: "Hello user3!", data: [
                "attachment": "image.jpg",
                "timestamp": Date().timeIntervalSince1970
            ]), .person),

            // Example 4: Custom message type
            ("group1", [
                "type": 100,
                "action": "join_group",
                "user_id": "advanced_user_123",
                "group_name": "Advanced Group"
            ], .group),

            // Example 5: Rich media message
            ("user4", [
                "type": 3,
                "content": "Check out this location!",
                "location": [
                    "latitude": 37.7749,
                    "longitude": -122.4194,
                    "address": "San Francisco, CA"
                ],
                "media_type": "location"
            ], .person)
        ]

        for (channelId, payload, channelType) in examples {
            do {
                let result = try await easySDK.send(
                    channelId: channelId,
                    channelType: channelType,
                    payload: payload
                )

                print("📤 Sent to \(channelId): \(result.messageId)")
                print("   Payload: \(payload.toDictionary())")

                // Wait between messages
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            } catch {
                print("❌ Failed to send to \(channelId): \(error)")
            }
        }
    }
}

// MARK: - Main Entry Point

/// Run the examples
@main
struct ExampleRunner {
    static func main() async {
        print("🚀 WuKongEasySDK Examples")
        print("========================")
        
        // Run basic example
        print("\n📱 Running Basic Example...")
        let basicExample = BasicExample()
        await basicExample.run()
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Run advanced example
        print("\n🔧 Running Advanced Example...")
        let advancedExample = AdvancedExample()
        await advancedExample.run()
        
        print("\n✅ Examples completed!")
    }
}
