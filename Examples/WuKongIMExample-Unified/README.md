# WuKongIM Example - Unified iOS/macOS App

This is a unified example application demonstrating the WuKongEasySDK for both iOS and macOS platforms. The app provides a complete chat interface with real-time messaging capabilities.

## Bundle Identifier Fix

This project resolves the bundle identifier error that was occurring when trying to run Swift Package Manager executables in the iOS Simulator:

```
failure in void __BKSHIDEvent__BUNDLE_IDENTIFIER_FOR_CURRENT_PROCESS_IS_NIL__(NSBundle *__strong) (BKSHIDEvent.m:91) : missing bundleID for main bundle
```

### Problem

Swift Package Manager executable targets are designed for command-line tools, not iOS apps. When attempting to run them in the iOS Simulator, they lack the proper app bundle structure and metadata (bundle identifier, Info.plist, etc.) that iOS requires.

### Solution

This project uses a proper Xcode project structure instead of SPM executables:

- **Proper iOS App Bundle**: Creates a real iOS app with bundle identifier `com.wukongim.example.ios`
- **macOS App Bundle**: Creates a macOS app with bundle identifier `com.wukongim.example.macos`
- **Shared Source Code**: Both targets use the same SwiftUI source files from the `Shared/` directory
- **Cross-Platform Compatibility**: Handles platform-specific UI differences with conditional compilation

## Features

- **Cross-Platform UI**: Single SwiftUI codebase that works on both iOS and macOS
- **Real-time Messaging**: Connect to WuKongIM server and send/receive messages
- **Connection Management**: Easy server connection with status indicators
- **Message History**: View sent and received messages with timestamps
- **SDK Event Logs**: Real-time display of SDK events with color-coded log levels
- **Example Messages**: Pre-built message examples for testing different message types

## Project Structure

```
WuKongIMExample-Unified/
├── WuKongIMExample.xcodeproj/     # Xcode project file
├── Shared/                        # Shared source code
│   ├── WuKongIMExampleApp.swift  # Main app entry point
│   ├── ContentView.swift         # Main UI with cross-platform support
│   ├── Models/
│   │   ├── ChatManager.swift     # Chat logic and SDK integration
│   │   └── ChatMessage.swift     # Data models
│   ├── Assets.xcassets/          # App icons and assets
│   ├── iOS-Info.plist           # iOS-specific configuration
│   └── macOS-Info.plist         # macOS-specific configuration
└── README.md                     # This file
```

## Requirements

- iOS 15.0+ / macOS 13.0+
- Xcode 14.0+
- Swift 5.7+

## Building and Running

### iOS

```bash
# Build for iOS Simulator
xcodebuild -project WuKongIMExample.xcodeproj -scheme WuKongIMExample-iOS -destination 'platform=iOS Simulator,name=iPhone 16' build

# Install and run in simulator
xcrun simctl boot "iPhone 16"
xcrun simctl install booted "/path/to/WuKongIMExample-iOS.app"
xcrun simctl launch booted com.wukongim.example.ios
```

### macOS

```bash
# Build for macOS
xcodebuild -project WuKongIMExample.xcodeproj -scheme WuKongIMExample-macOS build

# Run the macOS app
open "/path/to/WuKongIMExample-macOS.app"
```

### Using Xcode

1. Open `WuKongIMExample.xcodeproj` in Xcode
2. Select either `WuKongIMExample-iOS` or `WuKongIMExample-macOS` scheme
3. Choose your target device/simulator
4. Press Cmd+R to build and run

## Configuration

The app connects to a WuKongIM server. Default settings:
- **Server URL**: `ws://localhost:5200`
- **User ID**: `testUser`
- **Token**: `testToken`

You can modify these values in the connection interface when running the app.

## Cross-Platform Considerations

The app handles platform differences automatically:

- **Navigation**: Uses iOS-style navigation bar titles on iOS, standard titles on macOS
- **Colors**: Uses cross-platform compatible colors instead of iOS-specific system colors
- **Text Fields**: Handles different TextField API availability across iOS/macOS versions
- **UI Layout**: Adapts to platform-specific interface guidelines

## Dependencies

- **WuKongEasySDK**: Referenced as a local Swift package from the parent directory
- **SwiftUI**: For cross-platform UI
- **Foundation**: For basic functionality

## Bundle Identifiers

- **iOS**: `com.wukongim.example.ios`
- **macOS**: `com.wukongim.example.macos`

These unique bundle identifiers ensure proper app installation and execution on both platforms.
