#!/bin/bash

# WuKongIM Example Build Script
# This script builds and optionally runs the WuKongIM example app

set -e

echo "🚀 WuKongIM Example Build Script"
echo "================================"

# Function to show usage
show_usage() {
    echo "Usage: $0 [ios|macos] [--run]"
    echo ""
    echo "Options:"
    echo "  ios     Build for iOS Simulator"
    echo "  macos   Build for macOS"
    echo "  --run   Run the app after building (macOS only)"
    echo ""
    echo "Examples:"
    echo "  $0 ios              # Build iOS version"
    echo "  $0 macos            # Build macOS version"
    echo "  $0 macos --run      # Build and run macOS version"
    exit 1
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
fi

PLATFORM=$1
RUN_APP=false

if [ "$2" = "--run" ]; then
    RUN_APP=true
fi

case $PLATFORM in
    ios)
        echo "📱 Building for iOS Simulator..."
        xcodebuild -project WuKongIMExample.xcodeproj \
                   -scheme WuKongIMExample-iOS \
                   -destination 'platform=iOS Simulator,name=iPhone 16' \
                   build
        
        if [ $? -eq 0 ]; then
            echo "✅ iOS build successful!"
            echo ""
            echo "To run in simulator:"
            echo "  xcrun simctl boot 'iPhone 16'"
            echo "  xcrun simctl install booted \"\$(xcodebuild -project WuKongIMExample.xcodeproj -scheme WuKongIMExample-iOS -destination 'platform=iOS Simulator,name=iPhone 16' -showBuildSettings | grep BUILT_PRODUCTS_DIR | head -1 | sed 's/.*= //')/WuKongIMExample-iOS.app\""
            echo "  xcrun simctl launch booted com.wukongim.example.ios"
        else
            echo "❌ iOS build failed!"
            exit 1
        fi
        ;;
    
    macos)
        echo "💻 Building for macOS..."
        xcodebuild -project WuKongIMExample.xcodeproj \
                   -scheme WuKongIMExample-macOS \
                   build
        
        if [ $? -eq 0 ]; then
            echo "✅ macOS build successful!"
            
            if [ "$RUN_APP" = true ]; then
                echo "🎯 Running macOS app..."
                APP_PATH=$(xcodebuild -project WuKongIMExample.xcodeproj -scheme WuKongIMExample-macOS -showBuildSettings | grep BUILT_PRODUCTS_DIR | head -1 | sed 's/.*= //')/WuKongIMExample-macOS.app
                open "$APP_PATH"
                echo "📱 App launched!"
            else
                echo ""
                echo "To run the app:"
                APP_PATH=$(xcodebuild -project WuKongIMExample.xcodeproj -scheme WuKongIMExample-macOS -showBuildSettings | grep BUILT_PRODUCTS_DIR | head -1 | sed 's/.*= //')/WuKongIMExample-macOS.app
                echo "  open \"$APP_PATH\""
            fi
        else
            echo "❌ macOS build failed!"
            exit 1
        fi
        ;;
    
    *)
        echo "❌ Unknown platform: $PLATFORM"
        show_usage
        ;;
esac

echo ""
echo "🎉 Done!"
