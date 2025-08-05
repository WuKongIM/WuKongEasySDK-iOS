# WuKongEasySDK

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-12.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

WuKongIM 实时消息 iOS/macOS SDK。几分钟内为您的应用添加聊天功能。

## 特性

- **简单集成**：支持 async/await 的简洁 API
- **灵活载荷**：使用字典字面量发送任意 JSON 数据
- **自动重连**：智能重连机制，支持指数退避
- **跨平台**：支持 iOS、macOS、tvOS、watchOS
- **线程安全**：所有操作都是线程安全的

## 系统要求

- iOS 12.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Xcode 12.0+
- Swift 5.7+

## 安装

### Swift Package Manager

**Xcode 中添加：**
1. File → Add Package Dependencies
2. 输入：`https://github.com/WuKongIM/WuKongEasySDK-iOS`

**Package.swift：**
```swift
dependencies: [
    .package(url: "https://github.com/WuKongIM/WuKongEasySDK-iOS.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'WuKongEasySDK', '~> 1.0.0'
```

## 快速开始

```swift
import WuKongEasySDK

// 1. 配置和初始化
let config = try WuKongConfig(
    serverUrl: "ws://your-server.com:5200",
    uid: "user123",
    token: "auth_token"
)
let sdk = WuKongEasySDK(config: config)

// 2. 设置事件监听器
sdk.onConnect { _ in print("已连接！") }
sdk.onMessage { message in print("收到消息：\(message.payload)") }
sdk.onError { error in print("错误：\(error)") }

// 3. 连接
try await sdk.connect()

// 4. 发送消息
let payload: MessagePayload = [
    "type": 1,
    "content": "你好世界！",
    "timestamp": Date().timeIntervalSince1970
]

try await sdk.send(
    channelId: "friend_id",
    channelType: .person,
    payload: payload
)
```

## 消息载荷

使用字典字面量发送任意 JSON 数据：

```swift
// 文本消息
let textMessage: MessagePayload = [
    "type": 1,
    "content": "你好世界！"
]

// 图片消息
let imageMessage: MessagePayload = [
    "type": 2,
    "content": "看看这个！",
    "image": [
        "url": "https://example.com/image.jpg",
        "width": 1920,
        "height": 1080
    ]
]

// 自定义消息
let customMessage: MessagePayload = [
    "type": 100,
    "action": "game_invite",
    "game_id": "chess_123"
]
```

## 示例应用

在 `Examples/WuKongIMExample-Unified/` 中提供了 SwiftUI 示例应用：

- 实时消息传输，显示原始 JSON 载荷
- 连接管理和事件日志
- 跨平台（iOS/macOS）

```bash
cd Examples/WuKongIMExample-Unified
./build.sh ios    # 构建 iOS 版本
./build.sh macos  # 构建 macOS 版本
```

## 高级用法

### 配置构建器

```swift
let sdk = try WuKongEasySDK.create { builder in
    try builder
        .serverUrl("ws://your-server.com:5200")
        .uid("user123")
        .token("auth-token")
        .connectionTimeout(30)
        .enableDebugLogging(true)
        .build()
}
```

### 错误处理

```swift
sdk.onError { error in
    if let wkError = error as? WuKongError {
        switch wkError {
        case .authFailed(let message):
            print("认证失败：\(message)")
        case .networkError(let message):
            print("网络错误：\(message)")
        case .notConnected:
            print("未连接")
        default:
            print("错误：\(wkError.localizedDescription)")
        }
    }
}
```

## SwiftUI 集成

```swift
import SwiftUI
import WuKongEasySDK

@MainActor
class ChatManager: ObservableObject {
    private let sdk: WuKongEasySDK
    @Published var isConnected = false
    @Published var messages: [Message] = []
    
    init() {
        let config = try! WuKongConfig(
            serverUrl: "ws://your-server.com:5200",
            uid: "user123",
            token: "auth-token"
        )
        self.sdk = WuKongEasySDK(config: config)
        
        sdk.onConnect { [weak self] _ in self?.isConnected = true }
        sdk.onDisconnect { [weak self] _ in self?.isConnected = false }
        sdk.onMessage { [weak self] message in self?.messages.append(message) }
    }
    
    func connect() async {
        try? await sdk.connect()
    }
    
    func disconnect() {
        sdk.disconnect()
    }
}
```

## 文档

- [WuKongIM 文档](https://docs.wukongim.com)
- [API 参考](https://docs.wukongim.com/sdk/ios)

## 许可证

MIT 许可证。查看 [LICENSE](LICENSE) 文件。

## 支持

- [问题反馈](https://github.com/WuKongIM/WuKongEasySDK-iOS/issues)
- [社区讨论](https://github.com/WuKongIM/WuKongIM/discussions)
