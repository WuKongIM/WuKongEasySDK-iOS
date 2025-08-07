#!/bin/bash

# WuKongEasySDK 发布脚本
# 用法: ./scripts/release.sh <version>
# 示例: ./scripts/release.sh 1.0.1

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查参数
if [ $# -eq 0 ]; then
    print_error "请提供版本号"
    echo "用法: $0 <version>"
    echo "示例: $0 1.0.1"
    exit 1
fi

VERSION=$1
TAG="v$VERSION"

print_info "准备发布 WuKongEasySDK $VERSION"

# 检查是否在 main 分支
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_error "必须在 main 分支上发布。当前分支: $CURRENT_BRANCH"
    exit 1
fi

print_success "确认在 main 分支"

# 检查工作目录是否干净
if [ -n "$(git status --porcelain)" ]; then
    print_error "工作目录不干净，请先提交或暂存所有更改"
    git status
    exit 1
fi

print_success "工作目录干净"

# 拉取最新代码
print_info "拉取最新代码..."
git pull origin main

# 检查标签是否已存在
if git tag -l | grep -q "^$TAG$"; then
    print_error "标签 $TAG 已存在"
    exit 1
fi

print_success "标签 $TAG 可用"

# 更新 podspec 版本
print_info "更新 podspec 版本..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/spec\.version.*=.*/spec.version = \"$VERSION\"/" WuKongEasySDK.podspec
else
    # Linux
    sed -i "s/spec\.version.*=.*/spec.version = \"$VERSION\"/" WuKongEasySDK.podspec
fi

# 验证版本更新
PODSPEC_VERSION=$(grep -E "^\s*spec\.version\s*=" WuKongEasySDK.podspec | sed -E 's/.*"([^"]+)".*/\1/')
if [ "$PODSPEC_VERSION" != "$VERSION" ]; then
    print_error "Podspec 版本更新失败。期望: $VERSION，实际: $PODSPEC_VERSION"
    exit 1
fi

print_success "Podspec 版本已更新为 $VERSION"

# 验证 podspec
print_info "验证 podspec..."
if ! pod spec lint WuKongEasySDK.podspec --allow-warnings --quick; then
    print_error "Podspec 验证失败"
    exit 1
fi

print_success "Podspec 验证通过"

# 更新 README（如果包含版本号）
if grep -q "pod 'WuKongEasySDK'" README.md; then
    print_info "更新 README 中的版本号..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/pod 'WuKongEasySDK'.*$/pod 'WuKongEasySDK', '~> $VERSION'/" README.md
    else
        sed -i "s/pod 'WuKongEasySDK'.*$/pod 'WuKongEasySDK', '~> $VERSION'/" README.md
    fi
    print_success "README 已更新"
fi

# 检查是否有 CHANGELOG.md
if [ -f "CHANGELOG.md" ]; then
    print_warning "请确保已更新 CHANGELOG.md 中的版本 $VERSION"
    read -p "是否已更新 CHANGELOG.md? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "请更新 CHANGELOG.md 后重新运行脚本"
        exit 1
    fi
fi

# 显示将要提交的更改
print_info "将要提交的更改:"
git diff --name-only

# 确认发布
echo
print_warning "即将发布版本 $VERSION"
echo "这将会:"
echo "1. 提交版本更新"
echo "2. 创建标签 $TAG"
echo "3. 推送到远程仓库"
echo "4. 触发自动发布到 CocoaPods"
echo
read -p "确认继续? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "发布已取消"
    exit 0
fi

# 提交版本更新
print_info "提交版本更新..."
git add WuKongEasySDK.podspec README.md CHANGELOG.md 2>/dev/null || true
git commit -m "bump version to $VERSION

- 更新 podspec 版本到 $VERSION
- 更新 README 安装说明
- 准备发布到 CocoaPods"

print_success "版本更新已提交"

# 推送到远程仓库
print_info "推送到远程仓库..."
git push origin main

print_success "代码已推送到远程仓库"

# 创建并推送标签
print_info "创建标签 $TAG..."
git tag -a "$TAG" -m "Release version $VERSION"

print_info "推送标签到远程仓库..."
git push origin "$TAG"

print_success "标签 $TAG 已推送到远程仓库"

# 发布完成
echo
print_success "🎉 发布流程已启动!"
echo
print_info "接下来的步骤:"
echo "1. 访问 GitHub Actions 查看发布进度:"
echo "   https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
echo
echo "2. 发布完成后，验证安装:"
echo "   pod search WuKongEasySDK"
echo "   pod spec cat WuKongEasySDK"
echo
echo "3. 检查 GitHub Release:"
echo "   https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases"
echo
print_info "发布通常需要 5-10 分钟完成"
