import XCTest
import WuKongEasySDK
@testable import WuKongIMExample_Unified

final class StreamProjectionTests: XCTestCase {
    func testUtf8OverlapDedupAndTerminalStatus() {
        var timeline = StreamTimeline(channel: "room")
        timeline.apply(event("1", "stream.delta", ["delta": "你好🙂"], offset: 0))
        timeline.apply(event("1", "stream.delta", ["delta": "你好🙂"], offset: 0))
        timeline.apply(event("2", "stream.delta", ["delta": "🙂完成"], offset: 6))
        XCTAssertEqual(timeline.rows.first?.text, "你好🙂完成")
        timeline.apply(event("3", "stream.cancel", ["snapshot": ["kind": "text", "text": "你好🙂完成"]]))
        timeline.apply(event("4", "stream.finish", ["snapshot": ["kind": "text", "text": "你好🙂完成"]], lane: "__finish__"))
        timeline.apply(event("5", "stream.delta", ["delta": "late"], offset: 16))
        XCTAssertEqual(timeline.rows.first?.status, "已取消")
        XCTAssertEqual(timeline.rows.first?.text, "你好🙂完成")
    }

    func testGapAndForeignEventsDoNotCorruptText() {
        var timeline = StreamTimeline(channel: "room")
        timeline.apply(event("1", "stream.delta", ["delta": "🙂"], offset: 1))
        XCTAssertEqual(timeline.rows.first?.text, "")
        XCTAssertEqual(timeline.rows.first?.status, "增量中断，等待快照")
        timeline.apply(event("2", "stream.snapshot", ["snapshot": ["kind": "text", "text": "restored"]]))
        XCTAssertEqual(timeline.rows.first?.text, "restored")
        timeline.apply(event("3", "stream.delta", ["delta": "bad"], offset: 8, lane: "foreign"))
        XCTAssertEqual(timeline.rows.first?.text, "restored")
    }

    func testSnapshotRecoveryThenBufferedOverlapAndParentPreservesText() {
        var timeline = StreamTimeline(channel: "room")
        timeline.restore(["messages": [["client_msg_no": "reply", "message_seq": 2, "setting": 2,
            "event_meta": ["completed": false, "events": [["event_key": "main", "status": "open", "snapshot": ["kind": "text", "text": "你好🙂"]]]]]]])
        timeline.apply(event("2", "stream.delta", ["delta": "🙂完成"], offset: 6))
        timeline.receive(Message(header: Header(), messageId: "m", messageSeq: 2, timestamp: 1, channelId: "room", channelType: 2, fromUid: "writer", payload: [:], clientMsgNo: "reply", setting: MessageSetting(stream: true)))
        XCTAssertEqual(timeline.rows.first?.text, "你好🙂完成")
    }

    func testProjectionBoundsAndContextExcludesPartialFailure() {
        var timeline = StreamTimeline(channel: "room")
        for index in 0..<45 {
            timeline.receive(Message(header: Header(), messageId: "m", messageSeq: Int64(index+1), timestamp: 1, channelId: "room", channelType: 2, fromUid: "reader", payload: ["content": "q"], clientMsgNo: "q\(index)"))
        }
        XCTAssertEqual(timeline.rows.count, 40)
        timeline.apply(event("e", "stream.error", ["snapshot": ["kind": "text", "text": "partial"]]))
        XCTAssertFalse(timeline.context().contains { $0["content"] == "partial" })
        timeline.apply(event("large", "stream.finish", ["snapshot": ["kind": "text", "text": String(repeating: "🙂", count: 20000)]], lane: "__finish__"))
        XCTAssertLessThanOrEqual(timeline.rows.first { $0.key == "reply" }?.text.utf16.count ?? 0, 16384)
    }

    private func event(_ id: String, _ type: String, _ payload: [String: Any], offset: Int = 0, lane: String = "main") -> EventNotification {
        EventNotification(id: id, type: type, timestamp: 1, data: ["channel_id": "room", "channel_type": 2, "client_msg_no": "reply", "event_key": lane, "text_offset": offset, "payload": payload])
    }
}
