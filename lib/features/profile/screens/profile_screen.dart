import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  String? _avatarBase64; // Store avatar image as base64
  String? _currentAvatar; // Current avatar from server

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
      setState(() {
        _currentAvatar = state.user.avatar;
      });
    } else if (state is AuthSuccess) {
      _nameController.text = state.user.name;
      _stateController.text = state.user.state;
      _mobileController.text = state.user.mobile ?? '';
      setState(() {
        _currentAvatar = state.user.avatar;
      });
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
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
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
                              child: _buildProfileImage(),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00ff88),
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

                      // Account Management Section
                      _buildSectionTitle('Account Management'),
                      const SizedBox(height: 16),
                      _buildActionTile(
                        title: 'Temporary Account Delete',
                        icon: Icons.pause_circle_outline,
                        color: Colors.orange,
                        onTap: _showTemporaryDeleteDialog,
                      ),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        title: 'Permanent Account Delete',
                        icon: Icons.delete_forever_outlined,
                        color: const Color(0xFFff4444),
                        onTap: _showPermanentDeleteDialog,
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

    // Call the API to update profile (including avatar if changed)
    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        name: _nameController.text.trim(),
        state: _stateController.text.trim(),
        avatar: _avatarBase64, // Send avatar if updated
      ),
    );
  }

  // Build profile image widget
  Widget _buildProfileImage() {
    try {
      // Priority: newly selected image > current avatar > default icon
      if (_avatarBase64 != null && _avatarBase64!.isNotEmpty) {
        print('🖼️ [PROFILE] Showing newly selected image');
        final bytes = base64Decode(_avatarBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              print('❌ [PROFILE] Error displaying new image: $error');
              return const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF667eea),
              );
            },
          ),
        );
      } else if (_currentAvatar != null &&
          _currentAvatar!.isNotEmpty &&
          _currentAvatar != '👤') {
        print('🖼️ [PROFILE] Showing current avatar from server');
        final bytes = base64Decode(_currentAvatar!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              print('❌ [PROFILE] Error displaying current avatar: $error');
              return const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF667eea),
              );
            },
          ),
        );
      } else {
        print('🖼️ [PROFILE] Showing default icon');
        return const Icon(Icons.person, size: 60, color: Color(0xFF667eea));
      }
    } catch (e) {
      print('❌ [PROFILE] Error building profile image: $e');
      return const Icon(Icons.person, size: 60, color: Color(0xFF667eea));
    }
  }

  // Show image source dialog (Camera or Gallery)
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2a2a2a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Profile Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: const Color(0xFF00ff88),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),

                // Camera
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: const Color(0xFF4a90e2),
                  onTap: () {
                    Navigator.pop(context);
                    _openCamera();
                  },
                ),

                // Remove (if has avatar)
                if (_avatarBase64 != null ||
                    (_currentAvatar != null && _currentAvatar != '👤'))
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    label: 'Remove',
                    color: const Color(0xFFff4444),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color, size: 35),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Pick image from gallery
  void _pickFromGallery() async {
    print('📷 [PROFILE] Opening gallery...');

    // Request photos permission
    PermissionStatus status;
    if (await Permission.photos.isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      print('❌ [PROFILE] Gallery permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery permission is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ [PROFILE] Image selected: ${image.path}');
        await _processImage(image);
      }
    } catch (e) {
      print('❌ [PROFILE] Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open camera
  void _openCamera() async {
    print('📸 [PROFILE] Opening camera...');

    final status = await Permission.camera.request();
    if (status.isDenied) {
      print('❌ [PROFILE] Camera permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (photo != null) {
        print('✅ [PROFILE] Photo captured: ${photo.path}');
        await _processImage(photo);
      }
    } catch (e) {
      print('❌ [PROFILE] Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Process selected/captured image
  Future<void> _processImage(XFile image) async {
    try {
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('📏 [PROFILE] Image size: ${bytes.length} bytes');
      print('🔤 [PROFILE] Base64 length: ${base64Image.length}');

      setState(() {
        _avatarBase64 = base64Image;
      });

      print('✅ [PROFILE] Profile image updated in state');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Profile photo updated! Don't forget to save changes.",
            ),
            backgroundColor: Color(0xFF00ff88),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [PROFILE] Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove profile image
  void _removeProfileImage() {
    setState(() {
      _avatarBase64 = '👤'; // Set to default emoji
      _currentAvatar = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile photo removed! Don't forget to save changes."),
        backgroundColor: Color(0xFF00ff88),
        duration: Duration(seconds: 2),
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

  void _showTemporaryDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Temporary Delete', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Your account will be deactivated temporarily. You can reactivate it anytime by logging in again.\n\nYour data will be preserved.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthTemporaryDeleteRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFff4444),
              size: 28,
            ),
            SizedBox(width: 12),
            Text('Permanent Delete', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ WARNING: This action cannot be undone!',
              style: TextStyle(
                color: Color(0xFFff4444),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your account and all associated data will be permanently deleted:\n\n• Profile information\n• Messages and audio files\n• Frequencies and groups\n• Friends and connections\n\nThis action is irreversible.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalConfirmationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFff4444),
            ),
            child: const Text(
              'Delete Forever',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Final Confirmation',
          style: TextStyle(color: Color(0xFFff4444)),
        ),
        content: const Text(
          'Are you absolutely sure you want to permanently delete your account?\n\nType "DELETE" to confirm.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthPermanentDeleteRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFff4444),
            ),
            child: const Text(
              'Yes, Delete Forever',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
