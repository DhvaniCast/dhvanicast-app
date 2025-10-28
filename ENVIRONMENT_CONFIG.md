# 🌍 Environment Configuration Guide
## Local vs Production Backend URLs

---

## 📋 Quick Switch Guide

### **Currently Active: PRODUCTION** 🌐

```dart
// File: lib/core/constants/api_endpoints.dart
static const Environment _currentEnvironment = Environment.production;
```

**Production URLs:**
```
API:    https://dhvani-cast-radio-backend.onrender.com/api
Socket: https://dhvani-cast-radio-backend.onrender.com
```

---

## 🔄 How to Switch Environments

### **Switch to PRODUCTION (Deployment URL):**

**File:** `lib/core/constants/api_endpoints.dart`

```dart
// Line 12: Change this line
static const Environment _currentEnvironment = Environment.production;
// static const Environment _currentEnvironment = Environment.local;  // Comment out
```

**URLs Used:**
- API: `https://dhvani-cast-radio-backend.onrender.com/api`
- Socket: `https://dhvani-cast-radio-backend.onrender.com`
- **Transport:** WebSocket with polling fallback
- **Timeout:** 20 seconds
- **Reconnection:** 5 attempts with exponential backoff

---

### **Switch to LOCAL (Testing on Emulator):**

**File:** `lib/core/constants/api_endpoints.dart`

```dart
// Line 12: Change this line
// static const Environment _currentEnvironment = Environment.production;  // Comment out
static const Environment _currentEnvironment = Environment.local;
```

**URLs Used:**
- API: `http://10.0.2.2:5000/api` (Android Emulator)
- Socket: `http://10.0.2.2:5000`
- **Transport:** WebSocket with polling fallback
- **Timeout:** 10 seconds
- **Reconnection:** 5 attempts

---

## 🔌 WebSocket Configuration

### **New Features (v2.0):**

✅ **Dual Transport Support**
- Primary: WebSocket (`ws://` or `wss://`)
- Fallback: Long-polling (if WebSocket fails)

✅ **Production Optimizations**
- Longer timeout (20s vs 10s)
- Better reconnection strategy
- Enhanced error logging
- Connection info debugging

✅ **Enhanced Logging**
```dart
print('🔌 Connecting to Socket.IO...');
print('📡 URL: $socketUrl');
print('🌍 Environment: ${ApiEndpoints.environmentName}');
print('✅ Socket.IO Connected to ${ApiEndpoints.socketUrl}');
print('🎯 Transport: websocket/polling');
```

### **Connection Flow:**

1. **Initial Connection Attempt**
   - Try WebSocket first
   - If fails, fallback to polling
   - Retry up to 5 times with delays

2. **Reconnection Strategy**
   - Attempt 1: 1 second delay
   - Attempt 2: 2 seconds delay
   - Attempt 3: 3 seconds delay
   - Attempt 4: 4 seconds delay
   - Attempt 5: 5 seconds delay
   - Max delay: 5 seconds

---

## 🎯 Testing Steps

### **1. Production Testing**

```bash
# Step 1: Set environment to PRODUCTION in api_endpoints.dart
# Step 2: Run app
cd C:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run

# Step 3: Check logs
# You should see:
# 🌐 HTTP Request: POST https://dhvani-cast-radio-backend.onrender.com/api/auth/send-otp
```

### **2. Local Testing**

```bash
# Step 1: Start local backend first
cd C:\FlutterDev\project\Clone\harborleaf_radio_backend
node server.js

# Step 2: Set environment to LOCAL in api_endpoints.dart
# Step 3: Run app
cd C:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run

# Step 4: Check logs
# You should see:
# 🌐 HTTP Request: POST http://10.0.2.2:5000/api/auth/send-otp
```

---

## 🔍 Verification

### **Check Current Environment in Code:**

```dart
import 'package:harborleaf_radio_app/core/constants/api_endpoints.dart';

void checkEnvironment() {
  print('🌍 Environment: ${ApiEndpoints.environmentName}');
  print('📡 Base URL: ${ApiEndpoints.baseUrl}');
  print('🔌 Socket URL: ${ApiEndpoints.socketUrl}');
  print('🏭 Is Production: ${ApiEndpoints.isProduction}');
  print('🏠 Is Local: ${ApiEndpoints.isLocal}');
}
```

**Expected Output (Production):**
```
🌍 Environment: PRODUCTION
📡 Base URL: https://dhvani-cast-radio-backend.onrender.com/api
🔌 Socket URL: https://dhvani-cast-radio-backend.onrender.com
🏭 Is Production: true
🏠 Is Local: false
```

**Expected Output (Local):**
```
🌍 Environment: LOCAL
📡 Base URL: http://10.0.2.2:5000/api
🔌 Socket URL: http://10.0.2.2:5000
🏭 Is Production: false
🏠 Is Local: true
```

---

## 📱 Device-Specific URLs

### **Android Emulator:**
```dart
Environment.local → 'http://10.0.2.2:5000'
```

### **iOS Simulator:**
If you need iOS support, add:
```dart
static String get baseUrl {
  switch (_currentEnvironment) {
    case Environment.local:
      // iOS Simulator:
      return 'http://localhost:5000/api';
      // Android Emulator:
      // return 'http://10.0.2.2:5000/api';
    case Environment.production:
      return 'https://dhvani-cast-radio-backend.onrender.com/api';
  }
}
```

### **Physical Device (Same Network):**
Add new environment:
```dart
enum Environment {
  local,
  localDevice,  // Add this
  production,
}

// In switch case:
case Environment.localDevice:
  return 'http://192.168.1.100:5000/api';  // Your computer's IP
```

---

## 🐛 Common Issues

### **Issue 1: Connection Refused (Local)**

**Problem:**
```
❌ Network error: Connection refused
```

**Solution:**
1. Check backend is running: `node server.js`
2. Verify port 5000 is accessible
3. Check firewall settings

### **Issue 2: Timeout (Production)**

**Problem:**
```
❌ Request timeout
```

**Solution:**
1. Check internet connection
2. Verify production backend is online: Visit `https://dhvani-cast-radio-backend.onrender.com/health`
3. Wait if backend is in cold start (Render free tier)

### **Issue 3: SSL Certificate Error (Production)**

**Problem:**
```
❌ SSL handshake failed
```

**Solution:**
1. Ensure HTTPS is used (not HTTP)
2. Check Android network security config
3. Verify production SSL certificate is valid

---

## 🎨 Environment Indicator in App

Add this widget to show current environment:

```dart
// lib/core/widgets/environment_banner.dart
import 'package:flutter/material.dart';
import '../constants/api_endpoints.dart';

class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ApiEndpoints.isProduction) {
      return const SizedBox.shrink(); // Hide in production
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.orange,
      child: Text(
        '🔧 ${ApiEndpoints.environmentName} MODE - ${ApiEndpoints.baseUrl}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

**Usage:**
```dart
// In your Scaffold:
body: Column(
  children: [
    const EnvironmentBanner(),  // Shows in LOCAL mode only
    // ... rest of your widgets
  ],
),
```

---

## 📊 Environment Comparison

| Feature | LOCAL | PRODUCTION |
|---------|-------|------------|
| **Backend** | Your computer | Render.com |
| **Database** | Local MongoDB | Cloud MongoDB |
| **Speed** | ⚡ Fast | 🐌 Network dependent |
| **Offline** | ❌ Needs backend running | ❌ Needs internet |
| **Debug** | ✅ Easy | ⚠️ Limited |
| **Testing** | ✅ Perfect | ⚠️ Slow cold starts |
| **Production** | ❌ Not suitable | ✅ Ready |

---

## ✅ Final Checklist

### **Before Testing:**
- [ ] Environment set correctly in `api_endpoints.dart`
- [ ] Backend running (if LOCAL mode)
- [ ] Internet connection (if PRODUCTION mode)
- [ ] Correct device/emulator type

### **After Changing Environment:**
```bash
# Option 1: Hot Reload (if app is running)
Press 'r' in terminal

# Option 2: Hot Restart (recommended)
Press 'R' in terminal

# Option 3: Full Restart
Press 'q' then flutter run again
```

---

## 🚀 Quick Commands

### **Start Local Backend:**
```powershell
cd C:\FlutterDev\project\Clone\harborleaf_radio_backend
node server.js
```

### **Start Flutter App:**
```powershell
cd C:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run
```

### **Check Production Backend Status:**
```powershell
curl https://dhvani-cast-radio-backend.onrender.com/health
```

---

## 📝 Summary

**Easy 3-Step Process:**

1. **Edit** `lib/core/constants/api_endpoints.dart` (Line 12)
2. **Choose** Environment (production or local)
3. **Restart** Flutter app

**No other files need to be changed!** 🎉

---

**Current Configuration:** ✅ **PRODUCTION MODE ACTIVE**

Ready to connect to: `https://dhvani-cast-radio-backend.onrender.com` 🌐
