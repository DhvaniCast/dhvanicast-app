import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;
  bool _microphoneGranted = false;
  bool _cameraGranted = false;
  bool _storageGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final micStatus = await Permission.microphone.status;
      final cameraStatus = await Permission.camera.status;

      setState(() {
        _microphoneGranted = micStatus.isGranted;
        _cameraGranted = cameraStatus.isGranted;
        _storageGranted =
            true; // Storage permission handled by scoped storage on Android 10+
      });

      // If all permissions are granted, navigate automatically
      if (_allPermissionsGranted()) {
        _navigateToDialer();
      }
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
    }
  }

  bool _allPermissionsGranted() {
    return _microphoneGranted && _cameraGranted;
  }

  Future<void> _requestPermissions() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      debugPrint('🎤 Requesting permissions...');

      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      debugPrint('🎤 Microphone permission: $micStatus');

      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      debugPrint('📷 Camera permission: $cameraStatus');

      setState(() {
        _microphoneGranted = micStatus.isGranted;
        _cameraGranted = cameraStatus.isGranted;
        _storageGranted = true;
      });

      if (_allPermissionsGranted()) {
        _navigateToDialer();
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e, stack) {
      debugPrint('❌ Error requesting permissions: $e');
      debugPrint('Stack: $stack');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  void _navigateToDialer() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dialer');
      }
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs microphone and camera permissions to function properly. '
          'Please grant these permissions in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToDialer();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a1a), Color(0xFF2a2a2a)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Harborleaf Radio',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voice Communication App',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
                const SizedBox(height: 48),

                // Permissions List
                _buildPermissionItem(
                  icon: Icons.mic,
                  title: 'Microphone',
                  description: 'For voice communication',
                  isGranted: _microphoneGranted,
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  description: 'For taking photos',
                  isGranted: _cameraGranted,
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  icon: Icons.folder,
                  title: 'Storage',
                  description: 'For saving media',
                  isGranted: _storageGranted,
                ),
                const SizedBox(height: 48),

                // Grant Permissions Button
                if (!_allPermissionsGranted())
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isRequesting ? null : _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Grant Permissions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                // Skip Button
                if (!_allPermissionsGranted())
                  TextButton(
                    onPressed: _navigateToDialer,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isGranted ? Colors.green : Colors.grey,
              size: 24,
            ),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Icon(
            isGranted ? Icons.check_circle : Icons.circle_outlined,
            color: isGranted ? Colors.green : Colors.grey,
            size: 24,
          ),
        ],
      ),
    );
  }
}
