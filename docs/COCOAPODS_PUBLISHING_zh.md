# CocoaPods 发布指南

本指南提供了将 WuKongEasySDK 发布到 CocoaPods 仓库的详细步骤说明。

## 前置条件

### 1. 安装 CocoaPods

确保系统已安装 CocoaPods：

```bash
# 安装 CocoaPods
sudo gem install cocoapods

# 验证安装
pod --version
```

### 2. CocoaPods Trunk 账户

如果还没有 CocoaPods Trunk 账户，请先注册：

```bash
# 使用邮箱和姓名注册
pod trunk register your-email@example.com 'Your Name' --description='MacBook Pro'

# 验证注册（检查邮箱确认邮件）
pod trunk me
```

### 3. Git 仓库设置

确保仓库设置正确：

```bash
# 验证远程仓库设置
git remote -v

# 确保在主分支
git checkout main

# 确保工作目录干净
git status
```

## 发布流程

### 步骤 1：更新版本信息

1. **更新 podspec 版本：**

```ruby
# 在 WuKongEasySDK.podspec 中
spec.version = "1.0.1"  # 递增版本号
```

2. **更新相关文件中的版本**（如适用）：
   - Package.swift
   - 源代码版本常量
   - README.md 示例

### 步骤 2：验证 Podspec

发布前验证 podspec 文件：

```bash
# 基本验证
pod spec lint WuKongEasySDK.podspec

# 详细验证（显示详细输出）
pod spec lint WuKongEasySDK.podspec --verbose

# 允许警告的验证（如需要）
pod spec lint WuKongEasySDK.podspec --allow-warnings
```

### 步骤 3：创建并推送 Git 标签

CocoaPods 需要与版本匹配的 git 标签：

```bash
# 为版本创建标签
git tag 1.0.1

# 推送标签到远程仓库
git push origin 1.0.1

# 验证标签已创建
git tag -l
```

### 步骤 4：发布到 CocoaPods Trunk

```bash
# 发布 pod
pod trunk push WuKongEasySDK.podspec

# 详细输出发布
pod trunk push WuKongEasySDK.podspec --verbose

# 允许警告发布（如必要）
pod trunk push WuKongEasySDK.podspec --allow-warnings
```

## 版本管理

### 语义化版本控制

遵循语义化版本控制（SemVer）：

- **主版本.次版本.修订版本**（例如：1.0.1）
- **主版本**：破坏性变更
- **次版本**：新功能（向后兼容）
- **修订版本**：错误修复（向后兼容）

### 版本更新检查清单

- [ ] 更新 WuKongEasySDK.podspec 中的 `spec.version`
- [ ] 更新 CHANGELOG.md（如存在）
- [ ] 如 API 有变更，更新 README.md 示例
- [ ] 提交所有更改
- [ ] 创建并推送 git 标签
- [ ] 验证 podspec
- [ ] 发布到 CocoaPods

## 验证步骤

### 1. 验证发布

```bash
# 检查 pod 是否可用
pod search WuKongEasySDK

# 检查 pod 信息
pod trunk info WuKongEasySDK
```

### 2. 测试安装

创建测试项目并验证安装：

```bash
# 创建测试 Podfile
echo "platform :ios, '12.0'
use_frameworks!
target 'TestApp' do
  pod 'WuKongEasySDK', '~> 1.0.1'
end" > Podfile

# 安装并测试
pod install
```

### 3. 在 CocoaPods.org 上验证

访问 [CocoaPods.org](https://cocoapods.org/pods/WuKongEasySDK) 确认您的 pod 正确显示。

## 故障排除

### 常见问题和解决方案

#### 1. 验证错误

**错误："Unable to find a specification"**
```bash
# 解决方案：确保 podspec 语法正确
pod spec lint WuKongEasySDK.podspec --verbose
```

**错误："The version should be included in the Git repository"**
```bash
# 解决方案：创建并推送 git 标签
git tag 1.0.1
git push origin 1.0.1
```

#### 2. 认证问题

**错误："You are not allowed to push new versions"**
```bash
# 解决方案：验证 trunk 注册
pod trunk me

# 如需要重新注册
pod trunk register your-email@example.com 'Your Name'
```

#### 3. 依赖问题

**错误："Unable to find a specification for dependency"**
```bash
# 解决方案：更新 CocoaPods 仓库
pod repo update

# 或在 podspec 中明确指定依赖版本
```

#### 4. 构建问题

**错误："The pod does not build"**
```bash
# 解决方案：本地测试构建
pod lib lint WuKongEasySDK.podspec --verbose

# 检查缺失文件或错误路径
```

### 调试命令

```bash
# 详细检查，完整输出
pod spec lint WuKongEasySDK.podspec --verbose --no-clean

# 检查 trunk 状态
pod trunk info WuKongEasySDK

# 更新本地 CocoaPods 仓库
pod repo update

# 清除 CocoaPods 缓存
pod cache clean --all
```

## 维护

### 定期更新

1. **监控问题**：检查 GitHub issues 和 CocoaPods 反馈
2. **更新依赖**：保持 Starscream 和其他依赖最新
3. **测试兼容性**：验证新 iOS/Xcode 版本兼容性
4. **文档维护**：保持 README 和文档更新

### 最佳实践

- 发布前始终本地测试
- 一致使用语义化版本控制
- 维护 CHANGELOG.md 文件
- 在 Git 中正确标记发布
- 及时响应社区反馈
- 保持依赖项更新

## 资源

- [CocoaPods 指南](https://guides.cocoapods.org/)
- [Podspec 语法参考](https://guides.cocoapods.org/syntax/podspec.html)
- [CocoaPods Trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk.html)
- [语义化版本控制](https://semver.org/)

## 支持

发布问题支持：
- 查看 [CocoaPods GitHub Issues](https://github.com/CocoaPods/CocoaPods/issues)
- 访问 [CocoaPods Slack](https://cocoapods-slack-invite.herokuapp.com/)
- 查阅 [CocoaPods 故障排除指南](https://guides.cocoapods.org/using/troubleshooting.html)
