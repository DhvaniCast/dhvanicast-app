# 🎯 SIMPLE GUIDE - Debug Mode Testing

## Sirf 5 Commands! Bas!

---

## 📋 Pehle Ye Check Karo

### ✅ Backend Running Hai?
```powershell
netstat -ano | findstr :5000
```
**Agar kuch output aaye = Backend ON ✅**  
**Agar blank = Backend start karo:**
```powershell
cd c:\FlutterDev\project\Clone\harborleaf_radio_backend
npm start
```

---

## 🚀 Testing Start Karo - Sirf 3 Steps!

### 📱 TERMINAL 1: First User

```powershell
# Step 1: Folder me jao
cd c:\FlutterDev\project\Clone\harborleaf_radio_app

# Step 2: Chrome me run karo
flutter run -d chrome
```

**Kya hoga:**
- Chrome window khulega (wait 1-2 min)
- App load hoga
- Terminal me logs dikhenge

**App me kya karna:**
1. Mobile: `9876543210`
2. OTP: `100623`  
3. Login ✅
4. Dialer → `450` dial karo → Join

**Terminal me ye dikhe:**
```
✅ [LiveKit] Connected to room
✅ [LiveKit] Audio track published
```

---

### 📱 TERMINAL 2: Second User

**NYA terminal window kholo** (pehla chhod do running)

```powershell
# Same commands dobara
cd c:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run -d chrome
```

**Dusri Chrome window khulegi!**

**Usme kya karna:**
1. Mobile: `9876543211` ← **Different number**
2. OTP: `100623`
3. Login ✅
4. Dialer → `450` dial karo → Join

**Terminal me ye dikhe:**
```
👤 [LiveKit] Participant joined: [First User]
🔊 [LiveKit] Receiving audio from: [First User]
```

---

### 🎤 VOICE TEST

**Window 1 me:** Kuch bolo 🗣️  
**Window 2 me:** Sunai dega! 👂

**Window 2 me:** Kuch bolo 🗣️  
**Window 1 me:** Sunai dega! 👂

**✅ SUCCESS!** Agar dono ek dusre ko sun rahe hain!

---

## 🎬 Visual Flow

```
Terminal 1               Chrome Window 1           Chrome Window 2           Terminal 2
---------                --------------            ---------------           ----------
npm start (backend)            |                         |                        |
     ↓                         |                         |                        |
flutter run -d chrome   →  App loads              App loads     ←    flutter run -d chrome
     ↓                         ↓                         ↓                        ↓
  Logs show              Login (9876543210)      Login (9876543211)         Logs show
     ↓                         ↓                         ↓                        ↓
"Connected to room"       Join freq 450          Join freq 450          "Participant joined"
     ↓                         ↓                         ↓                        ↓
"Audio published"          Speak 🗣️  ────────────→  Hears 👂              "Receiving audio"
     ↓                         ↓                         ↓                        ↓
"Receiving audio"          Hears 👂  ←────────────  Speak 🗣️              "Audio published"
     ↓                         ↓                         ↓                        ↓
    ✅                        ✅                        ✅                       ✅
```

---

## 🎯 Easy Script Run Karo

**Sabse easy way:**

```powershell
# Ye script run karo - ye sab check kar lega
.\quick_test.ps1

# Ye automatically start kar dega testing!
```

---

## ❓ FAQs

### Q: Do phone chahiye?
**A:** Nahi! Chrome me hi test ho jayega. 2 Chrome windows!

### Q: APK banana padega?
**A:** Bilkul nahi! Debug mode hai, APK ki zaroorat nahi.

### Q: Kitna time lagega?
**A:** 2-3 minutes. Bahut fast!

### Q: Code change karne ke baad?
**A:** Terminal me 'r' press karo = instant reload!

### Q: Errors aaye to?
**A:** Terminal ki output copy karke dikhao, main fix kar dunga.

---

## 🎯 Summary - Sirf Ye Karna Hai

1. **Backend start karo** (agar nahi chal raha)
2. **Terminal 1:** `flutter run -d chrome`
3. **Login + Join 450**
4. **Terminal 2:** `flutter run -d chrome` (naya terminal)
5. **Login + Join 450**
6. **Test voice!**

**DONE! Itna hi!** 🎉

---

## 📞 Help Chahiye?

**Agar koi step samajh nahi aaya:**
1. Screenshot lo
2. Terminal output copy karo
3. Bolo kaha stuck ho

Main step-by-step guide kar dunga! 💪

---

## 🚀 Ab Start Karo!

```powershell
# Is folder me jao
cd c:\FlutterDev\project\Clone\harborleaf_radio_app

# Ye script run karo
.\quick_test.ps1

# Ya direct command:
flutter run -d chrome
```

**All the best! 🎉**
