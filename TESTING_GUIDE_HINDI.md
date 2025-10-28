# 🧪 Complete Testing Guide - Step by Step

## पहले Backend को Start करें

### Step 1: Backend Server Start करें

```bash
# Terminal 1 - Backend Directory में जाएं
cd C:\FlutterDev\project\Clone\harborleaf_radio_backend

# Dependencies install करें (पहली बार)
npm install

# .env file check करें
# PORT=5000
# MONGODB_URI=your_mongodb_uri
# JWT_SECRET=your_secret_key
# JWT_EXPIRE=30d

# Server start करें
npm start

# या development mode में
npm run dev
```

**Expected Output:**
```
✅ Server running on port 5000
✅ MongoDB Connected
✅ Socket.IO initialized
```

---

## अब Flutter App को Test करें

### Step 2: Flutter Dependencies Install करें

```bash
# Terminal 2 - Flutter App Directory
cd C:\FlutterDev\project\Clone\harborleaf_radio_app

# Dependencies install करें
flutter pub get

# Check करें कि सब install हो गया
flutter doctor
```

---

### Step 3: Base URL Configure करें

`lib/core/constants/api_endpoints.dart` file खोलें और check करें:

```dart
// Android Emulator के लिए
static const String baseUrl = 'http://10.0.2.2:5000/api';
static const String socketUrl = 'http://10.0.2.2:5000';

// Physical Device के लिए (अपना IP डालें)
// static const String baseUrl = 'http://192.168.1.100:5000/api';
// static const String socketUrl = 'http://192.168.1.100:5000';

// iOS Simulator के लिए
// static const String baseUrl = 'http://localhost:5000/api';
// static const String socketUrl = 'http://localhost:5000';
```

**अपना Local IP पता करने के लिए:**
```bash
# Windows
ipconfig

# आपका IPv4 Address देखें (जैसे: 192.168.1.100)
```

---

### Step 4: App Run करें

```bash
# Android Emulator या Device में run करें
flutter run

# या specific device के लिए
flutter devices  # Available devices देखें
flutter run -d <device-id>
```

---

## 🧪 Testing Steps - Screen by Screen

### Test 1: Authentication Flow

#### 1.1 Register New User
```
1. App खोलें
2. Registration screen पर जाएं
3. Fill करें:
   - Name: Test User
   - Mobile: 9876543210
   - State: Maharashtra
4. "Register" button दबाएं
5. Console में OTP देखें (Backend terminal में)
```

**Backend Console में दिखेगा:**
```
Sending OTP 123456 to mobile: 9876543210
```

#### 1.2 Verify OTP
```
1. OTP enter करें (जो console में दिखा)
2. "Verify" button दबाएं
3. Success होने पर Home Screen खुलेगी
```

**Check Points:**
- ✅ Token save हो गया (SharedPreferences में)
- ✅ User profile load हो गया
- ✅ WebSocket connected हो गया

---

### Test 2: Dialer Screen (Frequency Management)

#### 2.1 Load Frequencies
```
1. Dialer Screen खोलें
2. Automatic frequencies load होंगी
```

**Console में check करें:**
```
✅ HTTP Request: GET http://10.0.2.2:5000/api/frequencies
✅ HTTP Response: 200
✅ Loaded X frequencies
```

**अगर Error आए:**
```
🔴 Error Loading Frequencies:
- Check: Backend running है?
- Check: Base URL सही है?
- Check: Network permission है?
```

#### 2.2 Join Frequency
```
1. Frequency slider घुमाएं (450.0 MHz पर)
2. "Join" या frequency पर tap करें
3. Join success होना चाहिए
```

**Console में check करें:**
```
✅ HTTP Request: POST /api/frequencies/:id/join
✅ Socket.IO: join_frequency event sent
✅ Joined frequency successfully
```

#### 2.3 Real-time Updates Test
```
1. दूसरा device/emulator open करें
2. Same frequency join करें
3. पहले device में user count बढ़ना चाहिए
```

**Socket Events:**
```
✅ user_joined event received
✅ frequency_users_update event received
✅ UI updated with new user count
```

---

### Test 3: Groups

#### 3.1 Load Groups
```
1. Groups section खोलें
2. "My Groups" देखें
```

**Console:**
```
✅ HTTP Request: GET /api/groups
✅ Loaded X groups
```

#### 3.2 Create New Group
```
1. "Create Group" button दबाएं
2. Fill करें:
   - Name: Test Emergency Team
   - Description: Emergency response team
   - Select frequency (optional)
3. "Create" दबाएं
```

**Console:**
```
✅ HTTP Request: POST /api/groups
✅ Group created successfully
✅ Socket.IO: join_group event sent
```

#### 3.3 Join Group
```
1. Available groups में से एक select करें
2. "Join" दबाएं
```

**Console:**
```
✅ HTTP Request: POST /api/groups/:id/join
✅ Joined group
✅ Socket connected to group room
```

---

### Test 4: Communication Screen (Messages)

#### 4.1 Load Messages
```
1. Group select करके Communication Screen खोलें
2. Messages automatic load होंगी
```

**Console:**
```
✅ HTTP Request: GET /api/communication/messages?recipientType=group&recipientId=...
✅ Loaded X messages
✅ Socket.IO: join_group event
```

#### 4.2 Send Text Message
```
1. Message type करें: "Hello from Flutter App!"
2. Send button दबाएं
3. Message तुरंत appear होना चाहिए
```

**Console:**
```
✅ Socket.IO: send_message event
✅ Message sent via WebSocket
```

#### 4.3 Real-time Message Test
```
1. दूसरे device से same group में message भेजें
2. पहले device में तुरंत message दिखना चाहिए
```

**Socket Events:**
```
✅ message_received event
✅ New message added to list
✅ UI updated
```

#### 4.4 Reactions Test
```
1. किसी message पर long press करें
2. Reaction select करें (👍, ❤️, etc)
3. Reaction add होना चाहिए
```

**Console:**
```
✅ Socket.IO: add_reaction event
✅ reaction_added event received
✅ UI updated with reaction
```

---

### Test 5: Live Radio Screen (Audio Communication)

#### 5.1 Join Frequency for Live Communication
```
1. Live Radio Screen खोलें
2. Frequency select करें
3. "Connect" दबाएं
```

**Console:**
```
✅ HTTP Request: POST /api/frequencies/:id/join
✅ Socket.IO: join_frequency event
✅ Connected to frequency
```

#### 5.2 Start Transmission
```
1. PTT (Push-to-Talk) button hold करें
2. Speaking animation start होना चाहिए
3. Release करने पर stop होना चाहिए
```

**Console:**
```
✅ Socket.IO: start_transmission event
✅ transmission_started event received
✅ Audio recording started
```

---

## 🔍 Debug करने के तरीके

### 1. Network Calls Check करें

**Flutter DevTools में:**
```bash
# DevTools open करें
flutter pub global activate devtools
flutter pub global run devtools

# App run करें with DevTools
flutter run --observatory-port=9200
```

**Network tab में देखें:**
- सभी HTTP requests
- Response status codes
- Response data

### 2. Console Logs Check करें

**Backend में:**
```javascript
// server.js में debug logs add करें
console.log('API Called:', req.method, req.path);
console.log('Request Body:', req.body);
console.log('User:', req.user);
```

**Flutter में:**
```dart
// कहीं भी debug print करें
print('Current Frequency: $_frequency');
print('Messages Count: ${_messages.length}');
print('Socket Connected: ${_socketClient.isConnected}');
```

### 3. Common Errors और Solutions

#### Error: "No Internet Connection"
**Solution:**
```
1. Backend running check करें
2. Base URL सही है verify करें
3. Emulator/Device network working है check करें
4. Firewall block तो नहीं कर रहा
```

#### Error: "Token Expired"
**Solution:**
```
1. Logout करें
2. फिर से Login करें
3. New token generate होगा
```

#### Error: "Socket Connection Failed"
**Solution:**
```
1. Backend में Socket.IO initialized है check करें
2. CORS settings check करें
3. Token valid है verify करें
```

#### Error: "Frequencies Not Loading"
**Solution:**
```
1. Backend में कुछ frequencies create करें (Postman से)
2. Database connected है check करें
3. API endpoint correct है verify करें
```

---

## 📊 Testing Checklist

### Authentication ✅
- [ ] Registration working
- [ ] OTP sending
- [ ] OTP verification
- [ ] Token storage
- [ ] Auto-login on app restart
- [ ] Logout

### Frequencies ✅
- [ ] Load all frequencies
- [ ] Load popular frequencies
- [ ] Search frequencies
- [ ] Join frequency
- [ ] Leave frequency
- [ ] Create frequency
- [ ] Real-time user updates

### Groups ✅
- [ ] Load user groups
- [ ] Create group
- [ ] Join group
- [ ] Leave group
- [ ] Update group
- [ ] Delete group
- [ ] Invite members
- [ ] Real-time member updates

### Messages ✅
- [ ] Load messages
- [ ] Send text message
- [ ] Send audio message
- [ ] Add reaction
- [ ] Delete message
- [ ] Mark as read
- [ ] Real-time message delivery
- [ ] Typing indicators

### WebSocket ✅
- [ ] Connection established
- [ ] Auto-reconnect on disconnect
- [ ] All events working
- [ ] Real-time updates
- [ ] Multiple users sync

---

## 🎯 Performance Testing

### Load Test
```
1. Multiple users (5-10) simultaneously:
   - Same frequency join करें
   - Messages rapidly send करें
   - Check: Lag नहीं होना चाहिए

2. Large message history:
   - 100+ messages load करें
   - Smooth scrolling होनी चाहिए
   - Memory leak नहीं होना चाहिए
```

### Network Test
```
1. Slow network पर test करें:
   - Loading states दिखने चाहिए
   - Error messages proper हों
   - Retry mechanism work करे

2. Offline/Online switching:
   - Offline होने पर proper error
   - Online होने पर auto-reconnect
```

---

## 🚀 Production Deployment Testing

### Before Production:
```
1. Base URL change करें (production server)
2. Debug logs disable करें
3. Error handling proper है verify करें
4. Security:
   - Token storage secure है
   - API keys exposed नहीं हैं
   - HTTPS use हो रहा है
```

---

## 📱 Device-specific Testing

### Android
```
- Emulator: API 30+ test करें
- Real Device: Different Android versions
- Permissions: Network, Microphone (for audio)
```

### iOS
```
- Simulator: Latest iOS version
- Real Device: Different iPhone models
- Permissions: Network, Microphone
```

---

## 🎉 Success Criteria

**App Ready है अगर:**
- ✅ सभी APIs काम कर रही हैं
- ✅ Real-time updates मिल रहे हैं
- ✅ No crashes या major bugs
- ✅ UI smooth और responsive है
- ✅ Error handling proper है
- ✅ Multiple users simultaneously work कर सकते हैं

---

## 🆘 Help & Support

**अगर कोई issue आए तो:**

1. **Console Logs देखें** (Backend + Flutter दोनों)
2. **Network Tab** check करें (DevTools में)
3. **Error Message** carefully पढ़ें
4. **Backend API** directly test करें (Postman से)
5. **Token** valid है verify करें

**Common Commands:**
```bash
# Backend logs देखें
npm run dev

# Flutter logs देखें
flutter run -v

# Clear cache
flutter clean
flutter pub get

# Restart everything
# Backend: Ctrl+C then npm start
# Flutter: Press 'r' in terminal या hot reload
```

---

**Ab test करना start करें! Good Luck! 🚀**
