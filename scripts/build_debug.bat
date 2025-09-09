@echo off
REM Mini Feed App - Debug Build Script (Windows)
REM This script builds a debug APK for testing purposes

echo 🚀 Starting Mini Feed App debug build...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    exit /b 1
)

REM Show Flutter version
echo 📋 Flutter version:
flutter --version

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get

REM Generate code (if needed)
echo 🔧 Generating code...
findstr /C:"build_runner" pubspec.yaml >nul 2>&1
if %errorlevel% equ 0 (
    flutter packages pub run build_runner build --delete-conflicting-outputs
)

REM Run tests
echo 🧪 Running tests...
flutter test

REM Build debug APK
echo 🔨 Building debug APK...
flutter build apk --debug

REM Check if build was successful
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ✅ Debug APK built successfully!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-debug.apk
    
    REM Create output directory if it doesn't exist
    if not exist "outputs" mkdir outputs
    
    REM Copy APK to outputs directory with timestamp
    for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
    set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
    set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
    set "timestamp=%YYYY%%MM%%DD%_%HH%%Min%%Sec%"
    
    copy "build\app\outputs\flutter-apk\app-debug.apk" "outputs\mini_feed_debug_%timestamp%.apk"
    echo 📋 APK copied to: outputs\mini_feed_debug_%timestamp%.apk
    
) else (
    echo ❌ Build failed!
    exit /b 1
)

echo 🎉 Build completed successfully!
pause