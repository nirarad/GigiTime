# 🎵 GigiTime Android Build Scripts

This directory contains automated build scripts to streamline your Android development workflow.

## 📱 What These Scripts Do

### **Build Scripts** (Opens Android Studio)
The build scripts automate the complete process of:
1. **Installing dependencies** (if needed)
2. **Building the React app** with `npm run build`
3. **Syncing with Capacitor** using `npx cap sync android`
4. **Building APK from command line** using `.\gradlew assembleDebug`
5. **Opening Android Studio** with `npx cap open android`

### **Update Scripts** (Direct to Emulator)
The update scripts do everything above but then:
6. **Build and run directly** on Android using `npx cap run android`
7. **Automatically reinstall** the APK in your running emulator
8. **Skip opening Android Studio** for faster development cycles

## 🚀 How to Use

### **Build Scripts** (Opens Android Studio)
```powershell
# PowerShell - Right-click and "Run with PowerShell" or run from terminal:
.\build-android.ps1
```

### **Update Scripts** (Direct to Emulator)
```powershell
# PowerShell - Right-click and "Run with PowerShell" or run from terminal:
.\update-android.ps1
```

### **APK-Only Script** (Builds APK without running)
```powershell
# PowerShell - Right-click and "Run with PowerShell" or run from terminal:
.\build-apk-only.ps1
```

### **When to Use Which Script**
- **`build-android.ps1`**: First setup, major changes, debugging in Android Studio
- **`update-android.ps1`**: Daily development, quick updates, seeing changes immediately
- **`build-apk-only.ps1`**: When you just want the APK file without running it

## ⚠️ Prerequisites

Make sure you have:
- ✅ **Node.js** and **npm** installed
- ✅ **Android Studio** installed
- ✅ **Android SDK** configured
- ✅ **Capacitor** project initialized

## 🔧 What Happens During Build

1. **Dependency Check**: Verifies `node_modules` exists
2. **Clean Build**: Removes previous build artifacts
3. **React Build**: Creates optimized production build
4. **Capacitor Sync**: Copies build files to Android project
5. **Command Line APK Build**: Generates debug APK using Gradle
6. **Android Studio**: Opens the project automatically (build script only)

## 📦 APK Output Location

After running either script, your debug APK will be located at:
```
build\gigi-time.apk
```

**File Size**: Typically 25-30 MB  
**Type**: Debug APK (properly signed for development)  
**Note**: The APK is automatically moved from `android\app\build\outputs\apk\debug\app-debug.apk` to `build\gigi-time.apk` for easier access and to avoid accidental git commits

## 🎯 After Running the Script

### **Build Script** (Android Studio)
1. **Android Studio** will open with your project
2. **Click the green "Run" button** (▶️)
3. **Select your target device** (emulator or physical device)
4. **Test your updated app!**

### **Update Script** (Direct to Emulator)
1. **APK is automatically built** and installed
2. **App launches directly** in your emulator
3. **No need to open Android Studio**

## 🐛 Troubleshooting

### Build Fails
- Check that you're in the project root directory
- Ensure all dependencies are installed
- Verify your React code compiles without errors

### Sync Fails
- Check that `capacitor.config.json` exists and is correct
- Ensure Android project is properly initialized
- Verify Capacitor CLI is installed globally

### APK Build Fails
- Check that Gradle is properly configured
- Ensure Android SDK is installed and configured
- Verify the Android project structure is correct

### Device Selection Issues
- **Problem**: `update-android.ps1` gets stuck waiting for device selection
- **Cause**: Multiple emulators available or no default device set
- **Solution**: 
  - Cancel with `Ctrl+C` and use `build-apk-only.ps1` instead
  - Or manually select a device when prompted
  - Or set a default device in your environment

### Android Studio Won't Open
- Check that Android Studio is installed and in your PATH
- Verify the Android project directory exists
- Try running `npx cap open android` manually

## 📝 Manual Commands

If you prefer to run commands manually:

```bash
# Build React app
npm run build

# Sync with Android
npx cap sync android

# Build APK from command line
cd android
.\gradlew assembleDebug
cd ..

# The APK will be at: android\app\build\outputs\apk\debug\app-debug.apk
# You can move it to: build\gigi-time.apk

# Open Android Studio
npx cap open android

# Or run directly on Android
npx cap run android
```

## 🎉 Benefits

- **Saves time** - One click instead of multiple commands
- **Reduces errors** - Automated error checking and validation
- **Consistent workflow** - Same process every time
- **Visual feedback** - Clear progress indicators and status messages
- **APK generation** - Creates installable APK files automatically
- **Direct installation** - Can install APK manually on devices

---

**Happy coding! 🎵🥁**
