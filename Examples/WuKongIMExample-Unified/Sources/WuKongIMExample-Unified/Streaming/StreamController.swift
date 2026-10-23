import Foundation
import SwiftUI
import WuKongEasySDK

/// Owns independent reader/author peers and one ordered producer for a screen session.
@MainActor final class StreamController: ObservableObject {
    private struct Session {
        let reader: String, writer: String, channel: String, token: String
    }
    private final class Run {
        let key = UUID().uuidString
        var text = "", stop = ""
        var index = 0
        var model: StreamModel?
    }
    @Published private(set) var timeline: StreamTimeline?
    @Published private(set) var connecting = false
    @Published private(set) var restoring = false
    @Published private(set) var sending = false
    @Published private(set) var generating = false
    @Published private(set) var readerOnline = false
    @Published private(set) var writerOnline = false
    @Published private(set) var error = ""
    @Published private(set) var generator = "就绪"
    @Published private(set) var logs: [String] = []
    private var session: Session?
    private var api: StreamAPI?
    private var reader: WuKongEasySDK?, writer: WuKongEasySDK?
    // Event listeners are weak in the SDK; the screen retains their tokens.
    private var listeners: [ObjectIdentifier: [EventListener]] = [:]
    private var buffered: [EventNotification] = []
    private var recovery: Task<Void, Never>?, generation: Task<Void, Never>?
    private var epoch = 0
    private var lifecycle = 0
    private var recoveryFailed = false
    private var run: Run?
    var busy: Bool { connecting || restoring || sending }
    var canSend: Bool { readerOnline && writerOnline && !busy && !generating && !recoveryFailed }
    var hasSession: Bool { session != nil }
    var status: String {
        if connecting { return "连接中" }
        if restoring { return "恢复历史中" }
        if recoveryFailed { return "历史恢复失败，请重连" }
        if readerOnline && writerOnline { return "在线" }
        if writerOnline { return "接收端离线" }
        return session == nil ? "未连接" : "离线"
    }

    func connect(_ base: String) async {
        guard !busy, !generating else { return }
        let stamp = lifecycle
        connecting = true; error = ""
        defer { if stamp == lifecycle { connecting = false } }
        do {
            if session == nil {
                api?.close()
                let service = try StreamAPI(base.trimmingCharacters(in: .whitespacesAndNewlines)); api = service
                let id = String(UUID().uuidString.prefix(8))
                let candidate = Session(reader: "ios-reader-" + id, writer: "ios-writer-" + id,
                                        channel: "ios-stream-" + id, token: UUID().uuidString)
                for uid in [candidate.reader, candidate.writer] {
                    _ = try await service.post("/user/token", ["uid": uid, "token": candidate.token, "device_flag": 0, "device_level": 0])
                }
                _ = try await service.post("/channel", ["channel_id": candidate.channel, "channel_type": 2, "subscribers": [candidate.reader, candidate.writer]])
                guard stamp == lifecycle else { return }
                session = candidate; timeline = StreamTimeline(channel: candidate.channel)
                log("HTTP 演示账号及群频道已创建")
            }
            try await connectPeers(stamp: stamp)
        } catch { guard stamp == lifecycle else { return }; closePeers(); self.error = "连接失败，请检查 API、设备可达的 WebSocket 地址和演示账号写入权限。" }
    }

    private func connectPeers(stamp: Int) async throws {
        guard let session, let api else { return }
        if reader?.isConnected != true {
            discard(reader)
            let address = try await api.route(session.reader)
            guard stamp == lifecycle else { throw CancellationError() }
            let peer = try makePeer(address, uid: session.reader, token: session.token, receiving: true)
            reader = peer; try await peer.connect()
        }
        guard stamp == lifecycle else { throw CancellationError() }
        if writer?.isConnected != true {
            discard(writer)
            let address = try await api.route(session.writer)
            guard stamp == lifecycle else { throw CancellationError() }
            let peer = try makePeer(address, uid: session.writer, token: session.token, receiving: false)
            writer = peer; try await peer.connect()
        }
    }

    private func makePeer(_ url: String, uid: String, token: String, receiving: Bool) throws -> WuKongEasySDK {
        let config = try WuKongConfig(serverUrl: url, uid: uid, token: token,
                                      connectionTimeout: 10, requestTimeout: 10, maxReconnectAttempts: 5,
                                      enableDebugLogging: false)
        let peer = WuKongEasySDK(config: config)
        func current(_ owner: StreamController) -> Bool { receiving ? owner.reader === peer : owner.writer === peer }
        var tokens: [EventListener] = []
        tokens.append(peer.onConnect { [weak self] _ in
            Task { @MainActor in
                guard let self, current(self) else { return }
                if receiving { self.readerOnline = true; self.recover() } else { self.writerOnline = true }
                self.log(receiving ? "SDK 接收端已连接" : "SDK 生成端已连接")
            }
        })
        tokens.append(peer.onDisconnect { [weak self] _ in
            Task { @MainActor in
                guard let self, current(self) else { return }
                if receiving { self.readerOnline = false; self.cancelRecovery() } else { self.writerOnline = false }
                self.log(receiving ? "SDK 接收端已断开" : "SDK 生成端已断开")
            }
        })
        tokens.append(peer.onError { [weak self] _ in
            Task { @MainActor in
                guard let self, current(self) else { return }
                self.error = "SDK 连接或协议异常，请检查网络后重试。"
                self.log("SDK 错误")
            }
        })
        if receiving {
            tokens.append(peer.onMessage { [weak self] message in
                Task { @MainActor in guard let self, current(self) else { return }; self.timeline?.receive(message) }
            })
            tokens.append(peer.onCustomEvent { [weak self] event in
                Task { @MainActor in
                    guard let self, current(self) else { return }
                    if self.restoring {
                        if self.buffered.count < 2048 { self.buffered.append(event) }
                        else { self.recoveryFailed = true; self.error = "恢复期间事件过多，请重连接收端。" }
                    } else { self.timeline?.apply(event) }
                    self.log("SDK ← 流事件")
                }
            })
        }
        listeners[ObjectIdentifier(peer)] = tokens
        return peer
    }

    /// Recover once per authenticated connection, then replay buffered live deltas.
    private func recover() {
        cancelRecovery()
        let stamp = epoch
        restoring = true; recoveryFailed = false
        recovery = Task {
            do {
                guard let session, let api else { return }
                let history = try await api.post("/channel/messagesync", ["login_uid": session.reader,
                    "channel_id": session.channel, "channel_type": 2, "limit": 40, "event_summary_mode": "full"])
                guard stamp == epoch, !Task.isCancelled else { return }
                timeline?.restore(history)
                for event in buffered { timeline?.apply(event) }
                buffered.removeAll(keepingCapacity: true)
                log("HTTP 历史快照已恢复")
            } catch {
                if stamp == epoch { recoveryFailed = true; self.error = "历史恢复失败，请重连接收端。" }
            }
            if stamp == epoch { restoring = false }
        }
    }
    private func cancelRecovery() {
        epoch += 1; recovery?.cancel(); recovery = nil
        restoring = false; buffered.removeAll(keepingCapacity: true)
    }
    func toggleReceiver() async {
        guard !busy, session != nil else { return }
        if readerOnline { reader?.disconnect(); readerOnline = false; cancelRecovery() }
        else {
            let stamp = lifecycle
            connecting = true; error = ""
            do { try await connectPeers(stamp: stamp) }
            catch { guard stamp == lifecycle else { return }; reader?.disconnect(); readerOnline = false; self.error = "重连失败，请检查网络后重试。" }
            if stamp == lifecycle { connecting = false }
        }
    }

    func send(_ question: String, reply: String, chunk: Int, interval: Int, model: StreamModelConfig?) async {
        guard canSend, !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let session, let reader else { return }
        sending = true; error = ""
        defer { sending = false }
        do {
            let key = UUID().uuidString, text = boundedText(question, limit: 4000)
            let payload = MessagePayload(["type": 1, "content": text])
            let ack = try await reader.send(channelId: session.channel, channelType: .group, payload: payload, options: SendOptions(clientMsgNo: key))
            timeline?.receive(Message(header: Header(), messageId: ack.messageId, messageSeq: ack.messageSeq,
                timestamp: 0, channelId: session.channel, channelType: 2, fromUid: session.reader,
                payload: payload.toDictionary(), clientMsgNo: key))
            log("SDK 问题已发送")
            generate(reply: reply, chunk: chunk, interval: interval, model: model)
        } catch { self.error = "发送结果未确认；请重连查看历史后再决定是否重发。" }
    }

    func generate(reply: String, chunk: Int, interval: Int, model: StreamModelConfig? = nil) {
        guard writerOnline, !generating, let session, let writer else { return }
        let active = Run(); run = active
        generating = true; generator = "生成中"; error = ""
        generation = Task {
            defer { active.model?.cancel(); run = nil; generating = false }
            do {
                _ = try await writer.send(channelId: session.channel, channelType: .group,
                    payload: MessagePayload(["type": 1, "content": ""]),
                    options: SendOptions(clientMsgNo: active.key, setting: MessageSetting(stream: true)))
                try await append(active, type: "stream.open", payload: ["kind": "text"])
                if let model {
                    let source = StreamModel(); active.model = source
                    do {
                        if active.stop.isEmpty {
                            try await source.consume(model, context: timeline?.context() ?? []) { delta in
                                if active.stop.isEmpty {
                                    try await self.append(active, type: "stream.delta", payload: ["kind": "text", "delta": delta])
                                    active.text += delta
                                }
                            }
                        }
                    } catch StreamFailure.eventWrite { throw StreamFailure.eventWrite }
                    catch {
                        try Task.checkCancellation()
                        if active.stop.isEmpty { active.stop = "error"; self.error = "模型请求失败或流意外中断，已保存确认的部分内容。" }
                    }
                } else {
                    let chars = Array(boundedText(reply.isEmpty ? Self.defaultReply : reply, limit: 16384))
                    var offset = 0
                    while offset < chars.count && active.stop.isEmpty {
                        try Task.checkCancellation()
                        let end = min(chars.count, offset + min(64, max(1, chunk)))
                        let delta = String(chars[offset..<end])
                        try await append(active, type: "stream.delta", payload: ["kind": "text", "delta": delta])
                        active.text += delta; offset = end
                        try await Task.sleep(nanoseconds: UInt64(min(2000, max(40, interval))) * 1_000_000)
                    }
                }
                let snapshot: [String: Any] = ["kind": "text", "text": active.text]
                if !active.stop.isEmpty { try await append(active, type: "stream." + active.stop, payload: ["snapshot": snapshot]) }
                try await append(active, type: "stream.finish", payload: ["snapshot": snapshot])
                generator = active.stop == "cancel" ? "已取消" : active.stop == "error" ? "失败" : "完成"
            } catch is CancellationError { generator = "已停止" }
            catch { generator = "写入结果未确认"; self.error = "流写入结果未确认；已停止追加，请重连恢复历史。" }
        }
    }

    private func append(_ active: Run, type: String, payload: [String: Any]) async throws {
        try Task.checkCancellation()
        guard let session, let api else { throw StreamFailure.eventWrite }
        active.index += 1
        do {
            _ = try await api.post("/message/event", ["channel_id": session.channel, "channel_type": 2,
                "from_uid": session.writer, "client_msg_no": active.key, "event_id": "\(active.key):\(active.index)",
                "event_type": type, "event_key": "main", "visibility": "public", "payload": payload])
        } catch { throw StreamFailure.eventWrite }
        log("HTTP → \(type) 已确认")
    }
    func stop(failed: Bool = false) {
        guard let run else { return }
        if run.stop.isEmpty { run.stop = failed ? "error" : "cancel" }
        run.model?.cancel()
    }
    func reset() {
        guard !busy, !generating else { return }
        close(); session = nil; timeline = nil; error = ""; generator = "就绪"; logs.removeAll()
    }
    /// Explicit screen disposal cancels producers, recoveries and both peers.
    func close() {
        lifecycle += 1; connecting = false
        generation?.cancel(); run?.model?.cancel(); closePeers(); api?.close(); api = nil
        session = nil
    }
    private func discard(_ peer: WuKongEasySDK?) {
        guard let peer else { return }
        peer.removeAllListeners(); peer.disconnect(); listeners.removeValue(forKey: ObjectIdentifier(peer))
    }
    private func closePeers() {
        cancelRecovery(); discard(reader); discard(writer)
        reader = nil; writer = nil; readerOnline = false; writerOnline = false
    }
    private func log(_ text: String) {
        if logs.count == 100 { logs.removeFirst() }
        logs.append(text)
    }
    static let defaultReply = "WuKongIM 会先创建一条流消息，再把回复逐段送达。\n\n这些文字由 iOS EasySDK 实时接收，中文和 emoji 🙂 按 UTF-8 字节偏移合并。\n\n试试取消生成，或断开接收端后重连，观察历史快照恢复。"
}
