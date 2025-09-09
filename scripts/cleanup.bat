@echo off
REM Mini Feed App - Code Cleanup Script (Windows)
REM This script performs various cleanup operations

echo 🧹 Starting code cleanup...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    exit /b 1
)

REM Clean build artifacts
echo 🗑️  Cleaning build artifacts...
flutter clean

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get

REM Format code
echo ✨ Formatting code...
dart format .

REM Run analyzer
echo 🔍 Running analyzer...
flutter analyze --no-fatal-infos > analysis_results.txt 2>&1

REM Show some analysis results
echo 📊 Analysis complete. Check analysis_results.txt for details.

REM Run tests
echo 🧪 Running tests...
flutter test --reporter=compact

REM Generate code if needed
echo 🔧 Generating code...
findstr /C:"build_runner" pubspec.yaml >nul 2>&1
if %errorlevel% equ 0 (
    flutter packages pub run build_runner build --delete-conflicting-outputs
)

echo ✅ Cleanup completed!
echo 📋 Check analysis_results.txt for detailed analysis results
pause