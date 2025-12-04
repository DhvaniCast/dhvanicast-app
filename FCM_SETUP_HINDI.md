# Firebase Cloud Messaging (FCM) Setup - Hindi Guide

## 🎯 Ye Kya Hai?

Abhi aapka app **sirf tab kaam karta hai jab app open ho**. 

**FCM lagane ke baad**: App band hone par bhi call notification aayegi (jaise normal phone call)

---

## 📱 Step 1: Firebase Account Banao

### 1.1 Firebase Console Kholo
- Browser mein jao: https://console.firebase.google.com/
- **Google account se login karo** (Gmail wala)

### 1.2 Naya Project Banao
1. **"Add project"** button pe click karo (ya existing project select karo)
2. **Project name likho**: `DhvaniCast` (ya koi bhi naam)
3. **Continue** pe click karo
4. **Google Analytics** - Off kar do (optional hai)
5. **Create project** pe click karo
6. Wait karo... project ban jayega (30 seconds)
7. **Continue** pe click karo

✅ **Done!** Aapka Firebase project ban gaya

---

## 📱 Step 2: Android App Add Karo

### 2.1 Android Package Name Dekho

**Pehle apne app ka package name nikalo:**

1. File kholo: `harborleaf_radio_app/android/app/build.gradle.kts`
2. Ye line dhundo:
   ```kotlin
   namespace = "com.harborleaf.radio"  // YE COPY KARO
   ```
3. Package name copy karo: `com.harborleaf.radio`

### 2.2 Firebase Mein Android App Add Karo

1. Firebase Console mein **Android icon** (Android robot) pe click karo
2. **Android package name** paste karo: `com.harborleaf.radio`
3. **App nickname** (optional): `DhvaniCast Android`
4. **SHA-1** certificate - **SKIP karo** (abhi nahi chahiye)
5. **"Register app"** button pe click karo

### 2.3 Configuration File Download Karo

1. **"Download google-services.json"** button pe click karo
2. File download ho jayegi computer mein
3. **Us file ko is folder mein paste karo:**
   ```
   harborleaf_radio_app/android/app/google-services.json
   ```
   (Directly `app` folder mein, `src` ke saath)

### 2.4 Firebase Console Mein Next Steps

- **"Next"** pe click karo
- Baaki steps **"Skip"** kar do
- **"Continue to console"** pe click karo

✅ **Done!** Android app Firebase se connect ho gaya

---

## 📱 Step 3: Firebase Options File Banao

### 3.1 google-services.json Open Karo

File kholo: `harborleaf_radio_app/android/app/google-services.json`

**Text editor mein kholo** (Notepad++ ya VS Code)

### 3.2 Values Copy Karo

File mein ye values dhundo:

```json
{
  "project_info": {
    "project_number": "123456789012",      ← YE COPY KARO (messagingSenderId)
    "project_id": "dhvanicast-12345"       ← YE COPY KARO (projectId)
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123:android:abc123"  ← YE COPY KARO (appId)
      },
      "api_key": [
        {
          "current_key": "AIzaSyABC123XYZ..."  ← YE COPY KARO (apiKey)
        }
      ]
    }
  ]
}
```

### 3.3 Naya File Banao

**File create karo:** `harborleaf_radio_app/lib/firebase_options.dart`

**Ye code paste karo:**

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABC123XYZ...',           // ← YAHAN APNA apiKey (current_key) PASTE KARO
    appId: '1:123:android:abc123',          // ← YAHAN APNA appId (mobilesdk_app_id) PASTE KARO
    messagingSenderId: '123456789012',      // ← YAHAN APNA messagingSenderId (project_number) PASTE KARO
    projectId: 'dhvanicast-12345',          // ← YAHAN APNA projectId PASTE KARO
    storageBucket: 'dhvanicast-12345.appspot.com',  // ← projectId + .appspot.com
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABC123XYZ...',           // Same as Android (abhi ke liye)
    appId: '1:123:ios:xyz789',              // iOS setup ke baad change karenge
    messagingSenderId: '123456789012',      // Same as Android
    projectId: 'dhvanicast-12345',          // Same as Android
    storageBucket: 'dhvanicast-12345.appspot.com',
    iosBundleId: 'com.harborleaf.radio',
  );
}
```

**⚠️ IMPORTANT:** Apne copied values se replace karo (example values mat rakho!)

✅ **Done!** Firebase options file ready

---

## 📱 Step 4: Packages Install Karo

### 4.1 pubspec.yaml Edit Karo

File kholo: `harborleaf_radio_app/pubspec.yaml`

**`dependencies:` section mein ye add karo:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # ... existing packages ...
  
  # Firebase - ADD THESE LINES
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
```

### 4.2 Packages Download Karo

**Terminal mein ye command run karo:**

```bash
flutter pub get
```

Wait karo... packages download ho jayenge.

✅ **Done!** Firebase packages install ho gaye

---

## 📱 Step 5: Android Configuration

### 5.1 File 1: android/build.gradle.kts

**File kholo:** `harborleaf_radio_app/android/build.gradle.kts`

**Ye lines add karo:**

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.4.0")  // ← YE LINE ADD KARO
    }
}
```

### 5.2 File 2: android/app/build.gradle.kts

**File kholo:** `harborleaf_radio_app/android/app/build.gradle.kts`

**Top mein plugins section mein ye line add karo:**

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← YE LINE ADD KARO
}
```

### 5.3 File 3: android/app/src/main/AndroidManifest.xml

**File kholo:** `harborleaf_radio_app/android/app/src/main/AndroidManifest.xml`

**`<manifest>` tag ke andar (top pe) ye permissions add karo:**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- ADD THESE PERMISSIONS -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <application>
        <!-- ... existing code ... -->
    </application>
</manifest>
```

✅ **Done!** Android configuration complete

---

## 📱 Step 6: Flutter Code Update Karo

### 6.1 main.dart File Edit Karo

**File kholo:** `harborleaf_radio_app/lib/main.dart`

**Top mein imports add karo:**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
```

**`main()` function ko replace karo:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Request notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Get FCM token
  String? fcmToken = await messaging.getToken();
  print('📲 [FCM TOKEN]: $fcmToken');
  // TODO: Is token ko backend mein save karna hai
  
  runApp(const MyApp());
}
```

✅ **Done!** Flutter code ready

---

## 📱 Step 7: Test Karo

### 7.1 App Run Karo

```bash
flutter run
```

### 7.2 Console Mein Token Check Karo

App start hone par console mein ye dikhega:

```
📲 [FCM TOKEN]: dABC123xyz...
```

**Ye token copy karo** - backend mein use hoga

### 7.3 Test Notification Bhejo

**Firebase Console se test:**

1. Firebase Console → **Cloud Messaging** (left menu)
2. **"Send your first message"** pe click karo
3. **Notification title:** "Test Call"
4. **Notification text:** "Incoming call test"
5. **Next** pe click karo
6. **Target:** Select your app
7. **Next** → **Review** → **Publish**

**Check karo:** Notification aaya ya nahi (app background mein hona chahiye)

✅ **Done!** FCM working!

---

## 📱 Step 8: Backend Integration (Final Step)

### 8.1 Backend Mein Firebase Admin SDK Add Karo

**Terminal kholo backend folder mein:**

```bash
cd harborleaf_radio_backend
npm install firebase-admin
```

### 8.2 Service Account Key Download Karo

1. **Firebase Console** → **Project Settings** (⚙️ icon)
2. **Service accounts** tab pe jao
3. **"Generate new private key"** button pe click karo
4. **Confirm** → JSON file download hogi
5. File rename karo: `firebase-service-account.json`
6. **Backend root folder** mein paste karo: `harborleaf_radio_backend/firebase-service-account.json`

⚠️ **IMPORTANT:** `.gitignore` mein add karo (GitHub pe upload mat karo!)

### 8.3 Backend Code Update

**File banao:** `harborleaf_radio_backend/src/config/firebase.js`

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('../../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = admin;
```

### 8.4 Communication Handler Update

**File kholo:** `harborleaf_radio_backend/src/sockets/communicationHandler.js`

**Top mein import add karo:**

```javascript
const admin = require('../config/firebase');
```

**`initiate_call` handler mein FCM code add karo:**

```javascript
socket.on('initiate_call', async (data) => {
  try {
    const { friendId, callType = 'voice', roomName } = data;
    
    // ... existing code ...
    
    // Get friend details
    const friend = await User.findById(friendId);
    const currentUser = await User.findById(socket.userId);
    
    // Send FCM notification if friend has token
    if (friend.fcmToken) {
      const message = {
        token: friend.fcmToken,
        notification: {
          title: '📞 Incoming Call',
          body: `${currentUser.name} is calling...`,
        },
        data: {
          type: 'incoming_call',
          callerId: socket.userId,
          callerName: currentUser.name,
          callerEmail: currentUser.email,
          roomName: roomName,
        },
        android: {
          priority: 'high',
        },
      };
      
      try {
        await admin.messaging().send(message);
        console.log('✅ [FCM] Notification sent to', friend.name);
      } catch (error) {
        console.error('❌ [FCM] Error:', error);
      }
    }
    
    // ... rest of existing code ...
  } catch (error) {
    console.error('Error initiating call:', error);
  }
});
```

### 8.5 User Model Update - FCM Token Field Add Karo

**File kholo:** `harborleaf_radio_backend/src/models/User.js`

```javascript
const userSchema = new mongoose.Schema({
  // ... existing fields ...
  
  fcmToken: {
    type: String,
    default: null,
  },
});
```

### 8.6 API Endpoint Banao - FCM Token Save Karne Ke Liye

**File kholo:** `harborleaf_radio_backend/src/routes/userRoutes.js`

```javascript
router.post('/update-fcm-token', authMiddleware, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    
    await User.findByIdAndUpdate(req.userId, { fcmToken });
    
    res.json({ success: true, message: 'FCM token saved' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### 8.7 Flutter Se FCM Token Backend Ko Bhejo

**File kholo:** `harborleaf_radio_app/lib/main.dart`

**`main()` function mein token send karo:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  String? fcmToken = await messaging.getToken();
  print('📲 [FCM TOKEN]: $fcmToken');
  
  // Send token to backend
  if (fcmToken != null) {
    _saveFCMToken(fcmToken);
  }
  
  runApp(const MyApp());
}

Future<void> _saveFCMToken(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    
    if (accessToken != null) {
      final response = await http.post(
        Uri.parse('YOUR_BACKEND_URL/api/users/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );
      
      if (response.statusCode == 200) {
        print('✅ [FCM] Token saved to backend');
      }
    }
  } catch (e) {
    print('❌ [FCM] Failed to save token: $e');
  }
}
```

**Don't forget imports:**

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
```

✅ **COMPLETE!** Background calls ab kaam karenge!

---

## 🎯 Final Testing

### Test 1: App Band Karke Test Karo

1. **App ko completely close karo** (recent apps se swipe away)
2. **Dusre device/account se call karo**
3. **Notification aani chahiye** with ringtone
4. **Notification tap karo** → App khulega

### Test 2: Backend Logs Check Karo

Backend console mein ye dikhna chahiye:

```
✅ [FCM] Notification sent to Friend Name
```

### Test 3: Firebase Console Check Karo

Firebase Console → Cloud Messaging → Statistics mein notifications count dikhega

---

## ❓ Common Problems

### Problem 1: "google-services.json not found"

**Solution:** File exactly `android/app/` folder mein hai ya nahi check karo

### Problem 2: FCM Token null aa raha hai

**Solution:** 
- Internet connection check karo
- Permissions check karo
- App restart karo

### Problem 3: Notification nahi aa raha

**Solution:**
- Check karo: `firebase-service-account.json` backend mein hai
- Check karo: FCM token database mein save hua ya nahi
- Backend logs dekho errors ke liye

### Problem 4: "Firebase app not initialized"

**Solution:** `Firebase.initializeApp()` `main()` function mein sabse pehle call karo

---

## 📞 Help Chahiye?

Agar koi step samajh mein nahi aaya to mujhe batao:
- Konsa step?
- Kya error aa raha hai?
- Screenshot share karo

**Ab aap background calls receive kar sakte ho! 🎉**
