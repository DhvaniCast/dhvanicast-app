import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:async';
import 'dart:io';
import '../services/private_frequency_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/services/ios_iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

class PrivateFrequencyScreen extends StatefulWidget {
  const PrivateFrequencyScreen({Key? key}) : super(key: key);

  @override
  State<PrivateFrequencyScreen> createState() => _PrivateFrequencyScreenState();
}

class _PrivateFrequencyScreenState extends State<PrivateFrequencyScreen> {
  String? _selectedOption; // 'create' ya 'join'
  List<Map<String, dynamic>> _activeFrequencies = [];
  bool _isLoadingFrequencies = true;
  final PrivateFrequencyService _apiService = PrivateFrequencyService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveFrequencies();
    // Refresh every minute to update countdown
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _loadActiveFrequencies();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveFrequencies() async {
    try {
      final frequencies = await _apiService.getMyFrequencies();
      if (mounted) {
        setState(() {
          _activeFrequencies = frequencies;
          _isLoadingFrequencies = false;
        });
      }
    } catch (e) {
      print('Error loading active frequencies: $e');
      if (mounted) {
        setState(() {
          _isLoadingFrequencies = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          'Private Frequency',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _selectedOption == null
            ? _buildOptionSelection()
            : _selectedOption == 'create'
            ? const CreateFrequencyFlow()
            : const JoinFrequencyFlow(),
      ),
    );
  }

  // Initial option selection screen
  Widget _buildOptionSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Frequencies Section
          if (_activeFrequencies.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.radio, color: Color(0xFF00ff88), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Active Frequencies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._activeFrequencies.map(
              (freq) => _buildActiveFrequencyCard(freq),
            ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFF333333), thickness: 1),
            const SizedBox(height: 32),
          ],

          // Header
          Center(
            child: Column(
              children: [
                const Icon(Icons.lock, size: 80, color: Color(0xFF00ff88)),
                const SizedBox(height: 24),
                const Text(
                  'Private Frequency',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create your own secure frequency or join an existing one',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),

          // Create Frequency Button
          _buildOptionCard(
            icon: Icons.add_circle_outline,
            title: 'Create Frequency',
            description:
                'Start your own private frequency with password protection',
            onTap: () {
              setState(() {
                _selectedOption = 'create';
              });
            },
          ),

          const SizedBox(height: 20),

          // Join Frequency Button
          _buildOptionCard(
            icon: Icons.login,
            title: 'Join Frequency',
            description: 'Connect to an existing private frequency',
            onTap: () {
              setState(() {
                _selectedOption = 'join';
              });
            },
          ),
        ],
      ),
    );
  }

  // Build active frequency card with countdown timer
  Widget _buildActiveFrequencyCard(Map<String, dynamic> freq) {
    // Calculate remaining time
    final expiresAt = DateTime.parse(freq['expiresAt']);
    final now = DateTime.now();
    final remaining = expiresAt.difference(now);

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    final isExpired = remaining.isNegative;
    final timeString = isExpired
        ? 'Expired'
        : '${hours}h ${minutes}m remaining';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExpired
              ? [const Color(0xFF2a2a2a), const Color(0xFF1a1a1a)]
              : [
                  const Color(0xFF00ff88).withOpacity(0.1),
                  const Color(0xFF00aaff).withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? const Color(0xFF444444)
              : const Color(0xFF00ff88).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Frequency Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExpired
                  ? const Color(0xFF444444).withOpacity(0.3)
                  : const Color(0xFF00ff88).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lock,
              color: isExpired
                  ? const Color(0xFF666666)
                  : const Color(0xFF00ff88),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Frequency Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  freq['name'] ?? 'Private Frequency',
                  style: TextStyle(
                    color: isExpired ? Colors.white60 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${freq['frequencyValue']} MHz',
                  style: TextStyle(
                    color: isExpired ? Colors.white38 : const Color(0xFF00ff88),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${freq['frequencyNumber']}',
                  style: TextStyle(
                    color: isExpired ? Colors.white30 : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Timer and Join Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired
                      ? const Color(0xFF444444).withOpacity(0.3)
                      : const Color(0xFF00ff88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpired ? Icons.timer_off : Icons.timer,
                      color: isExpired
                          ? const Color(0xFF666666)
                          : const Color(0xFF00ff88),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        timeString,
                        style: TextStyle(
                          color: isExpired
                              ? const Color(0xFF666666)
                              : const Color(0xFF00ff88),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!isExpired)
                ElevatedButton(
                  onPressed: () {
                    // Navigate to live radio with this frequency
                    Navigator.pushNamed(
                      context,
                      '/live_radio',
                      arguments: {
                        'frequencyNumber': freq['frequencyNumber'],
                        'frequencyValue': freq['frequencyValue'],
                        'frequencyName': freq['name'],
                        'isPrivate': true,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff88),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'JOIN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2a2a2a), Color(0xFF1a1a1a)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00ff88).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00ff88).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFF00ff88)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Create Frequency Flow
class CreateFrequencyFlow extends StatefulWidget {
  const CreateFrequencyFlow({Key? key}) : super(key: key);

  @override
  State<CreateFrequencyFlow> createState() => _CreateFrequencyFlowState();
}

class _CreateFrequencyFlowState extends State<CreateFrequencyFlow> {
  int _currentStep = 0; // 0: Payment, 1: Details, 2: Share
  final TextEditingController _passwordController = TextEditingController();
  String? _generatedFrequencyNumber;
  String? _generatedFrequencyName;
  double? _generatedFrequencyValue;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Android: Razorpay
  late Razorpay _razorpay;
  String? _orderId;
  String? _paymentId;
  String? _signature;

  // iOS: In-App Purchase
  final IosIapService _iapService = IosIapService();
  String? _iapReceiptData;
  String? _iapTransactionId;

  final PrivateFrequencyService _apiService = PrivateFrequencyService();

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      // Setup Razorpay for Android
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } else if (Platform.isIOS) {
      // Setup iOS IAP
      _setupIosIap();
    }
  }

  Future<void> _setupIosIap() async {
    try {
      await _iapService.initialize();

      // Set callbacks
      _iapService.onPurchaseSuccess = (PurchaseDetails purchase) {
        debugPrint('✅ Purchase successful in UI');

        if (purchase is AppStorePurchaseDetails) {
          setState(() {
            _iapReceiptData = purchase.verificationData.serverVerificationData;
            _iapTransactionId = purchase.purchaseID ?? '';
            _currentStep = 1;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment Successful!'),
              backgroundColor: Color(0xFF00ff88),
            ),
          );
        }
      };

      _iapService.onPurchaseError = (String error) {
        debugPrint('❌ Purchase error in UI: $error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      };

      debugPrint('✅ iOS IAP setup complete');
    } catch (e) {
      debugPrint('❌ iOS IAP setup error: $e');
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      _razorpay.clear();
    }
    _passwordController.dispose();
    super.dispose();
  }

  // Android Razorpay handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      _paymentId = response.paymentId;
      _signature = response.signature;
      _currentStep = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment Successful!'),
        backgroundColor: Color(0xFF00ff88),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (Platform.isIOS) {
        // iOS: Use In-App Purchase
        await _iapService.purchasePrivateFrequency();
      } else if (Platform.isAndroid) {
        // Android: Use Razorpay
        final orderData = await _apiService.createPaymentOrder();

        setState(() {
          _orderId = orderData['orderId'];
        });

        var options = {
          'key': orderData['keyId'],
          'amount': orderData['amount'],
          'currency': orderData['currency'],
          'name': 'DC Audio Rooms',
          'description': 'Private Frequency - 12 Hours',
          'order_id': orderData['orderId'],
          'prefill': {'contact': '', 'email': ''},
          'theme': {'color': '#00ff88'},
        };

        _razorpay.open(options);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createFrequency() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> frequencyData;

      if (Platform.isIOS) {
        // iOS: Verify IAP receipt with backend
        if (_iapReceiptData == null || _iapTransactionId == null) {
          throw Exception('Payment verification failed');
        }

        frequencyData = await _apiService.verifyIosIapAndCreate(
          receiptData: _iapReceiptData!,
          transactionId: _iapTransactionId!,
          password: _passwordController.text,
        );
      } else if (Platform.isAndroid) {
        // Android: Verify Razorpay payment
        if (_orderId == null || _paymentId == null || _signature == null) {
          throw Exception('Payment verification failed');
        }

        frequencyData = await _apiService.verifyPaymentAndCreate(
          orderId: _orderId!,
          paymentId: _paymentId!,
          signature: _signature!,
          password: _passwordController.text,
        );
      } else {
        throw Exception('Unsupported platform');
      }

      setState(() {
        _generatedFrequencyNumber = frequencyData['frequencyNumber'];
        _generatedFrequencyName = frequencyData['name'];
        _generatedFrequencyValue = frequencyData['frequencyValue'];
        _currentStep = 2;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Private Frequency Created Successfully!'),
          backgroundColor: Color(0xFF00ff88),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Share via any app (WhatsApp, SMS, etc.)
  Future<void> _shareViaApps() async {
    final shareUrl =
        'https://dhvanicast.app/join?freq=$_generatedFrequencyNumber';

    final shareText =
        '''
🔒 Join My Private Frequency!
📻 Frequency Number: $_generatedFrequencyNumber
📻 Frequency Name: $_generatedFrequencyName
🔑 Password: ${_passwordController.text}

🔗 Direct Link: $shareUrl

Download DC Audio Rooms to join!
''';

    try {
      await Share.share(
        shareText,
        subject: 'Join my Private Frequency on DC Audio Rooms',
      );
    } catch (e) {
      print('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to share'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share via phone contacts
  Future<void> _shareViaContacts() async {
    try {
      // Request contacts permission
      final permission = await Permission.contacts.request();

      if (permission.isGranted) {
        // Check if contacts are available
        if (await FlutterContacts.requestPermission()) {
          // Open contacts picker
          final contacts = await FlutterContacts.getContacts(
            withProperties: true,
            withPhoto: false,
          );

          if (contacts.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📱 No contacts found on your device'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          // Show contact picker dialog
          if (mounted) {
            _showContactPickerDialog(contacts);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Contacts permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Contacts permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error accessing contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to open contacts'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show contact picker dialog
  void _showContactPickerDialog(List<Contact> contacts) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.contacts,
                    color: Color(0xFF00ff88),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Contact',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contacts list
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final hasPhone = contact.phones.isNotEmpty;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00ff88),
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: hasPhone
                          ? Text(
                              contact.phones.first.number,
                              style: const TextStyle(color: Colors.white54),
                            )
                          : const Text(
                              'No phone number',
                              style: TextStyle(color: Colors.white30),
                            ),
                      trailing: hasPhone
                          ? const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF00ff88),
                              size: 16,
                            )
                          : null,
                      onTap: hasPhone
                          ? () {
                              Navigator.pop(context);
                              _shareToContact(contact);
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Share to selected contact
  Future<void> _shareToContact(Contact contact) async {
    final shareUrl =
        'https://dhvanicast.app/join?freq=$_generatedFrequencyNumber';

    final shareText =
        '''
Hi ${contact.displayName}! 

🔒 Join My Private Frequency on DC Audio Rooms!

📻 Frequency Number: $_generatedFrequencyNumber
📻 Frequency Name: $_generatedFrequencyName
🔑 Password: ${_passwordController.text}

🔗 Direct Link: $shareUrl

Download DC Audio Rooms app to join!
''';

    try {
      await Share.share(
        shareText,
        subject: 'Join my Private Frequency on DC Audio Rooms',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Shared with ${contact.displayName}'),
            backgroundColor: const Color(0xFF00ff88),
          ),
        );
      }
    } catch (e) {
      print('Error sharing to contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to share'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareFrequency() {
    // Generate shareable URL
    final shareUrl =
        'https://dhvanicast.app/join?freq=$_generatedFrequencyNumber';

    final shareText =
        '''
🔒 Join My Private Frequency!
📻 Frequency Number: $_generatedFrequencyNumber
📻 Frequency Name: $_generatedFrequencyName
🔑 Password: ${_passwordController.text}

🔗 Direct Link: $shareUrl

Download DC Audio Rooms to join!
''';

    // Show dialog with URL and frequency number
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Icon(Icons.share, size: 64, color: Color(0xFF00ff88)),
              const SizedBox(height: 16),
              const Text(
                'Share Frequency',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Frequency Number Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00ff88), Color(0xFF00cc6a)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Frequency Number',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedFrequencyNumber!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // URL Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00ff88).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.link,
                          color: Color(0xFF00ff88),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Share Link',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      shareUrl,
                      style: const TextStyle(
                        color: Color(0xFF00ff88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Copy to Clipboard Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Frequency details copied to clipboard!',
                        ),
                        backgroundColor: Color(0xFF00ff88),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  label: const Text(
                    'COPY ALL DETAILS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff88),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Copy URL Only Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareUrl));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔗 Link copied to clipboard!'),
                        backgroundColor: Color(0xFF00ff88),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.link, size: 20),
                  label: const Text(
                    'COPY LINK ONLY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00ff88),
                    side: const BorderSide(color: Color(0xFF00ff88), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Share via Apps Button (WhatsApp, SMS, etc.)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareViaApps();
                  },
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text(
                    'SHARE VIA APPS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Share to Contacts Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareViaContacts();
                  },
                  icon: const Icon(Icons.contacts, size: 20),
                  label: const Text(
                    'SHARE TO CONTACTS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Close Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step Indicator
          _buildStepIndicator(),
          const SizedBox(height: 32),

          // Content based on current step
          if (_currentStep == 0) _buildPaymentStep(),
          if (_currentStep == 1) _buildDetailsStep(),
          if (_currentStep == 2) _buildShareStep(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, 'Payment', _currentStep >= 0),
        _buildStepLine(_currentStep >= 1),
        _buildStepCircle(2, 'Details', _currentStep >= 1),
        _buildStepLine(_currentStep >= 2),
        _buildStepCircle(3, 'Share', _currentStep >= 2),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF00ff88) : const Color(0xFF444444),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00ff88)
                  : const Color(0xFF666666),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00ff88) : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? const Color(0xFF00ff88) : const Color(0xFF444444),
    );
  }

  Widget _buildPaymentStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00ff88).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.payment, size: 64, color: Color(0xFF00ff88)),
          const SizedBox(height: 24),
          const Text(
            'Payment Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create your private frequency',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Price Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00ff88), Color(0xFF00cc6a)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  '₹11',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '12 Hours Access',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Features List
          _buildFeatureItem('🔒 Password Protected'),
          _buildFeatureItem('👥 Share with Friends'),
          _buildFeatureItem('🎯 Private Communication'),
          _buildFeatureItem('⏰ 12 Hours Access'),

          const SizedBox(height: 32),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ff88),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
              child: const Text(
                'PROCEED TO PAYMENT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00ff88), size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00ff88).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setup Your Frequency',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter a password for your private frequency',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Info Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00ff88).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF00ff88), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Frequency name and number will be automatically assigned',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Password Input
          const Text(
            'Password',
            style: TextStyle(
              color: Color(0xFF00ff88),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter secure password',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1a1a1a),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF444444),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF00ff88),
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF00ff88)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF00ff88),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Create Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _createFrequency,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ff88),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
              child: const Text(
                'CREATE FREQUENCY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareStep() {
    // Generate shareable URL
    final shareUrl =
        'https://dhvanicast.app/join?freq=$_generatedFrequencyNumber';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00ff88).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 80, color: Color(0xFF00ff88)),
          const SizedBox(height: 24),
          const Text(
            'Frequency Created!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share these details with your friends',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Frequency Number Highlight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00ff88), Color(0xFF00cc6a)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00ff88).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Your Frequency Number',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _generatedFrequencyNumber!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Frequency Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00ff88).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow('Name', _generatedFrequencyName!),
                const Divider(color: Color(0xFF444444), height: 24),
                _buildDetailRow('Password', _passwordController.text),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Share Link Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00ff88).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link, color: Color(0xFF00ff88), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Share Link',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  shareUrl,
                  style: const TextStyle(
                    color: Color(0xFF00ff88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Share Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _shareFrequency,
              icon: const Icon(Icons.share, size: 24),
              label: const Text(
                'SHARE FREQUENCY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ff88),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Done Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00ff88),
                side: const BorderSide(color: Color(0xFF00ff88), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF00ff88),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Join Frequency Flow
class JoinFrequencyFlow extends StatefulWidget {
  const JoinFrequencyFlow({Key? key}) : super(key: key);

  @override
  State<JoinFrequencyFlow> createState() => _JoinFrequencyFlowState();
}

class _JoinFrequencyFlowState extends State<JoinFrequencyFlow> {
  final TextEditingController _frequencyNumberController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final PrivateFrequencyService _apiService = PrivateFrequencyService();

  @override
  void dispose() {
    _frequencyNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _joinFrequency() async {
    if (_frequencyNumberController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Join private frequency via API
      final frequencyData = await _apiService.joinFrequency(
        frequencyNumber: _frequencyNumberController.text,
        password: _passwordController.text,
      );

      // Navigate to live radio screen with frequency data
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/live_radio',
          arguments: {
            'frequencyNumber': frequencyData['frequencyNumber'],
            'frequencyValue': frequencyData['frequencyValue'],
            'frequencyName': frequencyData['name'],
            'isPrivate': true,
            'members': frequencyData['members'], // Pass members list
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00ff88).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.login, size: 64, color: Color(0xFF00ff88)),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Join Private Frequency',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Enter frequency details to connect',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),

            // Frequency Number Input
            const Text(
              'Frequency Number',
              style: TextStyle(
                color: Color(0xFF00ff88),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _frequencyNumberController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter frequency number',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1a1a1a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF444444),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF00ff88),
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Icons.numbers, color: const Color(0xFF00ff88)),
              ),
            ),

            const SizedBox(height: 24),

            // Password Input
            const Text(
              'Password',
              style: TextStyle(
                color: Color(0xFF00ff88),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter password',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1a1a1a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF444444),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF00ff88),
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Icons.lock, color: const Color(0xFF00ff88)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF00ff88),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Join Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinFrequency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ff88),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'JOIN FREQUENCY',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00ff88),
                  side: const BorderSide(color: Color(0xFF00ff88), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
