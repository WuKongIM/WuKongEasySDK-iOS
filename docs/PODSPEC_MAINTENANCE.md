# Podspec Maintenance Guide

This guide explains how to maintain and update the WuKongEasySDK.podspec file for CocoaPods distribution.

## Current Podspec Structure

The WuKongEasySDK.podspec file contains the following key sections:

```ruby
Pod::Spec.new do |spec|
  # Basic Information
  spec.name         = "WuKongEasySDK"
  spec.version      = "1.0.0"
  spec.summary      = "A lightweight iOS SDK for WuKongIM real-time messaging"
  spec.description  = <<-DESC
                      # Detailed description here
                      DESC

  # Repository Information
  spec.homepage     = "https://github.com/WuKongIM/WuKongEasySDK-iOS"
  spec.license      = { :type => "Apache-2.0", :file => "LICENSE" }
  spec.author       = { "WuKongIM" => "support@wukongim.com" }
  
  # Platform Support
  spec.ios.deployment_target = "12.0"
  spec.osx.deployment_target = "10.15"
  spec.tvos.deployment_target = "13.0"
  spec.watchos.deployment_target = "6.0"
  
  # Swift Version
  spec.swift_version = "5.7"
  
  # Source Configuration
  spec.source       = { :git => "https://github.com/WuKongIM/WuKongEasySDK-iOS.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/WuKongEasySDK/**/*.swift"
  
  # Framework Dependencies
  spec.frameworks = "Foundation", "Network"
  spec.requires_arc = true
  
  # Additional Configuration
  spec.documentation_url = "https://docs.wukongim.com"
  spec.social_media_url = "https://twitter.com/wukongim"
  
  # Test Specification
  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/WuKongEasySDKTests/**/*.swift'
    test_spec.frameworks = 'XCTest'
  end
end
```

## Key Fields to Maintain

### 1. Version Management

**Field:** `spec.version`

```ruby
spec.version = "1.0.1"  # Update for each release
```

**Guidelines:**
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Must match the Git tag exactly
- Update before each release

### 2. Description Updates

**Field:** `spec.description`

```ruby
spec.description = <<-DESC
                   WuKongIM iOS EasySDK is a lightweight iOS SDK that allows you to add real-time chat functionality to iOS applications in 5 minutes. 
                   
                   Features:
                   - Easy integration with just a few lines of code
                   - Real-time messaging with WebSocket
                   - Automatic reconnection with exponential backoff
                   - Thread-safe event handling
                   - Memory-safe event listeners
                   - Comprehensive error handling
                   - Support for iOS 12.0+
                   - Swift Package Manager and CocoaPods support
                   DESC
```

**When to Update:**
- New features added
- Platform support changes
- Major functionality updates

### 3. Platform Support

**Fields:** Deployment targets

```ruby
spec.ios.deployment_target = "12.0"
spec.osx.deployment_target = "10.15"
spec.tvos.deployment_target = "13.0"
spec.watchos.deployment_target = "6.0"
```

**Guidelines:**
- Update when dropping support for older versions
- Consider backward compatibility impact
- Test on minimum supported versions

### 4. Swift Version

**Field:** `spec.swift_version`

```ruby
spec.swift_version = "5.7"
```

**When to Update:**
- When adopting new Swift language features
- When dropping support for older Swift versions
- Coordinate with Xcode version requirements

### 5. Dependencies

**Field:** External dependencies (if any)

```ruby
# Currently no external dependencies listed
# If adding dependencies:
spec.dependency 'SomeLibrary', '~> 1.0'
```

**Guidelines:**
- Minimize external dependencies
- Use version constraints wisely
- Test compatibility thoroughly

## Common Maintenance Tasks

### 1. Version Release Update

```ruby
# Before release
spec.version = "1.0.0"

# After implementing new features
spec.version = "1.1.0"

# After bug fixes
spec.version = "1.0.1"
```

### 2. Adding New Source Files

```ruby
# Current configuration includes all Swift files
spec.source_files = "Sources/WuKongEasySDK/**/*.swift"

# If adding specific files or excluding some:
spec.source_files = "Sources/WuKongEasySDK/**/*.swift"
spec.exclude_files = "Sources/WuKongEasySDK/Internal/**/*.swift"
```

### 3. Platform Support Updates

```ruby
# Dropping iOS 12 support
spec.ios.deployment_target = "13.0"

# Adding new platform
spec.visionos.deployment_target = "1.0"
```

### 4. Framework Dependencies

```ruby
# Adding new system frameworks
spec.frameworks = "Foundation", "Network", "Combine"

# Adding weak frameworks (optional)
spec.weak_frameworks = "SomeOptionalFramework"
```

## Validation Checklist

Before updating the podspec, verify:

- [ ] Version number follows semantic versioning
- [ ] Git tag exists for the version
- [ ] All source files are included correctly
- [ ] Platform targets are appropriate
- [ ] Swift version is correct
- [ ] License information is accurate
- [ ] Repository URLs are correct
- [ ] Description reflects current features

## Testing Changes

### 1. Local Validation

```bash
# Validate syntax and basic checks
pod spec lint WuKongEasySDK.podspec

# Verbose validation
pod spec lint WuKongEasySDK.podspec --verbose

# Allow warnings if needed
pod spec lint WuKongEasySDK.podspec --allow-warnings
```

### 2. Integration Testing

```bash
# Test in a sample project
pod lib lint WuKongEasySDK.podspec

# Test with specific platforms
pod lib lint WuKongEasySDK.podspec --platforms=ios
```

### 3. Dependency Testing

```bash
# Test installation in a new project
echo "platform :ios, '12.0'
use_frameworks!
target 'TestApp' do
  pod 'WuKongEasySDK', :path => '.'
end" > TestPodfile

pod install --podfile=TestPodfile
```

## Best Practices

### 1. Documentation

- Keep description up-to-date with features
- Update homepage and documentation URLs
- Maintain accurate author information

### 2. Versioning

- Use semantic versioning consistently
- Create Git tags before publishing
- Update CHANGELOG.md alongside podspec

### 3. Compatibility

- Test on minimum supported platforms
- Verify Swift version compatibility
- Check framework availability across platforms

### 4. Source Management

- Use inclusive source file patterns
- Exclude unnecessary files (tests, examples)
- Organize source files logically

## Troubleshooting

### Common Issues

1. **Version Mismatch**
   - Ensure Git tag matches spec.version
   - Push tags to remote repository

2. **Source File Issues**
   - Verify file paths are correct
   - Check for missing or moved files

3. **Platform Compatibility**
   - Test on actual devices/simulators
   - Verify framework availability

4. **Swift Version Conflicts**
   - Ensure consistency across project
   - Update Xcode version requirements

### Debug Commands

```bash
# Detailed validation output
pod spec lint WuKongEasySDK.podspec --verbose --no-clean

# Check specific platforms
pod spec lint WuKongEasySDK.podspec --platforms=ios,macos

# Validate without network checks
pod spec lint WuKongEasySDK.podspec --skip-import-validation
```

## Resources

- [Podspec Syntax Reference](https://guides.cocoapods.org/syntax/podspec.html)
- [CocoaPods Best Practices](https://guides.cocoapods.org/making/making-a-cocoapod.html)
- [Semantic Versioning](https://semver.org/)
- [Swift Version Compatibility](https://swift.org/download/)
