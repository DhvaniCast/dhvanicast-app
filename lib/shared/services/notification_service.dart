import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

import '../../features/social/screens/incoming_call_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    // Android notification channel for incoming calls
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Notifications for incoming voice calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Initialize settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('✅ [NOTIFICATION_SERVICE] Initialized');
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📲 [NOTIFICATION_SERVICE] Notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final callData = jsonDecode(response.payload!);

        if (callData['type'] == 'incoming_call') {
          _navigateToIncomingCall(callData);
        }
      } catch (e) {
        print('❌ [NOTIFICATION_SERVICE] Error parsing payload: $e');
      }
    }
  }

  // Navigate to incoming call screen
  void _navigateToIncomingCall(Map<String, dynamic> callData) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => IncomingCallScreen(
            callData: {
              'callerName': callData['callerName'],
              'callerAvatar': callData['callerAvatar'] ?? '👤',
              'callerId': callData['callerId'],
              'callId': callData['callId'],
              'callerEmail': callData['callerEmail'],
            },
            onCallResponse: (accepted) {
              Navigator.of(context).pop();
              // TODO: Handle accept/reject from notification
            },
          ),
        ),
      );
    }
  }

  // Play ringtone for incoming call
  Future<void> _playRingtone() async {
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.setVolume(0.7);
      try {
        await _ringtonePlayer.play(AssetSource('sounds/ringtone.mp3'));
        print('🔔 [NOTIFICATION] Playing ringtone');
      } catch (e) {
        print('⚠️ [NOTIFICATION] Ringtone file not found, using system sound');
      }
    } catch (e) {
      print('⚠️ [NOTIFICATION] Audio player error: $e');
    }
  }

  // Stop ringtone
  void stopRingtone() {
    _ringtonePlayer.stop();
  }

  // Show incoming call notification (when app is in foreground)
  Future<void> showIncomingCallNotification(
    Map<String, dynamic> callData,
  ) async {
    // Play ringtone when notification is shown
    await _playRingtone();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'incoming_calls',
          'Incoming Calls',
          channelDescription: 'Notifications for incoming voice calls',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          ongoing: true, // Makes notification persistent
          autoCancel: false, // Don't dismiss on tap
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'INCOMING_CALL',
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      callData['callId'].hashCode, // Unique ID for each call
      '📞 Incoming Call',
      '${callData['callerName']} is calling...',
      notificationDetails,
      payload: jsonEncode(callData),
    );

    print('✅ [NOTIFICATION_SERVICE] Incoming call notification shown');
  }

  // Cancel incoming call notification
  Future<void> cancelIncomingCallNotification(String callId) async {
    await _flutterLocalNotificationsPlugin.cancel(callId.hashCode);
    print('✅ [NOTIFICATION_SERVICE] Notification cancelled for call: $callId');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Handle FCM messages (foreground, background, terminated)
  void setupFCMListeners() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📲 [FCM] Foreground message: ${message.notification?.title}');
      print('📲 [FCM] Data: ${message.data}');

      if (message.data['type'] == 'incoming_call') {
        // Show local notification even when app is open but on different screen
        showIncomingCallNotification({
          'type': 'incoming_call',
          'callId': message.data['callId'],
          'callerId': message.data['callerId'],
          'callerName': message.data['callerName'],
          'callerAvatar': message.data['callerAvatar'] ?? '👤',
          'callerEmail': message.data['callerEmail'],
          'roomName': message.data['roomName'],
        });
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 [FCM] Notification opened app: ${message.notification?.title}');

      if (message.data['type'] == 'incoming_call') {
        _navigateToIncomingCall(message.data);
      }
    });

    // Check if app was opened from a notification (terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📲 [FCM] App opened from terminated state');

        if (message.data['type'] == 'incoming_call') {
          // Wait for app to be ready
          Future.delayed(const Duration(seconds: 1), () {
            _navigateToIncomingCall(message.data);
          });
        }
      }
    });

    print('✅ [NOTIFICATION_SERVICE] FCM listeners setup complete');
  }
}
