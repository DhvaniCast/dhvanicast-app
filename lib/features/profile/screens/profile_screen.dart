import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../providers/auth_bloc.dart';
import '../../../providers/auth_event.dart';
import '../../../providers/auth_state.dart';
import '../../policies/screens/privacy_policy_screen.dart';
import '../../policies/screens/refund_policy_screen.dart';
import '../../policies/screens/terms_conditions_screen.dart';
import '../../policies/screens/help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load user profile when screen initializes
    context.read<AuthBloc>().add(AuthProfileRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stateController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _loadProfileData(AuthState state) {
    if (state is AuthProfileLoaded) {
      _nameController.text = state.user.name;
      _stateController.text = state.user.state;
      _mobileController.text = state.user.mobile ?? '';
    } else if (state is AuthSuccess) {
      _nameController.text = state.user.name;
      _stateController.text = state.user.state;
      _mobileController.text = state.user.mobile ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = state is AuthLoading;
        });

        if (state is AuthProfileLoaded) {
          _loadProfileData(state);
        } else if (state is AuthSuccess) {
          _loadProfileData(state);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthLoggedOut) {
          Navigator.pushReplacementNamed(context, '/login');
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
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1a1a1a),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a1a), Color(0xFF2a2a2a)],
              stops: [0.0, 0.5],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF667eea),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF48BB78),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text
                            : 'Loading...',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stateController.text.isNotEmpty
                            ? _stateController.text
                            : 'Loading...',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        label: 'Full Name',
                        controller: _nameController,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        label: 'State/Region',
                        controller: _stateController,
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        label: 'Mobile Number',
                        controller: _mobileController,
                        icon: Icons.phone_outlined,
                        enabled: false,
                      ),
                      const SizedBox(height: 32),

                      // Settings Section
                      _buildSectionTitle('Settings'),
                      const SizedBox(height: 16),
                      _buildSettingsTile(
                        title: 'Notifications',
                        subtitle: 'Receive push notifications',
                        icon: Icons.notifications_outlined,
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                          activeColor: const Color(0xFF00ff88),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsTile(
                        title: 'Location Services',
                        subtitle: 'Allow location tracking',
                        icon: Icons.location_on_outlined,
                        trailing: Switch(
                          value: _locationEnabled,
                          onChanged: (value) {
                            setState(() {
                              _locationEnabled = value;
                            });
                          },
                          activeColor: const Color(0xFF00ff88),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Actions Section
                      _buildSectionTitle('Legal & Support'),
                      const SizedBox(height: 16),
                      _buildActionTile(
                        title: 'Privacy Policy',
                        icon: Icons.privacy_tip_outlined,
                        color: Colors.white70,
                        onTap: _openPrivacyPolicy,
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        title: 'Refund Policy',
                        icon: Icons.payment_outlined,
                        color: Colors.white70,
                        onTap: _openRefundPolicy,
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        title: 'Terms & Conditions',
                        icon: Icons.description_outlined,
                        color: Colors.white70,
                        onTap: _openTermsConditions,
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        title: 'Help & Support',
                        icon: Icons.help_outline,
                        color: const Color(0xFF00ff88),
                        onTap: _openHelpSupport,
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00ff88),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
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
        fillColor: enabled ? const Color(0xFF1a1a1a) : const Color(0xFF333333),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF555555)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00ff88).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF00ff88), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color, size: 16),
      ),
    );
  }

  void _saveProfile() {
    if (_nameController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Call the API to update profile
    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        name: _nameController.text.trim(),
        state: _stateController.text.trim(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Call logout API
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFff4444),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  void _openRefundPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RefundPolicyScreen()),
    );
  }

  void _openTermsConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
    );
  }

  void _openHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
    );
  }
}
