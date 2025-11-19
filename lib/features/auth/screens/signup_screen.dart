import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../providers/auth_bloc.dart';
import '../../../providers/auth_event.dart';
import '../../../providers/auth_state.dart';
import '../../../models/user.dart';
import '../../../injection.dart';
import '../../../core/websocket_client.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _currentStep = 0;
  String? _selectedState;

  // List of Indian states and union territories
  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

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
    _nameController.dispose();
    _stateController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_emailController.text.trim().isNotEmpty &&
        _ageController.text.trim().isNotEmpty &&
        _mobileController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        _selectedState != null &&
        _selectedState!.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      final age = int.tryParse(_ageController.text.trim()) ?? 0;

      // Register user via API
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          age: age,
          state: _selectedState!,
          mobile: _mobileController.text.trim(),
        ),
      );
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Verify OTP via API
      context.read<AuthBloc>().add(
        AuthOtpVerifyRequested(
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Dhvani Cast!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has been created successfully',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/dialer');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save user data and token to SharedPreferences for LiveKit initialization
  Future<void> _saveUserDataToPrefs(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save user data as JSON (using toJson method from User model)
      final userData = jsonEncode(user.toJson());
      await prefs.setString('user', userData);

      // Save token
      await prefs.setString('token', token);

      print('💾 [Storage] User data and token saved to SharedPreferences');
      print('👤 [Storage] User: ${user.name}');
      print('🔑 [Storage] Token: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ [Storage] Failed to save user data: $e');
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
            _currentStep = 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthSuccess) {
          // Save user data and token to SharedPreferences for LiveKit
          _saveUserDataToPrefs(state.user, state.token);

          // Initialize WebSocket connection with token
          final wsClient = getIt<WebSocketClient>();
          print('🔌 Initializing WebSocket connection...');
          wsClient.connect(state.token);

          _showSuccessDialog();
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a1a), Color(0xFF2a2a2a)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2a2a2a),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                    color: const Color(0xFF00ff88),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_add,
                                  size: 40,
                                  color: Color(0xFF00ff88),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Join Dhvanicast',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create your account',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Progress Indicator
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildStepIndicator(
                                0,
                                'Details',
                                _currentStep >= 0,
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: _currentStep >= 1
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                              _buildStepIndicator(
                                1,
                                'Verify',
                                _currentStep >= 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Card
                        Expanded(
                          child: Container(
                            width: double.infinity,
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
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _currentStep == 0
                                        ? 'Personal Information'
                                        : 'Verify Your Number',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),

                                  if (_currentStep == 0) ...[
                                    // Name Field
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      icon: Icons.person_outline,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter your name';
                                        if (v.trim().length < 2)
                                          return 'Enter valid name';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // State Dropdown Field
                                    _buildStateDropdown(),
                                    const SizedBox(height: 20),

                                    // Email Field
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter email address';
                                        if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(v.trim()))
                                          return 'Enter valid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Age Field
                                    _buildTextField(
                                      controller: _ageController,
                                      label: 'Age',
                                      icon: Icons.cake,
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter your age';
                                        final age = int.tryParse(v.trim());
                                        if (age == null ||
                                            age < 13 ||
                                            age > 120)
                                          return 'Age must be between 13-120';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Mobile Number Field (Required)
                                    _buildTextField(
                                      controller: _mobileController,
                                      label: 'Mobile Number',
                                      icon: Icons.phone_android,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter mobile number';
                                        if (v.trim().length != 10)
                                          return 'Mobile must be 10 digits';
                                        if (!RegExp(
                                          r'^[0-9]{10}$',
                                        ).hasMatch(v.trim()))
                                          return 'Enter valid mobile number';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 32),

                                    // Send OTP Button
                                    Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF667eea,
                                            ).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                if (_nameController.text
                                                        .trim()
                                                        .isNotEmpty &&
                                                    _selectedState != null &&
                                                    _selectedState!
                                                        .isNotEmpty &&
                                                    _emailController.text
                                                        .trim()
                                                        .isNotEmpty &&
                                                    _ageController.text
                                                        .trim()
                                                        .isNotEmpty) {
                                                  _sendOtp();
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Please fill all fields',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
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
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                'Send OTP',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ] else ...[
                                    // OTP Verification Step
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.sms_outlined,
                                            size: 48,
                                            color: Color(0xFF667eea),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'OTP sent to your email',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _emailController.text,
                                            style: const TextStyle(
                                              color: Color(0xFF718096),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // OTP Field
                                    _buildTextField(
                                      controller: _otpController,
                                      label: 'Enter OTP',
                                      icon: Icons.lock_outline,
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter OTP';
                                        if (v.trim().length < 4)
                                          return 'Enter valid OTP';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Verify Button
                                    Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF48BB78),
                                            Color(0xFF38A169),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF48BB78,
                                            ).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _submit,
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
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Resend OTP
                                    TextButton(
                                      onPressed: _sendOtp,
                                      child: const Text(
                                        'Resend OTP',
                                        style: TextStyle(
                                          color: Color(0xFF667eea),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // Login Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          color: Color(0xFF718096),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/login',
                                          );
                                        },
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Color(0xFF667eea),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF00ff88)
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF00ff88) : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF00ff88)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF555555)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00ff88), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1a1a1a),
      ),
      style: const TextStyle(color: Colors.white),
      validator: validator,
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedState,
      decoration: InputDecoration(
        labelText: 'State/Region',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFF00ff88),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF555555)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00ff88), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1a1a1a),
      ),
      dropdownColor: const Color(0xFF2a2a2a),
      style: const TextStyle(color: Colors.white),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00ff88)),
      isExpanded: true,
      hint: const Text(
        'Select your state',
        style: TextStyle(color: Colors.white70),
      ),
      items: _indianStates.map((String state) {
        return DropdownMenuItem<String>(
          value: state,
          child: Text(state, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedState = newValue;
          _stateController.text = newValue ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your state';
        }
        return null;
      },
    );
  }
}
