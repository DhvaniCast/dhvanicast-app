# 🎙️ LiveKit Voice Communication - Fixed Issues & Testing Guide

## 📋 Problems Identified & Fixed

### **Issue 1: Missing LiveKit Audio Permissions** ❌ ✅ FIXED
**Problem:** AndroidManifest.xml aur iOS Info.plist me LiveKit ke liye zaroori audio permissions missing the.

**Fix Applied:**
- ✅ Android: Added `BLUETOOTH`, `BLUETOOTH_CONNECT`, `ACCESS_NETWORK_STATE`, `CHANGE_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE`
- ✅ iOS: Added `NSMicrophoneUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `UIBackgroundModes` (audio, voip)

---

### **Issue 2: Audio Track Auto-Subscription Disabled** ❌ ✅ FIXED
**Problem:** Remote participants ki audio tracks automatically subscribe nahi ho rahi thi.

**Fix Applied:**
- ✅ LiveKitService me explicit audio track subscription logic add kiya
- ✅ `_subscribeToParticipant()` function banaya jo har remote participant ke audio tracks ko enable karta hai
- ✅ `_subscribeToExistingParticipants()` function banaya jo room join karte waqt existing users ke tracks subscribe karta hai
- ✅ `TrackPublishedEvent` aur `TrackSubscribedEvent` handlers improve kiye
- ✅ Remote audio tracks ko explicitly enable kiya: `audioTrack.enable()`

---

### **Issue 3: Room Options Incomplete** ❌ ✅ FIXED
**Problem:** Room creation me proper audio configuration missing tha.

**Fix Applied:**
- ✅ Room options me `dtx: false` (better audio continuity)
- ✅ `adaptiveStream: true` aur `dynacast: true` enabled
- ✅ Backend me room metadata me `audioEnabled: true` set kiya
- ✅ Token generation me `canPublishSources: ['microphone']` explicitly add kiya

---

## 🧪 Testing Steps (Step-by-Step)

### **Test Scenario: 450 MHz Frequency Voice Communication**

#### **Setup:**
1. **2 devices chahiye** (2 phones ya 1 phone + 1 emulator)
2. Dono devices me app install karo
3. Dono me login karo (different users)

#### **Testing Process:**

##### **Device 1 (User A):**
```
Step 1: App open karo
Step 2: Dialer screen pe jao
Step 3: "450" frequency dial karo
Step 4: "Join" button press karo
Step 5: Console logs check karo:
   ✅ "🎙️ [LiveKit] Connecting to frequency: 450"
   ✅ "✅ [LiveKit] Connected to room"
   ✅ "✅ [LiveKit] Audio track published"
   ✅ "🔊 [LiveKit] Microphone is ACTIVE"
Step 6: Kuch bolo (speak something)
```

##### **Device 2 (User B):**
```
Step 1: App open karo
Step 2: Dialer screen pe jao
Step 3: "450" frequency dial karo
Step 4: "Join" button press karo
Step 5: Console logs check karo:
   ✅ "👤 [LiveKit] ✅ Participant joined: [User A name]"
   ✅ "👥 [LiveKit] Current participants: 1"
   ✅ "🔗 [LiveKit] Subscribing to User A's tracks..."
   ✅ "🔊 [LiveKit] Enabled audio from User A"
   ✅ "🔊 [LiveKit] ✅ Receiving audio from: User A"
   ✅ "📡 [LiveKit] You should now hear User A"
Step 6: User A ki awaaz sunai degi! 🎉
Step 7: Aap bhi kuch bolo - User A ko sunai dega!
```

---

## 🔍 Debugging Tips

### **Check Console Logs:**
Look for these specific messages:

#### **Good Signs (Working):** ✅
```
✅ [LiveKit] Connected to room
✅ [LiveKit] Audio track published
🔊 [LiveKit] Microphone is ACTIVE
👤 [LiveKit] ✅ Participant joined: [Name]
🔊 [LiveKit] ✅ Receiving audio from: [Name]
🔊 [LiveKit] Audio track enabled for playback
```

#### **Bad Signs (Issues):** ❌
```
❌ [LiveKit] Connection error
❌ [LiveKit] Failed to get token
⚠️ [LiveKit] Cannot initialize - missing frequencyId
⚠️ [LiveKit] Cannot toggle - not connected
```

---

## 🎤 Microphone Permission Check

### **First Time App Launch:**
1. App ko microphone permission mangni chahiye
2. "Allow" select karo
3. Agar permission denied ho gaya:
   - Settings → Apps → Harborleaf Radio → Permissions → Microphone → Allow

### **iOS:**
- Settings → Harborleaf Radio App → Microphone → Enable

---

## 🔊 Audio Playback Check

### **If Voice Not Hearing:**
1. **Volume check karo** - Device volume high rakho
2. **Bluetooth check karo** - Agar Bluetooth headset connected hai, to audio waha jayega
3. **Speaker mode** - Phone speaker pe audio aana chahiye
4. **Logs check karo** - Console me audio subscription messages dekho

---

## 🌐 Network Requirements

### **Internet Connection:**
- **Strong WiFi** ya **4G/5G** chahiye
- Weak network pe audio lag ho sakta hai
- LiveKit URL check karo: `wss://radio-app-y4ia2uaz.livekit.cloud`

### **Firewall:**
- Port 443 (WebSocket) open hona chahiye
- CORS properly configured hai backend me

---

## 🐛 Common Issues & Solutions

### **1. "No voice coming" after all fixes:**
**Solution:**
- Device restart karo
- App uninstall → reinstall karo (permissions fresh milenge)
- Different frequency try karo (550, 600, etc.)

### **2. "One-way audio" (A hears B, but B doesn't hear A):**
**Solution:**
- Check kar lo ki dono users unmuted hain
- Console logs dekho ki "Audio track published" message aa raha hai
- Microphone permission check karo

### **3. "Echo/Feedback" problem:**
**Solution:**
- Earphones use karo
- Echo cancellation enabled hai service me

### **4. "Delayed audio" (lag):**
**Solution:**
- Better internet connection use karo
- Backend server status check karo
- LiveKit cloud status check karo: https://status.livekit.io/

---

## 📱 App Flow Diagram

```
User A (450 MHz)                    LiveKit Server                    User B (450 MHz)
     |                                    |                                  |
     |-------- Join Request ------------->|                                  |
     |<------- Token + Room URL ----------|                                  |
     |-------- Connect ------------------>|                                  |
     |<------- Connected ----------------|                                  |
     |-------- Publish Audio ------------>|                                  |
     |                                    |<-------- Join Request ----------|
     |                                    |--------- Token + Room URL ------>|
     |                                    |<-------- Connect ---------------|
     |                                    |--------- Connected ------------->|
     |<------- Participant Joined --------|                                  |
     |                                    |--------- Participant Joined ---->|
     |-------- Speaking 🗣️ -------------->|--------- Audio Stream --------->|
     |                                    |                         🔊 Hears User A
     |                         🔊 Hears User B <-------- Audio Stream --------|
     |<------- Audio Stream --------------|<-------- Speaking 🗣️ ----------|
```

---

## 🎯 Expected Behavior

### **When User Joins Frequency:**
1. LiveKit token fetch hota hai
2. Room me connect hota hai
3. Audio track publish hoti hai
4. Microphone UNMUTED state me start hota hai
5. Other users ka audio automatically subscribe hota hai

### **When Another User Joins:**
1. "Participant joined" event trigger hoti hai
2. Automatically unki audio track subscribe hoti hai
3. Audio playback enable hoti hai
4. Dono users ek dusre ko sun sakte hain

### **Voice Communication:**
- **Real-time** voice transmission
- **Low latency** (< 200ms typically)
- **Echo cancellation** enabled
- **Noise suppression** enabled
- **Auto gain control** enabled

---

## 🔧 Technical Details

### **LiveKit Configuration:**
```dart
Room Options:
- defaultAudioPublishOptions: AudioPublishOptions(name: 'microphone', dtx: false)
- defaultAudioCaptureOptions: AudioCaptureOptions(
    noiseSuppression: true,
    echoCancellation: true,
    autoGainControl: true,
  )
- adaptiveStream: true
- dynacast: true
```

### **Token Permissions:**
```javascript
{
  room: "frequency_450",
  roomJoin: true,
  canPublish: true,
  canSubscribe: true,
  canPublishData: true,
  canPublishSources: ['microphone']
}
```

### **Backend Room Settings:**
```javascript
{
  name: "frequency_450",
  emptyTimeout: 300, // 5 minutes
  maxParticipants: 100,
  metadata: {
    audioEnabled: true,
    videoEnabled: false,
    type: 'radio_frequency'
  }
}
```

---

## 📞 Quick Test Commands (Developer)

### **Check Room Participants (Backend):**
```bash
curl -X GET http://localhost:5000/api/v1/livekit/room/450/participants \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### **Check LiveKit Server Status:**
```bash
# Check if LiveKit cloud is reachable
curl -I https://radio-app-y4ia2uaz.livekit.cloud
```

---

## ✅ Final Checklist

Before testing, ensure:

- [ ] Backend server running (`npm start` in harborleaf_radio_backend)
- [ ] Frontend app installed on both devices
- [ ] Both users logged in
- [ ] Internet connection strong on both devices
- [ ] Microphone permissions granted
- [ ] Volume turned up
- [ ] No Bluetooth devices interfering
- [ ] LiveKit credentials correct in `.env`

---

## 🎉 Success Indicators

Aapko pata chal jayega ki sab kaam kar raha hai jab:

1. ✅ User A joins 450 → Console me "Connected" aur "Audio track published" dikhe
2. ✅ User B joins 450 → Console me "Participant joined: User A" dikhe
3. ✅ User A speaks → User B ko awaaz sunai de
4. ✅ User B speaks → User A ko awaaz sunai de
5. ✅ No delay, no echo, clear audio quality

---

## 📧 If Still Issues Persist

Agar fir bhi koi problem ho:

1. **Console logs save karo** - Full terminal output
2. **Check karo:**
   - Backend logs (`node index.js` ka output)
   - Frontend logs (Flutter console)
   - LiveKit dashboard (if accessible)
3. **Network check:**
   - `ping radio-app-y4ia2uaz.livekit.cloud`
   - Check firewall settings

---

## 🚀 Next Steps

After successful testing:
1. Test with multiple frequencies (450, 550, 600)
2. Test with 3+ users on same frequency
3. Test mute/unmute functionality
4. Test leaving and rejoining frequency
5. Test on different network conditions

---

**Last Updated:** November 10, 2025
**Status:** ✅ All Critical Issues Fixed - Ready for Testing
