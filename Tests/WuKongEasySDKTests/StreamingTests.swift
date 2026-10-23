import Foundation
import Starscream
import XCTest
@testable import WuKongEasySDK

@available(macOS 12.0, *)
final class StreamingTests: XCTestCase {
    func testEventDecodesObjectStringAndNullWithoutLeakingData() throws {
        for data in [#"{"channel_id":"room","payload":{"delta":"你好🙂","optional":null}}"#,
                     #""{\"channel_id\":\"room\",\"payload\":{\"delta\":\"你好🙂\",\"optional\":null}}""#] {
            let json = "{\"id\":\"private-id\",\"type\":\"stream.delta\",\"timestamp\":1,\"data\":\(data)}"
            let event = try JSONDecoder().decode(EventNotification.self, from: Data(json.utf8))
            let object = try XCTUnwrap(event.data as? [String: Any])
            XCTAssertEqual(object["channel_id"] as? String, "room")
            XCTAssertEqual((object["payload"] as? [String: Any])?["delta"] as? String, "你好🙂")
            XCTAssertTrue((object["payload"] as? [String: Any])?["optional"] is NSNull)
            XCTAssertFalse(String(describing: event).contains("private-id"))
            XCTAssertFalse(String(reflecting: event).contains("你好"))
        }
    }

    func testStreamFlagAndNullablePayloadRoundTrip() throws {
        let source = #"{"header":{},"messageId":"m","messageSeq":3,"timestamp":1,"channelId":"r","channelType":2,"fromUid":"a","payload":{"value":null},"clientMsgNo":"stable","setting":{"stream":true}}"#
        let message = try JSONDecoder().decode(Message.self, from: Data(source.utf8))
        XCTAssertEqual(message.setting?.stream, true)
        let roundTrip = try JSONDecoder().decode(Message.self, from: JSONEncoder().encode(message))
        XCTAssertEqual(roundTrip.setting?.stream, true)
        XCTAssertTrue(roundTrip.payload["value"] is NSNull)
        let legacy = try JSONDecoder().decode(SendResult.self, from: Data(#"{"messageId":"m","messageSeq":3}"#.utf8))
        XCTAssertEqual(legacy.reasonCode, 1)
    }

    func testCustomEventDispatchedOnMainThreadWithoutRecvAck() throws {
        let config = try makeConfig()
        let events = WuKongEventManager(config: config)
        let socket = WuKongWebSocket(config: config, eventManager: events)
        let delivered = expectation(description: "custom event")
        let listener = events.onCustomEvent { event in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(event.type, "stream.finish")
            delivered.fulfill()
        }
        socket.handleWebSocketEvent(.text(#"{"jsonrpc":"2.0","method":"event","params":{"id":"e","type":"stream.finish","timestamp":1,"data":{"event_key":"__finish__"}}}"#))
        wait(for: [delivered], timeout: 1)
        withExtendedLifetime(listener) {}
    }

    func testSendPreservesStreamOptionsAndRejectsFailedAck() async throws {
        let transport = StreamingTransport()
        let config = try makeConfig()
        let events = WuKongEventManager(config: config)
        let socket = WuKongWebSocket(config: config, eventManager: events, webSocketFactory: { _ in transport })
        try await socket.connect()
        let options = SendOptions(clientMsgNo: "stable", setting: MessageSetting(stream: true))
        let ack = try await socket.send(channelId: "room", channelType: .group, payload: ["type": 1], options: options.dictionary)
        XCTAssertEqual(ack.reasonCode, 1)
        XCTAssertEqual(transport.sendParams?["clientMsgNo"] as? String, "stable")
        XCTAssertEqual((transport.sendParams?["setting"] as? [String: Any])?["stream"] as? Bool, true)
        transport.ackCode = 2
        do {
            _ = try await socket.send(channelId: "room", channelType: .group, payload: [:])
            XCTFail("non-success SENDACK accepted")
        } catch {}
        socket.disconnect()
    }

    func testTransientStreamParentRejectedBeforeTransportWrite() async throws {
        let transport = StreamingTransport()
        let config = try makeConfig()
        let socket = WuKongWebSocket(config: config, eventManager: WuKongEventManager(config: config), webSocketFactory: { _ in transport })
        try await socket.connect()
        for header in [["noPersist": true], ["syncOnce": true]] {
            do {
                _ = try await socket.send(channelId: "r", channelType: .group, payload: [:], options: ["setting": ["stream": true], "header": header])
                XCTFail("non-durable parent accepted")
            } catch {}
        }
        XCTAssertNil(transport.sendParams)
        socket.disconnect()
    }

    private func makeConfig() throws -> WuKongConfig {
        try WuKongConfig(serverUrl: "ws://127.0.0.1:5200", uid: "test", token: "test", requestTimeout: 1, pingInterval: 60, maxReconnectAttempts: 0, autoReconnect: false)
    }
}

private final class StreamingTransport: ManagedWebSocketClient {
    weak var delegate: WebSocketDelegate?
    var callbackQueue = DispatchQueue.main
    var sendParams: [String: Any]?
    var ackCode = 1
    func connect() { emit(.connected([:])) }
    func disconnect(closeCode: UInt16) {}
    func write(string: String, completion: (() -> Void)?) { respond(Data(string.utf8)); completion?() }
    func write(stringData: Data, completion: (() -> Void)?) { respond(stringData); completion?() }
    func write(data: Data, completion: (() -> Void)?) { respond(data); completion?() }
    func write(ping: Data, completion: (() -> Void)?) { completion?() }
    func write(pong: Data, completion: (() -> Void)?) { completion?() }
    private func emit(_ event: WebSocketEvent) {
        callbackQueue.async { self.delegate?.didReceive(event: event, client: self) }
    }
    private func respond(_ bytes: Data) {
        guard let request = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any], let id = request["id"] else { return }
        let result: [String: Any]
        if request["method"] as? String == "connect" { result = ["reasonCode": 1] }
        else if request["method"] as? String == "send" {
            sendParams = request["params"] as? [String: Any]
            result = ["messageId": "m", "messageSeq": 1, "reasonCode": ackCode]
        } else { return }
        let response = try! JSONSerialization.data(withJSONObject: ["jsonrpc": "2.0", "id": id, "result": result])
        emit(.text(String(decoding: response, as: UTF8.self)))
    }
}
