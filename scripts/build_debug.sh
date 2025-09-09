#!/bin/bash

# Mini Feed App - Debug Build Script
# This script builds a debug APK for testing purposes

set -e  # Exit on any error

echo "🚀 Starting Mini Feed App debug build..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Check Flutter version
echo "📋 Flutter version:"
flutter --version

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code (if needed)
echo "🔧 Generating code..."
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Run tests
echo "🧪 Running tests..."
flutter test

# Build debug APK
echo "🔨 Building debug APK..."
flutter build apk --debug

# Check if build was successful
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "✅ Debug APK built successfully!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-debug.apk"
    
    # Get APK size
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo "📏 APK size: $APK_SIZE"
    
    # Create output directory if it doesn't exist
    mkdir -p outputs
    
    # Copy APK to outputs directory with timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    cp build/app/outputs/flutter-apk/app-debug.apk "outputs/mini_feed_debug_$TIMESTAMP.apk"
    echo "📋 APK copied to: outputs/mini_feed_debug_$TIMESTAMP.apk"
    
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🎉 Build completed successfully!"