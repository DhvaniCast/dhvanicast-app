import 'package:flutter/material.dart';
import '../../core/websocket_client.dart';
import '../../features/social/screens/incoming_call_screen.dart';
import '../../features/social/screens/active_call_screen.dart';
import '../../shared/services/livekit_service.dart';
import '../../core/auth_storage_service.dart';
import '../../injection.dart';
import '../../shared/services/notification_service.dart';

/// Global call listener that works across all screens
class GlobalCallListener extends StatefulWidget {
  final Widget child;

  GlobalCallListener({Key? key, required this.child}) : super(key: key);

  @override
  State<GlobalCallListener> createState() {
    print('🔨 [GLOBAL_CALL_LISTENER] createState called');
    return _GlobalCallListenerState();
  }
}

class _GlobalCallListenerState extends State<GlobalCallListener>
    with WidgetsBindingObserver {
  final WebSocketClient _socketClient = WebSocketClient();
  final LiveKitService _livekitService = getIt<LiveKitService>();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    print('🚀 [GLOBAL_CALL_LISTENER] initState called');
    WidgetsBinding.instance.addObserver(this);

    // Delay to ensure WebSocket is connected
    Future.delayed(const Duration(milliseconds: 500), () {
      print(
        '⏰ [GLOBAL_CALL_LISTENER] Delayed setup triggered, mounted: $mounted',
      );
      if (mounted) {
        _setupGlobalCallListeners();
      } else {
        print(
          '❌ [GLOBAL_CALL_LISTENER] Widget not mounted, skipping listener setup',
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeGlobalCallListeners();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🌐 [GLOBAL_CALL_LISTENER] App lifecycle changed: $state');

    // Don't re-setup on every lifecycle change - causes issues
    // Listeners remain active across lifecycle changes
  }

  void _setupGlobalCallListeners() {
    print('🌐 [GLOBAL_CALL_LISTENER] Setting up global call listeners');
    print(
      '🌐 [GLOBAL_CALL_LISTENER] Socket connected: ${_socketClient.isConnected}',
    );
    print(
      '🌐 [GLOBAL_CALL_LISTENER] Socket instance: ${_socketClient.socket != null}',
    );
    print(
      '🌐 [GLOBAL_CALL_LISTENER] Socket ID: ${_socketClient.socket?.id ?? 'NULL'}',
    );

    if (_socketClient.socket == null) {
      print('❌ [GLOBAL_CALL_LISTENER] Socket is null, cannot setup listeners');
      return;
    }

    // Test: Listen to ALL events for debugging
    _socketClient.socket?.onAny((event, data) {
      print('🎯 [SOCKET DEBUG] Received event: $event');
      if (event == 'incoming_call') {
        print('🎯 [SOCKET DEBUG] This is an incoming_call event!');
        print('🎯 [SOCKET DEBUG] Data: $data');
      }
    });

    // Listen for incoming calls globally
    _socketClient.socket?.on('incoming_call', (data) {
      print(
        '📞 [GLOBAL_CALL_LISTENER] ===== INCOMING CALL EVENT RECEIVED =====',
      );
      print('📞 [GLOBAL_CALL_LISTENER] Call data: $data');

      // Show local notification (works even on different screens)
      _notificationService.showIncomingCallNotification({
        'type': 'incoming_call',
        'callId': data['callId'],
        'callerId': data['callerId'],
        'callerName': data['callerName'],
        'callerAvatar': data['callerAvatar'] ?? '👤',
        'callerEmail': data['callerEmail'],
        'roomName': data['roomName'],
      });

      // Show incoming call screen if mounted
      if (mounted) {
        print('📞 [GLOBAL_CALL_LISTENER] Showing incoming call screen');
        _showIncomingCallScreen(data);
      } else {
        print(
          '❌ [GLOBAL_CALL_LISTENER] Widget not mounted, cannot show call screen',
        );
      }
    });

    print('✅ [GLOBAL_CALL_LISTENER] Registered incoming_call listener');

    // Listen for call accepted (for caller)
    _socketClient.socket?.on('call_accepted', (data) {
      print('✅ [GLOBAL_CALL_LISTENER] Call accepted: $data');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['acceptedByName']} answered the call'),
            backgroundColor: const Color(0xFF00ff88),
          ),
        );
      }
    });

    // Listen for call rejected
    _socketClient.socket?.on('call_rejected', (data) {
      print('❌ [GLOBAL_CALL_LISTENER] Call rejected: $data');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['rejectedByName']} declined the call'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _livekitService.disconnect();
      _notificationService.cancelIncomingCallNotification(data['callId']);
    });

    // Listen for call ended
    _socketClient.socket?.on('call_ended', (data) {
      print('📴 [GLOBAL_CALL_LISTENER] Call ended: $data');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['endedByName']} ended the call'),
            backgroundColor: Colors.grey,
          ),
        );
      }

      _livekitService.disconnect();
      _notificationService.cancelIncomingCallNotification(data['callId']);
      _notificationService.stopRingtone(); // Stop ringtone when call ends
    });
  }

  void _removeGlobalCallListeners() {
    _socketClient.socket?.off('incoming_call');
    _socketClient.socket?.off('call_accepted');
    _socketClient.socket?.off('call_rejected');
    _socketClient.socket?.off('call_ended');
  }

  void _showIncomingCallScreen(Map<String, dynamic> callData) {
    final callerName = callData['callerName'] ?? 'Unknown';
    final callerAvatar = callData['callerAvatar'] ?? '👤';
    final callerId = callData['callerId'];
    final callId = callData['callId'];
    final callerEmail = callData['callerEmail'];

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => IncomingCallScreen(
          callData: {
            'callerName': callerName,
            'callerAvatar': callerAvatar,
            'callerId': callerId,
            'callId': callId,
            'callerEmail': callerEmail,
          },
          onCallResponse: (accepted) {
            Navigator.of(context).pop();

            if (accepted) {
              _acceptCall(
                callId,
                callerId,
                callerEmail,
                callerName,
                callerAvatar,
              );
            } else {
              _rejectCall(callId, callerId);
            }
          },
        ),
      ),
    );
  }

  void _acceptCall(
    String callId,
    String callerId,
    String callerEmail,
    String callerName,
    String callerAvatar,
  ) async {
    print('✅ [GLOBAL_CALL_LISTENER] Accepting call: $callId');

    // Send accept event to backend
    _socketClient.socket?.emit('accept_call', {
      'callId': callId,
      'callerId': callerId,
    });

    // Cancel notification
    _notificationService.cancelIncomingCallNotification(callId);

    // Join the call via LiveKit
    try {
      final authToken = await AuthStorageService.getToken();
      if (authToken == null) {
        throw Exception('Not authenticated');
      }

      await _livekitService.connectToFriendCall(callerEmail, authToken);

      // Navigate to active call screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => ActiveCallScreen(
              callData: {
                'friendName': callerName,
                'friendAvatar': callerAvatar,
                'friendId': callerId,
                'callId': callId,
              },
              onEndCall: () async {
                await _endCall(callerId, callId);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              callStartTime: DateTime.now(), // Call answered right now
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ [GLOBAL_CALL_LISTENER] Failed to join call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectCall(String callId, String callerId) {
    print('❌ [GLOBAL_CALL_LISTENER] Rejecting call: $callId');

    // Send reject event to backend
    _socketClient.socket?.emit('reject_call', {
      'callId': callId,
      'callerId': callerId,
    });

    // Cancel notification
    _notificationService.cancelIncomingCallNotification(callId);
  }

  Future<void> _endCall(String friendId, String callId) async {
    try {
      print('📞 [GLOBAL_CALL_LISTENER] Ending call');

      // Send end call event to backend
      _socketClient.socket?.emit('end_call', {
        'callId': callId,
        'friendId': friendId,
      });

      await _livekitService.disconnect();
      _notificationService.cancelIncomingCallNotification(callId);
      print('✅ [GLOBAL_CALL_LISTENER] Call ended');
    } catch (e) {
      print('❌ [GLOBAL_CALL_LISTENER] Error ending call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [GLOBAL_CALL_LISTENER] build() called');
    return widget.child;
  }
}
