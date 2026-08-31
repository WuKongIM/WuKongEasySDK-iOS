import Darwin
import Foundation
import Starscream
import XCTest
@testable import WuKongEasySDK

@available(macOS 12.0, *)
final class LoggingSecurityTests: XCTestCase {
    func testDisabledLoggingSilencesSdkEventAndWebSocketDiagnostics() throws {
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "TOKEN_CANARY_DISABLED_9E4152A7",
            autoReconnect: false,
            enableDebugLogging: false,
            logLevel: .info,
            enableJsonLogging: true
        )
        let (socket, eventManager, client) = makeSocket(config: config)

        let output = captureStandardOutput {
            let sdk = WuKongEasySDK(config: config)
            _ = sdk.onMessage { _ in }
            _ = eventManager.onError { _ in }
            socket.didReceive(
                event: .text(#"{"jsonrpc":"2.0","method":"futureMethod","params":{"payload":"PAYLOAD_CANARY_DISABLED_0F3E5C7B"}}"#),
                client: client
            )
            socket.didReceive(
                event: .error(NSError(domain: "ERROR_CANARY_DISABLED_63B7728D", code: 7)),
                client: client
            )
            withExtendedLifetime(sdk) {}
        }

        XCTAssertEqual(output, "", "enableDebugLogging=false must silence INFO, ERROR, DEBUG, and JSON diagnostics: \(output)")
    }

    func testDisabledLoggingRemainsSilentWhenLogLevelIsDebug() throws {
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: false,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)

        let output = captureStandardOutput {
            let sdk = WuKongEasySDK(config: config)
            _ = sdk.onMessage { _ in }
            socket.didReceive(
                event: .text(#"{"jsonrpc":"2.0","method":"recv","params":{"payload":"LEVEL_CANARY_3DCE68D1"}}"#),
                client: client
            )
            socket.didReceive(event: .error(NSError(domain: "level-canary", code: 8)), client: client)
            withExtendedLifetime(sdk) {}
        }

        XCTAssertEqual(output, "", "logLevel must not bypass the enableDebugLogging master switch: \(output)")
    }

    func testDisabledDebugLoggingDoesNotExposeReceivedPayload() throws {
        let payloadCanary = "PAYLOAD_CANARY_6E7A0A87"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: false,
            logLevel: .info,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)
        let incomingMessage = """
        {
          "jsonrpc": "2.0",
          "method": "recv",
          "params": {
            "header": {},
            "messageId": "message-1",
            "messageSeq": 1,
            "timestamp": 1,
            "channelId": "alice",
            "channelType": 1,
            "fromUid": "bob",
            "payload": {"type": 1, "content": "\(payloadCanary)"}
          }
        }
        """

        let output = captureStandardOutput {
            socket.didReceive(event: .text(incomingMessage), client: client)
        }

        XCTAssertFalse(output.contains("[DEBUG]"), "enableDebugLogging=false still emitted debug output: \(output)")
        XCTAssertFalse(output.contains("[JSON]"), "enableDebugLogging=false still emitted JSON output: \(output)")
        XCTAssertFalse(output.contains(payloadCanary), "Disabled logging exposed the received payload: \(output)")
    }

    func testDebugJsonLoggingRedactsReceivedPayloadButKeepsEnvelopeMetadata() throws {
        let payloadCanary = "PAYLOAD_CANARY_3C0E4BA8"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)
        let incomingMessage = """
        {
          "jsonrpc": "2.0",
          "method": "recv",
          "params": {
            "header": {},
            "messageId": "message-2",
            "messageSeq": 2,
            "timestamp": 2,
            "channelId": "alice",
            "channelType": 1,
            "fromUid": "bob",
            "payload": {"type": 1, "content": "\(payloadCanary)"}
          }
        }
        """

        let output = captureStandardOutput {
            socket.didReceive(event: .text(incomingMessage), client: client)
        }

        XCTAssertTrue(output.contains("NOTIFICATION[recv]"), "Debug logging should retain JSON-RPC envelope metadata: \(output)")
        XCTAssertFalse(output.contains(payloadCanary), "Debug logging exposed the received payload: \(output)")
    }

    func testDebugJsonLoggingDoesNotEchoMalformedInput() throws {
        let malformedCanary = "MALFORMED_CANARY_23D4819F"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)
        let malformedMessage = "{\"payload\":\"\(malformedCanary)\""

        let output = captureStandardOutput {
            socket.didReceive(event: .text(malformedMessage), client: client)
        }

        XCTAssertTrue(output.contains("Malformed JSON data"), "Debug logging should retain the parse failure category: \(output)")
        XCTAssertFalse(output.contains(malformedCanary), "Malformed input was echoed into debug logs: \(output)")
    }

    func testDebugJsonLoggingRedactsUnknownNotificationParams() throws {
        let paramsCanary = "UNKNOWN_PARAMS_CANARY_D3756592"
        let methodCanary = "UNKNOWN_METHOD_CANARY_BAC59E20"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)
        let incomingMessage = """
        {
          "jsonrpc": "2.0",
          "method": "\(methodCanary)",
          "params": {"arbitrary": "\(paramsCanary)"}
        }
        """

        let output = captureStandardOutput {
            socket.didReceive(event: .text(incomingMessage), client: client)
        }

        XCTAssertTrue(output.contains("NOTIFICATION[unknown]"), "Debug logging should classify an unknown method without echoing it: \(output)")
        XCTAssertFalse(output.contains(methodCanary), "Unknown notification method was exposed: \(output)")
        XCTAssertFalse(output.contains(paramsCanary), "Unknown notification params were exposed: \(output)")
    }

    func testDebugJsonLoggingRedactsUnclassifiedJsonObject() throws {
        let objectCanary = "UNKNOWN_OBJECT_CANARY_F5820863"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)
        let incomingMessage = """
        {"unexpected":"\(objectCanary)"}
        """

        let output = captureStandardOutput {
            socket.didReceive(event: .text(incomingMessage), client: client)
        }

        XCTAssertTrue(output.contains("RECEIVED ERROR"), "Debug logging should retain the unclassified-message category: \(output)")
        XCTAssertFalse(output.contains(objectCanary), "Unclassified JSON input was exposed: \(output)")
    }

    func testDebugJsonLoggingRedactsResponseBodies() throws {
        let resultCanary = "RESULT_CANARY_6700B7CF"
        let errorCanary = "ERROR_CANARY_EFF58D57"
        let resultIdCanary = "RESULT_ID_CANARY_E92BF61E"
        let errorIdCanary = "ERROR_ID_CANARY_B253EC25"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)
        let resultResponse = """
        {"jsonrpc":"2.0","id":"\(resultIdCanary)","result":{"arbitrary":"\(resultCanary)"}}
        """
        let errorResponse = """
        {"jsonrpc":"2.0","id":"\(errorIdCanary)","error":{"code":500,"message":"\(errorCanary)"}}
        """

        let output = captureStandardOutput {
            socket.didReceive(event: .text(resultResponse), client: client)
            socket.didReceive(event: .text(errorResponse), client: client)
        }

        XCTAssertTrue(output.contains("ID:present"), "Debug logging should retain response correlation presence: \(output)")
        XCTAssertFalse(output.contains(resultIdCanary), "Response correlation ID was exposed: \(output)")
        XCTAssertFalse(output.contains(errorIdCanary), "Error correlation ID was exposed: \(output)")
        XCTAssertFalse(output.contains(resultCanary), "Response result body was exposed: \(output)")
        XCTAssertFalse(output.contains(errorCanary), "Response error body was exposed: \(output)")
    }

    func testJsonDataLogEventsExposeOnlySafeMetadata() throws {
        let methodCanary = "EVENT_METHOD_CANARY_F9F8F379"
        let requestIdCanary = "EVENT_ID_CANARY_7A161E01"
        let bodyCanary = "EVENT_BODY_CANARY_E25A2383"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, eventManager, client) = makeSocket(config: config)
        var capturedEvents: [JSONDataLogEvent] = []
        let receivedEvents = expectation(description: "redacted JSON data log events")
        receivedEvents.expectedFulfillmentCount = 2
        let listener = eventManager.onJsonDataLog { event in
            capturedEvents.append(event)
            receivedEvents.fulfill()
        }
        let notification = """
        {"jsonrpc":"2.0","method":"\(methodCanary)","params":{"arbitrary":"\(bodyCanary)"}}
        """
        let response = """
        {"jsonrpc":"2.0","id":"\(requestIdCanary)","result":{"arbitrary":"\(bodyCanary)"}}
        """

        _ = captureStandardOutput {
            socket.didReceive(event: .text(notification), client: client)
            socket.didReceive(event: .text(response), client: client)
            wait(for: [receivedEvents], timeout: 1)
        }

        XCTAssertEqual(capturedEvents.count, 2)
        XCTAssertEqual(capturedEvents[0].method, "unknown")
        XCTAssertNil(capturedEvents[0].requestId)
        XCTAssertNil(capturedEvents[1].method)
        XCTAssertEqual(capturedEvents[1].requestId, "present")
        for event in capturedEvents {
            XCTAssertFalse(event.jsonString.contains(methodCanary))
            XCTAssertFalse(event.jsonString.contains(requestIdCanary))
            XCTAssertFalse(event.jsonString.contains(bodyCanary))
        }
        withExtendedLifetime(listener) {}
    }

    func testDebugLoggingDoesNotEchoConnectionUrlOrDisconnectReasons() throws {
        let urlCanary = "URL_CANARY_4A1D784C"
        let serverReasonCanary = "SERVER_REASON_CANARY_5D9182C7"
        let transportReasonCanary = "TRANSPORT_REASON_CANARY_7E0010F5"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200/connect?credential=\(urlCanary)",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)
        let serverDisconnect = """
        {"jsonrpc":"2.0","method":"disconnect","params":{"reasonCode":1000,"reason":"\(serverReasonCanary)"}}
        """

        let output = captureStandardOutput {
            let sdk = WuKongEasySDK(config: config)
            socket.didReceive(event: .text(serverDisconnect), client: client)
            socket.didReceive(event: .disconnected(transportReasonCanary, 1000), client: client)
            withExtendedLifetime(sdk) {}
        }

        XCTAssertTrue(output.contains("initialized"), "Initialization diagnostics should remain available: \(output)")
        XCTAssertTrue(output.contains("Server initiated disconnect"), "Server disconnect diagnostics should retain their category: \(output)")
        XCTAssertTrue(output.contains("WebSocket connection closed with code: 1000"), "Transport close diagnostics should retain their code: \(output)")
        XCTAssertFalse(output.contains(urlCanary), "Connection URL details were exposed: \(output)")
        XCTAssertFalse(output.contains(serverReasonCanary), "Server disconnect reason was exposed: \(output)")
        XCTAssertFalse(output.contains(transportReasonCanary), "Transport disconnect reason was exposed: \(output)")
    }

    func testErrorLoggingDoesNotExposeSensitiveErrorDetails() throws {
        let tokenCanary = "TOKEN_CANARY_B6D4C0AE"
        let payloadCanary = "ERROR_PAYLOAD_CANARY_69E24E9F"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: tokenCanary,
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .error,
            enableJsonLogging: false
        )
        let (socket, _, client) = makeSocket(config: config)
        let transportError = NSError(domain: "Transport-\(tokenCanary)-\(payloadCanary)", code: 1)

        let output = captureStandardOutput {
            socket.didReceive(event: .error(transportError), client: client)
        }

        XCTAssertTrue(output.contains("WebSocket error"), "Error logging should retain its category: \(output)")
        XCTAssertFalse(output.contains(tokenCanary), "Error logging exposed the configured token: \(output)")
        XCTAssertFalse(output.contains(payloadCanary), "Error logging exposed unstructured error details: \(output)")
    }

    func testEnableDebugLoggingActivatesPublicSdkDebugOutput() throws {
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: false
        )

        let output = captureStandardOutput {
            let sdk = WuKongEasySDK(config: config)
            _ = sdk.onMessage { _ in }
            withExtendedLifetime(sdk) {}
        }

        XCTAssertTrue(output.contains("[DEBUG] Added message event listener"), "enableDebugLogging was ignored: \(output)")
    }

    func testEnabledLoggingStillUsesLogLevelAsSeverityFilter() throws {
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .info,
            enableJsonLogging: true
        )
        let (socket, _, client) = makeSocket(config: config)

        let output = captureStandardOutput {
            let sdk = WuKongEasySDK(config: config)
            _ = sdk.onMessage { _ in }
            socket.didReceive(
                event: .text(#"{"jsonrpc":"2.0","method":"futureMethod","params":{"payload":"FILTER_CANARY_428762DF"}}"#),
                client: client
            )
            socket.didReceive(event: .error(NSError(domain: "filter-canary", code: 9)), client: client)
            withExtendedLifetime(sdk) {}
        }

        XCTAssertTrue(output.contains("[INFO] WuKongEasySDK initialized"), "Info diagnostics should remain enabled: \(output)")
        XCTAssertTrue(output.contains("[ERROR] WebSocket error"), "Error diagnostics should remain enabled: \(output)")
        XCTAssertFalse(output.contains("[DEBUG]"), "Info level must filter debug diagnostics: \(output)")
        XCTAssertFalse(output.contains("[JSON]"), "Info level must filter JSON diagnostics: \(output)")
        XCTAssertFalse(output.contains("FILTER_CANARY_428762DF"), "Filtered diagnostics exposed wire data: \(output)")
    }

    func testConfigBuilderCanDisableJsonLogging() throws {
        let config = try WuKongConfigBuilder()
            .serverUrl("ws://127.0.0.1:5200")
            .uid("alice")
            .token("safe-test-token")
            .enableDebugLogging(true)
            .enableJsonLogging(false)
            .build()

        XCTAssertFalse(config.enableJsonLogging)
    }

    func testJsonLoggingCanBeDisabledWhileDebugLoggingRemainsEnabled() throws {
        let paramsCanary = "JSON_DISABLED_CANARY_95304F53"
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug,
            enableJsonLogging: false
        )
        let (socket, _, client) = makeSocket(config: config)
        let incomingMessage = """
        {"jsonrpc":"2.0","method":"futureMethod","params":{"arbitrary":"\(paramsCanary)"}}
        """

        let output = captureStandardOutput {
            socket.didReceive(event: .text(incomingMessage), client: client)
        }

        XCTAssertTrue(output.contains("Received notification: unknown"), "Debug diagnostics should remain enabled: \(output)")
        XCTAssertFalse(output.contains("[JSON]"), "enableJsonLogging=false was ignored: \(output)")
        XCTAssertFalse(output.contains(paramsCanary), "Disabled JSON logging exposed wire data: \(output)")
    }

    func testPublicModelsUseRedactedStringRepresentations() {
        let authOptions = AuthOptions(
            uid: "AUTH_UID_CANARY_474D1C21",
            token: "AUTH_TOKEN_CANARY_D74F8A60",
            deviceId: "AUTH_DEVICE_CANARY_0F4E5BE6"
        )
        assertSafeStringRepresentations(
            authOptions,
            expected: "AuthOptions(<redacted>)",
            forbidden: [authOptions.uid, authOptions.token, authOptions.deviceId!]
        )

        let connectResult = ConnectResult(
            serverKey: "SERVER_KEY_CANARY_C6D98603",
            salt: "SALT_CANARY_EE8E9C55",
            timeDiff: 42,
            reasonCode: 0,
            serverVersion: 3,
            nodeId: 7
        )
        assertSafeStringRepresentations(
            connectResult,
            expected: "ConnectResult(reasonCode: 0, <redacted>)",
            forbidden: [connectResult.serverKey, connectResult.salt]
        )

        let sendResult = SendResult(
            messageId: "MESSAGE_ID_CANARY_2709D543",
            messageSeq: 23
        )
        assertSafeStringRepresentations(
            sendResult,
            expected: "SendResult(messageSeq: 23, messageId: <redacted>)",
            forbidden: [sendResult.messageId]
        )

        let message = Message(
            header: Header(),
            messageId: "RECV_MESSAGE_ID_CANARY_A0B827B8",
            messageSeq: 31,
            timestamp: 1,
            channelId: "CHANNEL_ID_CANARY_E5EE557C",
            channelType: 2,
            fromUid: "FROM_UID_CANARY_B861159E",
            payload: ["content": "PAYLOAD_CANARY_754930EE"],
            clientMsgNo: "CLIENT_MSG_CANARY_55591723",
            streamNo: "STREAM_NO_CANARY_95093ECB",
            streamId: "STREAM_ID_CANARY_3BB3AA4C",
            streamFlag: 1,
            topic: "TOPIC_CANARY_0CF97577"
        )
        assertSafeStringRepresentations(
            message,
            expected: "Message(messageSeq: 31, channelType: 2, payload: <redacted>)",
            forbidden: [
                message.messageId,
                message.channelId,
                message.fromUid,
                message.payload["content"] as! String,
                message.clientMsgNo!,
                message.streamNo!,
                message.streamId!,
                message.topic!
            ]
        )

        let disconnectInfo = DisconnectInfo(
            code: 1008,
            reason: "DISCONNECT_REASON_CANARY_EB2C8CA5"
        )
        assertSafeStringRepresentations(
            disconnectInfo,
            expected: "DisconnectInfo(code: 1008, reason: <redacted>)",
            forbidden: [disconnectInfo.reason]
        )

        let payload = MessagePayload([
            "content": "OUTBOUND_PAYLOAD_CANARY_6BC7E640",
            "secretKey": "PAYLOAD_SECRET_CANARY_ECA20479"
        ])
        assertSafeStringRepresentations(
            payload,
            expected: "MessagePayload(count: 2, payload: <redacted>)",
            forbidden: [
                payload.content!,
                payload.getValue(forKey: "secretKey", as: String.self)!
            ]
        )
    }

    func testWuKongErrorUsesRedactedStringRepresentations() {
        let cases: [(error: WuKongError, category: String, forbidden: [String])] = [
            (.connectionFailed("CONNECTION_CANARY_097551B8"), "connectionFailed", ["CONNECTION_CANARY_097551B8"]),
            (.authFailed("AUTH_ERROR_CANARY_4BCAFE96"), "authFailed", ["AUTH_ERROR_CANARY_4BCAFE96"]),
            (.serverDisconnected(1008, "DISCONNECT_ERROR_CANARY_123723FD"), "serverDisconnected", ["DISCONNECT_ERROR_CANARY_123723FD"]),
            (.networkError("NETWORK_ERROR_CANARY_D1AE55A2"), "networkError", ["NETWORK_ERROR_CANARY_D1AE55A2"]),
            (.invalidChannel("CHANNEL_ERROR_CANARY_723B6911"), "invalidChannel", ["CHANNEL_ERROR_CANARY_723B6911"]),
            (.invalidPayload("PAYLOAD_ERROR_CANARY_CB45A344"), "invalidPayload", ["PAYLOAD_ERROR_CANARY_CB45A344"]),
            (.sendFailed("SEND_ERROR_CANARY_4335D03D"), "sendFailed", ["SEND_ERROR_CANARY_4335D03D"]),
            (.invalidConfiguration("CONFIG_ERROR_CANARY_4916479C"), "invalidConfiguration", ["CONFIG_ERROR_CANARY_4916479C"]),
            (.missingParameters(["PARAMETER_ERROR_CANARY_3DAA5A1E"]), "missingParameters", ["PARAMETER_ERROR_CANARY_3DAA5A1E"]),
            (.protocolError(401, "PROTOCOL_ERROR_CANARY_885D44DA"), "protocolError", ["PROTOCOL_ERROR_CANARY_885D44DA"]),
            (.invalidJSON("JSON_ERROR_CANARY_01296D7C"), "invalidJSON", ["JSON_ERROR_CANARY_01296D7C"]),
            (.unexpectedResponse("RESPONSE_ERROR_CANARY_D42F26D5"), "unexpectedResponse", ["RESPONSE_ERROR_CANARY_D42F26D5"]),
            (.unknown("UNKNOWN_ERROR_CANARY_A8CFCEB0"), "unknown", ["UNKNOWN_ERROR_CANARY_A8CFCEB0"])
        ]

        for testCase in cases {
            let expected = "WuKongError.\(testCase.category)(code: \(testCase.error.code))"
            assertSafeStringRepresentations(
                testCase.error,
                expected: expected,
                forbidden: testCase.forbidden
            )
            assertSafeStringRepresentations(
                testCase.error as Error,
                expected: expected,
                forbidden: testCase.forbidden
            )
        }
    }

    func testWebSocketIsReleasedAfterItsLastOwnerGoesAway() throws {
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false
        )
        weak var weakSocket: WuKongWebSocket?

        autoreleasepool {
            let eventManager = WuKongEventManager(config: config)
            var socket: WuKongWebSocket? = WuKongWebSocket(config: config, eventManager: eventManager)
            weakSocket = socket
            socket = nil
        }

        XCTAssertNil(weakSocket, "The WebSocket must not retain itself while deinitializing")
    }

    func testWebSocketDeinitDoesNotEmitLifecycleDiagnostics() throws {
        let config = try WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "alice",
            token: "safe-test-token",
            autoReconnect: false,
            enableDebugLogging: true,
            logLevel: .debug
        )

        let output = captureStandardOutput {
            autoreleasepool {
                let eventManager = WuKongEventManager(config: config)
                var socket: WuKongWebSocket? = WuKongWebSocket(
                    config: config,
                    eventManager: eventManager
                )
                withExtendedLifetime(socket) {}
                socket = nil
                withExtendedLifetime(eventManager) {}
            }
        }

        XCTAssertEqual(output, "", "Deinitialization must not leak diagnostics into later operations: \(output)")
    }

    func testExampleDiagnosticsDoNotInterpolateSensitiveValues() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let examplesRoot = repositoryRoot.appendingPathComponent("Examples", isDirectory: true)
        let forbiddenInterpolations = [
            #"\(error"#,
            #"\(wkError)"#,
            #"\(wkError.localizedDescription"#,
            #"\(wkError.recoverySuggestion"#,
            #"\(message)"#,
            #"\(serverUrl"#,
            #"\(uid"#,
            #"\(targetChannelId"#,
            #"\(channelId"#,
            #"\(result.serverKey"#,
            #"\(result.messageId"#,
            #"\(disconnectInfo.reason"#,
            #"\(info.reason"#,
            #"\(message.fromUid"#,
            #"\(message.channelId"#,
            #"\(message.payload"#,
            #"\(message.streamId)"#,
            #"\(message.streamId ??"#,
            #"\(payload"#,
            #"\(suggestion"#,
            #"\(nodeId"#
        ]
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: examplesRoot,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return XCTFail("Could not enumerate example sources")
        }
        var violations: [String] = []

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            for (lineOffset, line) in source.components(separatedBy: .newlines).enumerated() {
                let isDiagnosticSink = line.contains("print(") || line.contains("addLog(") || line.contains("setError(")
                guard isDiagnosticSink,
                      forbiddenInterpolations.contains(where: line.contains) else { continue }
                let relativePath = fileURL.path.replacingOccurrences(of: repositoryRoot.path + "/", with: "")
                violations.append("\(relativePath):\(lineOffset + 1): \(line.trimmingCharacters(in: .whitespaces))")
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            "Example diagnostics must use fixed categories or safe metadata:\n\(violations.joined(separator: "\n"))"
        )
    }
}

private final class StubWebSocketClient: WebSocketClient {
    func connect() {}
    func disconnect(closeCode: UInt16) {}
    func write(string: String, completion: (() -> Void)?) { completion?() }
    func write(stringData: Data, completion: (() -> Void)?) { completion?() }
    func write(data: Data, completion: (() -> Void)?) { completion?() }
    func write(ping: Data, completion: (() -> Void)?) { completion?() }
    func write(pong: Data, completion: (() -> Void)?) { completion?() }
}

@available(macOS 12.0, *)
private func makeSocket(config: WuKongConfig) -> (WuKongWebSocket, WuKongEventManager, StubWebSocketClient) {
    let eventManager = WuKongEventManager(config: config)
    let socket = WuKongWebSocket(config: config, eventManager: eventManager)
    return (socket, eventManager, StubWebSocketClient())
}

private func captureStandardOutput(_ body: () -> Void) -> String {
    fflush(stdout)

    let outputPipe = Pipe()
    let originalStandardOutput = dup(STDOUT_FILENO)
    precondition(originalStandardOutput >= 0)
    precondition(dup2(outputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO) >= 0)

    body()

    fflush(stdout)
    precondition(dup2(originalStandardOutput, STDOUT_FILENO) >= 0)
    close(originalStandardOutput)
    outputPipe.fileHandleForWriting.closeFile()

    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

private func assertSafeStringRepresentations<T>(
    _ value: T,
    expected: String,
    forbidden: [String],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let representations = [
        ("description", String(describing: value)),
        ("debugDescription", String(reflecting: value)),
        ("interpolation", "\(value)")
    ]

    for (kind, representation) in representations {
        XCTAssertEqual(
            representation,
            expected,
            "Unexpected \(kind) for \(T.self)",
            file: file,
            line: line
        )
        for canary in forbidden {
            XCTAssertFalse(
                representation.contains(canary),
                "\(kind) for \(T.self) exposed sensitive data: \(representation)",
                file: file,
                line: line
            )
        }
    }
}
