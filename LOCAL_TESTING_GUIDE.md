# 🧪 Local Testing Guide - LiveKit Voice Communication

## 🎯 Objective
Test voice communication locally WITHOUT building APK, using Flutter debug mode.

---

## ✅ Prerequisites Checklist

### 1. Backend Server Running
```powershell
# Check if backend is running on port 5000
netstat -ano | findstr :5000

# If not running, start it:
cd c:\FlutterDev\project\Clone\harborleaf_radio_backend
npm start

# Should see:
# ✅ Server running on port 5000
# ✅ MongoDB Connected
```

### 2. LiveKit Credentials in .env
```bash
LIVEKIT_URL=wss://radio-app-y4ia2uaz.livekit.cloud
LIVEKIT_API_KEY=APIRZwmB5JsT7RB
LIVEKIT_API_SECRET=Yi8MeCEaphp6UrWevdReyl6QI0pmBVWXBdR444QaDjDB
```

### 3. Phone/Emulator Connected
```powershell
# Check connected devices
flutter devices

# Should show your phone or emulator
```

---

## 🚀 Testing Steps (Detailed)

### Step 1: Start Backend Server
```powershell
cd c:\FlutterDev\project\Clone\harborleaf_radio_backend
npm start
```

**Expected Output:**
```
🚀 Server running on port 5000
📊 Environment: development
🔌 MongoDB Connected Successfully
✅ LiveKit configured: wss://radio-app-y4ia2uaz.livekit.cloud
```

---

### Step 2: Run Flutter App in Debug Mode
```powershell
cd c:\FlutterDev\project\Clone\harborleaf_radio_app

# Run with verbose logging
flutter run -v

# OR specific device:
flutter run -d <device-id>
```

**This will:**
- Install app on connected device
- Show real-time console logs
- Allow hot reload for quick testing

---

### Step 3: Login on Device 1
```
1. Open app on Device 1
2. Enter mobile number: 9876543210
3. Enter OTP: 100623 (static OTP for testing)
4. Login successful ✅
```

**Watch Console for:**
```
✅ [Auth] Login successful
📱 [Auth] Token saved
👤 [Auth] User: [Your Name]
```

---

### Step 4: Join Frequency on Device 1
```
1. Go to Dialer screen
2. Dial: 450
3. Click "Join" button
4. Wait for connection...
```

**Watch Console Logs (CRITICAL):**
```
🎙️ [LiveKit] Connecting to frequency: 450
👤 [LiveKit] User: [Your Name]
📡 [LiveKit Token] Response: 200
✅ [LiveKit Token] Success: true
🔗 [LiveKit] Server URL: wss://radio-app-y4ia2uaz.livekit.cloud
✅ [LiveKit] Connected to room
👥 [LiveKit] Current participants: 0
🎤 [LiveKit] Creating audio track...
✅ [LiveKit] Audio track created
📡 [LiveKit] Publishing audio track...
✅ [LiveKit] Audio track published
🔊 [LiveKit] Microphone is ACTIVE
```

**If you see ❌ errors:**
- Note the exact error message
- Check if token generation failed
- Verify LiveKit URL is reachable

---

### Step 5: Join Same Frequency on Device 2

**Option A: Second Physical Device**
```
1. Install app on second device
2. Login with different mobile: 9876543211
3. Join frequency: 450
```

**Option B: Chrome Browser (Web Testing)**
```powershell
# Run Flutter web version
flutter run -d chrome

# Login and join 450
```

**Option C: Second Emulator**
```powershell
# Start another emulator
flutter emulators --launch <emulator-name>

# Run on second device
flutter run -d <device-2-id>
```

---

### Step 6: Verify Connection on Device 2

**Device 2 Console Logs:**
```
🎙️ [LiveKit] Connecting to frequency: 450
✅ [LiveKit] Connected to room
👥 [LiveKit] Current participants: 1
   - [Device 1 User Name] (user-id-123)
🔗 [LiveKit] Subscribing to Device 1's tracks...
🔊 [LiveKit] Enabled audio from Device 1
🔊 [LiveKit] ✅ Receiving audio from: Device 1 User
📡 [LiveKit] You should now hear Device 1 User
```

**Device 1 Should Also See:**
```
👤 [LiveKit] ✅ Participant joined: Device 2 User
👥 [LiveKit] Total participants now: 2
🔗 [LiveKit] Subscribing to Device 2's tracks...
🔊 [LiveKit] ✅ Receiving audio from: Device 2 User
```

---

### Step 7: Test Voice Communication

**Device 1:** 
- Speak something: "Hello, can you hear me?"
- Watch mic icon - should NOT be muted

**Device 2:**
- Should hear Device 1's voice
- Speak back: "Yes, I can hear you!"

**Device 1:**
- Should hear Device 2's voice

**✅ SUCCESS if both can hear each other!**

---

## 🔍 Debugging: Common Issues

### Issue 1: "Failed to get token"
```
❌ [LiveKit Token] Response: 401
❌ [LiveKit Token] Failed: Unauthorized
```

**Solution:**
- Re-login to get fresh auth token
- Check backend logs for authentication errors
- Verify token in SharedPreferences

---

### Issue 2: "Cannot connect to LiveKit"
```
❌ [LiveKit] Connection error: WebSocketException
```

**Solution:**
```powershell
# Test LiveKit URL
curl -I https://radio-app-y4ia2uaz.livekit.cloud

# Check internet connection
# Verify LiveKit credentials in backend .env
```

---

### Issue 3: "No audio track created"
```
❌ [LiveKit] Audio track creation failed
```

**Solution:**
- Check microphone permissions
- Settings → Apps → Harborleaf Radio → Permissions → Microphone → Allow
- Restart app after granting permissions

---

### Issue 4: "Participant joined but no audio"
```
👤 [LiveKit] ✅ Participant joined: User2
❌ [LiveKit] No TrackSubscribedEvent received
```

**Solution:**
- Check if participant's mic is muted
- Verify audio track is published: Look for "✅ Audio track published"
- Check speaker volume on receiving device

---

### Issue 5: "Audio track published but not subscribed"
```
✅ [LiveKit] Audio track published
⚠️ [LiveKit] TrackPublishedEvent received but no subscription
```

**Solution:**
- This is the MAIN ISSUE we fixed
- Verify `_subscribeToParticipant()` is being called
- Check logs for: "🔗 [LiveKit] Subscribing to [User]'s tracks..."

---

## 📊 Console Log Analysis

### ✅ Good Signs (Everything Working):
```
✅ [LiveKit] Connected to room
✅ [LiveKit] Audio track published
🔊 [LiveKit] Microphone is ACTIVE
👤 [LiveKit] ✅ Participant joined: [Name]
🔗 [LiveKit] Subscribing to [Name]'s tracks...
🔊 [LiveKit] ✅ Receiving audio from: [Name]
🔊 [LiveKit] Audio track enabled for playback
```

### ❌ Bad Signs (Problems):
```
❌ [LiveKit] Connection error
❌ [LiveKit] Failed to get token
❌ [LiveKit] Audio track creation failed
⚠️ [LiveKit] Cannot initialize - missing frequencyId
⚠️ No TrackSubscribedEvent received
```

---

## 🎤 Audio Testing Checklist

- [ ] Device 1 mic icon shows UNMUTED (🎤 active)
- [ ] Device 2 mic icon shows UNMUTED (🎤 active)
- [ ] Device 1 console: "✅ Audio track published"
- [ ] Device 2 console: "✅ Audio track published"
- [ ] Device 1 console: "🔊 ✅ Receiving audio from: Device 2"
- [ ] Device 2 console: "🔊 ✅ Receiving audio from: Device 1"
- [ ] Device 1 can hear Device 2 speaking ✅
- [ ] Device 2 can hear Device 1 speaking ✅
- [ ] No echo or feedback
- [ ] Audio is clear, not choppy

---

## 🛠️ Quick Debug Commands

### Check Backend Logs
```powershell
# In backend terminal, watch for:
🎫 Creating LiveKit token:
   - Room: frequency_450
   - Participant: User Name
✅ Token generated: eyJhbG...
```

### Check Flutter Logs
```powershell
# Filter LiveKit logs only
flutter logs | Select-String "LiveKit"

# OR save to file
flutter logs > livekit_logs.txt
```

### Test Token Generation Manually
```powershell
# Run the test script
cd c:\FlutterDev\project\Clone\harborleaf_radio_app
dart run test_livekit_local.dart

# Follow prompts to test token generation
```

---

## 🎯 Success Criteria

**Your test is SUCCESSFUL when:**

1. ✅ Both devices connect to room without errors
2. ✅ Both see "Audio track published" message
3. ✅ Both see "Participant joined" for other user
4. ✅ Both see "Receiving audio from" for other user
5. ✅ Device 1 speaks → Device 2 HEARS
6. ✅ Device 2 speaks → Device 1 HEARS
7. ✅ No delay > 500ms
8. ✅ No echo or audio quality issues

---

## 📝 Log Template for Reporting Issues

If still facing issues, save these logs:

```
=== DEVICE 1 LOGS ===
[Paste Device 1 console output here]

=== DEVICE 2 LOGS ===
[Paste Device 2 console output here]

=== BACKEND LOGS ===
[Paste backend terminal output here]

=== ISSUE DESCRIPTION ===
- What happened: [Describe]
- Expected: [What should happen]
- Actual: [What actually happened]
- Steps to reproduce: [List steps]
```

---

## 🔄 Hot Reload Testing

**Advantage of Debug Mode:**
```dart
// Make changes in livekit_service.dart
// Then press 'r' in terminal for hot reload
// OR 'R' for hot restart

// No need to rebuild APK!
```

---

## 📱 Testing on Different Devices

### Physical Phone + Emulator:
```
✅ Best option for testing
✅ Real microphone behavior
✅ Fast iteration
```

### Two Physical Phones:
```
✅ Most realistic test
✅ Actual network conditions
⚠️ Need 2 phones
```

### Chrome + Phone:
```
✅ Easy to test
⚠️ Web audio permissions different
⚠️ Not fully representative
```

---

## 🚀 Once Working Locally

**ONLY THEN build APK:**
```powershell
flutter build apk --release

# Test APK on device
flutter install
```

---

**Remember:** Debug mode is MUCH FASTER for testing! Only build APK once everything works perfectly in debug mode.
