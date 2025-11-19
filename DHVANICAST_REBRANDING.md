# Dhvanicast Rebranding Complete ✅

All "Harborleaf" references have been successfully replaced with "Dhvanicast" throughout the Flutter application.

## Files Modified

### 1. App Configuration Files
- **`lib/main.dart`**
  - Changed app title from "Harborleaf Radio" to "Dhvanicast"

- **`pubspec.yaml`**
  - Package name remains `harborleaf_radio_app` (changing would break imports)
  - Note: Internal package name is not user-facing

### 2. Android Platform
- **`android/app/src/main/AndroidManifest.xml`**
  - App label: "Harborleaf Radio" → "Dhvanicast"

- **`android/app/build.gradle.kts`**
  - Package ID: `com.harborleaf.radio` (unchanged - changing would affect app signing)

### 3. iOS Platform
- **`ios/Runner/Info.plist`**
  - Display name: "Harborleaf Radio App" → "Dhvanicast"
  - Bundle name: "harborleaf_radio_app" → "dhvanicast"

### 4. macOS Platform
- **`macos/Runner/Configs/AppInfo.xcconfig`**
  - Product name: "harborleaf_radio_app" → "Dhvanicast"

### 5. Linux Platform
- **`linux/runner/my_application.cc`**
  - Window title: "harborleaf_radio_app" → "Dhvanicast"

### 6. Windows Platform
- **`windows/runner/main.cpp`**
  - Window title: "harborleaf_radio_app" → "Dhvanicast"

- **`windows/runner/Runner.rc`**
  - File description: "Dhvanicast"
  - Internal name: "dhvanicast"
  - Original filename: "dhvanicast.exe"
  - Product name: "Dhvanicast"

### 7. Web Platform
- **`web/manifest.json`**
  - Name: "Dhvanicast"
  - Short name: "Dhvanicast"

- **`web/index.html`**
  - Title: "Dhvanicast"
  - Apple web app title: "Dhvanicast"

### 8. UI Screens
- **`lib/features/auth/screens/signup_screen.dart`**
  - Button text: "Join HarborLeaf" → "Join Dhvanicast"

- **`lib/features/auth/screens/permission_screen.dart`**
  - App name display: "Harborleaf Radio" → "Dhvanicast"

### 9. Documentation
- **`README.md`**
  - Title: "Harborleaf Radio App" → "Dhvanicast Radio App"

## User-Facing Changes

All visible instances of "Harborleaf" have been changed to "Dhvanicast":

1. **App Name** - Shows "Dhvanicast" on device home screen
2. **Window Titles** - Desktop platforms show "Dhvanicast"
3. **Signup Screen** - Button says "Join Dhvanicast"
4. **Permission Screen** - Shows "Dhvanicast" as app name
5. **Web App** - Browser tab and PWA show "Dhvanicast"

## Technical Notes

### What Was NOT Changed
- **Package name** in `pubspec.yaml`: `harborleaf_radio_app`
  - Changing this would break all imports across the codebase
  - Internal package names are not user-facing

- **Package IDs**: 
  - Android: `com.harborleaf.radio`
  - iOS/macOS: `com.example.harborleafRadioApp`
  - Changing these would require new app signing and would be considered a different app

- **Import statements**: All remain as `package:harborleaf_radio_app/...`
  - These are internal and not visible to users

- **Folder paths**: `c:\FlutterDev\project\Clone\harborleaf_radio_app`
  - Local development paths don't affect the built app

### Backend References
The backend still uses "harborleaf" in URLs and configurations:
- API endpoints: `https://harborleaf-radio-backend.onrender.com`
- These are internal and not shown to end users

## Testing Checklist

After rebranding, test these areas:

- [ ] Android app name on home screen shows "Dhvanicast"
- [ ] iOS app name on home screen shows "Dhvanicast"  
- [ ] Signup screen shows "Join Dhvanicast"
- [ ] Permission screen shows "Dhvanicast"
- [ ] Windows desktop app title shows "Dhvanicast"
- [ ] macOS app title shows "Dhvanicast"
- [ ] Linux app title shows "Dhvanicast"
- [ ] Web browser tab shows "Dhvanicast"
- [ ] All app functionality still works (no import errors)

## Build Commands

To build with the new branding:

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Web
flutter build web --release
```

---
**Status**: ✅ Complete
**Date**: January 2025
**Branding**: Harborleaf → Dhvanicast
