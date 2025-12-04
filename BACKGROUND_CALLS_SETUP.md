# Background Call Notifications Setup (FCM)

## Overview
To receive call notifications when the app is closed or in background, you need Firebase Cloud Messaging (FCM).

## Current Status
✅ **Call sync when app is open**: Both users see call end immediately  
✅ **Ringtone on incoming calls**: Audio plays when call arrives  
⚠️ **Background calls**: Requires FCM setup (follow steps below)

---

## 📱 Why FCM is Needed?

When your app is **closed** or in **background**, the WebSocket connection is disconnected. To receive call notifications like normal phone calls, you need:

1. **Firebase Cloud Messaging (FCM)** - Push notifications from server
2. **Android/iOS native integration** - Display call screen even when app is killed
3. **Backend FCM integration** - Send push notification when call is initiated

---

## 🔧 Setup Steps

### 1. Add Firebase to Flutter Project

**Choose ONE method:**

#### Method A: Automatic Setup (Recommended if you have Firebase CLI)
```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Add Pub Cache to PATH (Windows)
# Add this to System Environment Variables > Path:
# C:\Users\YOUR_USERNAME\AppData\Local\Pub\Cache\bin

# Configure Firebase
flutterfire configure
```

This will:
- Create/select Firebase project
- Register Android and iOS apps
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Generate `firebase_options.dart`

---

#### Method B: Manual Setup (Easier, No CLI Required)

**Step 1: Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Enter project name (e.g., "dhvanicast-app")
4. Follow the setup wizard

**Step 2: Add Android App**
1. In Firebase Console → Click "Android" icon
2. Android package name: `com.harborleaf.radio` (check in `android/app/build.gradle.kts`)
3. App nickname: "DhvaniCast Android" (optional)
4. Click "Register app"
5. **Download `google-services.json`**
6. Place it in: `android/app/google-services.json`
7. Click "Next" → "Continue to console"

**Step 3: Add iOS App (Optional)**
1. In Firebase Console → Click "iOS" icon  
2. iOS bundle ID: Check in `ios/Runner.xcodeproj/project.pbxproj`
3. App nickname: "DhvaniCast iOS" (optional)
4. **Download `GoogleService-Info.plist`**
5. Place it in: `ios/Runner/GoogleService-Info.plist`
6. Click "Next" → "Continue to console"

**Step 4: Create `firebase_options.dart`**

Create file: `lib/firebase_options.dart`

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // Get these values from Firebase Console > Project Settings > General
  // Scroll down to "Your apps" section
  
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',  // From google-services.json: "api_key" > "current_key"
    appId: 'YOUR_ANDROID_APP_ID',     // From google-services.json: "mobilesdk_app_id"
    messagingSenderId: 'YOUR_SENDER_ID', // From google-services.json: "project_number"
    projectId: 'YOUR_PROJECT_ID',     // From google-services.json: "project_id"
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',       // From GoogleService-Info.plist: API_KEY
    appId: 'YOUR_IOS_APP_ID',         // From GoogleService-Info.plist: GOOGLE_APP_ID
    messagingSenderId: 'YOUR_SENDER_ID', // From GoogleService-Info.plist: GCM_SENDER_ID
    projectId: 'YOUR_PROJECT_ID',     // From GoogleService-Info.plist: PROJECT_ID
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.harborleaf.radio',
  );
}
```

**How to get values:**
- Open `android/app/google-services.json` in text editor
- Find values and replace in `firebase_options.dart`
- Example:
  ```json
  {
    "project_info": {
      "project_number": "123456789",  // This is messagingSenderId
      "project_id": "dhvanicast-app"  // This is projectId
    },
    "client": [{
      "client_info": {
        "mobilesdk_app_id": "1:123:android:abc"  // This is appId
      },
      "api_key": [{
        "current_key": "AIzaSyABC123..."  // This is apiKey
      }]
    }]
  }
  ```

---

### 2. Update `pubspec.yaml`

Add Firebase packages:

```yaml
dependencies:
  # Existing dependencies...
  
  # Firebase Core
  firebase_core: ^3.8.1
  
  # Firebase Cloud Messaging
  firebase_messaging: ^15.1.5
  
  # Local notifications (to show incoming call UI)
  flutter_local_notifications: ^18.0.1
```

Run:
```bash
flutter pub get
```

---

### 3. Android Configuration

#### Update `android/app/build.gradle.kts`

Add Google Services plugin:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add this line
}
```

#### Update `android/build.gradle.kts`

Add Google Services classpath:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0") // Add this
    }
}
```

#### Add Permissions in `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application>
        <!-- Existing content -->
        
        <!-- FCM service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
    </application>
</manifest>
```

---

### 4. iOS Configuration

#### Add GoogleService-Info.plist

Place the downloaded `GoogleService-Info.plist` in `ios/Runner/` directory.

#### Update `ios/Runner/Info.plist`

```xml
<dict>
    <!-- Existing content -->
    
    <!-- Background modes for VoIP -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>voip</string>
        <string>remote-notification</string>
    </array>
    
    <!-- Notification permissions -->
    <key>NSUserNotificationsUsageDescription</key>
    <string>We need notification permission to show incoming calls</string>
</dict>
```

#### Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Click "+ Capability"
4. Add **Push Notifications**
5. Add **Background Modes** (check: Audio, Voice over IP, Remote notifications)

---

### 5. Flutter Code Integration

#### Update `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📲 [FCM] Background message: ${message.notification?.title}');
  
  // Handle incoming call notification
  if (message.data['type'] == 'incoming_call') {
    // Show full-screen call notification
    await _showIncomingCallNotification(message.data);
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );
  
  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Get FCM token and save to backend
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  print('📲 [FCM] Token: $fcmToken');
  // TODO: Send this token to your backend
  
  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📲 [FCM] Foreground message: ${message.notification?.title}');
    
    if (message.data['type'] == 'incoming_call') {
      _showIncomingCallNotification(message.data);
    }
  });
  
  runApp(const MyApp());
}

Future<void> _showIncomingCallNotification(Map<String, dynamic> callData) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'incoming_calls',
    'Incoming Calls',
    channelDescription: 'Notifications for incoming voice calls',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    sound: RawResourceAndroidNotificationSound('ringtone'),
    playSound: true,
    enableVibration: true,
  );
  
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'ringtone.mp3',
    categoryIdentifier: 'INCOMING_CALL',
  );
  
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  
  await flutterLocalNotificationsPlugin.show(
    0,
    'Incoming Call',
    '${callData['callerName']} is calling...',
    notificationDetails,
    payload: jsonEncode(callData),
  );
}

void _onNotificationTapped(NotificationResponse response) {
  if (response.payload != null) {
    final callData = jsonDecode(response.payload!);
    // Navigate to incoming call screen
    // TODO: Implement navigation
  }
}
```

---

### 6. Backend Integration (Node.js)

#### Install Firebase Admin SDK

```bash
cd harborleaf_radio_backend
npm install firebase-admin
```

#### Get Firebase Service Account Key

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save the JSON file as `firebase-service-account.json` in backend root
4. **DO NOT commit this file to Git** - add to `.gitignore`

#### Update Backend: `src/config/firebase.js`

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('../../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = admin;
```

#### Update `src/sockets/communicationHandler.js`

```javascript
const admin = require('../config/firebase');

// In initiate_call handler
socket.on('initiate_call', async (data) => {
  try {
    // ... existing code ...
    
    // Get friend's FCM token from database
    const friend = await User.findById(friendId);
    
    if (friend.fcmToken) {
      // Send push notification via FCM
      const message = {
        token: friend.fcmToken,
        notification: {
          title: 'Incoming Call',
          body: `${currentUser.name} is calling...`,
        },
        data: {
          type: 'incoming_call',
          callId: callData.callId,
          callerId: socket.userId,
          callerName: currentUser.name,
          callerAvatar: currentUser.avatar || '👤',
          callerEmail: currentUser.email,
          roomName: callData.roomName,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'incoming_calls',
            sound: 'ringtone',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'ringtone.mp3',
              category: 'INCOMING_CALL',
            },
          },
        },
      };
      
      await admin.messaging().send(message);
      console.log('📲 [FCM] Push notification sent to', friend.name);
    }
    
    // ... rest of existing code ...
  } catch (error) {
    console.error('Error initiating call:', error);
  }
});
```

#### Update User Model to Store FCM Token

```javascript
// src/models/User.js
const userSchema = new mongoose.Schema({
  // ... existing fields ...
  
  fcmToken: {
    type: String,
    default: null,
  },
});
```

---

### 7. Save FCM Token to Backend

Create API endpoint to save FCM token:

#### `src/routes/userRoutes.js`

```javascript
router.post('/update-fcm-token', authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    
    await User.findByIdAndUpdate(req.userId, {
      fcmToken: fcmToken,
    });
    
    res.json({ success: true, message: 'FCM token updated' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### Call this API from Flutter after getting FCM token

```dart
// In main.dart after getting FCM token
final authService = getIt<AuthStorageService>();
final token = await authService.getAccessToken();

if (fcmToken != null && token != null) {
  final response = await http.post(
    Uri.parse('YOUR_BACKEND_URL/api/users/update-fcm-token'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'fcmToken': fcmToken}),
  );
}
```

---

## 🧪 Testing Background Calls

### Test on Real Device (Recommended)

1. **Install app on physical device**
2. **Close the app completely** (swipe away from recent apps)
3. **From another device**, initiate a call to this user
4. **You should see**: Full-screen incoming call notification with ringtone

### Debug Background Messages

```bash
# Android
adb logcat | grep -i "fcm\|firebase"

# iOS
Open Xcode → Window → Devices and Simulators → View Device Logs
```

---

## 📝 Important Notes

1. **Real Device Required**: Background notifications don't work well on emulators
2. **Production**: Before production, generate proper APNs certificates for iOS
3. **FCM Token Refresh**: Handle token refresh in `FirebaseMessaging.instance.onTokenRefresh`
4. **Battery Optimization**: Ask users to disable battery optimization for your app on Android
5. **Ringtone File**: Add actual `ringtone.mp3` to `assets/sounds/` and `android/app/src/main/res/raw/`

---

## 🎯 What's Working Now (Without FCM)

✅ **App Open**: Calls work perfectly with WebSocket  
✅ **Call Sync**: Both users see call end immediately  
✅ **Ringtone**: Plays when call arrives (app must be open)  
✅ **Live Audio**: LiveKit voice calls working

## 🚀 What FCM Adds

✨ **App Closed**: Receive call notifications even when app is killed  
✨ **Background**: Full-screen incoming call UI appears  
✨ **System Integration**: Works like native phone calls  

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [FCM Backend Integration](https://firebase.google.com/docs/cloud-messaging/server)

---

## ⚠️ Troubleshooting

### Android: Notifications not showing
- Check if notification channel is created properly
- Verify `google-services.json` is in `android/app/`
- Run `flutter clean && flutter pub get`

### iOS: Push notifications not working
- Verify APNs certificates are set up in Firebase Console
- Check Xcode capabilities (Push Notifications enabled)
- Test on real device (not simulator)

### Background handler not called
- Ensure handler function is `@pragma('vm:entry-point')` annotated
- Function must be top-level (not inside class)
- Check if Firebase is initialized before handler

---

**Current Implementation Status**: ✅ Call sync working, ⏳ FCM setup pending
