# WuKongEasySDK Documentation

This directory contains comprehensive documentation for developing, maintaining, and publishing the WuKongEasySDK.

## 📚 Available Documentation

### Publishing Guides

- **[CocoaPods Publishing Guide](COCOAPODS_PUBLISHING.md)** - Complete guide for publishing to CocoaPods Trunk
- **[CocoaPods Publishing Guide (中文)](COCOAPODS_PUBLISHING_zh.md)** - CocoaPods 发布指南（中文版）
- **[Podspec Maintenance Guide](PODSPEC_MAINTENANCE.md)** - How to maintain the WuKongEasySDK.podspec file

## 🚀 Quick Start for Publishers

### First-Time Setup

1. **Register with CocoaPods Trunk:**
   ```bash
   pod trunk register your-email@example.com 'Your Name'
   ```

2. **Verify your account:**
   ```bash
   pod trunk me
   ```

### Publishing a New Version

1. **Update version in podspec:**
   ```ruby
   spec.version = "1.0.1"
   ```

2. **Validate the podspec:**
   ```bash
   pod spec lint WuKongEasySDK.podspec
   ```

3. **Create and push Git tag:**
   ```bash
   git tag 1.0.1
   git push origin 1.0.1
   ```

4. **Publish to CocoaPods:**
   ```bash
   pod trunk push WuKongEasySDK.podspec
   ```

## 📖 Documentation Structure

```
docs/
├── README.md                    # This file - documentation index
├── COCOAPODS_PUBLISHING.md      # English publishing guide
├── COCOAPODS_PUBLISHING_zh.md   # Chinese publishing guide
└── PODSPEC_MAINTENANCE.md       # Podspec maintenance guide
```

## 🔗 External Resources

- [CocoaPods Guides](https://guides.cocoapods.org/)
- [Podspec Syntax Reference](https://guides.cocoapods.org/syntax/podspec.html)
- [Semantic Versioning](https://semver.org/)
- [WuKongIM Documentation](https://docs.wukongim.com)

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting sections in the publishing guides
2. Review [CocoaPods GitHub Issues](https://github.com/CocoaPods/CocoaPods/issues)
3. Visit [CocoaPods Slack](https://cocoapods-slack-invite.herokuapp.com/)
4. Contact the WuKongIM team at support@wukongim.com

## 📝 Contributing to Documentation

To improve this documentation:

1. Fork the repository
2. Make your changes
3. Test any commands or procedures
4. Submit a pull request

Keep documentation:
- **Clear and concise**
- **Up-to-date with current practices**
- **Tested and verified**
- **Accessible to developers of all levels**
