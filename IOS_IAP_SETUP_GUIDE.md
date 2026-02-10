# iOS In-App Purchase Setup Guide

**DC Audio Rooms - Private Frequency**

## ✅ Completed Implementation

### 1. Flutter Code Changes

- ✅ Added `in_app_purchase: ^3.2.0` package to pubspec.yaml
- ✅ Created `lib/shared/services/ios_iap_service.dart` - iOS StoreKit service
- ✅ Updated `lib/features/dialer/services/private_frequency_service.dart` - Added iOS IAP verification
- ✅ Updated `lib/features/dialer/screens/private_frequency_screen.dart` - Platform-specific payment flow
- ✅ Updated `ios/Runner/Info.plist` - Added SKAdNetwork configuration
- ✅ Created `ios/Products.storekit` - StoreKit Configuration file for testing

### 2. How It Works

**iOS (In-App Purchase):**

1. User taps "Create Frequency"
2. App calls StoreKit to purchase `com.dhvanicast.private_frequency`
3. User completes payment via Apple Pay/App Store
4. App receives receipt data from Apple
5. Receipt sent to your backend for verification
6. Backend verifies with Apple's API
7. Private frequency created

**Android (Razorpay - Unchanged):**

1. User taps "Create Frequency"
2. App uses Razorpay (existing flow)
3. Payment verified with your backend
4. Private frequency created

---

## 📋 Next Steps (IMPORTANT)

### Step 1: Install Dependencies

```bash
cd /Users/abcom/Desktop/Projects/demoSo/dhavanicast/dhvanicast-app
flutter pub get
```

### Step 2: App Store Connect Setup

#### A. Create In-App Purchase Product

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app (DC Audio Rooms)
3. Go to **Features** → **In-App Purchases**
4. Click ➕ to create new product:
   - **Type:** Consumable
   - **Reference Name:** Private Frequency 12 Hours
   - **Product ID:** `com.dhvanicast.private_frequency`
   - **Price:** ₹99 (or your desired price)
   - **Display Name (English):** Private Frequency - 12 Hours
   - **Description:** Create a private frequency that lasts for 12 hours with password protection

5. Add localizations for other languages if needed
6. Click **Save**
7. Submit for review (or use in TestFlight)

#### B. Set up Sandbox Testing

1. Go to **Users and Access** → **Sandbox Testers**
2. Create test accounts for iOS testing
3. Use these accounts to test purchases

### Step 3: Backend API Changes (CRITICAL)

You need to add a new endpoint to verify iOS IAP receipts:

**Endpoint:** `POST /private-frequencies/create-ios`

**Request Body:**

```json
{
  "receiptData": "base64_encoded_receipt_from_apple",
  "transactionId": "apple_transaction_id",
  "password": "user_frequency_password"
}
```

**Backend Logic:**

```javascript
// Example Node.js/Express endpoint
router.post("/create-ios", auth, async (req, res) => {
  try {
    const { receiptData, transactionId, password } = req.body;

    // 1. Verify receipt with Apple
    const appleResponse = await verifyReceiptWithApple(receiptData);

    // 2. Check if receipt is valid
    if (appleResponse.status !== 0) {
      return res.status(400).json({
        message: "Invalid receipt",
      });
    }

    // 3. Check if transaction was already used
    const existingFreq = await PrivateFrequency.findOne({
      appleTransactionId: transactionId,
    });

    if (existingFreq) {
      return res.status(400).json({
        message: "Transaction already used",
      });
    }

    // 4. Create private frequency
    const frequency = await createPrivateFrequency(
      req.user._id,
      password,
      transactionId, // Store transaction ID
    );

    res.status(201).json({ data: frequency });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Helper function to verify with Apple
async function verifyReceiptWithApple(receiptData) {
  const appleUrl = "https://buy.itunes.apple.com/verifyReceipt"; // Production
  // Use 'https://sandbox.itunes.apple.com/verifyReceipt' for testing

  const response = await fetch(appleUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receiptData,
      password: "YOUR_SHARED_SECRET", // Get from App Store Connect
    }),
  });

  return await response.json();
}
```

**Apple Receipt Verification URLs:**

- **Sandbox (Testing):** `https://sandbox.itunes.apple.com/verifyReceipt`
- **Production:** `https://buy.itunes.apple.com/verifyReceipt`

**Get Shared Secret:**

1. Go to App Store Connect
2. Your App → Features → In-App Purchases
3. Click **App-Specific Shared Secret**
4. Copy and save securely

### Step 4: Testing on iOS

#### Local Testing (Simulator)

```bash
# Run with StoreKit Configuration file
flutter run -d "iPhone 15 Pro"
```

In Xcode:

1. Open `ios/Runner.xcworkspace`
2. Go to **Product** → **Scheme** → **Edit Scheme**
3. Select **Run** → **Options**
4. Enable **StoreKit Configuration**
5. Select `Products.storekit`

#### TestFlight Testing

1. Build iOS app:

```bash
flutter build ios --release
```

2. Archive in Xcode and upload to TestFlight
3. Invite testers with Sandbox accounts
4. Test purchases

### Step 5: Update Product ID (If Needed)

If your bundle identifier is different, update the product ID in:

**File:** `lib/shared/services/ios_iap_service.dart`

```dart
static const String privateFrequencyProductId = 'com.dhvanicast.private_frequency';
```

Change to match your bundle ID format:

```dart
static const String privateFrequencyProductId = 'YOUR_BUNDLE_ID.private_frequency';
```

---

## 🔧 Troubleshooting

### "No products available" Error

- Ensure product is created in App Store Connect
- Product ID matches exactly
- Wait 2-4 hours after creating product
- App must be signed with correct Team ID
- Test with TestFlight build (not simulator only)

### "Payment failed" Error

- Check Sandbox tester account is signed in (Settings → App Store → Sandbox Account)
- Ensure receipt verification endpoint works
- Check backend logs for verification errors

### "Receipt verification failed"

- Use sandbox URL for testing
- Use production URL for live app
- Ensure shared secret is correct
- Check Apple's receipt format

---

## 📱 User Experience

### iOS Users

- Tap "Create Frequency" → Apple Pay/App Store payment
- Seamless native payment experience
- Can use Face ID/Touch ID
- Compliant with Apple's guidelines ✅

### Android Users

- Tap "Create Frequency" → Razorpay (existing flow)
- No changes to Android experience
- Everything works as before ✅

---

## 📄 Required for App Review

When submitting to Apple:

1. **In App Review Information:**
   - Provide Sandbox tester credentials
   - Explain the private frequency feature
   - Mention that Android uses external payment (Razorpay)

2. **App Review Notes:**

```
iOS users purchase "Private Frequency" feature via Apple In-App Purchase.
Android users use Razorpay (outside the iOS app).
The app detects platform and uses appropriate payment method.
```

3. **Screenshots:**
   - Show iOS purchase flow
   - Show frequency creation after purchase

---

## 🚀 Deployment Checklist

- [ ] Run `flutter pub get`
- [ ] Create product in App Store Connect
- [ ] Add backend endpoint `/create-ios`
- [ ] Test with Sandbox account
- [ ] Test receipt verification
- [ ] Upload to TestFlight
- [ ] Test on real device
- [ ] Submit for App Review
- [ ] Monitor for issues

---

## 📞 Support

If you encounter issues:

1. Check console logs (look for `[iOS IAP]` prefix)
2. Verify backend endpoint receives requests
3. Check Apple's receipt verification response
4. Test with different Sandbox accounts

---

## 🎯 Summary

✅ **iOS:** Uses Apple In-App Purchase (StoreKit)  
✅ **Android:** Uses Razorpay (unchanged)  
✅ **Compliant:** Meets Apple's App Store guidelines  
✅ **Seamless:** Platform-specific payment flows

**Next:** Install dependencies, set up App Store Connect, and add backend verification endpoint!
