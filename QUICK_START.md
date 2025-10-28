# 🚀 Quick Start Guide - 5 Minutes में API Test करें!

## Step 1: Backend Start करें (2 min)

```bash
# Terminal 1
cd C:\FlutterDev\project\Clone\harborleaf_radio_backend
npm install
npm start
```

**Wait for:** ✅ Server running on port 5000

---

## Step 2: Flutter App Setup (2 min)

```bash
# Terminal 2
cd C:\FlutterDev\project\Clone\harborleaf_radio_app
flutter pub get
flutter run
```

---

## Step 3: First API Test (1 min)

### Option A: Postman से Backend Test करें

```
POST http://localhost:5000/api/auth/register
Body (JSON):
{
  "name": "Test User",
  "mobile": "9876543210",
  "state": "Maharashtra"
}
```

**Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "expiresIn": 300,
    "attemptsLeft": 3
  }
}
```

### Option B: App से Direct Test करें

```
1. App खोलें
2. Register button दबाएं
3. Form fill करें
4. Backend terminal में OTP देखें
5. OTP enter करके verify करें
```

---

## ✅ Verify - API काम कर रही है अगर:

**Backend Terminal में दिखे:**
```
🌐 HTTP Request: POST /api/auth/register
📋 Headers: {...}
📦 Body: {"name":"Test User",...}
📨 HTTP Response: 200
```

**Flutter Console में दिखे:**
```
✅ HTTP Request: POST http://10.0.2.2:5000/api/auth/register
✅ HTTP Response: 200
✅ Registration successful
```

---

## 🎯 Quick API Testing Commands

### Test 1: Check Backend Health
```bash
curl http://localhost:5000/health
```
Expected: `{"status":"ok"}`

### Test 2: Test Socket.IO Connection
```bash
# Browser में खोलें
http://localhost:5000/api-docs
```

### Test 3: Create Frequency (Postman)
```
POST http://localhost:5000/api/frequencies
Headers:
  Authorization: Bearer YOUR_TOKEN
  Content-Type: application/json

Body:
{
  "frequency": 450.5,
  "name": "Test Frequency",
  "isPublic": true
}
```

---

## 🔧 Quick Fix Commands

### If Backend Not Starting:
```bash
# MongoDB running है check करें
# या .env में MONGODB_URI update करें

# Dependencies reinstall
rm -rf node_modules
npm install
npm start
```

### If Flutter Not Running:
```bash
# Clean और rebuild
flutter clean
flutter pub get
flutter run
```

### If API Not Connecting:
```dart
// lib/core/constants/api_endpoints.dart में check करें:

// Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Physical Device (अपना IP डालें)
// static const String baseUrl = 'http://192.168.1.X:5000/api';
```

---

## 📱 Device-wise Base URL

| Device Type | Base URL |
|-------------|----------|
| Android Emulator | `http://10.0.2.2:5000/api` |
| iOS Simulator | `http://localhost:5000/api` |
| Physical Device | `http://YOUR_IP:5000/api` |

**Find your IP:**
```bash
# Windows
ipconfig
# Look for IPv4 Address (e.g., 192.168.1.100)
```

---

## ✨ Features to Test Immediately

### 1. Authentication (30 seconds)
```
Register → Get OTP → Verify → Login Success ✅
```

### 2. Load Frequencies (10 seconds)
```
Open Dialer → See frequencies load → Join one ✅
```

### 3. Send Message (15 seconds)
```
Select Group → Type message → Send → See in real-time ✅
```

---

## 🎉 Success! Ab kya करें?

1. **Testing Guide** पढ़ें: `TESTING_GUIDE_HINDI.md`
2. **API Documentation** देखें: `API_INTEGRATION_HINDI.md`
3. **Custom Features** add करें अपने हिसाब से

---

**Happy Coding! 🚀**

All APIs integrated and tested हैं! Static data remove हो चुका है!
