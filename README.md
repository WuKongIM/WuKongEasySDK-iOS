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

- iOS 13.0+ / macOS 12.0+ / tvOS 13.0+ / watchOS 6.0+
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
    .package(url: "https://github.com/WuKongIM/WuKongEasySDK-iOS.git", from: "1.1.1")
]
```

### CocoaPods

```ruby
pod 'WuKongEasySDK', '~> 1.1.1'
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
sdk.onMessage { message in print("Received message, sequence: \(message.messageSeq)") }
sdk.onError { error in
    if let sdkError = error as? WuKongError {
        print("SDK error code: \(sdkError.code)")
    } else {
        print("SDK transport error")
    }
}

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

- Real-time messaging with message metadata display
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
        .logLevel(.info)
        .build()
}
```

`enableDebugLogging` is the master switch for every SDK diagnostic. When it is
`false`, `logLevel` cannot enable INFO, ERROR, DEBUG, or JSON output. When it is
`true`, `logLevel` selects the maximum verbosity. JSON wire summaries also
require `.debug` and `enableJsonLogging`; they contain only redacted JSON-RPC
envelope data. Params, payloads, results, errors, malformed input, connection
URLs, disconnect reasons, unknown methods, and request IDs are never echoed.

### Error Handling

```swift
sdk.onError { error in
    if let wkError = error as? WuKongError {
        switch wkError {
        case .authFailed:
            print("Authentication failed")
        case .networkError:
            print("Network error")
        case .notConnected:
            print("Not connected")
        default:
            print("SDK error code: \(wkError.code)")
        }
    } else {
        print("SDK transport error")
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

## Development & Release

### Automatic Release to CocoaPods

This project uses GitHub Actions to automatically publish new versions to CocoaPods when tags are created.

#### Quick Release Process

```bash
# Use the release script (recommended)
./scripts/release.sh 1.0.1

# Or manually:
# 1. Update version in WuKongEasySDK.podspec
# 2. Update CHANGELOG.md
# 3. Commit changes
# 4. Create and push tag: git tag v1.0.1 && git push origin v1.0.1
```

#### Setup Requirements

For maintainers, ensure the following GitHub Secrets are configured:
- `COCOAPODS_TRUNK_EMAIL`: Your CocoaPods Trunk registered email address
- `COCOAPODS_TRUNK_TOKEN`: Your CocoaPods Trunk API token

For detailed instructions, see:
- [CocoaPods Setup Guide](docs/COCOAPODS_SETUP.md)
- [Release Guide](docs/RELEASE_GUIDE.md)

### Manual Development

```bash
# Clone the repository
git clone https://github.com/your-username/WuKongEasySDK.git
cd WuKongEasySDK

# Validate podspec
pod spec lint WuKongEasySDK.podspec --allow-warnings
```

## Documentation

- [WuKongIM Documentation](https://docs.wukongim.com)
- [API Reference](https://docs.wukongim.com/sdk/ios)
- [CocoaPods Setup Guide](docs/COCOAPODS_SETUP.md)
- [Release Guide](docs/RELEASE_GUIDE.md)

## License

Apache License 2.0. See [LICENSE](LICENSE) file.

## Support

- [Issues](https://github.com/WuKongIM/WuKongEasySDK-iOS/issues)
- [Discussions](https://github.com/WuKongIM/WuKongIM/discussions)
