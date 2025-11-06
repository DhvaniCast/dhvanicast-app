import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:harborleaf_radio_app/injection.dart';
import 'package:harborleaf_radio_app/shared/services/communication_service.dart';
import 'package:harborleaf_radio_app/shared/services/audio_service.dart';
import 'package:harborleaf_radio_app/core/websocket_client.dart';

/// ✅ UPDATED VERSION - This file now has the correct UI with proper message alignment
///
/// UI Features:
/// - Right-aligned sent messages (green gradient)
/// - Left-aligned received messages (gray background)
/// - Sender name shows ONLY above received messages
/// - Time shows below sent messages, above with name for received
/// - Dynamic frequency display from groupData
/// - Real-time active users from WebSocket
///
/// This matches your requirement:
/// Right Side (Your Messages):
///                     ┌─────────────────┐
///                     │ Hello everyone! │ <- Green gradient
///                     └─────────────────┘
///                            10:30 AM
///
/// Left Side (Received):
/// Ravi Kumar  10:32 AM
/// ┌─────────────────┐
/// │ Hi there!       │ <- Gray background
/// └─────────────────┘

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({Key? key}) : super(key: key);

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen>
    with TickerProviderStateMixin {
  late AnimationController _audioWaveController;
  late AnimationController _pulseController;
  late Animation<double> _audioWaveAnimation;
  late Animation<double> _pulseAnimation;
  late CommunicationService _commService;
  late AudioService _audioService;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isRecording = false;

  Map<String, dynamic>? groupData;
  String? _currentUserId; // Store current user ID

  // Local state for messages and active users/members
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _activeUsers = [];

  @override
  void initState() {
    super.initState();

    // Get services from DI
    _commService = getIt<CommunicationService>();
    _audioService = getIt<AudioService>();

    print('🚀 CommunicationScreen: Initializing...');
    print('🎤 AudioService initialized');

    _audioWaveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _audioWaveAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _audioWaveController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to service changes
    _commService.addListener(_onServiceUpdate);
    _audioService.addListener(_onAudioServiceUpdate);

    // Load current user ID
    _loadCurrentUserId();
  }

  void _onAudioServiceUpdate() {
    setState(() {
      _isRecording = _audioService.isRecording;
    });
    print('🎤 [AUDIO UPDATE] Recording: $_isRecording');
  }

  Future<void> _loadCurrentUserId() async {
    print('👤 [USER ID] Loading current user ID...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user');

      print('👤 [USER ID] User data from storage: $userDataString');

      if (userDataString != null) {
        final userData = Map<String, dynamic>.from(
          jsonDecode(userDataString) as Map,
        );
        setState(() {
          _currentUserId = userData['id'] ?? userData['_id'];
        });
        print('✅ [USER ID] Current User ID loaded: $_currentUserId');
        print('✅ [USER ID] User Name: ${userData['name']}');
      } else {
        print('❌ [USER ID] No user data found in storage');
      }
    } catch (e) {
      print('❌ [USER ID] Error loading current user ID: $e');
    }
  }

  String _getCurrentUserId() {
    final userId = _currentUserId ?? '';
    print('👤 [GET USER ID] Returning: $userId');
    return userId;
  }

  void _onServiceUpdate() {
    print('📡 CommunicationScreen: Service updated');
    print('💬 Messages count: ${_commService.messages.length}');

    if (_commService.error != null) {
      print('❌ Error: ${_commService.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_commService.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      // Convert MessageModel to Map for UI if needed
    });
    _scrollToBottom();
  }

  Future<void> _loadGroupData(String groupId) async {
    print('📥 CommunicationScreen: Loading group data for $groupId');

    // Load group details
    await _commService.loadGroupDetails(groupId);
    print('✅ Group loaded: ${_commService.currentGroup?.name}');

    // Load messages
    await _commService.loadMessages(
      recipientType: 'group',
      recipientId: groupId,
    );
    print('✅ Messages loaded: ${_commService.messages.length}');

    // Setup WebSocket listeners
    _commService.setupSocketListeners();
    print('✅ WebSocket listeners setup complete');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    print('📥 CommunicationScreen: Received arguments: $args');

    if (args != null && args is Map<String, dynamic>) {
      groupData = args;

      // Check if it's frequency chat or group chat
      final type = args['type'] as String?;
      final frequencyId = args['frequencyId'] as String?;
      final groupId = args['groupId'] as String?;

      print('🔍 Chat Type: $type');
      print('🆔 Frequency ID: $frequencyId');
      print('🆔 Group ID: $groupId');

      if (type == 'frequency' && frequencyId != null) {
        print('💬 Setting up FREQUENCY CHAT');
        _setupFrequencyChat(frequencyId);
      } else if (groupId != null) {
        print('💬 Setting up GROUP CHAT');
        _loadGroupData(groupId);
      } else {
        print('⚠️ No valid chat target found!');
      }
    }
  }

  // Setup frequency chat
  void _setupFrequencyChat(String frequencyId) {
    print('🔧 Setting up frequency chat for: $frequencyId');

    final wsClient = getIt<WebSocketClient>();

    // Request frequency chat history
    print('📜 Requesting frequency chat history...');
    wsClient.getFrequencyChatHistory(frequencyId);

    // Setup frequency-specific listeners
    wsClient.on('frequency_chat_message', (data) {
      print('💬 [FREQUENCY] Received chat message: $data');
      if (mounted) {
        final currentUserId = _getCurrentUserId();
        final messageType = data['messageType'] ?? 'text';

        setState(() {
          _messages.add({
            'id': data['id'],
            'senderId': data['sender']['id'],
            'sender': data['sender']['name'],
            'senderName': data['sender']['name'],
            'message': messageType == 'audio'
                ? 'Audio Message'
                : data['message'],
            'text': data['message'],
            'timestamp': data['timestamp'],
            'time': _formatTime(data['timestamp']),
            'type': messageType,
            'isMe': data['sender']['id'] == currentUserId,
            if (messageType == 'audio') ...{
              'audioUrl': data['audioUrl'],
              'duration': data['duration'] ?? '0:00',
            },
          });
        });
        _scrollToBottom();
      }
    });

    // Listen for audio messages specifically
    wsClient.on('audio_message_received', (data) {
      print('🎤 [FREQUENCY] Received audio message: $data');
      if (mounted) {
        final currentUserId = _getCurrentUserId();
        setState(() {
          _messages.add({
            'id': data['id'],
            'senderId': data['sender']?['id'],
            'sender': data['sender']?['name'] ?? 'Unknown',
            'senderName': data['sender']?['name'] ?? 'Unknown',
            'message': 'Audio Message',
            'timestamp': data['timestamp'],
            'time': _formatTime(data['timestamp']),
            'type': 'audio',
            'isMe': data['sender']?['id'] == currentUserId,
            'audioUrl': data['audioUrl'],
            'duration': data['duration'] ?? '0:00',
          });
        });
        _scrollToBottom();
      }
    });

    wsClient.on('frequency_chat_history', (data) {
      print(
        '📜 [FREQUENCY] Received chat history: ${data['messages']?.length ?? 0} messages',
      );
      if (mounted && data['messages'] != null) {
        final currentUserId = _getCurrentUserId();
        setState(() {
          _messages = (data['messages'] as List).map((msg) {
            final messageType = msg['messageType'] ?? 'text';
            return {
              'id': msg['id'],
              'senderId': msg['sender']['id'],
              'sender': msg['sender']['name'],
              'senderName': msg['sender']['name'],
              'message': messageType == 'audio'
                  ? 'Audio Message'
                  : msg['message'],
              'text': msg['message'],
              'timestamp': msg['timestamp'],
              'time': _formatTime(msg['timestamp']),
              'type': messageType,
              'isMe': msg['sender']['id'] == currentUserId,
              if (messageType == 'audio') ...{
                'audioUrl': msg['audioUrl'],
                'duration': msg['duration'] ?? '0:00',
              },
            };
          }).toList();
        });
        Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    // Listen for active users updates
    wsClient.on('frequency_users_update', (data) {
      print(
        '👥 [FREQUENCY] Active users updated: ${data['users']?.length ?? 0}',
      );
      if (mounted && data['users'] != null) {
        setState(() {
          _activeUsers = List<Map<String, dynamic>>.from(data['users']);
        });
      }
    });

    wsClient.on('user_joined_frequency', (data) {
      print('👤 [FREQUENCY] User joined: ${data['user']['name']}');
      if (mounted) {
        setState(() {
          final userExists = _activeUsers.any(
            (u) => u['id'] == data['user']['id'],
          );
          if (!userExists) {
            _activeUsers.add(data['user']);
          }
        });
      }
    });

    wsClient.on('user_left_frequency', (data) {
      print('👤 [FREQUENCY] User left: ${data['userId']}');
      if (mounted) {
        setState(() {
          _activeUsers.removeWhere((u) => u['id'] == data['userId']);
        });
      }
    });

    print('✅ Frequency chat setup complete');
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _audioWaveController.dispose();
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _commService.removeListener(_onServiceUpdate);
    _audioService.removeListener(_onAudioServiceUpdate);
    super.dispose();
  }

  void _startRecording() async {
    print('\n🎤🎤🎤🎤🎤 ===== START RECORDING ===== 🎤🎤🎤🎤🎤');
    print('📱 Attempting to start audio recording...');
    print('📱 Current recording state: $_isRecording');
    print('📱 AudioService instance: EXISTS');

    try {
      final success = await _audioService.startRecording();
      print('📱 Recording start result: $success');

      if (success) {
        setState(() {
          _isRecording = true;
        });
        _audioWaveController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
        print('✅ Recording started successfully');
        print('🎤 Recording state: $_isRecording');
      } else {
        print('❌ Failed to start recording');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to start recording. Check microphone permissions.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌❌❌ EXCEPTION in _startRecording: $e');
      print('❌❌❌ Stack trace: $stackTrace');
    }
    print('===== START RECORDING COMPLETE =====\n');
  }

  void _stopRecording() async {
    print('\n🛑🛑🛑🛑🛑 ===== STOP RECORDING ===== 🛑🛑🛑🛑🛑');
    print('📱 Attempting to stop audio recording...');
    print('📱 Current recording state: $_isRecording');

    try {
      final audioPath = await _audioService.stopRecording();
      print('📱 Stop recording result - Audio path: $audioPath');

      setState(() {
        _isRecording = false;
      });
      _audioWaveController.stop();
      _pulseController.stop();

      print('🎤 Recording stopped');
      print('📁 Audio file path: $audioPath');

      if (audioPath != null && audioPath.isNotEmpty) {
        print('✅ Audio recorded successfully');
        print('⏱️ Duration: ${_audioService.recordingDuration.inSeconds}s');
        print(
          '⏱️ Duration formatted: ${_audioService.recordingDuration.inMinutes}:${(_audioService.recordingDuration.inSeconds % 60).toString().padLeft(2, "0")}',
        );

        // Send audio message
        print('📤 Calling _sendAudioMessage...');
        await _sendAudioMessage(audioPath);
      } else {
        print('❌ No audio file created');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save audio recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌❌❌ EXCEPTION in _stopRecording: $e');
      print('❌❌❌ Stack trace: $stackTrace');
    }
    print('===== STOP RECORDING COMPLETE =====\n');
  }

  Future<void> _sendAudioMessage(String audioPath) async {
    print('\n📤 ===== SEND AUDIO MESSAGE =====');
    print('📁 Audio path: $audioPath');

    // Check if file exists
    final file = File(audioPath);
    final exists = await file.exists();
    print('📂 File exists: $exists');

    if (!exists) {
      print('❌ Audio file does not exist');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio file not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fileSize = await file.length();
    print(
      '📊 File size: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)',
    );

    final duration = _audioService.recordingDuration;
    final durationString =
        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    print('⏱️ Duration: $durationString');

    // Check chat type
    final type = groupData?['type'] as String?;
    final frequencyId = groupData?['frequencyId'] as String?;
    final groupId = groupData?['groupId'] as String?;

    print('🔍 Chat Type: $type');
    print('🆔 Frequency ID: $frequencyId');
    print('🆔 Group ID: $groupId');

    if (type == 'frequency' && frequencyId != null) {
      print('📡 Sending FREQUENCY audio message...');

      // NO need to read and encode - just send metadata
      // Backend will handle audio storage and URL generation
      print('🎤 Sending audio message with metadata only');

      final wsClient = getIt<WebSocketClient>();

      // Send audio message via send_frequency_chat event with audio messageType
      print('📡 Emitting send_frequency_chat event...');
      wsClient.sendFrequencyChat(
        frequencyId,
        'Audio Message', // The message text
        messageType: 'audio',
        duration: durationString,
      );

      print(
        '✅ Audio message event sent to backend with duration: $durationString',
      );

      // Add optimistic message to UI
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      print('💬 Adding message to UI with ID: $messageId');

      setState(() {
        _messages.add({
          'id': messageId,
          'sender': 'You',
          'senderName': 'You',
          'senderId': _currentUserId,
          'message': 'Audio Message',
          'time':
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'audio',
          'messageType': 'audio',
          'isMe': true,
          'duration': durationString,
          'audioPath': audioPath,
        });
      });

      _scrollToBottom();
      print('✅ Audio message added to UI');
    } else if (groupId != null) {
      print('📡 Sending GROUP audio message...');

      // Send group audio message
      final success = await _commService.sendAudioMessage(
        recipientType: 'group',
        recipientId: groupId,
        audioData: {
          'path': audioPath,
          'duration': duration.inSeconds,
          'format': 'm4a',
          'size': fileSize,
        },
      );

      if (success) {
        print('✅ Group audio message sent');
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'sender': 'You',
            'senderName': 'You',
            'message': 'Audio Message',
            'time':
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            'type': 'audio',
            'isMe': true,
            'duration': durationString,
            'audioPath': audioPath,
          });
        });
        _scrollToBottom();
      } else {
        print('❌ Failed to send group audio message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send audio message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('❌ No valid chat target!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send audio: Invalid chat target'),
          backgroundColor: Colors.red,
        ),
      );
    }

    print('===== SEND AUDIO MESSAGE COMPLETE =====\n');
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      print('⚠️ Empty message, not sending');
      return;
    }

    final message = _messageController.text.trim();
    print('📤 Attempting to send message: $message');

    // Check if it's frequency chat or group chat
    final type = groupData?['type'] as String?;
    final frequencyId = groupData?['frequencyId'] as String?;
    final groupId = groupData?['groupId'] as String?;

    print('🔍 Chat Type: $type');
    print('🆔 Frequency ID: $frequencyId');
    print('🆔 Group ID: $groupId');

    if (type == 'frequency' && frequencyId != null) {
      // Send frequency chat message via WebSocket
      print('📡 Sending FREQUENCY chat message...');
      final wsClient = getIt<WebSocketClient>();
      wsClient.sendFrequencyChat(frequencyId, message);
      print('✅ Frequency chat message sent to backend');

      // Note: Don't add message here, wait for server response to add it
      // This ensures proper sender info and prevents duplicates
    } else if (groupId != null) {
      // Send group chat message
      print('📡 Sending GROUP chat message...');

      // Add optimistic message (will be replaced by server response)
      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'sender': 'You',
          'senderName': 'You',
          'message': message,
          'time':
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'type': 'text',
          'isMe': true,
        });
      });
    } else {
      print('❌ No valid chat target!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot send message: Invalid chat target'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupData?['name'] ??
                  (groupData?['frequency'] != null
                      ? 'Channel ${groupData!['frequency']} MHz'
                      : 'Radio Channel'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              '${_activeUsers.length} Active Units • Signal Strong',
              style: const TextStyle(
                color: Color(0xFF00ff88),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Emergency Button
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () {
                // Emergency broadcast
              },
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFff4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFff4444), width: 1),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Color(0xFFff4444),
                  size: 16,
                ),
              ),
            ),
          ),
          // Settings
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _showMembersSheet,
              icon: const Icon(Icons.settings, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Radio Status Panel
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00ff88).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00ff88).withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Channel Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupData?['frequency'] != null
                              ? 'CHANNEL ${groupData!['frequency']} MHz'
                              : 'CHANNEL 99.9 MHz',
                          style: const TextStyle(
                            color: Color(0xFF00ff88),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Active Transmission',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    // Signal Strength
                    Row(
                      children: List.generate(5, (index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 1.5),
                          width: 3,
                          height: 10 + (index * 2),
                          decoration: BoxDecoration(
                            color: index < 4
                                ? const Color(0xFF00ff88)
                                : const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Radio Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRadioControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: 'MIC',
                      isActive: !_isMuted,
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                        });
                      },
                    ),
                    _buildRadioControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      label: 'VOL',
                      isActive: _isSpeakerOn,
                      onPressed: () {
                        setState(() {
                          _isSpeakerOn = !_isSpeakerOn;
                        });
                      },
                    ),
                    _buildRadioControlButton(
                      icon: Icons.radio,
                      label: 'SIG',
                      isActive: true,
                      onPressed: () {},
                    ),
                    _buildRadioControlButton(
                      icon: Icons.emergency,
                      label: 'EMG',
                      isActive: false,
                      isEmergency: true,
                      onPressed: () {
                        // Emergency protocol
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages Area - Radio Communications
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1e1e1e),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                children: [
                  // Messages Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2a2a2a),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radio,
                          color: Color(0xFF00ff88),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'RADIO TRANSMISSIONS',
                          style: TextStyle(
                            color: Color(0xFF00ff88),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ff88).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Color(0xFF00ff88),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Messages List
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildRadioMessageBubble(message);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Radio Input Area
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00ff88).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00ff88).withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // PTT Instructions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF555555)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF00ff88),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hold PTT to record voice message',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Input Row
                Row(
                  children: [
                    // Push-to-Talk Button
                    GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(),
                      child: AnimatedBuilder(
                        animation: _isRecording
                            ? _pulseAnimation
                            : _audioWaveAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isRecording ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: _isRecording
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFff4444),
                                          Color(0xFFdd2222),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFF333333),
                                          Color(0xFF222222),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _isRecording
                                      ? const Color(0xFFff4444)
                                      : const Color(0xFF00ff88),
                                  width: 2,
                                ),
                                boxShadow: _isRecording
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFff4444,
                                          ).withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00ff88,
                                          ).withOpacity(0.15),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isRecording ? Icons.radio : Icons.push_pin,
                                    color: _isRecording
                                        ? Colors.white
                                        : const Color(0xFF00ff88),
                                    size: 18,
                                  ),
                                  Text(
                                    'PTT',
                                    style: TextStyle(
                                      color: _isRecording
                                          ? Colors.white
                                          : const Color(0xFF00ff88),
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // DEBUG: Test Record Button
                    ElevatedButton(
                      onPressed: () async {
                        print(
                          '\n🧪🧪🧪🧪🧪 DEBUG: Test record button pressed 🧪🧪🧪🧪🧪',
                        );
                        print('🧪 Current _isRecording state: $_isRecording');
                        if (_isRecording) {
                          print('🧪 DEBUG: Calling _stopRecording()...');
                          _stopRecording();
                          print('🧪 DEBUG: _stopRecording() completed');
                        } else {
                          print('🧪 DEBUG: Calling _startRecording()...');
                          _startRecording();
                          print('🧪 DEBUG: _startRecording() completed');
                        }
                        print(
                          '🧪🧪🧪🧪🧪 DEBUG: Button action complete 🧪🧪🧪🧪🧪\n',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red
                            : Colors.green,
                        padding: const EdgeInsets.all(8),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Message Input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1e1e1e),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF333333)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type radio message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            prefixIcon: Icon(
                              Icons.message,
                              color: const Color(0xFF00ff88).withOpacity(0.6),
                              size: 16,
                            ),
                          ),
                          maxLines: null,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Send Button
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00ff88), Color(0xFF00dd77)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00ff88).withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    bool isEmergency = false,
  }) {
    final Color buttonColor = isEmergency
        ? const Color(0xFFff4444)
        : isActive
        ? const Color(0xFF00ff88)
        : const Color(0xFF666666);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? buttonColor.withOpacity(0.15)
              : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: buttonColor, width: isActive ? 1.5 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: buttonColor, size: 14),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: buttonColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CORRECT MESSAGE BUBBLE - Shows proper alignment
  Widget _buildRadioMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] ?? false;
    final priority = message['priority'] ?? 'normal';

    Color priorityColor = const Color(0xFF00ff88);
    if (priority == 'urgent') priorityColor = const Color(0xFFffaa00);
    if (priority == 'emergency') priorityColor = const Color(0xFFff4444);
    if (priority == 'high') priorityColor = const Color(0xFF00aaff);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.70,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Header with sender name and time (only show for received messages)
            if (!isMe) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message['sender'] ?? message['senderName'] ?? 'Unknown',
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      message['time'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF00ff88), Color(0xFF00dd77)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : const Color(0xFF2a2a2a),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 12 : 4),
                  topRight: Radius.circular(isMe ? 4 : 12),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: const Radius.circular(12),
                ),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF00ff88).withOpacity(0.3)
                      : const Color(0xFF444444),
                  width: 1,
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00ff88).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: message['type'] == 'audio'
                  ? _buildAudioMessage(message, isMe)
                  : _buildTextMessage(message, isMe),
            ),
            // Time for sent messages
            if (isMe) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  message['time'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(Map<String, dynamic> message, bool isMe) {
    final messageText = message['message'] ?? message['text'] ?? '';

    return Text(
      messageText,
      style: TextStyle(
        color: isMe ? const Color(0xFF000000) : Colors.white,
        fontSize: 14,
        height: 1.4,
        fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }

  Widget _buildAudioMessage(Map<String, dynamic> message, bool isMe) {
    final audioPath = message['audioPath'] as String?;
    final audioUrl = message['audioUrl'] as String?;
    final isPlaying =
        _audioService.isPlaying &&
        (_audioService.currentRecordingPath == audioPath);

    return GestureDetector(
      onTap: () => _playAudioMessage(audioPath, audioUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.black.withOpacity(0.1)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: isMe ? const Color(0xFF000000) : const Color(0xFF00ff88),
              size: 28,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Message',
                  style: TextStyle(
                    color: isMe ? const Color(0xFF000000) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message['duration'] ?? '0:00',
                  style: TextStyle(
                    color: isMe
                        ? const Color(0xFF000000).withOpacity(0.7)
                        : Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.graphic_eq,
              color: isMe
                  ? const Color(0xFF000000).withOpacity(0.5)
                  : const Color(0xFF00ff88).withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playAudioMessage(String? audioPath, String? audioUrl) async {
    print('\n🔊 ===== PLAY AUDIO MESSAGE =====');
    print('📁 Audio path: $audioPath');
    print('🌐 Audio URL: $audioUrl');

    if (_audioService.isPlaying) {
      print('⏸️ Stopping current playback');
      await _audioService.stopPlayback();
      return;
    }

    bool success = false;

    if (audioPath != null && audioPath.isNotEmpty) {
      print('📱 Playing from local path...');
      final file = File(audioPath);
      if (await file.exists()) {
        success = await _audioService.playAudio(audioPath);
        print(success ? '✅ Playing from path' : '❌ Failed to play from path');
      } else {
        print('❌ Local file does not exist');
      }
    }

    if (!success && audioUrl != null && audioUrl.isNotEmpty) {
      print('🌐 Playing from URL...');
      success = await _audioService.playAudioUrl(audioUrl);
      print(success ? '✅ Playing from URL' : '❌ Failed to play from URL');
    }

    if (!success) {
      print('❌ Failed to play audio message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to play audio message'),
          backgroundColor: Colors.red,
        ),
      );
    }

    print('===== PLAY AUDIO MESSAGE COMPLETE =====\n');
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2a2a2a),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF555555),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                _activeUsers.isNotEmpty
                    ? 'Active Users (${_activeUsers.length})'
                    : 'No Active Users',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              // Users List
              Expanded(
                child: _activeUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users connected',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _activeUsers.length,
                        itemBuilder: (context, index) {
                          final user = _activeUsers[index];
                          return _buildUserTile(user);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isCurrentUser = user['id'] == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF00ff88).withOpacity(0.1)
            : const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF00ff88)
              : const Color(0xFF555555),
          width: isCurrentUser ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00ff88), Color(0xFF00dd77)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                (user['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00ff88),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00ff88),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user['state'] ?? 'Active',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Signal Strength
          Icon(
            Icons.signal_cellular_alt,
            color: const Color(0xFF00ff88),
            size: 20,
          ),
        ],
      ),
    );
  }
}
