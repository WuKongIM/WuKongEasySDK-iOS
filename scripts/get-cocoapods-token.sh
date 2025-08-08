#!/bin/bash

# CocoaPods Token 获取脚本
# 用于帮助用户获取正确的 CocoaPods Trunk token

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔑 CocoaPods Trunk Token 获取工具"
echo "=================================="
echo

# 检查是否已安装 CocoaPods
if ! command -v pod &> /dev/null; then
    print_error "CocoaPods 未安装"
    echo "请先安装 CocoaPods: gem install cocoapods"
    exit 1
fi

print_success "CocoaPods 已安装"

# 检查 .netrc 文件是否存在
if [ ! -f ~/.netrc ]; then
    print_warning ".netrc 文件不存在"
    echo
    print_info "需要先注册 CocoaPods Trunk 账户"
    read -p "请输入您的邮箱地址: " email
    read -p "请输入您的姓名: " name

    echo
    print_info "正在注册 CocoaPods Trunk 账户..."
    pod trunk register "$email" "$name" --description="GitHub Actions Token"

    print_success "注册请求已发送"
    print_warning "请检查您的邮箱并点击确认链接"
    print_info "确认后重新运行此脚本"
    exit 0
fi

print_success ".netrc 文件存在"

# 检查是否有 CocoaPods Trunk 配置
if ! grep -q "machine trunk.cocoapods.org" ~/.netrc; then
    print_error ".netrc 文件中没有 CocoaPods Trunk 配置"
    echo
    print_info "需要注册 CocoaPods Trunk 账户"
    read -p "请输入您的邮箱地址: " email
    read -p "请输入您的姓名: " name

    echo
    print_info "正在注册 CocoaPods Trunk 账户..."
    pod trunk register "$email" "$name" --description="GitHub Actions Token"

    print_success "注册请求已发送"
    print_warning "请检查您的邮箱并点击确认链接"
    print_info "确认后重新运行此脚本"
    exit 0
fi

print_success "找到 CocoaPods Trunk 配置"

# 验证认证状态
print_info "验证 CocoaPods Trunk 认证状态..."
if ! pod trunk me &> /dev/null; then
    print_error "CocoaPods Trunk 认证失败"
    echo
    print_info "可能的原因："
    echo "1. Token 已过期"
    echo "2. 邮箱未验证"
    echo "3. 配置文件损坏"
    echo
    print_info "建议重新注册："
    read -p "请输入您的邮箱地址: " email
    read -p "请输入您的姓名: " name

    pod trunk register "$email" "$name" --description="GitHub Actions Token"
    print_warning "请检查邮箱并确认后重新运行此脚本"
    exit 1
fi

print_success "CocoaPods Trunk 认证成功"

# 提取 email 和 token
print_info "提取 CocoaPods Trunk 认证信息..."
EMAIL=$(grep -A2 "machine trunk.cocoapods.org" ~/.netrc | grep login | awk '{print $2}')
TOKEN=$(grep -A2 "machine trunk.cocoapods.org" ~/.netrc | grep password | awk '{print $2}')

if [ -z "$EMAIL" ] || [ -z "$TOKEN" ]; then
    print_error "无法从 .netrc 文件中提取认证信息"
    echo
    print_info "请检查 ~/.netrc 文件格式是否正确："
    echo "machine trunk.cocoapods.org"
    echo "  login your-email@example.com"
    echo "  password your-token-here"
    exit 1
fi

print_success "认证信息提取成功"

# 显示结果
echo
echo "🎉 CocoaPods Trunk 认证信息获取成功！"
echo "====================================="
echo
print_info "您的 CocoaPods Trunk 认证信息："
echo
echo "📋 复制以下信息到 GitHub Secrets 中："
echo
echo "Secret 1 - 邮箱地址:"
echo "名称: COCOAPODS_TRUNK_EMAIL"
echo "值: $EMAIL"
echo
echo "Secret 2 - Token:"
echo "名称: COCOAPODS_TRUNK_TOKEN"
echo "值:"
echo "----------------------------------------"
echo "$TOKEN"
echo "----------------------------------------"
echo
print_warning "请妥善保管这些信息，不要泄露给他人"
echo
print_info "设置 GitHub Secrets 的步骤："
echo "1. 访问 GitHub 仓库"
echo "2. 进入 Settings > Secrets and variables > Actions"
echo "3. 点击 'New repository secret'"
echo "4. 添加第一个 Secret:"
echo "   - 名称: COCOAPODS_TRUNK_EMAIL"
echo "   - 值: $EMAIL"
echo "5. 点击 'Add secret'"
echo "6. 再次点击 'New repository secret'"
echo "7. 添加第二个 Secret:"
echo "   - 名称: COCOAPODS_TRUNK_TOKEN"
echo "   - 值: 上面显示的 token"
echo "8. 点击 'Add secret'"
echo
print_success "设置完成后即可使用自动发布功能！"