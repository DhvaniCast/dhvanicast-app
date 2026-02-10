# iOS App Store Release Guide - DC Audio Rooms

## ✅ Current Status

- **App Name:** DC Audio Rooms
- **Bundle ID:** com.dhvanicast.radio
- **Version:** 1.0.2+7
- **Package Name:** SAME AS BEFORE (कोई change नहीं)

---

## 📋 Step 1: Pre-Release Checklist

### A. Xcode Setup (ज़रूरी)

```bash
# 1. Xcode में Signing & Capabilities setup करें
open ios/Runner.xcworkspace
```

**Xcode में करें:**

1. Runner target select करें (left sidebar)
2. **Signing & Capabilities** tab पे जाएं
3. **Team** select करें (Apple Developer account)
4. **Automatically manage signing** ✅ enable करें
5. **Bundle Identifier** verify करें: `com.dhvanicast.radio`

### B. Build Configuration Check

- ✅ Info.plist - All privacy descriptions added
- ✅ Firebase removed
- ✅ Version: 1.0.2 (Build 7)
- ✅ Deployment Target: iOS 13.0+

---

## 🔨 Step 2: Archive बनाना

### Method 1: Xcode से (Recommended)

```bash
# 1. Workspace open करें
cd /Users/abcom/Desktop/Projects/demoSorave/dhavanicast/dhvanicast-app
open ios/Runner.xcworkspace
```

**Xcode में:**

1. Top bar में **Generic iOS Device** या **Any iOS Device (arm64)** select करें
   - ❌ Simulator select नहीं करना
2. Menu bar से जाएं: **Product → Archive**
   - Keyboard shortcut: `Cmd + Shift + B` (Build) फिर archive

3. Archive बनने में **5-10 minutes** लगेंगे

4. Archive complete होने पर **Organizer window** खुलेगा

---

## 📤 Step 3: App Store पे Upload करना

### Organizer Window में:

1. **Archives** tab में latest archive दिखेगा
2. **Distribute App** button क्लिक करें

3. Distribution method select करें:
   - ✅ **App Store Connect** select करें
   - Next क्लिक करें

4. Destination चुनें:
   - ✅ **Upload** select करें (TestFlight के लिए)
   - Next क्लिक करें

5. App Store Connect options:
   - ✅ **Include bitcode for iOS content** (if shown)
   - ✅ **Upload your app's symbols**
   - Next क्लिक करें

6. Signing options:
   - ✅ **Automatically manage signing** select करें
   - Next क्लिक करें

7. Review summary:
   - Content check करें
   - **Upload** क्लिक करें

8. Upload progress:
   - 5-10 minutes लगेंगे
   - Complete होने पर success message आएगा

---

## 🧪 Step 4: TestFlight Testing (Optional but Recommended)

### A. App Store Connect में:

1. Browser में जाएं: https://appstoreconnect.apple.com
2. **My Apps** → **DC Audio Rooms** select करें
3. **TestFlight** tab पे जाएं

### B. Build Ready होने का wait करें:

- Upload के बाद Apple processing करता है
- **"Processing"** status दिखेगा
- **5-15 minutes** में status **"Ready to Test"** होगा

### C. Internal Testing (Optional):

1. **Internal Testing** section में जाएं
2. **+** button से testers add करें
3. Build select करें और distribute करें
4. Testers को email आएगा TestFlight app से install करने के लिए

---

## 🚀 Step 5: App Store Submission

### A. App Information Setup:

1. App Store Connect → **DC Audio Rooms** → **App Store** tab
2. **+ Version or Platform** → **iOS**
3. Version number: **1.0.2** enter करें

### B. Version Information Fill करें:

**1. App Preview and Screenshots:**

- iPhone screenshots (6.7", 6.5", 5.5" - required)
- iPad screenshots (if supporting iPad)
- Upload करें: PNG या JPEG format

**2. Promotional Text (Optional):**

```
Experience seamless voice communication with DC Audio Rooms
```

**3. Description:**

```
DC Audio Rooms is a voice communication platform that enables real-time audio conversations. Connect with friends and communities through high-quality voice channels.

Features:
• Real-time voice communication
• Create and join audio rooms
• High-quality audio streaming
• User-friendly interface
• Secure and reliable connections

Perfect for:
✓ Community discussions
✓ Voice chat with friends
✓ Live audio sessions
✓ Group conversations
```

**4. Keywords:**

```
voice chat, audio rooms, communication, live audio, voice call
```

**5. Support URL:**

```
https://dhvanicast.com/support
```

**6. Marketing URL (Optional):**

```
https://dhvanicast.com
```

**7. Privacy Policy URL:**

```
https://dhvanicast.com/privacy
```

### C. Build Selection:

1. **Build** section में जाएं
2. **+** या **Select a build** क्लिक करें
3. Latest build (1.0.2+7) select करें

### D. App Review Information:

1. **Contact Information:**
   - First Name, Last Name
   - Phone Number
   - Email

2. **Demo Account (if needed):**
   - Username: (if login required)
   - Password: (if login required)

3. **Notes for Reviewer:**

```
This app provides voice communication features using LiveKit.
No special setup required for testing.
```

### E. Version Release:

- ✅ **Automatically release this version**
- या
- ⏸️ **Manually release this version** (आप control रखना चाहते हो तो)

### F. Submit for Review:

1. सब कुछ fill करने के बाद **Save** करें
2. **Add for Review** button क्लिक करें
3. **Submit for Review** confirm करें

---

## ⚠️ Common Issues और Solutions

### Issue 1: "No accounts with App Store Connect access"

**Solution:**

- Xcode → Preferences → Accounts
- Apple ID add करें (जो Developer Program member हो)

### Issue 2: "Failed to register bundle identifier"

**Solution:**

- Bundle ID already registered है (com.dhvanicast.radio)
- Apple Developer portal में check करें

### Issue 3: "Profile doesn't include signing certificate"

**Solution:**

- Xcode → Preferences → Accounts → Download Manual Profiles
- Automatic signing को toggle करें (off → on)

### Issue 4: Archive option greyed out

**Solution:**

- Top में **Generic iOS Device** select करें
- Simulator select नहीं होना चाहिए

### Issue 5: Build processing stuck

**Solution:**

- App Store Connect में 30 minutes तक wait करें
- फिर भी processing हो तो Apple Support contact करें

---

## 📱 Alternative: Command Line Archive

```bash
# 1. Clean करें
cd /Users/abcom/Desktop/Projects/demoSorave/dhavanicast/dhvanicast-app
flutter clean

# 2. Dependencies install करें
flutter pub get
cd ios
pod install
cd ..

# 3. iOS build करें
flutter build ios --release

# 4. Xcode से archive करें (manually)
open ios/Runner.xcworkspace
# फिर Product → Archive
```

---

## ✅ App Store Review Timeline

1. **Upload** → Instant
2. **Processing** → 5-15 minutes
3. **Waiting for Review** → 1-2 days
4. **In Review** → Few hours to 1 day
5. **Approved/Rejected** → Notification मिलेगा

---

## 📞 Support URLs (Update करें Production URLs से)

अगर ये URLs नहीं हैं तो create करें:

- Privacy Policy: https://dhvanicast.com/privacy
- Terms of Service: https://dhvanicast.com/terms
- Support: https://dhvanicast.com/support

**या temporary के लिए:**

- GitHub Pages use कर सकते हो
- Google Docs public link
- Simple static HTML page host करें

---

## 🎯 Next Steps After Approval

1. **App Store से live होने पर:**
   - Users install कर सकेंगे
   - Reviews और ratings monitor करें
2. **Updates के लिए:**
   - Version number increment करें (1.0.3)
   - Build number increment करें (+8, +9...)
   - Same process repeat करें

---

## 📝 Important Notes

- ✅ Package name **same hai**: com.dhvanicast.radio
- ✅ Play Store का app alag है, App Store का alag
- ✅ Dono ke bundle IDs same रख सकते हो
- ⚠️ Screenshots और description prepare रखें
- ⚠️ Privacy Policy URL ज़रूरी है

---

## 🆘 Quick Commands Reference

```bash
# Clean build
flutter clean && flutter pub get

# iOS build test
flutter build ios --release

# Open Xcode workspace
open ios/Runner.xcworkspace

# Check for issues
flutter analyze

# Run on iOS simulator
flutter run

# Check connected devices
flutter devices
```

---

**Ready to Start?** ✨

1. Xcode open करें: `open ios/Runner.xcworkspace`
2. Team select करें
3. Product → Archive
4. Upload to App Store Connect
5. Submit for Review

Good luck! 🚀
