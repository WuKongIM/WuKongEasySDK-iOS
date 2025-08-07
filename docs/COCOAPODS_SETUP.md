# CocoaPods 自动发布设置指南

本文档说明如何设置 GitHub Actions 自动发布 WuKongEasySDK 到 CocoaPods Trunk。

## 1. 获取 CocoaPods Trunk Token

### 步骤 1: 注册 CocoaPods Trunk 账户

如果您还没有 CocoaPods Trunk 账户，请先注册：

```bash
# 使用您的邮箱和姓名注册
pod trunk register your-email@example.com 'Your Name'
```

注册后，您会收到一封确认邮件，点击邮件中的链接完成验证。

### 步骤 2: 获取 Trunk Token

```bash
# 查看您的 Trunk 信息和 token
pod trunk me
```

输出示例：
```
- Name:     Your Name
- Email:    your-email@example.com
- Since:    January 1st, 2024
- Pods:     None
- Sessions:
  - January 1st, 2024 - December 31st, 2024. IP: xxx.xxx.xxx.xxx
    Description: MacBook Pro
```

### 步骤 3: 获取 Token 文件

CocoaPods Trunk token 通常存储在：
```bash
# macOS/Linux
cat ~/.cocoapods/trunk_token

# 或者查看配置目录
ls -la ~/.cocoapods/
```

如果文件不存在，可以通过以下命令生成新的 session：
```bash
pod trunk register your-email@example.com 'Your Name' --description='GitHub Actions'
```

## 2. 在 GitHub 仓库中设置 Secrets

### 步骤 1: 访问仓库设置

1. 打开您的 GitHub 仓库
2. 点击 **Settings** 标签
3. 在左侧菜单中选择 **Secrets and variables** → **Actions**

### 步骤 2: 添加 Secret

1. 点击 **New repository secret**
2. 设置以下 Secret：

| Secret 名称 | 值 | 描述 |
|------------|----|----|
| `COCOAPODS_TRUNK_TOKEN` | 您的 CocoaPods Trunk token | 用于身份验证的 token |

### 步骤 3: 验证设置

确保 Secret 已正确添加：
- Secret 名称必须完全匹配：`COCOAPODS_TRUNK_TOKEN`
- Token 值不应包含额外的空格或换行符

## 3. 使用自动发布流程

### 创建发布标签

自动发布流程通过 Git 标签触发。标签格式必须为 `v*.*.*`（语义化版本）。

#### 方法 1: 使用命令行

```bash
# 1. 确保在 main 分支
git checkout main
git pull origin main

# 2. 更新 podspec 中的版本号
# 编辑 WuKongEasySDK.podspec，更新 spec.version

# 3. 提交版本更新
git add WuKongEasySDK.podspec
git commit -m "bump version to 1.0.1"
git push origin main

# 4. 创建并推送标签
git tag v1.0.1
git push origin v1.0.1
```

#### 方法 2: 使用 GitHub Web 界面

1. 访问仓库的 **Releases** 页面
2. 点击 **Create a new release**
3. 在 **Tag version** 中输入版本号（如 `v1.0.1`）
4. 确保 **Target** 设置为 `main` 分支
5. 填写 Release 标题和描述
6. 点击 **Publish release**

### 版本号要求

- **Git 标签格式**: `v1.0.0`, `v1.0.1`, `v2.0.0` 等
- **Podspec 版本**: 必须与标签版本匹配（不包含 'v' 前缀）

示例：
```ruby
# WuKongEasySDK.podspec
spec.version = "1.0.1"  # 对应标签 v1.0.1
```

## 4. 监控发布流程

### 查看 GitHub Actions 状态

1. 访问仓库的 **Actions** 标签
2. 查找 "Publish to CocoaPods" 工作流程
3. 点击最新的运行记录查看详细日志

### 发布流程步骤

工作流程包含以下主要步骤：

1. **环境设置**: 安装 Ruby、CocoaPods、Xcode
2. **版本验证**: 检查标签版本与 podspec 版本是否匹配
3. **Podspec 验证**: 运行 `pod spec lint --allow-warnings`
4. **身份验证**: 使用 Trunk token 进行身份验证
5. **发布**: 执行 `pod trunk push --allow-warnings`
6. **创建 Release**: 自动创建 GitHub Release

### 验证发布成功

发布成功后，您可以：

```bash
# 搜索您的 pod
pod search WuKongEasySDK

# 查看 pod 信息
pod spec cat WuKongEasySDK

# 在项目中测试安装
pod install
```

## 5. 故障排除

### 常见问题

#### 1. Token 认证失败
```
Error: Authentication failed
```

**解决方案**:
- 检查 `COCOAPODS_TRUNK_TOKEN` Secret 是否正确设置
- 确认 token 没有过期
- 重新生成 token: `pod trunk register your-email@example.com 'Your Name'`

#### 2. 版本不匹配
```
Error: Podspec version doesn't match tag version
```

**解决方案**:
- 确保 `WuKongEasySDK.podspec` 中的 `spec.version` 与 Git 标签匹配
- 标签 `v1.0.1` 应对应 podspec 版本 `1.0.1`

#### 3. Podspec 验证失败
```
Error: The spec did not pass validation
```

**解决方案**:
- 本地运行验证: `pod spec lint WuKongEasySDK.podspec --allow-warnings`
- 修复验证错误后重新创建标签

#### 4. 分支限制
```
Error: Tag must be created on main branch
```

**解决方案**:
- 确保标签是在 `main` 分支上创建的
- 切换到 main 分支后重新创建标签

### 手动发布备用方案

如果自动发布失败，您可以手动发布：

```bash
# 1. 验证 podspec
pod spec lint WuKongEasySDK.podspec --allow-warnings

# 2. 登录 CocoaPods Trunk
pod trunk register your-email@example.com 'Your Name'

# 3. 发布
pod trunk push WuKongEasySDK.podspec --allow-warnings
```

## 6. 最佳实践

### 发布前检查清单

- [ ] 更新 `CHANGELOG.md` 记录变更
- [ ] 更新 `README.md` 中的版本号
- [ ] 本地测试 podspec: `pod spec lint --allow-warnings`
- [ ] 确保所有测试通过
- [ ] 在 main 分支上创建标签
- [ ] 版本号遵循语义化版本规范

### 版本管理建议

- **主版本** (1.0.0 → 2.0.0): 破坏性变更
- **次版本** (1.0.0 → 1.1.0): 新功能，向后兼容
- **修订版本** (1.0.0 → 1.0.1): Bug 修复，向后兼容

### 安全注意事项

- 定期轮换 CocoaPods Trunk token
- 限制对仓库 Secrets 的访问权限
- 监控发布活动和异常访问
