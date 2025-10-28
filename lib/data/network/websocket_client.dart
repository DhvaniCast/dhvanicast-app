import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';

class WebSocketClient {
  static final WebSocketClient _instance = WebSocketClient._internal();
  factory WebSocketClient() => _instance;
  WebSocketClient._internal();

  IO.Socket? _socket;
  String? _authToken;
  bool _isConnected = false;

  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  /// Initialize and connect to Socket.IO server
  void connect(String token) {
    _authToken = token;

    // Get socket URL and determine if production
    final socketUrl = ApiEndpoints.socketUrl;
    final isProduction = ApiEndpoints.isProduction;

    if (kDebugMode) {
      print('🔌 Connecting to Socket.IO...');
      print('📡 URL: $socketUrl');
      print('🌍 Environment: ${ApiEndpoints.environmentName}');
    }

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Fallback to polling if websocket fails
          .enableAutoConnect()
          .enableForceNew()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          // Production-specific settings
          .setTimeout(isProduction ? 20000 : 10000) // Longer timeout for production
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          // Security settings for production
          .disableMultiplex() // Better for production
          .build(),
    );

    _setupSocketListeners();
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    _socket?.on('connect', (_) {
      _isConnected = true;
      if (kDebugMode) {
        print('✅ Socket.IO Connected to ${ApiEndpoints.socketUrl}');
        print('🎯 Transport: ${_socket?.io.engine?.transport?.name ?? 'unknown'}');
      }
    });

    _socket?.on('disconnect', (reason) {
      _isConnected = false;
      if (kDebugMode) {
        print('❌ Socket.IO Disconnected');
        print('📋 Reason: $reason');
      }
    });

    _socket?.on('connect_error', (error) {
      _isConnected = false;
      if (kDebugMode) {
        print('🔴 Socket.IO Connection Error: $error');
        print('🌍 URL: ${ApiEndpoints.socketUrl}');
        print('🔧 Environment: ${ApiEndpoints.environmentName}');
      }
    });

    _socket?.on('error', (error) {
      if (kDebugMode) {
        print('🔴 Socket.IO Error: $error');
      }
    });

    _socket?.on('authenticated', (data) {
      if (kDebugMode) {
        print('🔐 Socket.IO Authenticated: $data');
      }
    });

    _socket?.on('reconnect', (attemptNumber) {
      if (kDebugMode) {
        print('🔄 Socket.IO Reconnected after $attemptNumber attempts');
      }
    });

    _socket?.on('reconnect_attempt', (attemptNumber) {
      if (kDebugMode) {
        print('🔄 Socket.IO Reconnection attempt #$attemptNumber');
      }
    });

    _socket?.on('reconnect_error', (error) {
      if (kDebugMode) {
        print('🔴 Socket.IO Reconnection error: $error');
      }
    });

    _socket?.on('reconnect_failed', (_) {
      if (kDebugMode) {
        print('❌ Socket.IO Reconnection failed - max attempts reached');
      }
    });
  }

  /// Join a frequency
  void joinFrequency(String frequencyId, {Map<String, dynamic>? userInfo}) {
    _socket?.emit('join_frequency', {
      'frequencyId': frequencyId,
      if (userInfo != null) 'userInfo': userInfo,
    });
  }

  /// Leave a frequency
  void leaveFrequency(String frequencyId) {
    _socket?.emit('leave_frequency', {'frequencyId': frequencyId});
  }

  /// Join a group
  void joinGroup(String groupId, {Map<String, dynamic>? memberInfo}) {
    _socket?.emit('join_group', {
      'groupId': groupId,
      if (memberInfo != null) 'memberInfo': memberInfo,
    });
  }

  /// Leave a group
  void leaveGroup(String groupId) {
    _socket?.emit('leave_group', {'groupId': groupId});
  }

  /// Send a text message
  void sendMessage(Map<String, dynamic> messageData) {
    _socket?.emit('send_message', messageData);
  }

  /// Send audio message
  void sendAudioMessage(Map<String, dynamic> audioData) {
    _socket?.emit('send_audio_message', audioData);
  }

  /// Start transmission on frequency
  void startTransmission(String frequencyId) {
    _socket?.emit('start_transmission', {'frequencyId': frequencyId});
  }

  /// Stop transmission
  void stopTransmission(String frequencyId) {
    _socket?.emit('stop_transmission', {'frequencyId': frequencyId});
  }

  /// Send audio data chunk
  void sendAudioData(Map<String, dynamic> audioChunk) {
    _socket?.emit('audio_data', audioChunk);
  }

  /// Start speaking in group
  void startSpeaking(String groupId) {
    _socket?.emit('start_speaking', {'groupId': groupId});
  }

  /// Stop speaking in group
  void stopSpeaking(String groupId) {
    _socket?.emit('stop_speaking', {'groupId': groupId});
  }

  /// Send group audio data
  void sendGroupAudioData(Map<String, dynamic> audioData) {
    _socket?.emit('group_audio_data', audioData);
  }

  /// Typing indicators
  void typingStart(String recipientType, String recipientId) {
    _socket?.emit('typing_start', {
      'recipientType': recipientType,
      'recipientId': recipientId,
    });
  }

  void typingStop(String recipientType, String recipientId) {
    _socket?.emit('typing_stop', {
      'recipientType': recipientType,
      'recipientId': recipientId,
    });
  }

  /// Add reaction to message
  void addReaction(String messageId, String emoji) {
    _socket?.emit('add_reaction', {'messageId': messageId, 'emoji': emoji});
  }

  /// Remove reaction from message
  void removeReaction(String messageId, String emoji) {
    _socket?.emit('remove_reaction', {'messageId': messageId, 'emoji': emoji});
  }

  /// Mark messages as read
  void markMessagesRead(
    String recipientType,
    String recipientId,
    List<String> messageIds,
  ) {
    _socket?.emit('mark_messages_read', {
      'recipientType': recipientType,
      'recipientId': recipientId,
      'messageIds': messageIds,
    });
  }

  /// Delete message
  void deleteMessage(String messageId) {
    _socket?.emit('delete_message', {'messageId': messageId});
  }

  /// Forward message
  void forwardMessage(
    String messageId,
    String recipientType,
    String recipientId,
  ) {
    _socket?.emit('forward_message', {
      'messageId': messageId,
      'recipientType': recipientType,
      'recipientId': recipientId,
    });
  }

  /// Update signal strength
  void updateSignalStrength(String frequencyId, int strength) {
    _socket?.emit('update_signal_strength', {
      'frequencyId': frequencyId,
      'strength': strength,
    });
  }

  /// Update location
  void updateLocation(Map<String, dynamic> location) {
    _socket?.emit('update_location', location);
  }

  /// Get frequency users
  void getFrequencyUsers(String frequencyId) {
    _socket?.emit('get_frequency_users', {'frequencyId': frequencyId});
  }

  /// Get group members
  void getGroupMembers(String groupId) {
    _socket?.emit('get_group_members', {'groupId': groupId});
  }

  /// Scan frequencies
  void scanFrequencies({double? minFreq, double? maxFreq}) {
    _socket?.emit('scan_frequencies', {
      if (minFreq != null) 'minFreq': minFreq,
      if (maxFreq != null) 'maxFreq': maxFreq,
    });
  }

  /// Listen to socket events
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Remove event listener
  void off(String event) {
    _socket?.off(event);
  }

  /// Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _authToken = null;
  }

  /// Reconnect socket
  void reconnect() {
    if (_authToken != null) {
      connect(_authToken!);
    }
  }

  /// Get connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'socketUrl': ApiEndpoints.socketUrl,
      'environment': ApiEndpoints.environmentName,
      'isProduction': ApiEndpoints.isProduction,
      'hasToken': _authToken != null,
      'socketExists': _socket != null,
      'transport': _socket?.io.engine?.transport?.name ?? 'none',
    };
  }
}
