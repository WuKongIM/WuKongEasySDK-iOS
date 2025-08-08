# WuKongEasySDK 发布指南

本指南提供了发布新版本 WuKongEasySDK 到 CocoaPods 的快速步骤。

## 🚀 快速发布流程

### 1. 准备发布

```bash
# 切换到 main 分支并拉取最新代码
git checkout main
git pull origin main

# 确保所有测试通过
pod spec lint WuKongEasySDK.podspec --allow-warnings
```

### 2. 更新版本信息

编辑以下文件中的版本号：

#### `WuKongEasySDK.podspec`
```ruby
spec.version = "1.0.1"  # 更新版本号
```

#### `README.md` (可选)
```markdown
pod 'WuKongEasySDK', '~> 1.0.1'
```

#### `CHANGELOG.md` (推荐)
```markdown
## [1.0.1] - 2024-01-15

### Added
- 新功能描述

### Fixed
- Bug 修复描述

### Changed
- 变更描述
```

### 3. 提交版本更新

```bash
# 添加修改的文件
git add WuKongEasySDK.podspec README.md CHANGELOG.md

# 提交版本更新
git commit -m "bump version to 1.0.1

- 更新 podspec 版本到 1.0.1
- 更新 README 安装说明
- 添加 CHANGELOG 条目"

# 推送到远程仓库
git push origin main
```

### 4. 创建发布标签

```bash
# 创建版本标签
git tag v1.0.1

# 推送标签到远程仓库（这将触发自动发布）
git push origin v1.0.1
```

### 5. 监控发布过程

1. 访问 GitHub 仓库的 **Actions** 标签
2. 查看 "Publish to CocoaPods" 工作流程状态
3. 等待发布完成（通常需要 5-10 分钟）

## 📋 发布检查清单

### 发布前检查

- [ ] 代码已合并到 `main` 分支
- [ ] 所有测试通过
- [ ] `pod spec lint` 验证成功
- [ ] 版本号已更新在 `WuKongEasySDK.podspec`
- [ ] `CHANGELOG.md` 已更新
- [ ] `README.md` 版本号已更新（如需要）

### GitHub Secrets 检查

- [ ] `COCOAPODS_TRUNK_EMAIL` 已设置（注册时使用的邮箱）
- [ ] `COCOAPODS_TRUNK_TOKEN` 已设置
- [ ] 邮箱地址与 CocoaPods Trunk 注册信息完全一致
- [ ] Token 有效且未过期
- [ ] 具有发布权限

### 版本号检查

- [ ] 遵循语义化版本规范 (SemVer)
- [ ] Git 标签格式正确 (`v1.0.1`)
- [ ] Podspec 版本匹配标签版本 (`1.0.1`)

## 🔧 故障排除

### 常见错误及解决方案

#### 1. 版本不匹配错误

```
Error: Podspec version (1.0.0) doesn't match tag version (1.0.1)
```

**解决方案**:
```bash
# 更新 podspec 版本
vim WuKongEasySDK.podspec  # 修改 spec.version

# 重新提交并创建标签
git add WuKongEasySDK.podspec
git commit -m "fix version mismatch"
git push origin main

# 删除错误的标签
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1

# 重新创建正确的标签
git tag v1.0.1
git push origin v1.0.1
```

#### 2. Podspec 验证失败

```
Error: The spec did not pass validation
```

**解决方案**:
```bash
# 本地验证并查看详细错误
pod spec lint WuKongEasySDK.podspec --allow-warnings --verbose

# 修复错误后重新发布
```

#### 3. CocoaPods 认证失败

```
Error: Authentication failed
```
或
```
[!] You need to register a session first.
```

**解决方案**:
1. 使用脚本获取正确的认证信息:
   ```bash
   ./scripts/get-cocoapods-token.sh
   ```
2. 检查 GitHub Secrets 中的两个配置:
   - `COCOAPODS_TRUNK_EMAIL`: 注册时使用的邮箱地址
   - `COCOAPODS_TRUNK_TOKEN`: 认证 token
3. 验证本地认证: `pod trunk me`
4. 重新注册获取新认证信息:
   ```bash
   pod trunk register your-email@example.com 'Your Name' --description='GitHub Actions'
   ```
5. 更新两个 GitHub Secrets

#### 4. 分支限制错误

```
Error: Tag must be created on main branch
```

**解决方案**:
```bash
# 确保在 main 分支
git checkout main
git pull origin main

# 重新创建标签
git tag v1.0.1
git push origin v1.0.1
```

## 📦 验证发布成功

### 1. 检查 CocoaPods

```bash
# 搜索 pod
pod search WuKongEasySDK

# 查看最新版本
pod spec cat WuKongEasySDK
```

### 2. 测试安装

创建测试项目验证安装：

```ruby
# Podfile
platform :ios, '13.0'

target 'TestApp' do
  use_frameworks!
  pod 'WuKongEasySDK', '~> 1.0.1'
end
```

```bash
pod install
```

### 3. 检查 GitHub Release

- 访问仓库的 **Releases** 页面
- 确认新版本的 Release 已自动创建
- 检查 Release 说明是否正确

## 🎯 最佳实践

### 版本号规范

- **补丁版本** (1.0.0 → 1.0.1): Bug 修复
- **次要版本** (1.0.0 → 1.1.0): 新功能，向后兼容
- **主要版本** (1.0.0 → 2.0.0): 破坏性变更

### 发布频率建议

- **补丁版本**: 及时发布重要 Bug 修复
- **次要版本**: 每月或每季度发布新功能
- **主要版本**: 年度发布或重大架构变更

### 文档维护

- 每次发布都更新 `CHANGELOG.md`
- 保持 `README.md` 中的示例代码最新
- 更新 API 文档和使用指南

### 测试策略

- 发布前在多个 iOS 版本上测试
- 验证示例应用正常工作
- 确保向后兼容性

## 📞 获取帮助

如果遇到发布问题：

1. 查看 GitHub Actions 日志获取详细错误信息
2. 参考 [CocoaPods 设置指南](COCOAPODS_SETUP.md)
3. 检查 [CocoaPods 状态页面](https://status.cocoapods.org/)
4. 在仓库中创建 Issue 寻求帮助

---

**注意**: 首次设置需要配置 CocoaPods Trunk token，详见 [COCOAPODS_SETUP.md](COCOAPODS_SETUP.md)。
