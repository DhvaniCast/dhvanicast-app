# 🚀 Debug Mode Testing - Simple Steps (Hindi Guide)

## ❓ Debug Mode Kya Hai?

**Debug Mode** = App ko directly phone/computer pe run karna **BINA APK banaye**

**Fayde:**
- ⚡ Fast - APK banana ka wait nahi
- 🔄 Changes instantly test kar sakte ho
- 📊 Console me sab logs dikhte hain
- 🐛 Bugs easily find kar sakte ho

---

## 🎯 Method 1: Chrome Browser Me Test (Sabse Easy!)

### Step 1: Backend Check Karo
```powershell
# Ye command run karo
netstat -ano | findstr :5000
```

**Agar output aaye** = Backend running hai ✅  
**Agar kuch nahi aaye** = Backend start karo:
```powershell
cd c:\FlutterDev\project\Clone\harborleaf_radio_backend
npm start
```

---

### Step 2: App Ko Chrome Me Chalao

```powershell
# Folder me jao
cd c:\FlutterDev\project\Clone\harborleaf_radio_app

# Chrome me run karo
flutter run -d chrome
```

**Kya hoga:**
1. Chrome browser automatically khulega
2. App load hoga (thoda wait karo, 1-2 minute)
3. Terminal me bahut saare logs dikhenge
4. App ready ho jayega!

---

### Step 3: Login Karo (Chrome Window 1)

**App me:**
1. Mobile number enter karo: `9876543210`
2. OTP enter karo: `100623`
3. Login ho jayega!

---

### Step 4: Frequency Join Karo

1. **Dialer** screen pe jao
2. **450** dial karo
3. **Join** button dabao

**Terminal me ye logs dikhne chahiye:**
```
🎙️ [LiveKit] Connecting to frequency: 450
✅ [LiveKit] Connected to room
✅ [LiveKit] Audio track published
🔊 [LiveKit] Microphone is ACTIVE
```

---

### Step 5: Dusri Chrome Window Kholo

**Naya PowerShell terminal kholo** (purana chhod do running):
```powershell
cd c:\FlutterDev\project\Clone\harborleaf_radio_app

# Dusri window me run karo
flutter run -d chrome
```

**Dusri Chrome window khulegi!**

---

### Step 6: Dusre User Se Login Karo

**Dusri window me:**
1. Mobile: `9876543211` (different number)
2. OTP: `100623`
3. Login ✅

---

### Step 7: Same Frequency Join Karo

**Dusri window me bhi:**
1. Dialer pe jao
2. **450** dial karo
3. Join karo

**Dono terminals me ye dikhna chahiye:**
```
👤 [LiveKit] ✅ Participant joined: [Name]
🔊 [LiveKit] ✅ Receiving audio from: [Name]
```

---

### Step 8: Voice Test Karo! 🎤

**Window 1:**
- Mic allow karo browser me
- Kuch bolo: "Hello, can you hear me?"

**Window 2:**
- Tumhe Window 1 ki awaaz sunai deni chahiye!
- Tum bhi bolo: "Yes, I can hear you!"

**Window 1:**
- Tumhe Window 2 ki awaaz sunai degi!

**✅ SUCCESS!** Agar dono ek dusre ko sun rahe hain!

---

## 🎯 Method 2: Phone Me Test (Agar Phone Connected Ho)

### Step 1: Phone Connect Karo

1. Phone ko USB se laptop/PC se connect karo
2. Phone me **USB Debugging** enable karo:
   - Settings → About Phone → Build Number (7 baar tap karo)
   - Settings → Developer Options → USB Debugging ✅

---

### Step 2: Check Karo Phone Detected Hai

```powershell
flutter devices
```

**Output me phone dikna chahiye:**
```
Your Phone Name • <device-id> • android-arm64 • Android 12
```

---

### Step 3: Phone Pe Run Karo

```powershell
cd c:\FlutterDev\project\Clone\harborleaf_radio_app

# Phone pe install aur run hoga
flutter run
```

**Kya hoga:**
1. App phone pe install hoga automatically
2. App open hoga
3. Console me logs dikhenge

---

### Step 4: Login aur Test

**Phone pe:**
1. Login karo
2. Frequency 450 join karo

**Chrome window kholo:**
```powershell
# Dusri terminal me
flutter run -d chrome
```

**Chrome me:**
1. Login karo (different number)
2. Frequency 450 join karo

**Ab phone aur chrome dono me test karo voice!**

---

## 📱 Screenshot: Kya Dikhega

### Terminal Output Example:
```
Launching lib\main.dart on Chrome in debug mode...
Building application for the web...                                
Waiting for connection from debug service on Chrome...            
This app is linked to the debug service: ws://127.0.0.1:50234/

🎙️ [LiveKit] Connecting to frequency: 450
👤 [LiveKit] User: Test User
📡 [LiveKit Token] Response: 200
✅ [LiveKit] Connected to room
✅ [LiveKit] Audio track published
👥 [LiveKit] Current participants: 0
🔊 [LiveKit] Microphone is ACTIVE
```

---

## ⚠️ Common Problems & Solutions

### Problem 1: "Chrome not found"
```powershell
# Solution: Flutter path check karo
flutter doctor

# Chrome install hai check karo
```

### Problem 2: "No devices detected"
```
# Solution: 
flutter devices

# Agar kuch nahi dikha:
# 1. Chrome browser open rakho
# 2. Phir flutter run -d chrome karo
```

### Problem 3: "Backend connection failed"
```
❌ [LiveKit Token] Failed: connect ECONNREFUSED
```
**Solution:**
```powershell
# Backend start karo
cd ..\harborleaf_radio_backend
npm start
```

### Problem 4: "Microphone access denied"
**Solution:**
- Browser me microphone permission allow karo
- Chrome → Settings → Privacy → Microphone → Allow

---

## 🎮 Quick Commands Reference

```powershell
# Backend start
cd c:\FlutterDev\project\Clone\harborleaf_radio_backend
npm start

# App run - Chrome
cd c:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run -d chrome

# App run - Phone
flutter run

# Devices check
flutter devices

# Logs dekhne ke liye
flutter logs
```

---

## 🔥 Hot Reload - Instant Changes!

**Code me change karo:**
1. File kholo: `lib\shared\services\livekit_service.dart`
2. Kuch change karo (jaise print statement)
3. Save karo (Ctrl+S)
4. Terminal me **'r'** press karo

**App instantly reload ho jayega! No restart needed!** 🚀

---

## ✅ Success Checklist

Test successful hai jab:

- [ ] Backend running on port 5000
- [ ] App chrome/phone pe run ho raha hai
- [ ] Login successful
- [ ] Frequency join hua without errors
- [ ] Console me "Connected to room" dikha
- [ ] Console me "Audio track published" dikha
- [ ] Dusra user join hua
- [ ] Console me "Participant joined" dikha
- [ ] Console me "Receiving audio from" dikha
- [ ] Device 1 speaks → Device 2 hears ✅
- [ ] Device 2 speaks → Device 1 hears ✅

---

## 🎯 Ab Kya Karo?

### Step 1: Backend Start Karo
```powershell
# Terminal 1 me
cd c:\FlutterDev\project\Clone\harborleaf_radio_backend
npm start
```

### Step 2: App Run Karo
```powershell
# Terminal 2 me (naya terminal kholo)
cd c:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run -d chrome
```

### Step 3: Dusri Window
```powershell
# Terminal 3 me (ek aur naya terminal)
cd c:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run -d chrome
```

### Step 4: Test Karo
- Dono windows me login karo
- Dono me frequency 450 join karo
- Voice test karo!

---

## 📞 Agar Problem Aaye

**Console logs copy karo aur dikhao:**
1. Terminal ki saari output copy karo
2. Error messages note karo
3. Kaunse logs missing hain wo batao

Main exactly bata dunga kya problem hai! 💪

---

## 🎉 Summary

**Debug Mode = No APK Needed!**

1. ✅ Backend start karo
2. ✅ `flutter run -d chrome` karo
3. ✅ Login karo, frequency join karo
4. ✅ Dusri window me same steps
5. ✅ Voice test karo!

**Bahut simple hai! Try karo aur batao agar koi confusion ho!** 🚀
