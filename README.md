# WuKongEasySDK

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-12.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

iOS/macOS SDK for WuKongIM real-time messaging. Add chat functionality to your app in minutes.

## Features

- **Easy Integration**: Simple API with async/await support
- **Flexible Payloads**: Send any JSON data using dictionary literals
- **Auto Reconnection**: Intelligent reconnection with exponential backoff
- **Cross-Platform**: iOS, macOS, tvOS, watchOS support
- **Thread Safe**: All operations are thread-safe

## Requirements

- iOS 12.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Xcode 12.0+
- Swift 5.7+

## Installation

### Swift Package Manager

**Xcode:**
1. File → Add Package Dependencies
2. Enter: `https://github.com/WuKongIM/WuKongEasySDK-iOS`

**Package.swift:**
```swift
dependencies: [
    .package(url: "https://github.com/WuKongIM/WuKongEasySDK-iOS.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'WuKongEasySDK', '~> 1.0.0'
```

## Quick Start

```swift
import WuKongEasySDK

// 1. Configure and initialize
let config = try WuKongConfig(
    serverUrl: "ws://your-server.com:5200",
    uid: "user123",
    token: "auth_token"
)
let sdk = WuKongEasySDK(config: config)

// 2. Set up event listeners
sdk.onConnect { _ in print("Connected!") }
sdk.onMessage { message in print("Received: \(message.payload)") }
sdk.onError { error in print("Error: \(error)") }

// 3. Connect
try await sdk.connect()

// 4. Send messages
let payload: MessagePayload = [
    "type": 1,
    "content": "Hello World!",
    "timestamp": Date().timeIntervalSince1970
]

try await sdk.send(
    channelId: "friend_id",
    channelType: .person,
    payload: payload
)
```

## Message Payloads

Send any JSON data using dictionary literals:

```swift
// Text message
let textMessage: MessagePayload = [
    "type": 1,
    "content": "Hello World!"
]

// Image message
let imageMessage: MessagePayload = [
    "type": 2,
    "content": "Check this out!",
    "image": [
        "url": "https://example.com/image.jpg",
        "width": 1920,
        "height": 1080
    ]
]

// Custom message
let customMessage: MessagePayload = [
    "type": 100,
    "action": "game_invite",
    "game_id": "chess_123"
]
```

## Example App

A SwiftUI example app is available in `Examples/WuKongIMExample-Unified/`:

- Real-time messaging with raw JSON payload display
- Connection management and event logging
- Cross-platform (iOS/macOS)

```bash
cd Examples/WuKongIMExample-Unified
./build.sh ios    # Build for iOS
./build.sh macos  # Build for macOS
```

## Advanced Usage

### Configuration Builder

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

### Error Handling

```swift
sdk.onError { error in
    if let wkError = error as? WuKongError {
        switch wkError {
        case .authFailed(let message):
            print("Auth failed: \(message)")
        case .networkError(let message):
            print("Network error: \(message)")
        case .notConnected:
            print("Not connected")
        default:
            print("Error: \(wkError.localizedDescription)")
        }
    }
}
```

## SwiftUI Integration

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

## Documentation

- [WuKongIM Documentation](https://docs.wukongim.com)
- [API Reference](https://docs.wukongim.com/sdk/ios)
- [CocoaPods Publishing Guide](docs/COCOAPODS_PUBLISHING.md)
- [Podspec Maintenance Guide](docs/PODSPEC_MAINTENANCE.md)

## License

Apache License 2.0. See [LICENSE](LICENSE) file.

## Support

- [Issues](https://github.com/WuKongIM/WuKongEasySDK-iOS/issues)
- [Discussions](https://github.com/WuKongIM/WuKongIM/discussions)
