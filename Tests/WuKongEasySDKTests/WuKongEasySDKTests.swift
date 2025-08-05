//
//  WuKongEasySDKTests.swift
//  WuKongEasySDKTests
//
//  Created by WuKongIM on 2024/08/04.
//  Copyright © 2024 WuKongIM. All rights reserved.
//

import XCTest
@testable import WuKongEasySDK

final class WuKongEasySDKTests: XCTestCase {
    
    var config: WuKongConfig!
    var sdk: WuKongEasySDK!
    
    override func setUpWithError() throws {
        config = try WuKongConfig(
            serverUrl: "ws://localhost:5200",
            uid: "test_user",
            token: "test_token"
        )
        sdk = WuKongEasySDK(config: config)
    }
    
    override func tearDownWithError() throws {
        sdk?.disconnect()
        sdk = nil
        config = nil
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationCreation() throws {
        let config = try WuKongConfig(
            serverUrl: "ws://test.com:5200",
            uid: "user123",
            token: "token123",
            deviceId: "device123",
            deviceFlag: .app
        )
        
        XCTAssertEqual(config.serverUrl, "ws://test.com:5200")
        XCTAssertEqual(config.uid, "user123")
        XCTAssertEqual(config.token, "token123")
        XCTAssertEqual(config.deviceId, "device123")
        XCTAssertEqual(config.deviceFlag, .app)
    }
    
    func testConfigurationValidation() {
        // Test empty server URL
        XCTAssertThrowsError(try WuKongConfig(serverUrl: "", uid: "user", token: "token")) { error in
            XCTAssertTrue(error is WuKongError)
        }
        
        // Test empty UID
        XCTAssertThrowsError(try WuKongConfig(serverUrl: "ws://test.com", uid: "", token: "token")) { error in
            XCTAssertTrue(error is WuKongError)
        }
        
        // Test empty token
        XCTAssertThrowsError(try WuKongConfig(serverUrl: "ws://test.com", uid: "user", token: "")) { error in
            XCTAssertTrue(error is WuKongError)
        }
        
        // Test invalid URL
        XCTAssertThrowsError(try WuKongConfig(serverUrl: "http://test.com", uid: "user", token: "token")) { error in
            XCTAssertTrue(error is WuKongError)
        }
    }
    
    func testConfigurationBuilder() throws {
        let config = try WuKongConfigBuilder()
            .serverUrl("ws://test.com:5200")
            .uid("user123")
            .token("token123")
            .deviceFlag(.web)
            .connectionTimeout(60)
            .enableDebugLogging(true)
            .build()
        
        XCTAssertEqual(config.serverUrl, "ws://test.com:5200")
        XCTAssertEqual(config.uid, "user123")
        XCTAssertEqual(config.token, "token123")
        XCTAssertEqual(config.deviceFlag, .web)
        XCTAssertEqual(config.connectionTimeout, 60)
        XCTAssertTrue(config.enableDebugLogging)
    }
    
    // MARK: - SDK Initialization Tests
    
    func testSDKInitialization() {
        XCTAssertNotNil(sdk)
        XCTAssertEqual(sdk.configuration.serverUrl, config.serverUrl)
        XCTAssertEqual(sdk.configuration.uid, config.uid)
        XCTAssertFalse(sdk.isConnected)
    }
    
    func testSDKFactoryMethods() throws {
        let sdk1 = try WuKongEasySDK.create(
            serverUrl: "ws://test.com:5200",
            uid: "user123",
            token: "token123"
        )
        XCTAssertNotNil(sdk1)
        
        let sdk2 = try WuKongEasySDK.create { builder in
            try builder
                .serverUrl("ws://test.com:5200")
                .uid("user123")
                .token("token123")
                .build()
        }
        XCTAssertNotNil(sdk2)
    }
    
    // MARK: - Event Listener Tests
    
    func testEventListenerManagement() {
        var connectCalled = false
        var messageCalled = false
        var errorCalled = false
        
        let connectListener = sdk.onConnect { _ in
            connectCalled = true
        }
        
        let messageListener = sdk.onMessage { _ in
            messageCalled = true
        }
        
        let errorListener = sdk.onError { _ in
            errorCalled = true
        }
        
        // Test listener count
        XCTAssertEqual(sdk.listenerCount(for: .connect), 1)
        XCTAssertEqual(sdk.listenerCount(for: .message), 1)
        XCTAssertEqual(sdk.listenerCount(for: .error), 1)
        XCTAssertEqual(sdk.totalListenerCount(), 3)
        
        // Test listener removal
        sdk.removeListener(connectListener)
        XCTAssertEqual(sdk.listenerCount(for: .connect), 0)
        XCTAssertEqual(sdk.totalListenerCount(), 2)
        
        // Test remove all listeners for event
        sdk.removeAllListeners(for: .message)
        XCTAssertEqual(sdk.listenerCount(for: .message), 0)
        XCTAssertEqual(sdk.totalListenerCount(), 1)
        
        // Test remove all listeners
        sdk.removeAllListeners()
        XCTAssertEqual(sdk.totalListenerCount(), 0)
    }
    
    // MARK: - Message Payload Tests

    func testMessagePayloadCreation() throws {
        // Test convenience initializer with data
        let payload1 = MessagePayload(type: 1, content: "Test message", data: ["key": "value"])

        XCTAssertEqual(payload1.type, 1)
        XCTAssertEqual(payload1.content, "Test message")
        XCTAssertEqual(payload1["key"] as? String, "value")

        let dict1 = payload1.toDictionary()
        XCTAssertEqual(dict1["type"] as? Int, 1)
        XCTAssertEqual(dict1["content"] as? String, "Test message")
        XCTAssertEqual(dict1["key"] as? String, "value")

        // Test dictionary literal initialization
        let payload2: MessagePayload = ["type": 2, "content": "Hello", "custom": true]
        XCTAssertEqual(payload2.type, 2)
        XCTAssertEqual(payload2.content, "Hello")
        XCTAssertEqual(payload2["custom"] as? Bool, true)

        // Test content-only initializer
        let payload3 = MessagePayload(content: "Simple message")
        XCTAssertEqual(payload3.type, 1)
        XCTAssertEqual(payload3.content, "Simple message")

        // Test empty initializer
        let payload4 = MessagePayload()
        XCTAssertTrue(payload4.isEmpty)
        XCTAssertEqual(payload4.count, 0)
    }
    
    func testMessagePayloadSerialization() throws {
        let payload = MessagePayload(type: 1, content: "Test", data: ["custom": "data"])

        // Test encoding
        let data = try JSONEncoder().encode(payload)
        XCTAssertFalse(data.isEmpty)

        // Test decoding
        let decodedPayload = try JSONDecoder().decode(MessagePayload.self, from: data)
        XCTAssertEqual(decodedPayload.type, payload.type)
        XCTAssertEqual(decodedPayload.content, payload.content)
        XCTAssertEqual(decodedPayload["custom"] as? String, "data")
    }

    func testMessagePayloadOperations() {
        var payload = MessagePayload()
        XCTAssertTrue(payload.isEmpty)
        XCTAssertEqual(payload.count, 0)

        // Test subscript access
        payload["type"] = 1
        payload["content"] = "Hello"
        payload["timestamp"] = Date().timeIntervalSince1970

        XCTAssertEqual(payload.count, 3)
        XCTAssertFalse(payload.isEmpty)
        XCTAssertEqual(payload.type, 1)
        XCTAssertEqual(payload.content, "Hello")

        // Test getValue with type casting
        let timestamp = payload.getValue(forKey: "timestamp", as: Double.self)
        XCTAssertNotNil(timestamp)

        // Test removeValue
        let removedValue = payload.removeValue(forKey: "timestamp")
        XCTAssertNotNil(removedValue)
        XCTAssertEqual(payload.count, 2)

        // Test merge
        let other: MessagePayload = ["extra": "data", "type": 2] // type should be overwritten
        payload.merge(other)
        XCTAssertEqual(payload.count, 3)
        XCTAssertEqual(payload.type, 2) // Should be overwritten
        XCTAssertEqual(payload["extra"] as? String, "data")

        // Test merging method (non-mutating)
        let payload1: MessagePayload = ["a": 1, "b": 2]
        let payload2: MessagePayload = ["b": 3, "c": 4]
        let merged = payload1.merging(payload2)
        XCTAssertEqual(merged["a"] as? Int, 1)
        XCTAssertEqual(merged["b"] as? Int, 3) // Should be overwritten
        XCTAssertEqual(merged["c"] as? Int, 4)
        XCTAssertEqual(merged.count, 3)
    }
    
    // MARK: - Error Tests
    
    func testWuKongErrorTypes() {
        let connectionError = WuKongError.connectionFailed("Test error")
        XCTAssertTrue(connectionError.isConnectionError)
        XCTAssertTrue(connectionError.isRecoverable)
        XCTAssertEqual(connectionError.code, 1001)
        
        let authError = WuKongError.authFailed("Auth failed")
        XCTAssertTrue(authError.isConnectionError)
        XCTAssertFalse(authError.isRecoverable)
        
        let payloadError = WuKongError.invalidPayload("Invalid payload")
        XCTAssertFalse(payloadError.isConnectionError)
        XCTAssertFalse(payloadError.isRecoverable)
    }
    
    func testErrorFromURLError() {
        let urlError = URLError(.timedOut)
        let wkError = WuKongError.from(urlError: urlError)
        
        if case .connectionTimeout = wkError {
            // Expected
        } else {
            XCTFail("Expected connectionTimeout error")
        }
    }
    
    // MARK: - Channel Type Tests
    
    func testChannelTypes() {
        XCTAssertEqual(ChannelType.person.rawValue, 1)
        XCTAssertEqual(ChannelType.group.rawValue, 2)
        XCTAssertEqual(ChannelType.community.rawValue, 4)
        
        // Test all cases are covered
        XCTAssertEqual(ChannelType.allCases.count, 10)
    }
    
    // MARK: - Device Flag Tests
    
    func testDeviceFlags() {
        XCTAssertEqual(DeviceFlag.app.rawValue, 1)
        XCTAssertEqual(DeviceFlag.web.rawValue, 2)
        XCTAssertEqual(DeviceFlag.desktop.rawValue, 3)
        XCTAssertEqual(DeviceFlag.other.rawValue, 4)
    }
    
    // MARK: - Data Structure Tests
    
    func testConnectResult() {
        let result = ConnectResult(
            serverKey: "key123",
            salt: "salt123",
            timeDiff: 1000,
            reasonCode: 200,
            serverVersion: 1,
            nodeId: 1
        )
        
        XCTAssertEqual(result.serverKey, "key123")
        XCTAssertEqual(result.salt, "salt123")
        XCTAssertEqual(result.timeDiff, 1000)
        XCTAssertEqual(result.reasonCode, 200)
        XCTAssertEqual(result.serverVersion, 1)
        XCTAssertEqual(result.nodeId, 1)
    }
    
    func testSendResult() {
        let result = SendResult(messageId: "msg123", messageSeq: 456)
        
        XCTAssertEqual(result.messageId, "msg123")
        XCTAssertEqual(result.messageSeq, 456)
    }
    
    func testDisconnectInfo() {
        let info = DisconnectInfo(code: 1000, reason: "Normal closure")
        
        XCTAssertEqual(info.code, 1000)
        XCTAssertEqual(info.reason, "Normal closure")
    }
    
    func testHeader() {
        let header = Header(noPersist: true, redDot: false, syncOnce: true, dup: false)
        
        XCTAssertEqual(header.noPersist, true)
        XCTAssertEqual(header.redDot, false)
        XCTAssertEqual(header.syncOnce, true)
        XCTAssertEqual(header.dup, false)
    }
    
    // MARK: - Performance Tests
    
    func testEventListenerPerformance() {
        measure {
            for _ in 0..<1000 {
                let listener = sdk.onMessage { _ in }
                sdk.removeListener(listener)
            }
        }
    }
    
    func testMessagePayloadPerformance() {
        let payload = MessagePayload(type: 1, content: "Test message", data: ["key": "value"])

        measure {
            for _ in 0..<1000 {
                _ = payload.toDictionary()
            }
        }
    }

    // MARK: - JSON-RPC Protocol Tests

    func testJsonRpcRequestFormat() {
        // Test that JsonRpcRequest produces correct JSON-RPC 2.0 format
        let params: [String: Any] = [
            "uid": "testUser",
            "token": "testToken",
            "deviceId": "device123",
            "deviceFlag": 1,
            "clientTimestamp": 1691234567890
        ]

        let request = JsonRpcRequest(method: "connect", params: params, id: "test-id")

        do {
            let data = try JSONEncoder().encode(request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            XCTAssertNotNil(json)
            XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
            XCTAssertEqual(json?["method"] as? String, "connect")
            XCTAssertEqual(json?["id"] as? String, "test-id")

            let paramsJson = json?["params"] as? [String: Any]
            XCTAssertNotNil(paramsJson)
            XCTAssertEqual(paramsJson?["uid"] as? String, "testUser")
            XCTAssertEqual(paramsJson?["token"] as? String, "testToken")
            XCTAssertEqual(paramsJson?["deviceId"] as? String, "device123")
            XCTAssertEqual(paramsJson?["deviceFlag"] as? Int, 1)
            XCTAssertEqual(paramsJson?["clientTimestamp"] as? Int, 1691234567890)

        } catch {
            XCTFail("Failed to encode/decode JsonRpcRequest: \(error)")
        }
    }

    func testJsonRpcNotificationFormat() {
        // Test that JsonRpcNotification produces correct JSON-RPC 2.0 format
        let params: [String: Any] = [
            "messageId": "msg123",
            "messageSeq": 456
        ]

        let notification = JsonRpcNotification(method: "recvack", params: params)

        do {
            let data = try JSONEncoder().encode(notification)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            XCTAssertNotNil(json)
            XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
            XCTAssertEqual(json?["method"] as? String, "recvack")
            XCTAssertNil(json?["id"]) // Notifications don't have id

            let paramsJson = json?["params"] as? [String: Any]
            XCTAssertNotNil(paramsJson)
            XCTAssertEqual(paramsJson?["messageId"] as? String, "msg123")
            XCTAssertEqual(paramsJson?["messageSeq"] as? Int, 456)

        } catch {
            XCTFail("Failed to encode/decode JsonRpcNotification: \(error)")
        }
    }
}
