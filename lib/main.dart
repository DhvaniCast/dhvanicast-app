import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import 'injection.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/permission_screen.dart';
import 'features/dialer/screens/dialer_screen.dart';
import 'features/dialer/screens/private_frequency_screen.dart';
import 'features/communication/screens/communication_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/radio/screens/live_radio_screen.dart';
import 'providers/auth_bloc.dart';

void main() async {
  // Setup error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runZonedGuarded(
    () async {
      // Ensure Flutter bindings are initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Setup dependency injection
      try {
        setupServiceLocator();
        debugPrint('✅ Service locator initialized');
      } catch (e, stack) {
        debugPrint('❌ Error initializing service locator: $e');
        debugPrint('Stack: $stack');
      }

      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('🔴 Uncaught Error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),
      child: MaterialApp(
        title: 'Dhvanicast',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/permissions': (context) => const PermissionScreen(),
          '/dialer': (context) => const DialerScreen(),
          '/private-frequency': (context) => const PrivateFrequencyScreen(),
          '/communication': (context) => const CommunicationScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/live_radio': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return LiveRadioScreen(groupData: args);
          },
        },
        builder: (context, widget) {
          // Add error handling wrapper
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please restart the app',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (!const bool.fromEnvironment('dart.vm.product'))
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            errorDetails.exception.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          };
          return widget ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
