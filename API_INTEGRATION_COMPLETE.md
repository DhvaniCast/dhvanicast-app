# API Integration Summary

## ✅ Complete Backend API Integration

All backend APIs have been integrated into the Flutter app. Here's the complete implementation:

---

## 📁 Models Created

### 1. **FrequencyModel** (`lib/data/models/frequency_model.dart`)
- Complete frequency data structure
- Includes active users, band info, and stats
- Handles UHF/VHF frequency range (320-650 MHz)

### 2. **GroupModel** (`lib/data/models/group_model.dart`)
- Group structure with members and settings
- Member roles and permissions
- Online status tracking

### 3. **MessageModel** (`lib/data/models/message_model.dart`)
- Text and audio message support
- Reactions and read receipts
- Priority levels (normal, high, emergency)

---

## 🔌 API Endpoints (`lib/core/constants/api_endpoints.dart`)

### Base Configuration
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
static const String socketUrl = 'http://10.0.2.2:5000';
```

### All Endpoints Integrated:

#### **Authentication**
- ✅ POST `/auth/register` - User registration
- ✅ POST `/auth/send-otp` - Send OTP for login
- ✅ POST `/auth/verify-otp` - Verify OTP
- ✅ GET `/auth/profile` - Get user profile
- ✅ PUT `/auth/profile` - Update profile
- ✅ POST `/auth/logout` - Logout

#### **Frequencies**
- ✅ GET `/frequencies` - Get all frequencies (with filters)
- ✅ GET `/frequencies/popular` - Get popular frequencies
- ✅ GET `/frequencies/band/:band` - Get by band (UHF/VHF)
- ✅ GET `/frequencies/:id` - Get specific frequency
- ✅ POST `/frequencies` - Create new frequency
- ✅ POST `/frequencies/:id/join` - Join frequency
- ✅ POST `/frequencies/:id/leave` - Leave frequency
- ✅ PUT `/frequencies/:id` - Update frequency
- ✅ DELETE `/frequencies/:id` - Delete frequency
- ✅ GET `/frequencies/:id/stats` - Get statistics
- ✅ GET `/frequencies/search` - Search frequencies

#### **Groups**
- ✅ GET `/groups` - Get user's groups
- ✅ GET `/groups/:id` - Get specific group
- ✅ POST `/groups` - Create new group
- ✅ POST `/groups/:id/join` - Join group
- ✅ POST `/groups/:id/leave` - Leave group
- ✅ POST `/groups/:id/invite` - Invite user to group
- ✅ PUT `/groups/:id` - Update group
- ✅ PUT `/groups/:id/members/role` - Update member role
- ✅ DELETE `/groups/:id` - Delete group
- ✅ DELETE `/groups/:id/members/remove` - Remove member
- ✅ GET `/groups/:id/stats` - Get group statistics
- ✅ GET `/groups/search` - Search groups

#### **Communication/Messages**
- ✅ GET `/communication/messages` - Get messages
- ✅ POST `/communication/send` - Send message
- ✅ POST `/communication/:id/reaction` - Add reaction
- ✅ DELETE `/communication/:id/reaction` - Remove reaction
- ✅ DELETE `/communication/:id` - Delete message
- ✅ POST `/communication/forward` - Forward message
- ✅ GET `/communication/search` - Search messages
- ✅ GET `/communication/stats` - Get message statistics
- ✅ GET `/communication/unread` - Get unread count
- ✅ POST `/communication/mark-read` - Mark as read

---

## 📚 Repositories Created

### 1. **AuthRepository** (`lib/data/repositories/auth_repository.dart`)
All authentication methods already implemented with JWT handling.

### 2. **FrequencyRepository** (`lib/data/repositories/frequency_repository.dart`)
Complete frequency management:
```dart
- getAllFrequencies({page, limit, band, isPublic, search})
- getPopularFrequencies({limit})
- getFrequenciesByBand(band)
- getFrequencyById(id)
- createFrequency({frequency, name, description, isPublic})
- joinFrequency(id)
- leaveFrequency(id)
- updateFrequency(id, {name, description, isPublic})
- deleteFrequency(id)
- getFrequencyStats(id)
- searchFrequencies(query)
```

### 3. **GroupRepository** (`lib/data/repositories/group_repository.dart`)
Complete group management:
```dart
- getUserGroups({page, limit})
- getGroupById(id)
- createGroup({name, description, avatar, frequencyId, settings})
- updateGroup(id, {name, description, avatar, settings})
- deleteGroup(id)
- joinGroup(id)
- leaveGroup(id)
- inviteToGroup(groupId, userId)
- updateMemberRole(groupId, userId, role)
- removeMember(groupId, userId)
- getGroupStats(id)
- searchGroups(query)
```

### 4. **CommunicationRepository** (`lib/data/repositories/communication_repository.dart`)
Complete messaging system:
```dart
- getMessages({recipientType, recipientId, page, limit, messageType, priority, since, before})
- sendMessage({recipientType, recipientId, messageType, content, priority, replyTo, mentions})
- addReaction(messageId, emoji)
- removeReaction(messageId, emoji)
- deleteMessage(messageId)
- forwardMessage(messageId, recipientType, recipientId)
- searchMessages({query, recipientType, recipientId, page, limit})
- getMessageStats({recipientType, recipientId})
- getUnreadCount({recipientType, recipientId})
- markAsRead({messageIds, recipientType, recipientId})
```

---

## 🔌 WebSocket Client (`lib/data/network/websocket_client.dart`)

Complete real-time communication with Socket.IO:

### Connection Management
```dart
- connect(token) - Connect with JWT token
- disconnect() - Disconnect
- reconnect() - Reconnect
```

### Frequency Events
```dart
- joinFrequency(frequencyId, {userInfo})
- leaveFrequency(frequencyId)
- startTransmission(frequencyId)
- stopTransmission(frequencyId)
- sendAudioData(audioChunk)
- updateSignalStrength(frequencyId, strength)
- getFrequencyUsers(frequencyId)
- scanFrequencies({minFreq, maxFreq})
```

### Group Events
```dart
- joinGroup(groupId, {memberInfo})
- leaveGroup(groupId)
- startSpeaking(groupId)
- stopSpeaking(groupId)
- sendGroupAudioData(audioData)
- getGroupMembers(groupId)
```

### Message Events
```dart
- sendMessage(messageData)
- sendAudioMessage(audioData)
- typingStart(recipientType, recipientId)
- typingStop(recipientType, recipientId)
- addReaction(messageId, emoji)
- removeReaction(messageId, emoji)
- markMessagesRead(recipientType, recipientId, messageIds)
- deleteMessage(messageId)
- forwardMessage(messageId, recipientType, recipientId)
```

### Event Listeners
```dart
- on(event, callback) - Listen to any socket event
- off(event) - Remove listener
```

### Server Events to Listen:
- `message_received` - New message
- `user_joined` - User joined frequency/group
- `user_left` - User left
- `transmission_started` - Someone started transmitting
- `transmission_stopped` - Transmission stopped
- `audio_stream` - Incoming audio data
- `typing_indicator` - Typing status
- `reaction_added` - New reaction
- `message_deleted` - Message deleted
- `frequency_users_update` - User list updated
- `group_members_update` - Members updated
- `scan_results` - Frequency scan results

---

## 🎯 Integration Status

### ✅ Completed
1. **All Models** - FrequencyModel, GroupModel, MessageModel with complete data structures
2. **All API Endpoints** - Defined in ApiEndpoints class
3. **All Repositories** - Frequency, Group, Communication repositories
4. **WebSocket Client** - Complete Socket.IO integration
5. **Query Parameter Handling** - Helper method `_buildUrl()` in repositories
6. **Error Handling** - Consistent error handling across all APIs
7. **Response Parsing** - ApiResponse wrapper for all API calls

### 📦 Package Added
- `socket_io_client: ^2.0.3+1` added to `pubspec.yaml`

---

## 🚀 Next Steps for Screen Integration

### 1. Dialer Screen Integration
```dart
// In dialer_screen.dart
import 'package:harborleaf_radio_app/data/repositories/frequency_repository.dart';
import 'package:harborleaf_radio_app/data/network/websocket_client.dart';

final _frequencyRepo = FrequencyRepository();
final _socketClient = WebSocketClient();

// Load frequencies
void loadFrequencies() async {
  final response = await _frequencyRepo.getAllFrequencies(
    band: 'UHF',
    page: 1,
    limit: 50,
  );
  
  if (response.success && response.data != null) {
    setState(() {
      frequencies = response.data!;
    });
  }
}

// Join frequency
void joinFrequency(String frequencyId) async {
  // HTTP API Call
  await _frequencyRepo.joinFrequency(frequencyId);
  
  // Socket connection
  _socketClient.joinFrequency(frequencyId, userInfo: {
    'callSign': userCallSign,
    'location': userLocation,
    'avatar': userAvatar,
  });
  
  // Listen for updates
  _socketClient.on('user_joined', (data) {
    // Update UI when someone joins
  });
}
```

### 2. Communication Screen Integration
```dart
import 'package:harborleaf_radio_app/data/repositories/communication_repository.dart';
import 'package:harborleaf_radio_app/data/repositories/group_repository.dart';

final _commRepo = CommunicationRepository();
final _groupRepo = GroupRepository();

// Load messages
void loadMessages() async {
  final response = await _commRepo.getMessages(
    recipientType: 'group',
    recipientId: currentGroupId,
    page: 1,
    limit: 50,
  );
  
  if (response.success && response.data != null) {
    setState(() {
      messages = response.data!;
    });
  }
}

// Send message
void sendMessage(String text) async {
  _socketClient.sendMessage({
    'recipientType': 'group',
    'recipientId': currentGroupId,
    'messageType': 'text',
    'content': {'text': text},
    'priority': 'normal',
  });
}

// Listen for new messages
_socketClient.on('message_received', (data) {
  final message = MessageModel.fromJson(data);
  setState(() {
    messages.add(message);
  });
});
```

### 3. Live Radio Screen Integration
```dart
// Join frequency and start listening
void startListening(String frequencyId) {
  _socketClient.joinFrequency(frequencyId);
  
  // Listen for audio streams
  _socketClient.on('audio_stream', (data) {
    // Play audio data
    playAudio(data['audioData']);
  });
  
  // Listen for transmission events
  _socketClient.on('transmission_started', (data) {
    setState(() {
      currentSpeaker = data['userId'];
    });
  });
}

// Start transmitting
void startTransmit() {
  _socketClient.startTransmission(currentFrequencyId);
  // Start recording and sending audio chunks
}
```

---

## 📝 Important Notes

1. **Authentication Token**: Set token after login
```dart
final httpClient = HttpClient();
httpClient.setAuthToken(token);

final socketClient = WebSocketClient();
socketClient.connect(token);
```

2. **Error Handling**: All APIs return `ApiResponse<T>` with:
   - `success`: bool
   - `message`: String
   - `data`: T?
   - `errors`: List?

3. **Query Parameters**: Use `_buildUrl()` helper in repositories

4. **Real-time Updates**: Always listen to socket events after API calls

5. **Clean Up**: Disconnect socket when leaving screens
```dart
@override
void dispose() {
  _socketClient.off('message_received');
  _socketClient.leaveGroup(groupId);
  super.dispose();
}
```

---

## 🎨 UI Integration Pattern

For each screen:
1. Import required repositories
2. Load initial data via HTTP APIs
3. Connect to WebSocket with authentication
4. Join relevant rooms (frequency/group)
5. Listen to real-time events
6. Update UI based on events
7. Clean up on dispose

---

## ✨ All APIs are Ready!

Every backend endpoint has been integrated. No API is missing. The app now has:
- ✅ Complete REST API integration
- ✅ Full WebSocket/Socket.IO support
- ✅ All models with proper serialization
- ✅ Comprehensive error handling
- ✅ Real-time communication ready
- ✅ Query parameter support
- ✅ JWT authentication flow

**Ready to integrate with all screens!** 🚀
