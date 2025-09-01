# GigiTime Android Build Script
# This script automates the build and sync process for Android development

Write-Host "GigiTime Android Build Script" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Host "Error: package.json not found. Please run this script from the GigiTime project root." -ForegroundColor Red
    exit 1
}

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Clean previous build
Write-Host "Cleaning previous build..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
    Write-Host "   Previous build removed" -ForegroundColor Green
}

# Build the React app
Write-Host "Building React app..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "   React app built successfully" -ForegroundColor Green

# Check if build was successful
if (-not (Test-Path "build\index.html")) {
    Write-Host "Build output is missing index.html" -ForegroundColor Red
    exit 1
}

# Sync with Capacitor
Write-Host "Syncing with Android..." -ForegroundColor Yellow
npx cap sync android
if ($LASTEXITCODE -ne 0) {
    Write-Host "Capacitor sync failed" -ForegroundColor Red
    exit 1
}
Write-Host "   Android project synced successfully" -ForegroundColor Green

# Build APK from command line
Write-Host "Building APK from command line..." -ForegroundColor Yellow
Set-Location "android"
.\gradlew assembleDebug
if ($LASTEXITCODE -ne 0) {
    Write-Host "APK build failed" -ForegroundColor Red
    Set-Location ".."
    exit 1
}
Write-Host "   APK built successfully" -ForegroundColor Green

# Go back to root directory
Set-Location ".."

# Check if APK was created
$apkPath = "android\app\build\outputs\apk\debug\app-debug.apk"
$finalApkPath = "build\gigi-time.apk"

if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length / 1MB
    
    # Rename the APK to gigi-time.apk in the build folder
    Write-Host "Moving APK to build folder as gigi-time.apk..." -ForegroundColor Yellow
    if (Test-Path $finalApkPath) {
        Remove-Item $finalApkPath -Force
    }
    Copy-Item $apkPath $finalApkPath
    Write-Host "   APK moved successfully" -ForegroundColor Green
    
    Write-Host "   Original APK: $apkPath" -ForegroundColor Green
    Write-Host "   Final APK: $finalApkPath" -ForegroundColor Green
    Write-Host "   APK size: $([math]::Round($apkSize, 1)) MB" -ForegroundColor Green
} else {
    Write-Host "APK not found at expected location" -ForegroundColor Red
}

# Open Android Studio
Write-Host "Opening Android Studio..." -ForegroundColor Yellow
npx cap open android
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to open Android Studio" -ForegroundColor Red
    exit 1
}
Write-Host "   Android Studio opened" -ForegroundColor Green

Write-Host ""
Write-Host "Build and sync completed successfully!" -ForegroundColor Green
Write-Host "Your Android app is ready to run in Android Studio" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. In Android Studio, click the 'Run' button (green play icon)" -ForegroundColor White
Write-Host "2. Select your emulator or connected device" -ForegroundColor White
Write-Host "3. Test the updated app!" -ForegroundColor White
Write-Host ""
Write-Host "For faster updates:" -ForegroundColor Cyan
Write-Host "   - Use 'npx cap run android' to build and run directly" -ForegroundColor White
Write-Host "   - Or use 'npx cap build android' then 'npx cap run android'" -ForegroundColor White
Write-Host "   - This will automatically rebuild and reinstall the APK in your emulator" -ForegroundColor White
Write-Host ""
Write-Host "APK Location:" -ForegroundColor Cyan
Write-Host "   - Debug APK: $finalApkPath" -ForegroundColor White
Write-Host "   - Copy this APK to your device to install manually" -ForegroundColor White
