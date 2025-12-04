import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'injection.dart';
import 'firebase_options.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/permission_screen.dart';
import 'features/dialer/screens/dialer_screen.dart';
import 'features/dialer/screens/private_frequency_screen.dart';
import 'features/communication/screens/communication_screen.dart';
import 'features/communication/screens/friend_chat_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/radio/screens/live_radio_screen.dart';
import 'features/social/screens/friends_screen.dart';
import 'providers/auth_bloc.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📲 [FCM] Background message: ${message.notification?.title}');

  if (message.data['type'] == 'incoming_call') {
    debugPrint(
      '📞 [FCM] Incoming call in background from: ${message.data['callerName']}',
    );
    // Local notification will be shown automatically
  }
}

// Local notifications instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

      // Initialize Firebase
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase initialized');

        // Set background message handler
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // Initialize local notifications
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const DarwinInitializationSettings initializationSettingsDarwin =
            DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            );

        const InitializationSettings initializationSettings =
            InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: initializationSettingsDarwin,
            );

        await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('📲 [FCM] Notification tapped: ${response.payload}');
            // TODO: Navigate to incoming call screen
          },
        );

        // Request notification permissions
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('✅ FCM permission status: ${settings.authorizationStatus}');

        // Get FCM token
        String? fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          debugPrint('📲 [FCM TOKEN]: $fcmToken');
          // Save token to backend after user logs in
          _saveFCMTokenLater(fcmToken);
        }

        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            '📲 [FCM] Foreground message: ${message.notification?.title}',
          );

          if (message.data['type'] == 'incoming_call') {
            _showIncomingCallNotification(message.data);
          }
        });
      } catch (e, stack) {
        debugPrint('❌ Error initializing Firebase: $e');
        debugPrint('Stack: $stack');
      }

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

// Save FCM token to backend (called after login)
Future<void> _saveFCMTokenLater(String token) async {
  // Store token locally, will be sent to backend after login
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_fcm_token', token);
  debugPrint(
    '📲 [FCM] Token saved locally, will sync with backend after login',
  );
}

// Show incoming call notification
Future<void> _showIncomingCallNotification(
  Map<String, dynamic> callData,
) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'incoming_calls',
    'Incoming Calls',
    channelDescription: 'Notifications for incoming voice calls',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    playSound: true,
    enableVibration: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    categoryIdentifier: 'INCOMING_CALL',
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    '📞 Incoming Call',
    '${callData['callerName']} is calling...',
    notificationDetails,
    payload: jsonEncode(callData),
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
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/permissions': (context) => const PermissionScreen(),
          '/dialer': (context) => const DialerScreen(),
          '/private-frequency': (context) => const PrivateFrequencyScreen(),
          '/communication': (context) => const CommunicationScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/friends': (context) => const FriendsScreen(),
          '/friend-chat': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return FriendChatScreen(friendData: args);
          },
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
