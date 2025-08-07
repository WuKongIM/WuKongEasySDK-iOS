# Changelog

All notable changes to WuKongEasySDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow for automatic CocoaPods publishing
- Release automation scripts and documentation

### Changed
- Updated minimum iOS version to 13.0 for async/await support
- Updated minimum macOS version to 12.0 for test compatibility

### Fixed
- Resolved Swift concurrency and Sendable protocol warnings
- Fixed URLSessionWebSocketTask availability issues
- Improved error handling in WebSocket connections

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
