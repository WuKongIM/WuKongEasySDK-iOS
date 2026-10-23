# iOS / macOS 原生流式聊天

SDK **1.2.0** 的 SwiftUI 示例新增 **流消息** 页，对齐 WuKongIM 的
[`demo/streamdemo`](https://github.com/WuKongIM/WuKongIM/tree/main/demo/streamdemo)。
页面使用两个独立 `WuKongEasySDK(config:)` 实例，分别模拟用户和回复作者。

## 运行

需要 Xcode 14+、Swift 5.7+，iOS 15+ 模拟器或 macOS 13+。

```sh
cd Examples/WuKongIMExample-Unified
./build.sh ios --run
# 或 ./build.sh macos --run
```

先启动包含在线 EVENT 投递的 WuKongIM v3 集群，使用 `wsmux` WebSocket 监听器。

1. 选择 **流消息** 页，填写设备可达的 HTTP API 地址。iOS Simulator 访问宿主机
   可用 `http://127.0.0.1:5001`；真机使用开发机局域网地址。
2. `/route` 返回的 `ws_addr` / `wss_addr` 也必须能从设备访问。开发示例的 ATS
   例外允许明文连接，生产应用使用 HTTPS / WSS 并移除该例外。
3. 点击“创建会话并连接”。Demo 创建随机账号和群频道，两个实例连接、历史恢复
   完成后显示“在线”。发送问题，观察同一气泡逐段更新。
4. 右上角“演示设置”可改模拟回复、每段字数和间隔，也可以单独生成回复。
5. 尝试“取消生成”“模拟失败”，或“断开接收端”后单独生成，再重连恢复快照。

会话和 Token 只在屏幕内存中保留。离开流消息页时中止任务、释放监听器并断开连接；
“新会话”清除当前连接与视图，不删除服务端历史。进程突然退出不会替作者提交最终
快照，生产系统应由可信后端持有生成任务并处理未确认终态。

本 Demo 为开发方便直接调用 `/user/token`、`/channel`、`/message/event` 和历史 API，
仅用于可写演示数据的开发集群。生产应用由业务后端验证用户、作者和频道权限，
托管模型调用、取消与流事件写入，普通客户端不持有管理凭据或机器人 Token。

## SDK 接入

```swift
import WuKongEasySDK

let peer = WuKongEasySDK(config: config)
// Retain the token: SDK event listeners use weak references and run on the main queue.
let listener = peer.onCustomEvent { event in
    guard let data = event.data as? [String: Any] else { return }
    // Route by channel_id, channel_type and client_msg_no before updating your UI.
    // stream.delta uses UTF-8 byte text_offset; stream.finish uses __finish__.
    _ = data
}
try await peer.connect()
let key = UUID().uuidString // Persist once per reply; reuse when reconciling retries.
let ack = try await peer.send(
    channelId: channel,
    channelType: .group,
    payload: MessagePayload(["type": 1, "content": ""]),
    options: SendOptions(clientMsgNo: key, setting: MessageSetting(stream: true))
)
// Only a successful SENDACK permits the backend to append events for this key.
precondition(ack.reasonCode == 1)
// At screen/session disposal, after the stream is no longer needed:
peer.removeListener(listener)
peer.disconnect()
```

`onCustomEvent` 接收 `{id,type,timestamp,data}`，兼容对象和 JSON 字符串形式的 `data`。
这些在线事件尽力投递，无 RECVACK 或离线重放。`Message.setting?.stream` 标记流消息
基础消息。已有普通发送和字典 `options` 接口保留；字典接口现在也传递 `setting`。
基础消息必须持久化，不能搭配 `noPersist` 或 `syncOnce`。

生成顺序：成功 SENDACK → `stream.open` → `stream.delta` × N → `stream.finish`。
取消／失败写 `stream.cancel`／`stream.error` 的部分文本快照后再写 `stream.finish`。
每次写入使用稳定事件 ID，结果未知时停止追加并对账，不换新 ID 盲重试。

`StreamTimeline` 按 Event ID 去重，按 UTF-8 字节合并重叠增量，缺口等待完整快照；
终态后的迟到事件不重新打开回复。每次连接或自动重连成功后读取一次
`/channel/messagesync`，使用 `event_summary_mode: "full"`；恢复期间缓冲事件，先应用
历史 `event_meta.events`，再回放实时事件。在线时不轮询，不用 `/message/eventsync`
替代在线传输。历史权限仍由业务后端负责。

## 兼容模型 SSE

在“演示设置”启用真实模型，填写基础 URL（例如 `https://provider.example/v1`）或完整
`/chat/completions` 地址、模型名和 API Key。本机无鉴权模型可留空 Key；Demo 不请求
模型目录，也不自动发起付费模型请求。

请求包含最近已完成问答，取消和失败回复不作为完成答案加入上下文。支持文本
Chat Completions SSE、多行 `data:`、网络分片中的 UTF-8 和显式 `[DONE]`。
意外 EOF、SSE 错误或 HTTP 失败保存已确认的部分内容并写失败终态；取消关闭上游。
错误正文不展示，Key 不写磁盘、日志、历史或报告，离开页面即清空。

模型请求最长 180 秒，读取空闲限制 30 秒，不跟随重定向；请求体最多 128 KiB，SSE
最多 4 MiB，单行／事件 64 KiB，回复 16,384 UTF-16 单元。上下文最多 39 条、
24,000 UTF-16 单元；视图最多 40 条，日志最多 100 行，恢复缓冲最多 2,048 个事件。

## 可重复验收

在 SDK 根目录执行：

```sh
swift test
swift test --package-path Examples/WuKongIMExample-Unified
LC_ALL=en_US.UTF-8 pod lib lint WuKongEasySDK.podspec --allow-warnings --platforms=ios,osx
./Examples/WuKongIMExample-Unified/build.sh ios

# 另在 WuKongIM 仓库构建：
GOWORK=off go build -o /tmp/wukongim-ios-stream-demo ./cmd/wukongim

# 返回 SDK 仓库，指定一个已启动的 iOS Simulator：
python3 Examples/tools/stream_acceptance.py \
  --server-bin /tmp/wukongim-ios-stream-demo \
  --simulator <simulator-udid> \
  --output /tmp/wk-ios-stream
```

脚本启动临时 256 hash slots 单节点集群与本机 SSE 模型夹具，通过原生页面使用的
控制器和真实 SDK 驱动链路；保留 `report.json`、四个阶段的 PNG 和服务端日志。
验证逐段文本、UTF-8、取消／失败、离线生成、历史与实时事件合并、模型错误／断流、
多轮上下文、上游取消、Key 不泄露和无在线轮询。退出只关闭本次自建服务和演示 App。
发布后可用 `--app <package-consumer.app>` 复用同一验收，证明正式包消费结果。

[失败场景清单](../../docs/STREAMING_DEMO_VALIDATION.md)在实现前记录。
