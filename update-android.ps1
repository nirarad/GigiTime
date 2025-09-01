# GigiTime Android Update Script
# This script updates the running app in the emulator without opening Android Studio

Write-Host "🎵 GigiTime Android Update Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "❌ Error: package.json not found. Please run this script from the GigiTime project root." -ForegroundColor Red
    exit 1
}

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Clean previous build
Write-Host "🧹 Cleaning previous build..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
    Write-Host "   ✓ Previous build removed" -ForegroundColor Green
}

# Build the React app
Write-Host "🔨 Building React app..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ React app built successfully" -ForegroundColor Green

# Check if build was successful
if (-not (Test-Path "build\index.html")) {
    Write-Host "❌ Build output is missing index.html" -ForegroundColor Red
    exit 1
}

# Sync with Capacitor
Write-Host "📱 Syncing with Android..." -ForegroundColor Yellow
npx cap sync android
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Capacitor sync failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Android project synced successfully" -ForegroundColor Green

# Build and run directly on Android
Write-Host "🚀 Building and running on Android..." -ForegroundColor Yellow
Write-Host "   This will rebuild the APK and reinstall it in your emulator" -ForegroundColor Cyan

npx cap run android
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to run on Android" -ForegroundColor Red
    Write-Host "💡 Make sure you have an emulator running or device connected" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🎉 App updated successfully!" -ForegroundColor Green
Write-Host "📱 The new version is now running in your emulator" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor White
Write-Host "   - Keep your emulator running between updates for faster builds" -ForegroundColor White
Write-Host "   - Use this script whenever you make changes to see them immediately" -ForegroundColor White
Write-Host "   - If you need to open Android Studio, use 'build-android.ps1' instead" -ForegroundColor White
