# GigiTime Emulator Fix Script
# This script helps fix frozen or unresponsive emulators

Write-Host "GigiTime Emulator Fix Script" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Find ADB
$adbPath = $null
$androidHome = $env:ANDROID_HOME
$androidSdkRoot = $env:ANDROID_SDK_ROOT

if ($androidHome) {
    $adbPath = Join-Path $androidHome "platform-tools\adb.exe"
    if (-not (Test-Path $adbPath)) {
        $adbPath = $null
    }
}

if (-not $adbPath -and $androidSdkRoot) {
    $adbPath = Join-Path $androidSdkRoot "platform-tools\adb.exe"
    if (-not (Test-Path $adbPath)) {
        $adbPath = $null
    }
}

if (-not $adbPath) {
    $commonPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:PROGRAMFILES\Android\Android Studio\platform-tools\adb.exe",
        "$env:PROGRAMFILES(X86)\Android\Android Studio\platform-tools\adb.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $adbPath = $path
            break
        }
    }
}

if (-not $adbPath) {
    Write-Host "ADB not found! Please check your Android SDK installation." -ForegroundColor Red
    exit 1
}

Write-Host "Using ADB at: $adbPath" -ForegroundColor Green

# Step 1: Kill all emulator processes
Write-Host "`n1. Killing all emulator processes..." -ForegroundColor Yellow
try {
    Get-Process -Name "emulator*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "qemu*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "   Emulator processes killed" -ForegroundColor Green
} catch {
    Write-Host "   No emulator processes found or already stopped" -ForegroundColor Yellow
}

# Step 2: Restart ADB
Write-Host "`n2. Restarting ADB server..." -ForegroundColor Yellow
& $adbPath kill-server
Start-Sleep -Seconds 3
& $adbPath start-server
Start-Sleep -Seconds 3
Write-Host "   ADB server restarted" -ForegroundColor Green

# Step 3: Check for any remaining devices
Write-Host "`n3. Checking for remaining devices..." -ForegroundColor Yellow
$devices = & $adbPath devices
Write-Host $devices

# Step 4: Find emulator executable
Write-Host "`n4. Finding emulator executable..." -ForegroundColor Yellow
$emulatorPath = $null
if ($androidHome) {
    $emulatorPath = Join-Path $androidHome "emulator\emulator.exe"
    if (-not (Test-Path $emulatorPath)) {
        $emulatorPath = $null
    }
}

if (-not $emulatorPath) {
    $commonPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe",
        "$env:PROGRAMFILES\Android\Android Studio\emulator\emulator.exe",
        "$env:PROGRAMFILES(X86)\Android\Android Studio\emulator\emulator.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $emulatorPath = $path
            break
        }
    }
}

if (-not $emulatorPath) {
    Write-Host "   Emulator not found! Please check your Android SDK installation." -ForegroundColor Red
    exit 1
}

Write-Host "   Emulator found at: $emulatorPath" -ForegroundColor Green

# Step 5: List available AVDs
Write-Host "`n5. Listing available AVDs..." -ForegroundColor Yellow
$avdList = & $emulatorPath -list-avds
if (-not $avdList) {
    Write-Host "   No AVDs found! Please create one in Android Studio first." -ForegroundColor Red
    exit 1
}

Write-Host "   Available AVDs:" -ForegroundColor Cyan
foreach ($avd in $avdList) {
    Write-Host "   - $avd" -ForegroundColor White
}

# Step 6: Start emulator with better settings
Write-Host "`n6. Starting emulator with optimized settings..." -ForegroundColor Yellow
$firstAvd = $avdList[0]
Write-Host "   Starting: $firstAvd" -ForegroundColor Cyan

# Use better emulator settings to prevent freezing
$emulatorArgs = @(
    "-avd", $firstAvd,
    "-no-snapshot-load",  # Don't load snapshots (prevents some freezing issues)
    "-no-snapshot-save",  # Don't save snapshots
    "-wipe-data",         # Start fresh
    "-no-boot-anim",      # Skip boot animation for faster startup
    "-gpu", "swiftshader_indirect",  # Use software rendering (more stable)
    "-memory", "2048",     # Limit memory usage
    "-cores", "2"          # Limit CPU cores
)

Write-Host "   Starting emulator with fresh data (this may take longer but should be more stable)..." -ForegroundColor Yellow

try {
    Start-Process -FilePath $emulatorPath -ArgumentList $emulatorArgs -NoNewWindow
    Write-Host "   Emulator started with fresh settings!" -ForegroundColor Green
    
    # Wait for emulator to be ready
    Write-Host "`n7. Waiting for emulator to be ready..." -ForegroundColor Yellow
    $maxWaitTime = 300 # 5 minutes
    $waitTime = 0
    $emulatorReady = $false
    
    while ($waitTime -lt $maxWaitTime -and -not $emulatorReady) {
        Start-Sleep -Seconds 10
        $waitTime += 10
        
        try {
            $devices = & $adbPath devices 2>&1
            $emulatorReady = $devices -match "emulator.*device" -and $devices -notmatch "List of devices"
            
            if ($emulatorReady) {
                $deviceId = ($devices | Select-String "emulator.*device").Line.Split()[0]
                $bootComplete = & $adbPath -s $deviceId shell getprop sys.boot_completed 2>&1
                if ($bootComplete -eq "1") {
                    Write-Host "   Emulator is ready and responsive!" -ForegroundColor Green
                    Write-Host "   Device ID: $deviceId" -ForegroundColor Cyan
                } else {
                    $emulatorReady = $false
                }
            }
        } catch {
            $emulatorReady = $false
        }
        
        if (-not $emulatorReady) {
            Write-Host "   Still waiting... ($waitTime seconds)" -ForegroundColor Yellow
        }
    }
    
    if ($emulatorReady) {
        Write-Host "`nEmulator is ready! You can now:" -ForegroundColor Green
        Write-Host "1. Run .\scripts\update-android.ps1 to install your app" -ForegroundColor White
        Write-Host "2. The emulator should now respond to mouse clicks" -ForegroundColor White
        Write-Host "3. Look for your app in the app drawer or home screen" -ForegroundColor White
    } else {
        Write-Host "`nEmulator took too long to start. Try these alternatives:" -ForegroundColor Yellow
        Write-Host "1. Open Android Studio and start the emulator from there" -ForegroundColor White
        Write-Host "2. Try a different AVD (create a new one in Android Studio)" -ForegroundColor White
        Write-Host "3. Check if your computer has enough RAM (emulator needs 2-4GB)" -ForegroundColor White
    }
    
} catch {
    Write-Host "   Failed to start emulator: $_" -ForegroundColor Red
    Write-Host "   Please try starting the emulator manually from Android Studio." -ForegroundColor Yellow
}

Write-Host "`nTroubleshooting tips:" -ForegroundColor Cyan
Write-Host "- If emulator is still frozen, try restarting your computer" -ForegroundColor White
Write-Host "- Make sure you have at least 8GB RAM available" -ForegroundColor White
Write-Host "- Try creating a new AVD with different settings in Android Studio" -ForegroundColor White
Write-Host "- Check Windows Hyper-V settings if you have virtualization issues" -ForegroundColor White
