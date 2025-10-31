import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../injection.dart';
import '../../services/communication_service.dart';
import '../../../data/network/websocket_client.dart';

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

    // Get CommunicationService from DI
    _commService = getIt<CommunicationService>();

    print('🚀 CommunicationScreen: Initializing...');

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

    // Load current user ID
    _loadCurrentUserId();
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
      // Convert MessageModel to Map for UI
      // Note: You may need to handle this differently based on your MessageModel structure
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
        setState(() {
          _messages.add({
            'id': data['id'],
            'senderId': data['sender']['id'],
            'sender': data['sender']['name'],
            'senderName': data['sender']['name'],
            'message': data['message'],
            'text': data['message'],
            'timestamp': data['timestamp'],
            'time': _formatTime(data['timestamp']),
            'type': 'text',
            'isMe': data['sender']['id'] == currentUserId,
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
          _messages = (data['messages'] as List)
              .map(
                (msg) => {
                  'id': msg['id'],
                  'senderId': msg['sender']['id'],
                  'sender': msg['sender']['name'],
                  'senderName': msg['sender']['name'],
                  'message': msg['message'],
                  'text': msg['message'],
                  'timestamp': msg['timestamp'],
                  'time': _formatTime(msg['timestamp']),
                  'type': 'text',
                  'isMe': msg['sender']['id'] == currentUserId,
                },
              )
              .toList();
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

    // ===== RADIO CONTROL LISTENERS =====

    // Mic status updates
    wsClient.on('user_mic_status', (data) {
      print(
        '🎤 [MIC] User ${data['userName']} mic status: ${data['isMuted'] ? "MUTED" : "UNMUTED"}',
      );
      // You can show a toast or update UI if needed
    });

    wsClient.on('mic_status_updated', (data) {
      if (mounted) {
        print('✅ [MIC] ${data['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: const Color(0xFF00ff88),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });

    // Volume status updates
    wsClient.on('volume_status_updated', (data) {
      if (mounted) {
        print('✅ [VOL] ${data['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: const Color(0xFF00ff88),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });

    // Signal status updates
    wsClient.on('signal_status', (data) {
      if (mounted) {
        print(
          '✅ [SIG] Signal: ${data['signalBars']}/5 bars (${data['signalQuality']})',
        );
        print('✅ [SIG] Active users: ${data['activeUsers']}');

        // Show signal info dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2a2a2a),
            title: Row(
              children: [
                const Icon(
                  Icons.signal_cellular_alt,
                  color: Color(0xFF00ff88),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Signal Status',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Quality: ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      data['signalQuality'],
                      style: const TextStyle(
                        color: Color(0xFF00ff88),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Strength: ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    ...List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 2),
                        width: 4,
                        height: 12 + (index * 2),
                        decoration: BoxDecoration(
                          color: index < data['signalBars']
                              ? const Color(0xFF00ff88)
                              : const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${data['signalBars']}/5',
                      style: const TextStyle(
                        color: Color(0xFF00ff88),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${data['activeUsers']} active users',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF00ff88)),
                ),
              ),
            ],
          ),
        );
      }
    });

    // Emergency broadcast received
    wsClient.on('emergency_broadcast', (data) {
      if (mounted) {
        print('🚨 [EMG] EMERGENCY BROADCAST RECEIVED');
        print('🚨 [EMG] From: ${data['sender']['name']}');
        print('🚨 [EMG] Message: ${data['message']}');

        // Show emergency alert dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2a2a2a),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFff4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Color(0xFFff4444),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'EMERGENCY',
                  style: TextStyle(
                    color: Color(0xFFff4444),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFff4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFff4444)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'From: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            data['sender']['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['message'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This is an emergency broadcast to all units on this frequency.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFff4444).withOpacity(0.2),
                ),
                child: const Text(
                  'ACKNOWLEDGE',
                  style: TextStyle(
                    color: Color(0xFFff4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        // Also add to messages
        setState(() {
          _messages.add({
            'id': data['id'],
            'senderId': data['sender']['id'],
            'sender': data['sender']['name'],
            'senderName': data['sender']['name'],
            'message': data['message'],
            'text': data['message'],
            'timestamp': data['timestamp'],
            'time': _formatTime(data['timestamp']),
            'type': 'text',
            'priority': 'emergency',
            'isMe': data['sender']['id'] == _getCurrentUserId(),
          });
        });
        _scrollToBottom();
      }
    });

    wsClient.on('emergency_triggered', (data) {
      if (mounted) {
        print('✅ [EMG] Emergency broadcast sent successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emergency, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Emergency broadcast sent to all units'),
              ],
            ),
            backgroundColor: const Color(0xFFff4444),
            duration: const Duration(seconds: 2),
          ),
        );
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
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    _audioWaveController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _audioWaveController.stop();
    _pulseController.stop();

    // Add recorded message with realistic radio data
    setState(() {
      _messages.add({
        'id': _messages.length + 1,
        'sender': 'Control',
        'senderName': 'You (Control)',
        'message':
            'voice_transmission_${DateTime.now().millisecondsSinceEpoch}.mp3',
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'type': 'audio',
        'isMe': true,
        'duration':
            '0:${(DateTime.now().second % 30 + 5).toString().padLeft(2, '0')}',
        'priority': 'normal',
      });
    });

    _scrollToBottom();
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

                        // Send mic status to backend
                        final frequencyId = groupData?['frequencyId'];
                        if (frequencyId != null) {
                          final wsClient = getIt<WebSocketClient>();
                          wsClient.toggleMic(frequencyId, _isMuted);
                          print(
                            '🎤 [MIC] Toggled: ${_isMuted ? "MUTED" : "UNMUTED"}',
                          );
                        }
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

                        // Send volume status to backend
                        final frequencyId = groupData?['frequencyId'];
                        if (frequencyId != null) {
                          final wsClient = getIt<WebSocketClient>();
                          wsClient.toggleVolume(frequencyId, _isSpeakerOn);
                          print(
                            '🔊 [VOL] Toggled: ${_isSpeakerOn ? "ON" : "OFF"}',
                          );
                        }
                      },
                    ),
                    _buildRadioControlButton(
                      icon: Icons.radio,
                      label: 'SIG',
                      isActive: true,
                      onPressed: () {
                        // Check signal strength
                        final frequencyId = groupData?['frequencyId'];
                        if (frequencyId != null) {
                          final wsClient = getIt<WebSocketClient>();
                          wsClient.checkSignal(frequencyId);
                          print('📡 [SIG] Checking signal...');
                        } else {
                          print('❌ [SIG] No frequency ID available');
                        }
                      },
                    ),
                    _buildRadioControlButton(
                      icon: Icons.emergency,
                      label: 'EMG',
                      isActive: false,
                      isEmergency: true,
                      onPressed: () {
                        // Show emergency confirmation dialog
                        final frequencyId = groupData?['frequencyId'];
                        if (frequencyId != null) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF2a2a2a),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFff4444,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.emergency,
                                      color: Color(0xFFff4444),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Emergency Broadcast',
                                    style: TextStyle(
                                      color: Color(0xFFff4444),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'This will send an emergency alert to ALL users on this frequency.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFff4444,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '⚠️ Use only in genuine emergency situations',
                                      style: TextStyle(
                                        color: Color(0xFFff4444),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'CANCEL',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);

                                    // Trigger emergency
                                    final wsClient = getIt<WebSocketClient>();
                                    wsClient.triggerEmergency(
                                      frequencyId,
                                      message:
                                          '🚨 EMERGENCY BROADCAST - Immediate assistance required!',
                                    );
                                    print('🚨 [EMG] Emergency triggered!');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFff4444),
                                  ),
                                  child: const Text(
                                    'SEND EMERGENCY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          print('❌ [EMG] No frequency ID available');
                        }
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_arrow,
          color: isMe ? const Color(0xFF000000) : const Color(0xFF00ff88),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Audio Message',
          style: TextStyle(
            color: isMe ? const Color(0xFF000000) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          message['duration'] ?? '0:00',
          style: TextStyle(
            color: isMe
                ? const Color(0xFF000000).withOpacity(0.7)
                : Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
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
