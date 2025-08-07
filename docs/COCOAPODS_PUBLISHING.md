# CocoaPods Publishing Guide

This guide provides step-by-step instructions for publishing WuKongEasySDK to the CocoaPods repository.

## Prerequisites

### 1. CocoaPods Installation

Ensure CocoaPods is installed on your system:

```bash
# Install CocoaPods
sudo gem install cocoapods

# Verify installation
pod --version
```

### 2. CocoaPods Trunk Account

Register for a CocoaPods Trunk account if you haven't already:

```bash
# Register with your email and name
pod trunk register your-email@example.com 'Your Name' --description='MacBook Pro'

# Verify registration (check your email for confirmation)
pod trunk me
```

### 3. Git Repository Setup

Ensure your repository is properly set up:

```bash
# Verify remote origin is set
git remote -v

# Ensure you're on the main branch
git checkout main

# Ensure working directory is clean
git status
```

## Publishing Process

### Step 1: Update Version Information

1. **Update the podspec version:**

```ruby
# In WuKongEasySDK.podspec
spec.version = "1.0.1"  # Increment version number
```

2. **Update version in relevant files** (if applicable):
   - Package.swift
   - Source code version constants
   - README.md examples

### Step 2: Validate the Podspec

Before publishing, validate your podspec file:

```bash
# Basic validation
pod spec lint WuKongEasySDK.podspec

# Verbose validation (shows detailed output)
pod spec lint WuKongEasySDK.podspec --verbose

# Validation with warnings allowed (if needed)
pod spec lint WuKongEasySDK.podspec --allow-warnings
```

### Step 3: Create and Push Git Tag

CocoaPods requires a git tag matching the version:

```bash
# Create a tag for the version
git tag 1.0.1

# Push the tag to remote repository
git push origin 1.0.1

# Verify tag was created
git tag -l
```

### Step 4: Publish to CocoaPods Trunk

```bash
# Publish the pod
pod trunk push WuKongEasySDK.podspec

# Publish with verbose output
pod trunk push WuKongEasySDK.podspec --verbose

# Publish allowing warnings (if necessary)
pod trunk push WuKongEasySDK.podspec --allow-warnings
```

## Version Management

### Semantic Versioning

Follow semantic versioning (SemVer) for version numbers:

- **MAJOR.MINOR.PATCH** (e.g., 1.0.1)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Version Update Checklist

- [ ] Update `spec.version` in WuKongEasySDK.podspec
- [ ] Update CHANGELOG.md (if exists)
- [ ] Update README.md examples if API changed
- [ ] Commit all changes
- [ ] Create and push git tag
- [ ] Validate podspec
- [ ] Publish to CocoaPods

## Verification Steps

### 1. Verify Publication

```bash
# Check if your pod is available
pod search WuKongEasySDK

# Check pod information
pod trunk info WuKongEasySDK
```

### 2. Test Installation

Create a test project and verify installation:

```bash
# Create test Podfile
echo "platform :ios, '12.0'
use_frameworks!
target 'TestApp' do
  pod 'WuKongEasySDK', '~> 1.0.1'
end" > Podfile

# Install and test
pod install
```

### 3. Verify on CocoaPods.org

Visit [CocoaPods.org](https://cocoapods.org/pods/WuKongEasySDK) to confirm your pod appears correctly.

## Troubleshooting

### Common Issues and Solutions

#### 1. Validation Errors

**Error: "Unable to find a specification"**
```bash
# Solution: Ensure podspec syntax is correct
pod spec lint WuKongEasySDK.podspec --verbose
```

**Error: "The version should be included in the Git repository"**
```bash
# Solution: Create and push the git tag
git tag 1.0.1
git push origin 1.0.1
```

#### 2. Authentication Issues

**Error: "You are not allowed to push new versions"**
```bash
# Solution: Verify trunk registration
pod trunk me

# Re-register if needed
pod trunk register your-email@example.com 'Your Name'
```

#### 3. Dependency Issues

**Error: "Unable to find a specification for dependency"**
```bash
# Solution: Update CocoaPods repository
pod repo update

# Or specify dependency versions explicitly in podspec
```

#### 4. Build Issues

**Error: "The pod does not build"**
```bash
# Solution: Test build locally
pod lib lint WuKongEasySDK.podspec --verbose

# Check for missing files or incorrect paths
```

### Debug Commands

```bash
# Verbose linting with full output
pod spec lint WuKongEasySDK.podspec --verbose --no-clean

# Check trunk status
pod trunk info WuKongEasySDK

# Update local CocoaPods repository
pod repo update

# Clear CocoaPods cache
pod cache clean --all
```

## Maintenance

### Regular Updates

1. **Monitor Issues**: Check GitHub issues and CocoaPods feedback
2. **Update Dependencies**: Keep Starscream and other dependencies current
3. **Test Compatibility**: Verify with new iOS/Xcode versions
4. **Documentation**: Keep README and documentation updated

### Best Practices

- Always test locally before publishing
- Use semantic versioning consistently
- Maintain a CHANGELOG.md file
- Tag releases properly in Git
- Respond to community feedback promptly
- Keep dependencies up to date

## Resources

- [CocoaPods Guides](https://guides.cocoapods.org/)
- [Podspec Syntax Reference](https://guides.cocoapods.org/syntax/podspec.html)
- [CocoaPods Trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk.html)
- [Semantic Versioning](https://semver.org/)

## Support

For issues with publishing:
- Check [CocoaPods GitHub Issues](https://github.com/CocoaPods/CocoaPods/issues)
- Visit [CocoaPods Slack](https://cocoapods-slack-invite.herokuapp.com/)
- Review [CocoaPods Troubleshooting Guide](https://guides.cocoapods.org/using/troubleshooting.html)
