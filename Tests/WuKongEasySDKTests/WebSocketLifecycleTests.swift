import Foundation
import Starscream
import XCTest
@testable import WuKongEasySDK

@available(macOS 12.0, *)
final class WebSocketLifecycleTests: XCTestCase {
    func testRunnableUnifiedExampleExposesTheDocumentedTargetUserField() throws {
        let contentView = runnableExampleSourceRoot()
            .appendingPathComponent("ContentView.swift")
        let source = try String(contentsOf: contentView, encoding: .utf8)

        XCTAssertTrue(source.contains("TextField(\"Target user\""))
        XCTAssertTrue(source.contains("$chatManager.targetChannelId"))
    }

    func testRunnableUnifiedExampleDisplaysMessageHistory() throws {
        let sourceRoot = runnableExampleSourceRoot()
        let contentView = try String(
            contentsOf: sourceRoot.appendingPathComponent("ContentView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(contentView.contains("ForEach(chatManager.messages)"))
        XCTAssertTrue(contentView.contains("Text(message.content)"))
    }

    func testRunnableUnifiedExampleUsesTheTextPayloadContract() throws {
        let sourceRoot = runnableExampleSourceRoot()
        let chatManager = try String(
            contentsOf: sourceRoot.appendingPathComponent("ChatManager.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(chatManager.contains("MessagePayload([\"content\": text, \"type\": 1])"))
        XCTAssertFalse(chatManager.contains("MessagePayload([\"text\": text"))
    }

    func testRunnableUnifiedExampleTreatsReceivedTimestampAsUnixSeconds() throws {
        let chatManager = try String(
            contentsOf: runnableExampleSourceRoot().appendingPathComponent("ChatManager.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(
            chatManager.contains("Date(timeIntervalSince1970: TimeInterval(message.timestamp))")
        )
        XCTAssertFalse(chatManager.contains("message.timestamp / 1000"))
    }

    func testRunnableUnifiedExampleUsesSwift57CompatiblePreviews() throws {
        let contentView = try String(
            contentsOf: runnableExampleSourceRoot().appendingPathComponent("ContentView.swift"),
            encoding: .utf8
        )

        XCTAssertFalse(contentView.contains("#Preview"))
        XCTAssertTrue(contentView.contains("PreviewProvider"))
    }

    func testDisconnectWhileConnectingCompletesThePendingConnect() throws {
        let connectStarted = expectation(description: "transport connect started")
        let connectCompleted = expectation(description: "connect completed with cancellation")
        let transport = TestManagedWebSocketClient(autoOpen: false)
        transport.onConnect = {
            connectStarted.fulfill()
        }
        let socket = makeLifecycleSocket(transports: [transport])

        Task {
            do {
                try await socket.connect()
                XCTFail("disconnect during connect unexpectedly succeeded")
            } catch let error as WuKongError {
                XCTAssertEqual(error, .cancelled)
                connectCompleted.fulfill()
            } catch {
                XCTFail("disconnect returned the wrong error: \(error)")
            }
        }

        wait(for: [connectStarted], timeout: 1)
        socket.disconnect()
        wait(for: [connectCompleted], timeout: 1)
    }

    func testTransportDisconnectWhileConnectingCompletesThePendingConnect() {
        let connectStarted = expectation(description: "transport connect started")
        let connectCompleted = expectation(description: "connect completed with server disconnect")
        let transport = TestManagedWebSocketClient(autoOpen: false)
        transport.onConnect = {
            connectStarted.fulfill()
        }
        let socket = makeLifecycleSocket(transports: [transport])

        Task {
            do {
                try await socket.connect()
                XCTFail("transport disconnect unexpectedly allowed connect to succeed")
            } catch let error as WuKongError {
                XCTAssertEqual(error, .serverDisconnected(1006, "server unavailable"))
                connectCompleted.fulfill()
            } catch {
                XCTFail("transport disconnect returned the wrong error: \(error)")
            }
        }

        wait(for: [connectStarted], timeout: 1)
        transport.emit(.disconnected("server unavailable", 1006))
        wait(for: [connectCompleted], timeout: 1)
    }

    func testRetiredTransportCannotDisconnectItsReplacement() async throws {
        let firstDisconnected = expectation(description: "first transport disconnected")
        let first = TestManagedWebSocketClient(autoOpen: true, autoAuthenticate: true)
        first.onDisconnect = {
            firstDisconnected.fulfill()
        }
        let second = TestManagedWebSocketClient(autoOpen: true, autoAuthenticate: true)
        let socket = makeLifecycleSocket(transports: [first, second])

        try await socket.connect()
        XCTAssertTrue(socket.isConnected)

        socket.disconnect()
        XCTAssertEqual(XCTWaiter.wait(for: [firstDisconnected], timeout: 1), .completed)
        XCTAssertFalse(socket.isConnected)

        try await socket.connect()
        XCTAssertTrue(socket.isConnected)

        first.emit(.disconnected("stale transport", 1006))

        // isConnected synchronizes with the manager callback queue, ensuring
        // the stale event has been observed before this assertion runs.
        XCTAssertTrue(socket.isConnected, "a retired transport disconnected its replacement")
    }

    private func makeLifecycleSocket(
        transports: [TestManagedWebSocketClient]
    ) -> WuKongWebSocket {
        let config = try! WuKongConfig(
            serverUrl: "ws://127.0.0.1:5200",
            uid: "lifecycle-test",
            token: "test-token",
            requestTimeout: 1,
            pingInterval: 60,
            maxReconnectAttempts: 0,
            autoReconnect: false
        )
        let eventManager = WuKongEventManager(config: config)
        let factory = TestTransportFactory(transports: transports)
        return WuKongWebSocket(
            config: config,
            eventManager: eventManager,
            webSocketFactory: factory.make
        )
    }

    private func runnableExampleSourceRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Examples/WuKongIMExample-Unified/Sources")
            .appendingPathComponent("WuKongIMExample-Unified")
    }
}

private final class TestTransportFactory {
    private let lock = NSLock()
    private var transports: [TestManagedWebSocketClient]

    init(transports: [TestManagedWebSocketClient]) {
        self.transports = transports
    }

    func make(request: URLRequest) -> ManagedWebSocketClient {
        lock.lock()
        defer { lock.unlock() }
        precondition(!transports.isEmpty, "test requested more transports than configured")
        return transports.removeFirst()
    }
}

private final class TestManagedWebSocketClient: ManagedWebSocketClient {
    weak var delegate: WebSocketDelegate?
    var callbackQueue = DispatchQueue.main
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?

    private let autoOpen: Bool
    private let autoAuthenticate: Bool

    init(autoOpen: Bool, autoAuthenticate: Bool = false) {
        self.autoOpen = autoOpen
        self.autoAuthenticate = autoAuthenticate
    }

    func connect() {
        onConnect?()
        if autoOpen {
            emit(.connected([:]))
        }
    }

    func disconnect(closeCode: UInt16) {
        onDisconnect?()
    }

    func write(string: String, completion: (() -> Void)?) {
        if let data = string.data(using: .utf8) {
            respondToAuthentication(in: data)
        }
        completion?()
    }

    func write(stringData: Data, completion: (() -> Void)?) {
        respondToAuthentication(in: stringData)
        completion?()
    }

    func write(data: Data, completion: (() -> Void)?) {
        respondToAuthentication(in: data)
        completion?()
    }

    func write(ping: Data, completion: (() -> Void)?) {
        completion?()
    }

    func write(pong: Data, completion: (() -> Void)?) {
        completion?()
    }

    func emit(_ event: WebSocketEvent) {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.delegate?.didReceive(event: event, client: self)
        }
    }

    private func respondToAuthentication(in data: Data) {
        guard autoAuthenticate,
              let request = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              request["method"] as? String == "connect",
              let id = request["id"] as? String else {
            return
        }

        let response = """
        {"jsonrpc":"2.0","id":"\(id)","result":{"serverKey":"test","salt":"test","timeDiff":0,"reasonCode":1}}
        """
        emit(.text(response))
    }
}
