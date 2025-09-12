# 🎵 GigiTime
A metronome for Gigi

## 🚀 Quick Start

### Android Development
1. **Start emulator**: `.\scripts\run-emulator.ps1`
2. **Deploy app**: `.\scripts\update-app.ps1`

## 📱 Available Scripts

- **`.\scripts\run-emulator.ps1`** - Start Android emulator (fixes issues if needed)
- **`.\scripts\update-app.ps1`** - Build and deploy app to emulator

## 🔧 What the Scripts Do

### **Run Emulator Script**
- Starts Android emulator
- Fixes emulator issues (freezing, black screen)
- Waits for emulator to be ready

### **Update App Script**
- Builds React app with `npm run build`
- Syncs with Capacitor using `npx cap sync android`
- Builds APK from command line using `.\gradlew assembleDebug`
- Copies APK to `build/gigi-time.apk`
- Installs and launches app on emulator

## ⚠️ Prerequisites

Make sure you have:
- ✅ **Node.js** and **npm** installed
- ✅ **Android Studio** installed
- ✅ **Android SDK** configured
- ✅ **Capacitor** project initialized

## 📦 APK Output Location

After running the update script, your debug APK will be located at:
```
build\gigi-time.apk
```

**File Size**: Typically 25-30 MB  
**Type**: Debug APK (properly signed for development)

## 🐛 Troubleshooting

### Build Fails
- Check that you're in the project root directory
- Ensure all dependencies are installed
- Verify your React code compiles without errors

### Emulator Issues
- For emulator freezing/black screen, run `.\scripts\run-emulator.ps1` again
- All scripts must be run from the project root directory

### Device Selection Issues
- **Problem**: Script gets stuck waiting for device selection
- **Cause**: Multiple emulators available or no default device set
- **Solution**: Cancel with `Ctrl+C` and restart the emulator

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

# Run directly on Android
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