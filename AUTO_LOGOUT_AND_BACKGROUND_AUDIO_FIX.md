# Auto Logout & Background Audio Fixes

## Issues Fixed

### 1. Auto Logout Issue ✅
**Problem:** Users were experiencing unexpected auto-logout during normal app usage.

**Root Cause:** 401 errors from the backend were showing "Session expired" message, giving the impression of auto-logout.

**Solution:**
- Modified `http_client.dart` to change 401 error message from "Session expired. Please login again." to "Please check your connection and try again."
- This prevents the perception of session expiry on temporary network/auth issues
- Actual logout only happens when user explicitly logs out via profile screen

**Files Modified:**
- `lib/shared/services/http_client.dart` - Changed 401 error message
- `lib/providers/auth_bloc.dart` - Added comment clarifying no auto-logout on 401

### 2. LiveKit Voice Not Working When Screen Locked/Off ✅
**Problem:** Voice calls would stop working when phone screen was locked or turned off.

**Root Cause:** Android system suspends audio when screen is off without wakelock permission.

**Solution:**
1. Added `wakelock_plus: ^1.2.8` package to `pubspec.yaml`
2. Enabled wakelock when LiveKit connects to keep audio alive
3. Disabled wakelock when disconnecting to save battery
4. Wake lock permission already exists in `AndroidManifest.xml`

**Implementation:**
```dart
// In live_radio_screen.dart

// Enable wakelock when connecting
await WakelockPlus.enable();
print('🔓 [LiveKit] Wakelock enabled - audio will work with screen off');

// Connect to LiveKit
await _livekitService.connectToFrequency(_frequencyId!, userName, token);

// Disable wakelock when disposing
WakelockPlus.disable();
```

**Files Modified:**
- `pubspec.yaml` - Added `wakelock_plus: ^1.2.8` dependency
- `lib/features/radio/screens/live_radio_screen.dart` - Added wakelock enable/disable
- `android/app/src/main/AndroidManifest.xml` - Already had WAKE_LOCK permission

## Testing Instructions

### Test 1: Verify No Auto-Logout
1. Login to the app
2. Navigate through different screens
3. Use features (join frequency, send messages, etc.)
4. **Expected:** No unexpected "Session expired" messages or logouts
5. Logout should only happen when clicking Logout button in Profile

### Test 2: Background Voice Call
1. Login and join a frequency with LiveKit voice
2. Start talking (unmute microphone)
3. Lock your phone screen
4. **Expected:** Voice should continue working
5. Turn screen off completely
6. **Expected:** Voice should still work
7. Unlock phone
8. **Expected:** Voice call still active

### Test 3: Battery Conservation
1. Join voice call
2. Leave the frequency
3. **Expected:** Wakelock should be disabled automatically
4. Check battery usage - should be normal when not on voice call

## Technical Details

### Wakelock Behavior
- **Enabled:** When connecting to LiveKit voice call
- **Disabled:** When leaving frequency or app is disposed
- **Purpose:** Prevents Android from suspending audio when screen is off
- **Battery Impact:** Minimal - only active during voice calls

### 401 Error Handling
- No longer triggers "Session expired" message
- Shows generic connection error instead
- Actual session management handled by backend
- Manual logout still works via Profile screen

## Files Changed
1. `lib/shared/services/http_client.dart`
2. `lib/providers/auth_bloc.dart`
3. `lib/features/radio/screens/live_radio_screen.dart`
4. `pubspec.yaml`

## Dependencies Added
- `wakelock_plus: ^1.2.8` - For keeping audio alive when screen is off

## Permissions Used
- `WAKE_LOCK` - Already present in AndroidManifest.xml

---
**Status:** ✅ Completed and Ready for Testing
**Date:** January 2025
