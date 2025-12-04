# How to Add Ringtone to Your App

## Option 1: Use Free Ringtone (Recommended)

### Step 1: Download a Free Ringtone
Visit any of these sites and download a ringtone:
- https://www.zedge.net/ringtones (Free ringtones)
- https://www.soundjay.com/phone-sound-effect.html
- https://mixkit.co/free-sound-effects/phone/

### Step 2: Convert to MP3 (if needed)
If your file is not MP3, use online converter:
- https://cloudconvert.com/to/mp3

### Step 3: Rename and Place File
1. Rename your file to `ringtone.mp3`
2. Copy it to: `harborleaf_radio_app/assets/sounds/ringtone.mp3`

---

## Option 2: Use System Default Sound

If you don't have a ringtone file, the app will still work but without sound. The visual notification will still appear.

To use Android default sound instead:

Open: `lib/features/social/screens/incoming_call_screen.dart`

Change line 69 from:
```dart
await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
```

To:
```dart
// Use system notification sound
await _audioPlayer.play(AssetSource('sounds/notification.mp3')); 
// Or just skip the sound if file doesn't exist
```

---

## Option 3: Create Simple Beep Sound

You can create a simple beep using online tools:
1. Go to: https://www.audiocheck.net/audiofrequencysignalgenerator_sinetone.php
2. Set frequency: 800 Hz
3. Duration: 2 seconds
4. Click "Play" → Right-click → "Save audio as..."
5. Save as `ringtone.mp3`
6. Place in `assets/sounds/`

---

## For Android Native Sound (Optional)

If using Firebase Cloud Messaging for background calls:

1. Create folder: `android/app/src/main/res/raw/`
2. Copy `ringtone.mp3` to this folder
3. Android will use this for push notifications

---

## Verify Installation

After adding the ringtone:

1. Run `flutter pub get` (in case)
2. Run your app
3. Make a call
4. You should hear the ringtone playing

If no sound plays:
- Check if file exists: `assets/sounds/ringtone.mp3`
- Check console logs for error: `⚠️ [CALL] Ringtone file not found`
- Verify `pubspec.yaml` includes `assets/sounds/` (already included)

---

## Current Status

⚠️ **No ringtone file yet**: App will work silently  
✅ **Visual call notification**: Works perfectly  
✅ **Call functionality**: Fully working  

**Action Required**: Add `ringtone.mp3` file to `assets/sounds/` folder
