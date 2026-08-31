# Changelog

All notable changes to WuKongEasySDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2026-09-01

### Fixed
- Isolated WebSocket transport generations so callbacks from retired sockets cannot alter the active connection
- Completed failed connection attempts and retired authentication attempts interrupted by disconnect
- Made the unified macOS and iOS example build and run from one script
- Rendered received message content and timestamps correctly in the unified example

## [1.1.0] - 2026-08-31

### Added
- Added `enableJsonLogging(_:)` to `WuKongConfigBuilder`

### Fixed
- Made `enableDebugLogging` the master switch for SDK, event, WebSocket, and JSON diagnostics while retaining `logLevel` as the enabled-logging severity filter
- Fixed WebSocket teardown so deinitialization no longer enqueues work that captures a partially deinitialized instance

### Security
- Prevented JSON wire logs from bypassing disabled debug logging
- Replaced raw JSON-RPC data with a safe envelope summary and redacted unstructured error details
- Removed connection URLs, disconnect reasons, unknown methods, and request IDs from diagnostic output
- Stopped malformed JSON input from being echoed into logs
- Updated README and sample applications to avoid logging complete messages, payloads, credentials, identifiers, disconnect reasons, or error descriptions
- Redacted sensitive fields from public model description, debug-description, and interpolation output

## [1.0.3] - 2026-08-28

### Added
- Pull request CI that runs Swift package tests and CocoaPods linting

### Fixed
- Aligned device flag wire values with WuKongIM: APP `0`, WEB `1`, and PC/Desktop `2`
- Qualified the Starscream WebSocket type to avoid a name collision with newer Apple Network SDKs

## [1.0.0] - 2024-01-07

### Added
- Initial release of WuKongEasySDK
- WebSocket-based real-time messaging
- Support for iOS 13.0+, macOS 12.0+, tvOS 13.0+, watchOS 6.0+
- JSON-RPC 2.0 protocol implementation
- Comprehensive error handling and logging
- Swift Package Manager support
- CocoaPods support
- Async/await API support
- Flexible dictionary-based payload handling
- Starscream WebSocket library integration

### Features
- **Connection Management**: Automatic reconnection with exponential backoff
- **Message Handling**: Send and receive messages with delivery confirmation
- **Channel Support**: Support for different channel types (person, group, etc.)
- **Error Handling**: Comprehensive error types and handling
- **Logging**: Configurable logging levels for debugging
- **Thread Safety**: Thread-safe operations with internal queue management
- **Modern Swift**: Full async/await support for modern Swift development

### Dependencies
- Starscream 4.0.8 for WebSocket connectivity
- Foundation framework for core functionality
- Network framework for connectivity monitoring

---

## Release Notes Template

When creating a new release, copy this template and fill in the details:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features or capabilities

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Now removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

## Version History

- **1.0.0**: Initial release with core messaging functionality
- **Future releases**: See [Unreleased] section above

## Migration Guides

### Upgrading to 1.0.0
This is the initial release, no migration needed.

## Support

For questions about specific releases or upgrade paths:
- [GitHub Issues](https://github.com/WuKongIM/WuKongEasySDK-iOS/issues)
- [GitHub Discussions](https://github.com/WuKongIM/WuKongIM/discussions)
