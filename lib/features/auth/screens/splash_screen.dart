import 'package:flutter/material.dart';
import '../../../core/auth_storage_service.dart';
import '../../../shared/services/http_client.dart';
import '../../../injection.dart';
import '../../../core/websocket_client.dart';

/// Splash screen that checks for saved authentication
/// and routes to appropriate screen (Radio or Login)
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash screen for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user has valid saved session
      final hasValidSession = await AuthStorageService.hasValidSession();

      if (!mounted) return;

      if (hasValidSession) {
        // Get saved token and user data
        final token = await AuthStorageService.getToken();
        final user = await AuthStorageService.getUser();

        if (token != null && user != null) {
          print('✅ [Splash] Auto-login successful');
          print('👤 [Splash] User: ${user.name}');

          // Set auth token for HTTP requests
          final httpClient = HttpClient();
          httpClient.setAuthToken(token);

          // Initialize WebSocket connection
          final wsClient = getIt<WebSocketClient>();
          wsClient.connect(token);

          // Navigate to dialer screen (main dashboard)
          Navigator.of(context).pushReplacementNamed('/dialer');
          return;
        }
      }

      // No valid session, navigate to login
      print('ℹ️ [Splash] No valid session, redirecting to login');
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('❌ [Splash] Error during auth check: $e');

      if (!mounted) return;

      // On error, navigate to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.radio,
                  size: 60,
                  color: Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 30),
              // App Name
              const Text(
                'Dhvanicast',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your Personal Radio Network',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 50),
              // Loading Indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
