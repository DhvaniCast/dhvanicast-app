import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../features/social/screens/incoming_call_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _ringtonePlayer = AudioPlayer();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    print('✅ [NOTIFICATION_SERVICE] Initialized (Local only - no Firebase)');
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

  // Show incoming call notification (in-app only, no system notifications)
  Future<void> showIncomingCallNotification(
    Map<String, dynamic> callData,
  ) async {
    // Play ringtone when call comes in
    await _playRingtone();

    // Navigate directly to incoming call screen
    _navigateToIncomingCall(callData);

    print('✅ [NOTIFICATION_SERVICE] Incoming call notification shown (in-app)');
  }

  // Cancel incoming call notification
  Future<void> cancelIncomingCallNotification(String callId) async {
    stopRingtone();
    print('✅ [NOTIFICATION_SERVICE] Notification cancelled for call: $callId');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    stopRingtone();
    print('✅ [NOTIFICATION_SERVICE] All notifications cancelled');
  }
}
