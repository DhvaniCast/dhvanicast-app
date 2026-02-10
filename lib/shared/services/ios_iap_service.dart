import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// iOS In-App Purchase service using StoreKit
/// This handles all IAP operations for private frequency purchases on iOS
class IosIapService {
  static final IosIapService _instance = IosIapService._internal();
  factory IosIapService() => _instance;
  IosIapService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs - MUST match App Store Connect configuration
  static const String privateFrequencyProductId =
      'com.dhvanicast.private_frequency';

  // Callback for successful purchases
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(String)? onPurchaseError;

  bool _isInitialized = false;
  List<ProductDetails> _products = [];

  /// Initialize the IAP service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🍎 [iOS IAP] Initializing In-App Purchase...');

    // Check if IAP is available
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('❌ [iOS IAP] Store not available');
      throw Exception('In-App Purchase not available');
    }

    debugPrint('✅ [iOS IAP] Store is available');

    // Set up purchase update listener
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        debugPrint('🔴 [iOS IAP] Purchase stream closed');
        _subscription.cancel();
      },
      onError: (error) {
        debugPrint('❌ [iOS IAP] Purchase stream error: $error');
        onPurchaseError?.call(error.toString());
      },
    );

    // Load products
    await _loadProducts();

    _isInitialized = true;
    debugPrint('✅ [iOS IAP] Initialization complete');
  }

  /// Load available products from App Store
  Future<void> _loadProducts() async {
    const Set<String> productIds = {privateFrequencyProductId};

    debugPrint('📦 [iOS IAP] Loading products: $productIds');

    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(productIds);

    if (response.error != null) {
      debugPrint('❌ [iOS IAP] Error loading products: ${response.error}');
      throw Exception('Failed to load products: ${response.error}');
    }

    if (response.productDetails.isEmpty) {
      debugPrint(
        '⚠️ [iOS IAP] No products found. Check App Store Connect configuration.',
      );
      throw Exception('No products available');
    }

    _products = response.productDetails;

    for (var product in _products) {
      debugPrint(
        '✅ [iOS IAP] Product loaded: ${product.id} - ${product.title} - ${product.price}',
      );
    }
  }

  /// Get product details for private frequency
  ProductDetails? getPrivateFrequencyProduct() {
    try {
      return _products.firstWhere(
        (product) => product.id == privateFrequencyProductId,
      );
    } catch (e) {
      debugPrint('⚠️ [iOS IAP] Private frequency product not found');
      return null;
    }
  }

  /// Purchase private frequency
  Future<void> purchasePrivateFrequency() async {
    if (!_isInitialized) {
      await initialize();
    }

    final ProductDetails? product = getPrivateFrequencyProduct();
    if (product == null) {
      throw Exception('Product not available');
    }

    debugPrint('💳 [iOS IAP] Starting purchase for: ${product.id}');

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    final bool success = await _inAppPurchase.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: false, // We'll manually consume after backend verification
    );

    if (!success) {
      debugPrint('❌ [iOS IAP] Failed to initiate purchase');
      throw Exception('Failed to start purchase');
    }

    debugPrint('📱 [iOS IAP] Purchase initiated, waiting for response...');
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('📬 [iOS IAP] Purchase update: ${purchaseDetails.status}');
      debugPrint('   Product ID: ${purchaseDetails.productID}');
      debugPrint('   Transaction ID: ${purchaseDetails.purchaseID}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('⏳ [iOS IAP] Purchase pending...');
          break;

        case PurchaseStatus.purchased:
          debugPrint('✅ [iOS IAP] Purchase successful!');
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          debugPrint('❌ [iOS IAP] Purchase error: ${purchaseDetails.error}');
          onPurchaseError?.call(
            purchaseDetails.error?.message ?? 'Purchase failed',
          );
          break;

        case PurchaseStatus.restored:
          debugPrint('♻️ [iOS IAP] Purchase restored');
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.canceled:
          debugPrint('🚫 [iOS IAP] Purchase canceled by user');
          onPurchaseError?.call('Purchase canceled');
          break;
      }

      // Complete pending purchase
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint('🔄 [iOS IAP] Completing pending purchase...');
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle successful purchase
  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    // Verify purchase with your backend
    debugPrint('🔐 [iOS IAP] Verifying purchase with backend...');

    // Extract receipt data (iOS specific)
    if (Platform.isIOS) {
      final iosPurchaseDetails = purchaseDetails as AppStorePurchaseDetails;
      final String receiptData =
          iosPurchaseDetails.verificationData.serverVerificationData;

      debugPrint('📄 [iOS IAP] Receipt data length: ${receiptData.length}');

      // Call success callback with purchase details
      onPurchaseSuccess?.call(purchaseDetails);
    }
  }

  /// Restore previous purchases (required by Apple)
  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('♻️ [iOS IAP] Restoring purchases...');

    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('✅ [iOS IAP] Restore purchases initiated');
    } catch (e) {
      debugPrint('❌ [iOS IAP] Restore purchases error: $e');
      throw Exception('Failed to restore purchases: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _subscription.cancel();
    _isInitialized = false;
    debugPrint('🔴 [iOS IAP] Service disposed');
  }

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Get product price as string
  String getProductPrice() {
    final product = getPrivateFrequencyProduct();
    return product?.price ?? '₹99';
  }
}
