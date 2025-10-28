# API Integration Testing Guide with Logs
## हर Screen की Complete Testing करें

यह guide आपको step-by-step बताएगी कि कैसे API integration test करें और logs check करें।

---

## 📋 Pre-Testing Checklist

### 1. Backend Server Running?
```powershell
cd C:\FlutterDev\project\Clone\harborleaf_radio_backend
node server.js
```

**Expected Output:**
```
✅ Server running on port 5000
✅ MongoDB connected
✅ Socket.IO initialized
```

### 2. Flutter App Base URL Check
File: `lib/core/constants/api_endpoints.dart`
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator
static const String socketUrl = 'http://10.0.2.2:5000';
```

### 3. Services Registered?
File: `lib/injection.dart`
```dart
// ✅ Check these are registered:
- HttpClient
- FrequencyRepository
- GroupRepository
- CommunicationRepository
- WebSocketClient
- DialerService
- CommunicationService
```

---

## 🧪 Testing Flow - Step by Step

### STEP 1: App Launch
```powershell
cd C:\FlutterDev\project\Clone\harborleaf_radio_app
flutter run
```

**Expected Logs:**
```
✅ Launching lib/main.dart
✅ Service Locator Setup Complete
```

---

### STEP 2: Login/Authentication

**Test:** Login with credentials

**Expected Logs in Terminal:**
```
🔐 AuthService: Logging in user...
📤 HTTP POST: http://10.0.2.2:5000/api/auth/login
✅ Login successful - Token received
```

**अगर Error आए:**
```
❌ HTTP Error: Connection refused
```
👉 **Solution:** Backend server check करें (node server.js running?)

```
❌ Error 401: Invalid credentials
```
👉 **Solution:** Username/password check करें

---

### STEP 3: Dialer Screen (Frequency Loading)

**Test:** Open Dialer Screen

**Expected Logs:**
```
🚀 DialerScreen: Initializing...
📥 DialerScreen: Loading initial data from API...
📤 HTTP GET: http://10.0.2.2:5000/api/frequencies?band=UHF&isPublic=true&page=1&limit=100
✅ Frequencies loaded: 10
📤 HTTP GET: http://10.0.2.2:5000/api/groups?page=1&limit=50
✅ Groups loaded: 5
✅ WebSocket listeners setup complete
📡 DialerScreen: Service updated
📊 Frequencies count: 10
👥 Groups count: 5
```

**अगर Static Data दिख रहा है:**
```
❌ Frequencies count: 0
```
👉 **Problem:** API call fail हो रही है या backend में data नहीं है

**Debug:**
```
1. Backend में frequencies exist करते हैं? 
   - MongoDB check करें
   
2. API endpoint सही है?
   - Postman से test करें: GET http://10.0.2.2:5000/api/frequencies
   
3. Token pass हो रहा है?
   - HttpClient में header check करें
```

---

### STEP 4: Active Groups Button Click

**Test:** "Active Groups" button दबाएं

**Expected Logs:**
```
👥 Showing 5 active groups from API
```

**Screen पर Expected:**
- API से groups की list
- Group name, members count
- Online status

**अगर Empty दिखे:**
```
No active groups found
```
👉 **Solution:** Backend में groups create करें

**Quick Create Group via Postman:**
```
POST http://10.0.2.2:5000/api/groups
Headers: Authorization: Bearer YOUR_TOKEN
Body: {
  "name": "Test Group",
  "description": "Testing group",
  "isPublic": true
}
```

---

### STEP 5: Frequency Users Check

**Test:** किसी frequency पर users देखें

**Expected Logs:**
```
👥 Users on 450.0 MHz: 3
```

**Debug:** अगर 0 users दिख रहे हैं:
```
1. Backend में frequency join किया गया है?
2. ActiveUsers array populate हो रहा है?
```

---

### STEP 6: JOIN Frequency

**Test:** JOIN button दबाएं

**Expected Logs:**
```
🔗 Attempting to join frequency: 450.0 MHz
🎯 JOIN button pressed - Calling API...
📤 HTTP POST: http://10.0.2.2:5000/api/frequencies/:id/join
✅ Successfully joined frequency via API
🔌 WebSocket: Joining frequency 450.0 MHz
```

**Navigation:**
```
✅ Navigate to Live Radio Screen
```

**अगर Error:**
```
❌ Failed to join frequency via API
Error: Frequency not found
```
👉 **Solution:** Frequency ID check करें, या नया frequency create करें

---

### STEP 7: Live Radio Screen

**Test:** Frequency join करने के बाद

**Expected Logs:**
```
🚀 LiveRadioScreen: Initializing...
📡 Connected to frequency 450.0 MHz
👥 Connected users: 3
```

**Screen पर Expected:**
- Connected users की grid
- Audio wave animation
- Control buttons (Mute, Speaker, Chat)

---

### STEP 8: Communication Screen (Messages)

**Test:** Chat button दबाएं या Group में जाएं

**Expected Logs:**
```
🚀 CommunicationScreen: Initializing...
📦 Received group data: {id: group123, name: Test Group}
🆔 Group ID: group123
📥 CommunicationScreen: Loading group data for group123
📤 HTTP GET: http://10.0.2.2:5000/api/groups/group123
✅ Group loaded: Test Group
📤 HTTP GET: http://10.0.2.2:5000/api/messages?recipientType=group&recipientId=group123
✅ Messages loaded: 15
✅ WebSocket listeners setup complete
📡 CommunicationScreen: Service updated
💬 Messages count: 15
```

**Screen पर Expected:**
- Past messages API से
- Real-time typing indicators
- Online members

**अगर Empty दिखे:**
```
No messages yet
Send first message to start
```
👉 **यह normal है अगर नया group है**

---

### STEP 9: Send Message

**Test:** Message type करें और send करें

**Expected Logs:**
```
📤 Sending message via API: Hello from API test
📤 HTTP POST: http://10.0.2.2:5000/api/messages
Body: {recipientType: group, recipientId: group123, messageType: text, content: {text: Hello from API test}}
✅ Message sent successfully
🔌 WebSocket: Emitting message_sent event
📡 CommunicationScreen: Service updated
💬 Messages count: 16
```

**अगर Fail:**
```
❌ Failed to send message: Unauthorized
```
👉 **Token expired हो सकता है, re-login करें**

---

### STEP 10: Push to Talk (Audio Message)

**Test:** PTT button hold करें

**Expected Logs:**
```
🎤 Recording started
// Hold button...
🎤 Recording stopped - Sending audio message via API...
📤 WebSocket: Emitting audio_transmission event
✅ Audio message sent successfully
```

---

## 🐛 Common Problems & Solutions

### Problem 1: "Frequencies count: 0"
**Reason:** Backend में data नहीं है या API fail

**Solution:**
```powershell
# Backend terminal में check करें:
GET /api/frequencies called
MongoDB query returned 0 results

# Fix: Sample data create करें
cd harborleaf_radio_backend
node scripts/seed-frequencies.js
```

### Problem 2: "Connection refused"
**Reason:** Backend running नहीं है

**Solution:**
```powershell
cd C:\FlutterDev\project\Clone\harborleaf_radio_backend
node server.js
```

### Problem 3: "Static data दिख रहा है"
**Reason:** Screen में अभी भी old code है

**Check:** 
```dart
// ❌ Wrong - Static data
final List<Map> _messages = [...];

// ✅ Correct - API data
_commService.messages
```

### Problem 4: "WebSocket not connecting"
**Logs:**
```
❌ WebSocket: Connection failed
```

**Solution:**
```dart
// Check WebSocketClient initialization
WebSocketClient().connect(); // Call this in main.dart or service
```

---

## ✅ Complete Testing Checklist

### Dialer Screen:
- [ ] Frequencies load होती हैं (count > 0)
- [ ] Groups load होते हैं (count > 0)
- [ ] User count हर frequency पर सही दिखता है
- [ ] JOIN button API call करता है
- [ ] Auto-tune काम करता है

### Communication Screen:
- [ ] Messages API से load होते हैं
- [ ] Send message API call करता है
- [ ] PTT audio message send करता है
- [ ] Real-time messages receive होते हैं
- [ ] Members list API से आती है

### Live Radio Screen:
- [ ] Connected users API से दिखते हैं
- [ ] Frequency info सही है
- [ ] WebSocket connected है

---

## 📊 Success Metrics

**✅ API Integration Successful अगर:**
1. कोई भी static array use नहीं हो रहा (`_messages`, `_activeGroups`, etc.)
2. हर screen में API calls के logs दिखते हैं
3. Backend में corresponding logs दिखते हैं
4. Data real-time update होता है
5. WebSocket events trigger होती हैं

---

## 🔍 Debug Commands

### Check API Endpoints:
```powershell
# PowerShell में test करें
Invoke-WebRequest -Uri "http://localhost:5000/api/frequencies" -Headers @{"Authorization"="Bearer YOUR_TOKEN"}
```

### Check WebSocket:
```javascript
// Browser console में
const socket = io('http://localhost:5000');
socket.on('connect', () => console.log('✅ Connected'));
socket.emit('join_frequency', {frequencyId: 'test'});
```

### Check MongoDB:
```powershell
# MongoDB Shell
use harborleaf_radio
db.frequencies.find()
db.groups.find()
db.messages.find()
```

---

## 📝 Testing Report Template

```
Date: __________
Tester: __________

DIALER SCREEN:
[ ] API calls working: YES / NO
[ ] Frequencies loaded: ____ items
[ ] Groups loaded: ____ items
[ ] Logs visible: YES / NO
[ ] Issues: ________________

COMMUNICATION SCREEN:
[ ] Messages from API: YES / NO
[ ] Send message working: YES / NO
[ ] WebSocket connected: YES / NO
[ ] Issues: ________________

LIVE RADIO SCREEN:
[ ] Users visible: YES / NO
[ ] Audio controls: YES / NO
[ ] Issues: ________________

OVERALL STATUS: PASS / FAIL
```

---

## 🎯 Next Steps After Testing

अगर सब ✅ है:
1. Static data वाली सभी files delete करें
2. Production build test करें
3. Error handling add करें

अगर ❌ errors हैं:
1. इस guide के Debug section follow करें
2. Backend logs check करें
3. Network inspector use करें
4. मुझे बताएं, मैं help करूंगा! 😊
