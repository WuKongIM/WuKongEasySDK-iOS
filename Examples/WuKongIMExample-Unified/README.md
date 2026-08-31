# WuKongEasySDK unified example

This SwiftUI example uses one Swift Package executable target on iOS 15+ and macOS 13+. It demonstrates connecting to WuKongIM, sending and receiving messages, disconnecting, and observing SDK events.

## Requirements

- Xcode 14 or newer
- Swift 5.7 or newer
- An iOS Simulator runtime when building the iOS variant
- A running WuKongIM server exposing the EasySDK JSON-RPC WebSocket endpoint

## Build and run

From this directory:

```bash
./build.sh macos
./build.sh macos --run

./build.sh ios
./build.sh ios --run
```

`./build.sh ios` uses `xcodebuild` to compile the Swift package, then creates an installable simulator app at:

```text
.build/ios-simulator/WuKongIMExample-Unified.app
```

For `ios --run`, boot a simulator first. To target a specific booted simulator or build destination:

```bash
SIMULATOR_ID=<simulator-udid> \
IOS_DESTINATION='platform=iOS Simulator,id=<simulator-udid>' \
./build.sh ios --run
```

You can also open `Package.swift` directly in Xcode. This repository does not contain an `.xcodeproj`; Swift Package Manager generates the scheme.

## Configuration

The default fields in the UI are:

- Server URL: `ws://localhost:5200`
- User ID: `testUser`
- Token: `testToken`
- Target user: `friendUser`

Change these values in the app to match your server. The iOS `Info.plist` permits arbitrary transport loads so the development example can connect to a local `ws://` endpoint; production apps should use `wss://` and remove that exception.

## Source layout

```text
WuKongIMExample-Unified/
├── Package.swift
├── Sources/WuKongIMExample-Unified/  # Files compiled by SwiftPM
├── Shared/iOS-Info.plist              # Simulator app-bundle template
├── build.sh
└── README.md
```

The package references the SDK at `../../`, so the example always exercises the checked-out WuKongEasySDK source.
