# 🎵 GigiTime Android Build Scripts

This directory contains automated build scripts to streamline your Android development workflow.

## 📱 What These Scripts Do

### **Build Scripts** (Opens Android Studio)
The build scripts automate the complete process of:
1. **Installing dependencies** (if needed)
2. **Building the React app** with `npm run build`
3. **Syncing with Capacitor** using `npx cap sync android`
4. **Opening Android Studio** with `npx cap open android`

### **Update Scripts** (Direct to Emulator)
The update scripts do everything above but then:
5. **Build and run directly** on Android using `npx cap run android`
6. **Automatically reinstall** the APK in your running emulator
7. **Skip opening Android Studio** for faster development cycles

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

# Batch - Double-click or run from Command Prompt:
update-android.bat
```

### **When to Use Which Script**
- **`build-android.ps1`**: First setup, major changes, debugging in Android Studio
- **`update-android.ps1`**: Daily development, quick updates, seeing changes immediately

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
5. **Android Studio**: Opens the project automatically

## 🎯 After Running the Script

1. **Android Studio** will open with your project
2. **Click the green "Run" button** (▶️)
3. **Select your target device** (emulator or physical device)
4. **Test your updated app!**

## 🐛 Troubleshooting

### Build Fails
- Check that you're in the project root directory
- Ensure all dependencies are installed
- Verify your React code compiles without errors

### Sync Fails
- Check that `capacitor.config.json` exists and is correct
- Ensure Android project is properly initialized
- Verify Capacitor CLI is installed globally

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

# Open Android Studio
npx cap open android
```

## 🎉 Benefits

- **Saves time** - One click instead of multiple commands
- **Reduces errors** - Automated error checking and validation
- **Consistent workflow** - Same process every time
- **Visual feedback** - Clear progress indicators and status messages

---

**Happy coding! 🎵🥁**
