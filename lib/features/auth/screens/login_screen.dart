import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../../../core/auth_storage_service.dart';
import '../../../providers/auth_bloc.dart';
import '../../../providers/auth_event.dart';
import '../../../providers/auth_state.dart';
import '../../../injection.dart';
import '../../../core/websocket_client.dart';
import '../../../models/user.dart';
import '../../../shared/constants/api_endpoints.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isOtpSent = false;
  bool _isLoading = false;

  // OTP Timer variables
  Timer? _otpTimer;
  int _otpTimeRemaining = 0;
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    print('\n⏱️ ========== OTP TIMER STARTED ==========');
    print('⏰ Starting 60 second countdown');
    print('🕒 Start Time: ${DateTime.now().toIso8601String()}');

    setState(() {
      _otpTimeRemaining = 60; // 60 seconds
      _canResendOtp = false;
    });

    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_otpTimeRemaining > 0) {
          _otpTimeRemaining--;
          if (_otpTimeRemaining % 10 == 0 || _otpTimeRemaining <= 5) {
            print('⏱️ Timer: $_otpTimeRemaining seconds remaining');
          }
        } else {
          print('\n⚠️ ========== OTP TIMER EXPIRED ==========');
          print('⚠️ Timer reached 0 - OTP has expired');
          print('✅ User can now resend OTP');
          print('🕒 Expiry Time: ${DateTime.now().toIso8601String()}');
          print('⚠️ IMPORTANT: User document should NOT be deleted!');
          print('========== TIMER EXPIRED ==========\n');

          _canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  void _sendOtp() async {
    print('\n========== SEND OTP INITIATED ==========');
    print('📧 Email: ${_emailController.text.trim()}');
    print('🕒 Timestamp: ${DateTime.now().toIso8601String()}');

    if (_emailController.text.trim().isNotEmpty) {
      print('✅ Email validation passed');
      setState(() {
        _isLoading = true;
      });

      print('🚀 Dispatching AuthLoginRequested event to BLoC...');
      // Send OTP via API
      context.read<AuthBloc>().add(
        AuthLoginRequested(email: _emailController.text.trim()),
      );
      print('========== SEND OTP REQUEST SENT ==========\n');
    } else {
      print('❌ ERROR: Email is empty!');
      print('========== SEND OTP FAILED ==========\n');
    }
  }

  void _resendOtp() async {
    print('\n========== RESEND OTP INITIATED ==========');
    print('🔄 Resend OTP requested');
    print('📧 Email: ${_emailController.text.trim()}');
    print('🕒 Timestamp: ${DateTime.now().toIso8601String()}');
    print('⏱️ Can Resend: $_canResendOtp');
    print('⏱️ Time Remaining: $_otpTimeRemaining seconds');

    if (_canResendOtp && _emailController.text.trim().isNotEmpty) {
      print('✅ Resend conditions met');
      setState(() {
        _isLoading = true;
      });

      print('🚀 Dispatching AuthLoginRequested event to BLoC for resend...');
      // Resend OTP via API (using same send-otp endpoint)
      context.read<AuthBloc>().add(
        AuthLoginRequested(email: _emailController.text.trim()),
      );

      print('✅ Resend OTP request sent successfully');
      print('========== RESEND OTP REQUEST SENT ==========\n');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has been resent to your email'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('❌ ERROR: Cannot resend OTP');
      print('   - Can Resend: $_canResendOtp');
      print('   - Email Empty: ${_emailController.text.trim().isEmpty}');
      print('========== RESEND OTP FAILED ==========\n');
    }
  }

  void _submit() async {
    print('\n========== VERIFY OTP INITIATED ==========');
    print('✅ Verify OTP button pressed');
    print('📧 Email: ${_emailController.text.trim()}');
    print('🔐 OTP: ${_otpController.text.trim()}');
    print('🕒 Timestamp: ${DateTime.now().toIso8601String()}');

    if (_formKey.currentState?.validate() ?? false) {
      print('✅ Form validation passed');
      setState(() {
        _isLoading = true;
      });

      print('🚀 Dispatching AuthOtpVerifyRequested event to BLoC...');
      // Verify OTP via API
      context.read<AuthBloc>().add(
        AuthOtpVerifyRequested(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
        ),
      );
      print('========== VERIFY OTP REQUEST SENT ==========\n');
    } else {
      print('❌ ERROR: Form validation failed');
      print('========== VERIFY OTP FAILED ==========\n');
    }
  }

  /// Save user data and token for auto-login (30 days)
  Future<void> _saveUserDataToPrefs(User user, String token) async {
    await AuthStorageService.saveAuthData(token: token, user: user);

    // Send FCM token to backend
    _sendFCMTokenToBackend(token);
  }

  /// Send FCM token to backend after login
  Future<void> _sendFCMTokenToBackend(String accessToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('pending_fcm_token');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final response = await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/users/update-fcm-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'fcmToken': fcmToken}),
        );

        if (response.statusCode == 200) {
          print('✅ [FCM] Token synced with backend');
          await prefs.remove('pending_fcm_token');
        } else {
          print('⚠️ [FCM] Failed to sync token: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ [FCM] Error sending token to backend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = false;
        });

        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is AuthOtpSent) {
          setState(() {
            _isOtpSent = true;
          });
          _startOtpTimer(); // Start 60 second timer
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthSuccess) {
          print('✅ Login Success!');
          print('🔑 Token: ${state.token}');
          print('👤 User: ${state.user.name}');

          // Save user data and token to SharedPreferences for LiveKit
          _saveUserDataToPrefs(state.user, state.token);

          // Initialize WebSocket connection with token
          final wsClient = getIt<WebSocketClient>();
          print('🔌 Initializing WebSocket connection...');
          wsClient.connect(state.token);

          // Navigate immediately without showing SnackBar
          Navigator.pushReplacementNamed(context, '/dialer');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userFriendlyMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a1a), Color(0xFF2a2a2a)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo and Welcome Section
                            Container(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2a2a2a),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: const Color(0xFF00ff88),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(48),
                                      child: Image.asset(
                                        'assets/images/app_logo.png',
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'DC Audio Rooms',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Connect & Communicate',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Login Form Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2a2a),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Sign in to continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled:
                                        !_isOtpSent, // Disable email field after OTP is sent
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: TextStyle(
                                        color: _isOtpSent
                                            ? Colors.white38
                                            : Colors.white70,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email,
                                        color: _isOtpSent
                                            ? Colors.white38
                                            : const Color(0xFF00ff88),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF555555),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF00ff88),
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF555555),
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: _isOtpSent
                                          ? const Color(0xFF151515)
                                          : const Color(0xFF1a1a1a),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Enter email address';
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(v.trim()))
                                        return 'Enter valid email';
                                      return null;
                                    },
                                    style: TextStyle(
                                      color: _isOtpSent
                                          ? Colors.white54
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // OTP Field (only show if OTP is sent)
                                  if (_isOtpSent) ...[
                                    TextFormField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Enter OTP',
                                        labelStyle: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          color: Color(0xFF00ff88),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF555555),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF00ff88),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF1a1a1a),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter OTP';
                                        if (v.trim().length < 4)
                                          return 'Enter valid OTP';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Login Button
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF00ff88),
                                          Color(0xFF00dd77),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00ff88,
                                          ).withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isOtpSent
                                          ? _submit
                                          : (_emailController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? _sendOtp
                                                : null),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _isOtpSent
                                                  ? 'Sign In'
                                                  : 'Send OTP',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Resend OTP section (only show when OTP is sent)
                                  if (_isOtpSent) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_otpTimeRemaining > 0) ...[
                                          Text(
                                            'Resend OTP in $_otpTimeRemaining seconds',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ] else ...[
                                          TextButton(
                                            onPressed: _canResendOtp
                                                ? _resendOtp
                                                : null,
                                            child: const Text(
                                              'Resend OTP',
                                              style: TextStyle(
                                                color: Color(0xFF00ff88),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Sign Up Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Don't have an account? ",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/signup',
                                          );
                                        },
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            color: Color(0xFF00ff88),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
