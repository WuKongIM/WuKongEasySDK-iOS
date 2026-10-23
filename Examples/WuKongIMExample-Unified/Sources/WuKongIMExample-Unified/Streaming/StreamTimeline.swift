import Foundation
import WuKongEasySDK

/// Bounded, disposable projection shared by live events and full history recovery.
struct StreamTimeline {
    struct Row: Identifiable {
        let key: String
        var sequence: Int64 = 0
        var user = false
        var text = ""
        var status = "生成中"
        var finished = false
        var seen: Set<String> = []
        var id: String { key }
    }
    let channel: String
    private var entries: [String: Row] = [:]
    init(channel: String) { self.channel = channel }
    var rows: [Row] {
        entries.values.sorted {
            let left = $0.sequence > 0 ? $0.sequence : Int64.max
            let right = $1.sequence > 0 ? $1.sequence : Int64.max
            return left == right ? $0.key < $1.key : left < right
        }
    }

    mutating func receive(_ message: Message) {
        guard message.channelId == channel, message.channelType == 2,
              let key = message.clientMsgNo, !key.isEmpty else { return }
        var row = entries[key] ?? Row(key: key)
        row.sequence = message.messageSeq
        row.user = message.setting?.stream != true
        if row.user { row.text = textPayload(message.payload); row.status = "已发送"; row.finished = true }
        save(row)
    }

    /// Offset is measured in UTF-8 bytes. Reject gaps and partial scalar overlaps.
    mutating func apply(_ event: EventNotification) {
        let kinds = ["stream.open", "stream.delta", "stream.snapshot", "stream.close", "stream.cancel", "stream.error", "stream.finish"]
        guard kinds.contains(event.type), let data = event.data as? [String: Any],
              data["channel_id"] as? String == channel, number(data["channel_type"]) == 2,
              data["event_key"] as? String == "main" || event.type == "stream.finish",
              let key = data["client_msg_no"] as? String, !key.isEmpty, !event.id.isEmpty else { return }
        var row = entries[key] ?? Row(key: key)
        if number(data["message_seq"]) > 0 { row.sequence = number(data["message_seq"]) }
        guard !row.seen.contains(event.id), !row.finished || event.type == "stream.finish" else { return }
        if row.seen.count == 2048 { row.seen.removeAll(keepingCapacity: true) }
        row.seen.insert(event.id)
        let payload = data["payload"] as? [String: Any] ?? [:]
        if event.type == "stream.delta", let text = payload["delta"] as? String {
            let delta = Array(text.utf8), current = row.text.utf8.count
            let offset = data["text_offset"] == nil ? Int64(current) : number(data["text_offset"])
            if offset < 0 || offset > current { row.status = "增量中断，等待快照" }
            else if offset + Int64(delta.count) > current {
                if let suffix = String(bytes: delta.dropFirst(current - Int(offset)), encoding: .utf8) { row.text += suffix }
                else { row.status = "增量中断，等待快照" }
            }
        }
        if ["stream.snapshot", "stream.close", "stream.cancel", "stream.error", "stream.finish"].contains(event.type) {
            let snapshot = payload["snapshot"] as? [String: Any] ?? payload
            if snapshot["kind"] as? String == "text", let text = snapshot["text"] as? String { row.text = text }
        }
        switch event.type {
        case "stream.cancel": row.status = "已取消"; row.finished = true
        case "stream.error": row.status = "失败"; row.finished = true
        case "stream.close", "stream.finish":
            if !["已取消", "失败"].contains(row.status) { row.status = "完成" }
            row.finished = true
        default: break
        }
        save(row)
    }

    /// History is authoritative at the recovery boundary, before buffered events.
    mutating func restore(_ history: [String: Any]) {
        entries.removeAll(keepingCapacity: true)
        for message in (history["messages"] as? [[String: Any]] ?? []).suffix(40) {
            guard let key = message["client_msg_no"] as? String, !key.isEmpty else { continue }
            var row = Row(key: key, sequence: number(message["message_seq"]))
            row.user = (number(message["setting"]) & 2) == 0
            if row.user { row.text = textPayload(message["payload"]); row.status = "已发送"; row.finished = true }
            else {
                let meta = message["event_meta"] as? [String: Any] ?? [:]
                let lane = (meta["events"] as? [[String: Any]] ?? []).first { $0["event_key"] as? String == "main" } ?? [:]
                let snapshot = lane["snapshot"] as? [String: Any] ?? [:]
                if snapshot["kind"] as? String == "text" { row.text = snapshot["text"] as? String ?? "" }
                switch lane["status"] as? String {
                case "cancelled": row.status = "已取消"
                case "error": row.status = "失败"
                case "closed": row.status = "完成"
                default: row.status = meta["completed"] as? Bool == true ? "完成" : "生成中"
                }
                row.finished = row.status != "生成中"
            }
            save(row)
        }
    }

    func context() -> [[String: String]] {
        var used = 0
        return rows.filter { $0.user || $0.status == "完成" }.suffix(39).reversed().filter {
            used += $0.text.utf16.count; return used <= 24000
        }.reversed().map { ["role": $0.user ? "user" : "assistant", "content": $0.text] }
    }

    private mutating func save(_ value: Row) {
        var row = value
        if row.text.utf16.count > 16384 {
            row.text = boundedText(row.text, limit: 16384)
            row.status = "回复超出演示上限"; row.finished = true
        }
        entries[row.key] = row
        while entries.count > 40, let key = rows.first?.key { entries.removeValue(forKey: key) }
    }
}

func number(_ value: Any?) -> Int64 { (value as? NSNumber)?.int64Value ?? 0 }
func boundedText(_ text: String, limit: Int) -> String {
    var count = 0
    return String(text.prefix { character in
        count += character.utf16.count; return count <= limit
    })
}
private func textPayload(_ value: Any?) -> String {
    if let object = value as? [String: Any] { return boundedText(object["content"] as? String ?? "", limit: 16384) }
    guard let text = value as? String else { return "" }
    let bytes = text.data(using: .utf8) ?? Data()
    let object = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any]
        ?? Data(base64Encoded: text).flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
    return boundedText(object?["content"] as? String ?? text, limit: 16384)
}
