# GigiTime Android Update Script
# This script updates the running app in the emulator without opening Android Studio

Write-Host "GigiTime Android Update Script" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Note: For emulator issues (black screen, freezing), use .\scripts\fix-emulator.ps1 first" -ForegroundColor Yellow

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

# Check emulator status before attempting to run
Write-Host "Checking emulator status..." -ForegroundColor Yellow

# Find ADB path
$adbPath = $null
$androidHome = $env:ANDROID_HOME
if (-not $androidHome) {
    $androidHome = $env:ANDROID_SDK_ROOT
}

if ($androidHome) {
    $adbPath = Join-Path $androidHome "platform-tools\adb.exe"
    if (-not (Test-Path $adbPath)) {
        $adbPath = $null
    }
}

# Try to find ADB in common locations if not found
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
    Write-Host "   ADB not found. Please ensure Android SDK is installed and ANDROID_HOME is set." -ForegroundColor Red
    Write-Host "   You can also manually install the APK from: $apkPath" -ForegroundColor Yellow
    exit 0
}

Write-Host "   Using ADB at: $adbPath" -ForegroundColor Green

# List available devices
Write-Host "   Checking for available devices..." -ForegroundColor Cyan
$devices = & $adbPath devices
Write-Host "   Available devices:" -ForegroundColor Cyan
Write-Host $devices -ForegroundColor White

# Check if any emulator is running and online
$emulatorOnline = $devices -match "emulator.*device$" -and $devices -notmatch "List of devices"
$emulatorOffline = $devices -match "emulator.*offline" -and $devices -notmatch "List of devices"

if ($emulatorOnline) {
    Write-Host "   Online emulator detected. Using existing emulator." -ForegroundColor Green
} elseif ($emulatorOffline) {
    Write-Host "   Emulator detected but offline. Restarting ADB to fix connection..." -ForegroundColor Yellow
    & $adbPath kill-server
    Start-Sleep -Seconds 2
    & $adbPath start-server
    Start-Sleep -Seconds 2
    
    # Check again after ADB restart
    $devices = & $adbPath devices
    $emulatorOnline = $devices -match "emulator.*device$" -and $devices -notmatch "List of devices"
    if ($emulatorOnline) {
        Write-Host "   ADB restart successful. Emulator is now online." -ForegroundColor Green
    } else {
        Write-Host "   Emulator still offline after ADB restart." -ForegroundColor Red
        Write-Host "   Please use .\scripts\fix-emulator.ps1 to restart the emulator, or start one manually." -ForegroundColor Yellow
        Write-Host "   Available devices:" -ForegroundColor Cyan
        Write-Host $devices -ForegroundColor White
        exit 1
    }
} else {
    Write-Host "   No emulator detected." -ForegroundColor Red
    Write-Host "   Please start an emulator first using:" -ForegroundColor Yellow
    Write-Host "   - .\scripts\fix-emulator.ps1 (for clean restart)" -ForegroundColor Cyan
    Write-Host "   - .\scripts\start-emulator.ps1 (for normal startup)" -ForegroundColor Cyan
    Write-Host "   - Android Studio (manual)" -ForegroundColor Cyan
    exit 1
}

# Build and run directly on Android
Write-Host "Building and running on Android..." -ForegroundColor Yellow
Write-Host "   This will rebuild the APK and reinstall it in your emulator" -ForegroundColor Cyan

# Try to run on Android, but don't wait indefinitely
Write-Host "   Starting Android build and run process..." -ForegroundColor Cyan
Write-Host "   If it gets stuck, press Ctrl+C to cancel and install manually" -ForegroundColor Yellow

try {
    # Get list of available devices
    Write-Host "   Checking available devices..." -ForegroundColor Yellow
    $devices = & $adbPath devices
    Write-Host "   Available devices:" -ForegroundColor Cyan
    Write-Host $devices
    
    $deviceList = $devices | Where-Object { $_ -match "emulator.*device$" -and $_ -notmatch "List of devices" }
    
    Write-Host "   Debug: Found device lines:" -ForegroundColor Magenta
    Write-Host $deviceList -ForegroundColor Magenta
    Write-Host "   Debug: Device list count: $($deviceList.Count)" -ForegroundColor Magenta
    Write-Host "   Debug: Device list type: $($deviceList.GetType().Name)" -ForegroundColor Magenta
    
    if (-not $deviceList) {
        Write-Host "   No online emulator devices found!" -ForegroundColor Red
        Write-Host "   Raw device output:" -ForegroundColor Yellow
        Write-Host $devices -ForegroundColor White
        Write-Host "   Please make sure an emulator is running and online" -ForegroundColor Yellow
        Write-Host "   You can try:" -ForegroundColor Cyan
        Write-Host "   - Use .\scripts\fix-emulator.ps1 to restart the emulator" -ForegroundColor Cyan
        Write-Host "   - Restart the emulator manually in Android Studio" -ForegroundColor Cyan
        exit 1
    }
    
    # Get the first device ID - parse more carefully
    Write-Host "   Debug: About to parse device list..." -ForegroundColor Magenta
    Write-Host "   Debug: Device list content: '$deviceList'" -ForegroundColor Magenta
    
    # Handle both string and array cases
    if ($deviceList -is [string]) {
        Write-Host "   Debug: Device list is a string, using directly" -ForegroundColor Magenta
        $deviceLine = $deviceList.Trim()
    } else {
        Write-Host "   Debug: Device list is an array, using first element" -ForegroundColor Magenta
        $deviceLine = $deviceList[0].Trim()
    }
    
    Write-Host "   Debug: Device line to parse: '$deviceLine'" -ForegroundColor Magenta
    
    # Split by whitespace and get the first non-empty part
    $deviceParts = $deviceLine -split '\s+' | Where-Object { $_ -ne '' }
    Write-Host "   Debug: Device parts: $($deviceParts -join ', ')" -ForegroundColor Magenta
    $adbDeviceId = $deviceParts[0]
    Write-Host "   Debug: Extracted device ID: '$adbDeviceId'" -ForegroundColor Magenta
    
    # Try to find the AVD name by checking running emulator processes
    Write-Host "   Detecting AVD name for device: $adbDeviceId" -ForegroundColor Yellow
    $capacitorTarget = $null
    Write-Host "   Debug: Starting AVD detection process..." -ForegroundColor Magenta
    
    # Try to get AVD name from emulator process
    try {
        Write-Host "   Debug: Looking for emulator processes..." -ForegroundColor Magenta
        $emulatorProcesses = Get-Process -Name "qemu-system-x86_64", "emulator", "emulator64-x86", "emulator-x86" -ErrorAction SilentlyContinue
        Write-Host "   Debug: Found $($emulatorProcesses.Count) emulator processes" -ForegroundColor Magenta
        
        if ($emulatorProcesses) {
            # Look for AVD name in process command line
            foreach ($process in $emulatorProcesses) {
                try {
                    Write-Host "   Debug: Checking process $($process.Id) ($($process.ProcessName))" -ForegroundColor Magenta
                    $commandLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
                    Write-Host "   Debug: Command line: $commandLine" -ForegroundColor Magenta
                    if ($commandLine -match "-avd\s+(\w+)") {
                        $capacitorTarget = $matches[1]
                        Write-Host "   Found AVD name: $capacitorTarget" -ForegroundColor Green
                        break
                    }
                } catch {
                    Write-Host "   Debug: Error getting command line for process $($process.Id): $_" -ForegroundColor Magenta
                }
            }
        }
    } catch {
        Write-Host "   Debug: Error getting emulator processes: $_" -ForegroundColor Magenta
    }
    
    # Fallback: try to use device ID as target (might work for some setups)
    if (-not $capacitorTarget) {
        $capacitorTarget = $adbDeviceId
        Write-Host "   Using device ID as target: $capacitorTarget" -ForegroundColor Yellow
    }
    
    Write-Host "   Debug: Final capacitor target: $capacitorTarget" -ForegroundColor Magenta
    
    Write-Host "   Using detected device: $adbDeviceId" -ForegroundColor Green
    Write-Host "   Debug: About to start Capacitor run process..." -ForegroundColor Magenta
    
    # Run with automatic device selection
    Write-Host "   Running Capacitor with target: $capacitorTarget" -ForegroundColor Cyan
    Write-Host "   Debug: About to run: npx cap run android --target $capacitorTarget" -ForegroundColor Magenta
    Write-Host "   Debug: Starting background job..." -ForegroundColor Magenta
    
    # Try Capacitor run with timeout
    try {
        Write-Host "   Debug: Creating background job..." -ForegroundColor Magenta
        $job = Start-Job -ScriptBlock { 
            param($target)
            Set-Location $using:PWD
            npx cap run android --target $target
        } -ArgumentList $capacitorTarget
        Write-Host "   Debug: Job created with ID: $($job.Id)" -ForegroundColor Magenta
        
        # Wait for job with timeout (60 seconds)
        $timeout = 60
        Write-Host "   Debug: Waiting for job completion (timeout: $timeout seconds)..." -ForegroundColor Magenta
        $completed = Wait-Job -Job $job -Timeout $timeout
        Write-Host "   Debug: Job wait completed. Result: $completed" -ForegroundColor Magenta
        
        if ($completed) {
            Write-Host "   Debug: Job completed, receiving results..." -ForegroundColor Magenta
            $result = Receive-Job -Job $job
            Write-Host "   Debug: Job state: $((Get-Job -Id $job.Id).State)" -ForegroundColor Magenta
            if ((Get-Job -Id $job.Id).State -eq "Completed") {
                $exitCode = 0
                Write-Host "   Debug: Job completed successfully" -ForegroundColor Magenta
            } else {
                $exitCode = 1
                Write-Host "   Debug: Job failed" -ForegroundColor Magenta
            }
            Write-Host "   Debug: Capacitor command completed with exit code: $exitCode" -ForegroundColor Magenta
            Write-Host "   Debug: Command output:" -ForegroundColor Magenta
            Write-Host $result -ForegroundColor White
        } else {
            Write-Host "   Debug: Capacitor command timed out after $timeout seconds" -ForegroundColor Magenta
            Stop-Job -Job $job
            $exitCode = 1
        }
        
        Write-Host "   Debug: Cleaning up job..." -ForegroundColor Magenta
        Remove-Job -Job $job
        $LASTEXITCODE = $exitCode
        Write-Host "   Debug: Final exit code set to: $LASTEXITCODE" -ForegroundColor Magenta
    } catch {
        Write-Host "   Debug: Error running Capacitor command: $_" -ForegroundColor Magenta
        $LASTEXITCODE = 1
    }
    Write-Host "   Debug: Checking Capacitor exit code: $LASTEXITCODE" -ForegroundColor Magenta
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Capacitor run failed. Trying direct APK installation..." -ForegroundColor Yellow
        Write-Host "   Debug: Starting fallback APK installation..." -ForegroundColor Magenta
        
        # Fallback: Install APK directly using ADB
        $finalApkPath = "build\gigi-time.apk"
        Write-Host "   Debug: Checking for APK at: $finalApkPath" -ForegroundColor Magenta
        if (Test-Path $finalApkPath) {
            Write-Host "   Installing APK directly: $finalApkPath" -ForegroundColor Cyan
            Write-Host "   Debug: Running: $adbPath -s $adbDeviceId install -r $finalApkPath" -ForegroundColor Magenta
            $installResult = & $adbPath -s $adbDeviceId install -r $finalApkPath 2>&1
            Write-Host "   Debug: APK install exit code: $LASTEXITCODE" -ForegroundColor Magenta
            Write-Host "   Debug: APK install output: $installResult" -ForegroundColor Magenta
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   APK installed successfully!" -ForegroundColor Green
                
                # Try to launch the app
                $packageName = "com.gigitime.app"
                Write-Host "   Launching app..." -ForegroundColor Cyan
                Write-Host "   Debug: Running: $adbPath -s $adbDeviceId shell am start -n $packageName/.MainActivity" -ForegroundColor Magenta
                $launchResult = & $adbPath -s $adbDeviceId shell am start -n "$packageName/.MainActivity" 2>&1
                Write-Host "   Debug: App launch exit code: $LASTEXITCODE" -ForegroundColor Magenta
                Write-Host "   Debug: App launch output: $launchResult" -ForegroundColor Magenta
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   App launched successfully!" -ForegroundColor Green
                } else {
                    Write-Host "   App installed but couldn't launch automatically. Look for 'GigiTime' in the emulator." -ForegroundColor Yellow
                }
            } else {
                Write-Host "   Direct APK installation also failed: $installResult" -ForegroundColor Red
                Write-Host "   You can manually install the APK from: $finalApkPath" -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host "   APK not found at: $finalApkPath" -ForegroundColor Red
            Write-Host "   You can manually install the APK from: $apkPath" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "   Debug: Capacitor run succeeded!" -ForegroundColor Magenta
    }
    
    Write-Host ""
    Write-Host "App deployed successfully!" -ForegroundColor Green
    
    # Launch the app explicitly
    Write-Host "Launching app on emulator..." -ForegroundColor Cyan
    $packageName = "com.gigitime.app"
    
    # Wait a moment for the app to be fully installed
    Start-Sleep -Seconds 5
    
    # Use the same device that was selected for deployment
    Write-Host "   Using device: $adbDeviceId" -ForegroundColor Green
    
    # Check if app is installed
    Write-Host "   Checking if app is installed..." -ForegroundColor Yellow
    $installedApps = & $adbPath -s $adbDeviceId shell pm list packages | Select-String $packageName
    if (-not $installedApps) {
        Write-Host "   App is not installed! Trying to install..." -ForegroundColor Yellow
        
        # Wait a bit more for package manager to be fully ready
        Write-Host "   Waiting for package manager to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Verify package manager is working
        $pmTest = & $adbPath -s $adbDeviceId shell pm list packages 2>&1
        if ($LASTEXITCODE -ne 0 -or $pmTest -match "error|failed|unknown") {
            Write-Host "   Package manager not ready. Waiting longer..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            
            # Try again
            $pmTest2 = & $adbPath -s $adbDeviceId shell pm list packages 2>&1
            if ($LASTEXITCODE -ne 0 -or $pmTest2 -match "error|failed|unknown") {
                Write-Host "   Package manager still not ready. Please restart the emulator." -ForegroundColor Red
                Write-Host "   You can install the APK manually: $apkPath" -ForegroundColor Yellow
                exit 1
            }
        }
        
        # Use the final APK path (the one that was moved to build folder)
        $finalApkPath = "build\gigi-time.apk"
        if (Test-Path $finalApkPath) {
            Write-Host "   Installing APK from: $finalApkPath" -ForegroundColor Yellow
            $installResult = & $adbPath -s $adbDeviceId install -r $finalApkPath 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "   Installation failed: $installResult" -ForegroundColor Red
                Write-Host "   Trying alternative installation method..." -ForegroundColor Yellow
                
                # Try installing with different flags
                $installResult2 = & $adbPath -s $adbDeviceId install -r -d $finalApkPath 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "   Alternative installation also failed: $installResult2" -ForegroundColor Red
                    Write-Host "   Please install manually: $finalApkPath" -ForegroundColor Yellow
                    exit 1
                } else {
                    Write-Host "   App installed successfully with alternative method!" -ForegroundColor Green
                }
            } else {
                Write-Host "   App installed successfully!" -ForegroundColor Green
            }
        } else {
            Write-Host "   APK not found at: $finalApkPath" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "   App is already installed" -ForegroundColor Green
    }
    
    # Try to launch the app using the main activity
    Write-Host "   Attempting to launch app..." -ForegroundColor Yellow
    $launchResult = & $adbPath -s $adbDeviceId shell am start -n "$packageName/.MainActivity" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "App launched successfully!" -ForegroundColor Green
    } else {
        Write-Host "   Main activity launch failed, trying package launch..." -ForegroundColor Yellow
        # Alternative: launch by package name only
        $launchResult2 = & $adbPath -s $adbDeviceId shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "App launched successfully using package launch!" -ForegroundColor Green
        } else {
            Write-Host "   Package launch failed, trying intent launch..." -ForegroundColor Yellow
            # Another alternative: use intent to launch
            $launchResult3 = & $adbPath -s $adbDeviceId shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n "$packageName/.MainActivity" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "App launched successfully using intent launch!" -ForegroundColor Green
            } else {
                Write-Host "Could not launch app automatically. You can launch it manually from the emulator." -ForegroundColor Yellow
                Write-Host "Look for 'GigiTime' in the app drawer or home screen." -ForegroundColor Cyan
                Write-Host "Debug info:" -ForegroundColor Yellow
                Write-Host "   Main activity result: $launchResult" -ForegroundColor White
                Write-Host "   Package launch result: $launchResult2" -ForegroundColor White
                Write-Host "   Intent launch result: $launchResult3" -ForegroundColor White
            }
        }
    }
    
    Write-Host "The new version is now available in your emulator" -ForegroundColor Cyan
} catch {
    Write-Host ""
    Write-Host "Android run process was interrupted or failed" -ForegroundColor Yellow
    Write-Host "You can manually install the APK from: $apkPath" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Tips:" -ForegroundColor White
Write-Host "   - Keep your emulator running between updates for faster builds" -ForegroundColor White
Write-Host "   - Use this script whenever you make changes to see them immediately" -ForegroundColor White
Write-Host "   - If you need to open Android Studio, use 'build-android.ps1' instead" -ForegroundColor White
Write-Host "   - If the script gets stuck, cancel with Ctrl+C and install APK manually" -ForegroundColor White
Write-Host ""
Write-Host "APK Location:" -ForegroundColor Cyan
Write-Host "   - Debug APK: $apkPath" -ForegroundColor White
Write-Host "   - Copy this APK to your device to install manually if needed" -ForegroundColor White
