#!/bin/bash

# Mini Feed App - Code Cleanup Script
# This script performs various cleanup operations

set -e  # Exit on any error

echo "🧹 Starting code cleanup..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Clean build artifacts
echo "🗑️  Cleaning build artifacts..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Format code
echo "✨ Formatting code..."
dart format .

# Run analyzer
echo "🔍 Running analyzer..."
flutter analyze --no-fatal-infos > analysis_results.txt 2>&1

# Count issues
ISSUES=$(grep -c "issues found" analysis_results.txt || echo "0")
echo "📊 Analysis complete. Issues found: $ISSUES"

# Show warnings and errors only
echo "⚠️  Warnings and errors:"
grep -E "(warning|error)" analysis_results.txt | head -20 || echo "No warnings or errors in first 20 lines"

# Run tests
echo "🧪 Running tests..."
flutter test --reporter=compact

# Generate code if needed
echo "🔧 Generating code..."
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Check for unused files
echo "📁 Checking for potential unused files..."
find lib -name "*.dart" -type f | while read file; do
    filename=$(basename "$file" .dart)
    # Simple check - this could be improved
    if ! grep -r "$filename" lib --include="*.dart" -q; then
        echo "Potentially unused file: $file"
    fi
done

echo "✅ Cleanup completed!"
echo "📋 Check analysis_results.txt for detailed analysis results"