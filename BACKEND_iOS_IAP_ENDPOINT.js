/**
 * Backend API Endpoint for iOS In-App Purchase Verification
 * Node.js/Express Example
 * 
 * Add this to your backend server (where you have /private-frequencies/create)
 */

const express = require('express');
const router = express.Router();
const fetch = require('node-fetch'); // or axios
const auth = require('../middleware/auth'); // Your auth middleware
const PrivateFrequency = require('../models/PrivateFrequency'); // Your model

/**
 * POST /private-frequencies/create-ios
 * Verify iOS IAP receipt and create private frequency
 */
router.post('/create-ios', auth, async (req, res) => {
    try {
        const { receiptData, transactionId, password } = req.body;

        // Validate input
        if (!receiptData || !transactionId || !password) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields'
            });
        }

        // Validate password
        if (password.length < 4 || password.length > 20) {
            return res.status(400).json({
                success: false,
                message: 'Password must be between 4-20 characters'
            });
        }

        console.log('🍎 [iOS IAP] Verifying receipt for user:', req.user._id);
        console.log('🍎 [iOS IAP] Transaction ID:', transactionId);

        // 1. Check if transaction was already used
        const existingFrequency = await PrivateFrequency.findOne({
            appleTransactionId: transactionId
        });

        if (existingFrequency) {
            console.log('❌ [iOS IAP] Transaction already used:', transactionId);
            return res.status(400).json({
                success: false,
                message: 'This purchase has already been used'
            });
        }

        // 2. Verify receipt with Apple
        const verificationResult = await verifyReceiptWithApple(receiptData);

        if (!verificationResult.valid) {
            console.log('❌ [iOS IAP] Invalid receipt:', verificationResult.error);
            return res.status(400).json({
                success: false,
                message: 'Payment verification failed: ' + verificationResult.error
            });
        }

        console.log('✅ [iOS IAP] Receipt verified successfully');

        // 3. Verify product ID matches
        const productId = verificationResult.productId;
        if (productId !== 'com.dhvanicast.private_frequency') {
            console.log('❌ [iOS IAP] Invalid product ID:', productId);
            return res.status(400).json({
                success: false,
                message: 'Invalid product purchased'
            });
        }

        // 4. Create private frequency (same logic as Razorpay)
        const frequency = await createPrivateFrequency(
            req.user._id,
            password,
            transactionId
        );

        console.log('✅ [iOS IAP] Private frequency created:', frequency.frequencyNumber);

        res.status(201).json({
            success: true,
            data: {
                frequencyNumber: frequency.frequencyNumber,
                name: frequency.name,
                frequencyValue: frequency.frequencyValue,
                password: frequency.password,
                expiresAt: frequency.expiresAt,
                createdAt: frequency.createdAt
            }
        });

    } catch (error) {
        console.error('❌ [iOS IAP] Error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error: ' + error.message
        });
    }
});

/**
 * Verify receipt with Apple's servers
 */
async function verifyReceiptWithApple(receiptData) {
    try {
        // Get your shared secret from App Store Connect
        const APPLE_SHARED_SECRET = process.env.APPLE_SHARED_SECRET;

        if (!APPLE_SHARED_SECRET) {
            throw new Error('APPLE_SHARED_SECRET not configured');
        }

        // Try production first, then sandbox (Apple recommended approach)
        let appleUrl = 'https://buy.itunes.apple.com/verifyReceipt';

        console.log('📡 [iOS IAP] Verifying with Apple (production)...');

        let response = await fetch(appleUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                'receipt-data': receiptData,
                'password': APPLE_SHARED_SECRET,
                'exclude-old-transactions': true
            })
        });

        let result = await response.json();

        // If status is 21007, receipt is from sandbox - try sandbox URL
        if (result.status === 21007) {
            console.log('🔄 [iOS IAP] Sandbox receipt detected, retrying with sandbox URL...');
            appleUrl = 'https://sandbox.itunes.apple.com/verifyReceipt';

            response = await fetch(appleUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    'receipt-data': receiptData,
                    'password': APPLE_SHARED_SECRET,
                    'exclude-old-transactions': true
                })
            });

            result = await response.json();
        }

        console.log('📥 [iOS IAP] Apple response status:', result.status);

        // Status 0 means valid receipt
        if (result.status === 0) {
            // Get latest receipt info
            const receipt = result.receipt || {};
            const inApp = receipt.in_app || [];

            if (inApp.length === 0) {
                return {
                    valid: false,
                    error: 'No in-app purchases found in receipt'
                };
            }

            // Get the latest transaction
            const latestTransaction = inApp[inApp.length - 1];

            return {
                valid: true,
                productId: latestTransaction.product_id,
                transactionId: latestTransaction.transaction_id,
                purchaseDate: latestTransaction.purchase_date_ms
            };
        } else {
            // Receipt verification failed
            const errorMessages = {
                21000: 'The App Store could not read the JSON object you provided.',
                21002: 'The data in the receipt-data property was malformed or missing.',
                21003: 'The receipt could not be authenticated.',
                21004: 'The shared secret you provided does not match the shared secret on file.',
                21005: 'The receipt server is not currently available.',
                21006: 'This receipt is valid but expired.',
                21007: 'This receipt is from the test environment.',
                21008: 'This receipt is from the production environment.',
                21010: 'This receipt could not be authorized.'
            };

            return {
                valid: false,
                error: errorMessages[result.status] || `Unknown error (status: ${result.status})`
            };
        }

    } catch (error) {
        console.error('❌ [iOS IAP] Verification error:', error);
        return {
            valid: false,
            error: 'Failed to verify receipt with Apple: ' + error.message
        };
    }
}

/**
 * Create private frequency (reuse your existing logic)
 */
async function createPrivateFrequency(userId, password, transactionId) {
    // Generate random frequency number (8 digits)
    const frequencyNumber = Math.floor(10000000 + Math.random() * 90000000).toString();

    // Generate frequency value (88.0 - 108.0 MHz)
    const frequencyValue = (Math.random() * (108.0 - 88.0) + 88.0).toFixed(1);

    // Generate frequency name
    const frequencyName = `Private ${frequencyValue}`;

    // Expires in 12 hours
    const expiresAt = new Date(Date.now() + 12 * 60 * 60 * 1000);

    // Create frequency document
    const frequency = new PrivateFrequency({
        frequencyNumber,
        name: frequencyName,
        frequencyValue: parseFloat(frequencyValue),
        password,
        createdBy: userId,
        participants: [userId],
        expiresAt,
        appleTransactionId: transactionId, // IMPORTANT: Store to prevent reuse
        paymentMethod: 'ios_iap',
        createdAt: new Date()
    });

    await frequency.save();

    return frequency;
}

module.exports = router;

/**
 * SETUP INSTRUCTIONS:
 * 
 * 1. Add to your .env file:
 *    APPLE_SHARED_SECRET=your_shared_secret_from_app_store_connect
 * 
 * 2. Get shared secret from App Store Connect:
 *    - Go to your app
 *    - Features → In-App Purchases
 *    - Click "App-Specific Shared Secret"
 *    - Generate and copy
 * 
 * 3. Update PrivateFrequency model to include:
 *    - appleTransactionId: String (indexed, unique)
 *    - paymentMethod: String ('razorpay' or 'ios_iap')
 * 
 * 4. Add this route to your Express app:
 *    const iosIapRoutes = require('./routes/ios-iap');
 *    app.use('/private-frequencies', iosIapRoutes);
 * 
 * 5. Install node-fetch if needed:
 *    npm install node-fetch
 * 
 * 6. Test with Sandbox account first!
 */
