#if DEBUG
import Foundation

/// Opt-in in-process UI driver: exercises the same controller and actual network peers.
@MainActor enum StreamAcceptance {
    static func run(_ controller: StreamController) async {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--stream-acceptance"), args.count > index + 2 else { return }
        let base = args[index + 1], model = args[index + 2]
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("stream-acceptance")
        try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var checks: [String] = []
        func record(_ name: String) { checks.append(name) }
        func verify(_ condition: @autoclosure () -> Bool, _ name: String) throws {
            if !condition() { throw StreamFailure.check(name) }
        }
        func wait(_ label: String, _ condition: () -> Bool) async throws {
            for _ in 0..<300 {
                if condition() { return }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            throw StreamFailure.check(label)
        }
        func phase(_ name: String) async throws {
            try name.write(to: output.appendingPathComponent("phase.txt"), atomically: true, encoding: .utf8)
            try await Task.sleep(nanoseconds: 700_000_000)
        }
        func last() -> StreamTimeline.Row? { controller.timeline?.rows.last { !$0.user } }
        func completed() -> Bool { !controller.generating && last()?.finished == true }
        var failed = ""
        do {
            await controller.connect(base)
            try await wait("initial connection") { controller.canSend }
            let reply = "原生 iOS 回复：你好🙂，按 UTF-8 偏移逐段抵达。"
            await controller.send("介绍一下流消息", reply: reply, chunk: 1, interval: 80, model: nil)
            try await wait("progressive text") { !(last()?.text.isEmpty ?? true) && last()?.text != reply }
            try await phase("partial")
            try await wait("normal finish", completed)
            try verify(last()?.text == reply, "normal text mismatch")
            try await phase("completed")
            record("actual SDK SEND, EVENT and progressive UTF-8 reply")

            var previousKey = last()?.key
            controller.generate(reply: String(repeating: "取消保留🙂", count: 40), chunk: 1, interval: 50)
            try await wait("cancel partial") { last()?.key != previousKey && !(last()?.text.isEmpty ?? true) && controller.generating }
            controller.stop()
            try await wait("cancel finish", completed)
            try verify(last()?.status == "已取消" && !(last()?.text.isEmpty ?? true), "cancel snapshot")
            record("cancel preserves confirmed partial snapshot")

            previousKey = last()?.key
            controller.generate(reply: String(repeating: "失败保留🙂", count: 40), chunk: 1, interval: 50)
            try await wait("error partial") { last()?.key != previousKey && !(last()?.text.isEmpty ?? true) && controller.generating }
            controller.stop(failed: true)
            try await wait("error finish", completed)
            try verify(last()?.status == "失败", "failure status")
            record("failure preserves confirmed partial snapshot")

            await controller.toggleReceiver()
            try await wait("receiver offline") { !controller.readerOnline }
            let offline = "离线时生成的完整快照🙂"
            controller.generate(reply: offline, chunk: 2, interval: 40)
            try await wait("offline producer finish") { !controller.generating && controller.generator == "完成" }
            await controller.toggleReceiver()
            try await wait("offline recovery") { controller.canSend && last()?.text == offline }
            try await phase("recovered")
            record("offline generation and messagesync recovery")

            let overlap = String(repeating: "重连合并🙂", count: 10)
            previousKey = last()?.key
            controller.generate(reply: overlap, chunk: 1, interval: 50)
            try await wait("overlap partial") { last()?.key != previousKey && controller.generating && (last()?.text.utf8.count ?? 0) > 20 }
            await controller.toggleReceiver()
            try await Task.sleep(nanoseconds: 150_000_000)
            await controller.toggleReceiver()
            try await wait("overlap finish") { controller.canSend && completed() && last()?.text == overlap }
            record("snapshot and buffered live deltas merge without repetition")

            let secret = "IOS_MODEL_KEY_CANARY_1A8F"
            func config(_ name: String) -> StreamModelConfig { StreamModelConfig(url: model, model: name, key: secret) }
            previousKey = last()?.key
            await controller.send("继续上一轮问题", reply: "", chunk: 1, interval: 40, model: config("fixture-chat"))
            try await wait("model finish") { last()?.key != previousKey && completed() }
            try verify(last()?.text == "模型回复🙂，分段到达。" && last()?.status == "完成", "model response")
            record("local compatible SSE model through actual IM events")
            for name in ["fixture-error", "fixture-truncated"] {
                previousKey = last()?.key
                controller.generate(reply: "", chunk: 1, interval: 40, model: config(name))
                try await wait(name) { last()?.key != previousKey && completed() }
                try verify(last()?.status == "失败" && !(last()?.text.isEmpty ?? true), name + " partial snapshot")
            }
            record("SSE error and unexpected EOF preserve partial snapshots")
            previousKey = last()?.key
            controller.generate(reply: "", chunk: 1, interval: 40, model: config("fixture-slow"))
            try await wait("model partial") { last()?.key != previousKey && controller.generating && !(last()?.text.isEmpty ?? true) }
            controller.stop()
            try await wait("model cancelled", completed)
            try verify(last()?.status == "已取消", "model cancellation status")
            record("upstream model cancellation")
            let visible = (controller.timeline?.rows.map { $0.text }.joined() ?? "") + controller.logs.joined()
            try verify(!visible.contains(secret), "model key visible")
            record("model key excluded from transcript and logs")
            try await phase("model")
        } catch StreamFailure.check(let stage) { failed = stage }
        catch { failed = "native acceptance operation" }
        let result: [String: Any] = ["passed": failed.isEmpty, "checks": checks, "failed_stage": failed,
            "environment": ["system": ProcessInfo.processInfo.operatingSystemVersionString]]
        if let bytes = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) {
            try? bytes.write(to: output.appendingPathComponent("report.json"), options: .atomic)
        }
    }
}
#endif
