import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../injection.dart';
import '../../../data/models/frequency_model.dart';
import '../../../data/network/websocket_client.dart';
import '../../services/dialer_service.dart';

class LiveRadioScreen extends StatefulWidget {
  final Map<String, dynamic>? groupData;

  const LiveRadioScreen({Key? key, this.groupData}) : super(key: key);

  @override
  State<LiveRadioScreen> createState() => _LiveRadioScreenState();
}

class _LiveRadioScreenState extends State<LiveRadioScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  late DialerService _dialerService;
  late WebSocketClient _wsClient;

  bool _isMuted = false;
  bool _isConnected = true;
  double _volume = 0.8;
  String _frequency = "505.1";
  String _stationName = "Dhvani Cast Station";
  String? _frequencyId;
  bool _showChat = false;

  FrequencyModel? _currentFrequency;
  List<Map<String, dynamic>> _connectedUsers = [];

  // Chat related
  List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Map<String, bool> _typingUsers = {};
  bool _isSendingMessage = false;
  String? _currentUserId; // Store current user ID

  @override
  void initState() {
    super.initState();

    _dialerService = getIt<DialerService>();
    _wsClient = getIt<WebSocketClient>();

    print('🚀 LiveRadioScreen: Initializing...');

    // Load current user ID
    _loadCurrentUserId();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_isConnected) {
      _waveController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }

    // Load frequency data if available
    if (widget.groupData != null) {
      _frequency = widget.groupData!['frequency']?.toString() ?? _frequency;
      _stationName = widget.groupData!['name'] ?? _stationName;
      _frequencyId = widget.groupData!['frequencyId'];

      print('📡 Frequency: $_frequency MHz');
      print('📻 Station: $_stationName');
      print('🆔 Frequency ID: $_frequencyId');

      _loadFrequencyData();

      // Load chat history
      if (_frequencyId != null) {
        _wsClient.getFrequencyChatHistory(_frequencyId!);
      }
    }

    _dialerService.addListener(_onServiceUpdate);
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    final wsClient = getIt<WebSocketClient>();

    // Listen for user joined events
    wsClient.on('user_joined_frequency', (data) {
      print('🔔 User joined frequency: $data');
      if (data['frequency']?['id'] == _frequencyId) {
        _refreshFrequencyData();
      }
    });

    // Listen for user left events
    wsClient.on('user_left_frequency', (data) {
      print('🔔 User left frequency: $data');
      if (data['frequency']?['id'] == _frequencyId) {
        _refreshFrequencyData();
      }
    });

    // Listen for frequency joined confirmation
    wsClient.on('frequency_joined', (data) {
      print('✅ Frequency joined via WebSocket: $data');
      _refreshFrequencyData();
    });

    // ===== CHAT LISTENERS =====

    // Listen for new chat messages
    wsClient.on('frequency_chat_message', (data) {
      print('💬 [CHAT LISTENER] Received chat message: $data');
      print('📱 Current frequency ID: $_frequencyId');
      print('📱 Message frequency ID: ${data['frequencyId']}');
      print('📱 IDs match: ${data['frequencyId'] == _frequencyId}');
      print('📱 Mounted: $mounted');

      if (mounted && data['frequencyId'] == _frequencyId) {
        final senderId = data['sender']['id'];
        final currentUserId = _getCurrentUserId();
        final isMe = senderId == currentUserId;

        print('👤 Sender ID: $senderId');
        print('👤 Current User ID: $currentUserId');
        print('👤 Is Me: $isMe');
        print('📝 Sender Name: ${data['sender']['name']}');
        print('💬 Message: ${data['message']}');

        setState(() {
          final newMessage = {
            'id': data['id'],
            'senderId': senderId,
            'senderName': data['sender']['name'],
            'senderAvatar': data['sender']['avatar'] ?? '👤',
            'message': data['message'],
            'timestamp': data['timestamp'],
            'isMe': isMe,
          };

          _chatMessages.add(newMessage);
          print(
            '✅ Message added to list. Total messages: ${_chatMessages.length}',
          );
          print('📋 All messages: $_chatMessages');
        });

        // Auto scroll to bottom
        _scrollChatToBottom();
      } else {
        print(
          '❌ Message not added - mounted: $mounted, IDs match: ${data['frequencyId'] == _frequencyId}',
        );
      }
    });

    // Listen for chat history
    wsClient.on('frequency_chat_history', (data) {
      print('📜 [CHAT HISTORY LISTENER] Received data: $data');
      print('📜 Messages count: ${data['messages']?.length ?? 0}');
      print('📜 Mounted: $mounted');

      if (mounted && data['messages'] != null) {
        final messages = data['messages'] as List;
        print('📜 Processing ${messages.length} messages...');

        setState(() {
          _chatMessages = messages.map((msg) {
            final newMsg = {
              'id': msg['id'],
              'senderId': msg['sender']['id'],
              'senderName': msg['sender']['name'],
              'senderAvatar': msg['sender']['avatar'] ?? '👤',
              'message': msg['message'],
              'timestamp': msg['timestamp'],
              'isMe': msg['sender']['id'] == _getCurrentUserId(),
            };
            print('📨 Processed message: $newMsg');
            return newMsg;
          }).toList();

          print(
            '✅ Chat history loaded. Total messages: ${_chatMessages.length}',
          );
        });

        // Scroll to bottom after loading history
        Future.delayed(Duration(milliseconds: 100), _scrollChatToBottom);
      } else {
        print(
          '❌ Chat history not loaded - mounted: $mounted, messages: ${data['messages']}',
        );
      }
    });

    // Listen for typing indicators
    wsClient.on('frequency_user_typing', (data) {
      if (mounted && data['frequencyId'] == _frequencyId) {
        setState(() {
          if (data['isTyping'] == true) {
            _typingUsers[data['userId']] = true;
          } else {
            _typingUsers.remove(data['userId']);
          }
        });
      }
    });

    // Listen for message sent confirmation
    wsClient.on('frequency_chat_sent', (data) {
      print('✅ Chat message sent successfully');
      setState(() {
        _isSendingMessage = false;
      });
    });
  }

  Future<void> _refreshFrequencyData() async {
    if (_frequencyId != null) {
      try {
        await _dialerService.loadFrequencies();
        _loadFrequencyData();
      } catch (e) {
        print('❌ Error refreshing frequency data: $e');
      }
    }
  }

  void _onServiceUpdate() {
    print('📡 LiveRadioScreen: Service updated');
    setState(() {});
  }

  Future<void> _loadFrequencyData() async {
    print('🔍 _loadFrequencyData: Starting...');
    print('🆔 Frequency ID: $_frequencyId');

    if (_frequencyId != null) {
      print(
        '📋 Total frequencies in service: ${_dialerService.frequencies.length}',
      );

      // Print all frequency IDs for debugging
      for (var freq in _dialerService.frequencies) {
        print(
          '   - Frequency ID: ${freq.id}, Value: ${freq.frequency} MHz, Users: ${freq.activeUsers.length}',
        );
      }

      // Get frequency details from already loaded data
      _currentFrequency = _dialerService.frequencies.firstWhere(
        (f) {
          print(
            '   🔍 Comparing: "${f.id}" == "$_frequencyId" ? ${f.id == _frequencyId}',
          );
          return f.id == _frequencyId;
        },
        orElse: () {
          print('❌ Frequency not found in service! Creating fallback...');
          return FrequencyModel(
            id: _frequencyId!,
            frequency: double.tryParse(_frequency) ?? 505.1,
            band: 'UHF',
            isPublic: true,
            activeUsers: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        },
      );

      print('✅ Found frequency: ${_currentFrequency?.id}');
      print(
        '📊 Active users in frequency model: ${_currentFrequency?.activeUsers.length ?? 0}',
      );

      if (_currentFrequency != null &&
          _currentFrequency!.activeUsers.isNotEmpty) {
        print('👥 Active users details:');
        for (var user in _currentFrequency!.activeUsers) {
          print(
            '   - User: ${user.callSign ?? user.userName}, Avatar: ${user.avatar}',
          );
        }
      }

      // Convert activeUsers to connectedUsers format for display
      _connectedUsers = _currentFrequency!.activeUsers.map((user) {
        return {
          'name': user.callSign ?? user.userName ?? 'Unknown',
          'avatar': user.avatar ?? '📻',
          'isActive': user.isTransmitting,
          'signalStrength': user.signalStrength,
        };
      }).toList();

      print(
        '✅ Current frequency users: ${_currentFrequency?.activeUsers.length ?? 0}',
      );
      print('👥 Connected users for display: ${_connectedUsers.length}');
      setState(() {});
    } else {
      print('❌ Frequency ID is null!');
    }
  }

  @override
  void dispose() {
    _dialerService.removeListener(_onServiceUpdate);
    _chatController.dispose();
    _chatScrollController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ===== HELPER METHODS =====

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

  void _scrollChatToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendChatMessage() {
    print('📤 [SEND MESSAGE] Send button clicked');
    print('📤 [SEND MESSAGE] Text: ${_chatController.text}');
    print('📤 [SEND MESSAGE] Frequency ID: $_frequencyId');

    if (_chatController.text.trim().isEmpty || _frequencyId == null) {
      print(
        '❌ [SEND MESSAGE] Validation failed - empty text or no frequency ID',
      );
      return;
    }

    final message = _chatController.text.trim();

    print('📤 [SEND MESSAGE] Sending message: "$message"');
    print('📤 [SEND MESSAGE] To frequency: $_frequencyId');

    setState(() {
      _isSendingMessage = true;
    });

    // Send message via WebSocket
    _wsClient.sendFrequencyChat(_frequencyId!, message);

    print('✅ [SEND MESSAGE] Message sent to WebSocket');

    // Clear input
    _chatController.clear();

    // Stop typing indicator
    _wsClient.sendFrequencyTyping(_frequencyId!, false);
  }

  void _onChatTextChanged(String text) {
    if (_frequencyId == null) return;

    // Send typing indicator
    if (text.isNotEmpty) {
      _wsClient.sendFrequencyTyping(_frequencyId!, true);
    } else {
      _wsClient.sendFrequencyTyping(_frequencyId!, false);
    }
  }

  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
    });

    if (_showChat) {
      // Scroll to bottom when opening chat
      Future.delayed(Duration(milliseconds: 100), _scrollChatToBottom);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    print('🎤 Mic ${_isMuted ? "muted" : "unmuted"}');
  }

  void _shareFrequency() {
    // Show share dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2a2a2a),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share, color: Color(0xFF00ff88), size: 50),
              const SizedBox(height: 16),
              const Text(
                'Share Frequency',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share frequency $_frequency MHz with others?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Frequency shared successfully!'),
                          backgroundColor: Color(0xFF00ff88),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ff88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Share',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _leaveChannel() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2a2a2a),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.exit_to_app, color: Color(0xFFff4444), size: 50),
              const SizedBox(height: 16),
              const Text(
                'Leave Channel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to leave this radio channel?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // Go back to dialer
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFff4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Leave',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat() {
    print('🎯 Opening chat for frequency: $_frequencyId');

    if (_frequencyId == null) {
      print('❌ Cannot open chat: Frequency ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open chat: Frequency not connected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to communication screen with frequency data
    Navigator.pushNamed(
      context,
      '/communication',
      arguments: {
        'frequencyId': _frequencyId,
        'name': _stationName,
        'frequency': _frequency,
        'color': const Color(0xFF00ff88),
        'status': 'active',
        'icon': Icons.radio,
        'type': 'frequency', // Important: to identify it's frequency chat
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _leaveChannel,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Radio Frequency $_frequency',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _shareFrequency,
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Radio Screen Content
            Column(
              children: [
                const SizedBox(height: 20),

                // Connected Users Grid
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                      itemCount: _connectedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _connectedUsers[index];
                        return _buildUserAvatar(user);
                      },
                    ),
                  ),
                ),

                // Control Panel
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Station Info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00ff88).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00ff88,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFF00ff88),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.radio,
                                      color: Color(0xFF00ff88),
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _stationName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Frequency: $_frequency MHz',
                                    style: const TextStyle(
                                      color: Color(0xFF00ff88),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
                                      const Text(
                                        'Live Broadcasting',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Audio Wave Visualization
                      Container(
                        height: 80,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: AudioWavePainter(_waveAnimation.value),
                              size: const Size(double.infinity, 80),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            label: _isMuted ? 'Unmute' : 'Mute',
                            color: _isMuted
                                ? const Color(0xFFff4444)
                                : const Color(0xFF00ff88),
                            onPressed: _toggleMute,
                          ),
                          _buildControlButton(
                            icon: Icons.chat,
                            label: 'Chat',
                            color: const Color(0xFF9c27b0),
                            onPressed: _openChat,
                          ),
                          _buildControlButton(
                            icon: Icons.volume_up,
                            label: 'Volume',
                            color: const Color(0xFF00aaff),
                            onPressed: _showVolumeControl,
                          ),
                          _buildControlButton(
                            icon: Icons.settings,
                            label: 'Settings',
                            color: const Color(0xFFffaa00),
                            onPressed: _showSettings,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),

            // ===== CHAT OVERLAY =====
            // Chat Panel (Slides in from bottom)
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
              bottom: _showChat ? 0 : -600,
              left: 0,
              right: 0,
              height: 600,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF2a2a2a),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble, color: Color(0xFF00ff88)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Frequency Chat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_connectedUsers.length} users online',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _toggleChat,
                            icon: Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // Chat Messages
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          print('🎨 [CHAT UI] Building chat list...');
                          print('🎨 Messages count: ${_chatMessages.length}');
                          print('🎨 Messages: $_chatMessages');

                          if (_chatMessages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.white24,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Start the conversation!',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _chatScrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: _chatMessages.length,
                            itemBuilder: (context, index) {
                              final message = _chatMessages[index];
                              print(
                                '🎨 Building message $index: ${message['message']}',
                              );
                              return _buildChatMessage(message);
                            },
                          );
                        },
                      ),
                    ),

                    // Typing Indicator
                    if (_typingUsers.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          '${_typingUsers.length} user(s) typing...',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Chat Input
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF2a2a2a),
                        border: Border(
                          top: BorderSide(color: Colors.white10, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              onChanged: _onChatTextChanged,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: Color(0xFF1a1a1a),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendChatMessage(),
                            ),
                          ),
                          SizedBox(width: 12),
                          GestureDetector(
                            onTap: _isSendingMessage ? null : _sendChatMessage,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF00ff88),
                                    Color(0xFF00aaff),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: _isSendingMessage
                                  ? Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final isActive = user['isActive'] as bool;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  const Color(0xFF00ff88).withOpacity(0.3),
                  const Color(0xFF00aaff).withOpacity(0.3),
                ]
              : [const Color(0xFF333333), const Color(0xFF444444)],
        ),
        border: Border.all(
          color: isActive ? const Color(0xFF00ff88) : const Color(0xFF555555),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(user['avatar'], style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeControl() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2a2a2a),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.volume_up, color: Color(0xFF00aaff)),
                  SizedBox(width: 12),
                  Text(
                    'Volume Control',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Volume:', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                        });
                      },
                      activeColor: const Color(0xFF00aaff),
                      inactiveColor: const Color(0xFF555555),
                    ),
                  ),
                  Text(
                    '${(_volume * 100).round()}%',
                    style: const TextStyle(color: Color(0xFF00aaff)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Color(0xFF00aaff)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2a2a2a),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings, color: Color(0xFFffaa00)),
                  SizedBox(width: 12),
                  Text(
                    'Radio Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Color(0xFFffaa00),
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: const Color(0xFFffaa00),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.record_voice_over,
                  color: Color(0xFFffaa00),
                ),
                title: const Text(
                  'Auto Voice Detection',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: const Color(0xFFffaa00),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Color(0xFFffaa00)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build chat message bubble
  Widget _buildChatMessage(Map<String, dynamic> message) {
    print('🎨 [BUILD MESSAGE] Building message bubble...');
    print('🎨 [BUILD MESSAGE] Message data: $message');

    final bool isMe = message['isMe'] ?? false;
    final String senderName = message['senderName'] ?? 'Unknown';
    final String senderAvatar = message['senderAvatar'] ?? '👤';
    final String messageText = message['message'] ?? '';
    final String timestamp = message['timestamp'] ?? '';

    print('🎨 [BUILD MESSAGE] isMe: $isMe');
    print('🎨 [BUILD MESSAGE] senderName: $senderName');
    print('🎨 [BUILD MESSAGE] messageText: $messageText');

    // Parse timestamp
    String timeString = '';
    try {
      final DateTime time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) {
        timeString = 'Just now';
      } else if (difference.inHours < 1) {
        timeString = '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        timeString = '${difference.inHours}h ago';
      } else {
        timeString = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      timeString = '';
      print('⚠️ [BUILD MESSAGE] Timestamp parse error: $e');
    }

    print('🎨 [BUILD MESSAGE] Alignment: ${isMe ? "RIGHT" : "LEFT"}');

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // Avatar for other users
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFF00ff88).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFF00ff88).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(senderAvatar, style: TextStyle(fontSize: 18)),
              ),
            ),
            SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        color: Color(0xFF00ff88),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [Color(0xFF00ff88), Color(0xFF00aaff)],
                          )
                        : null,
                    color: isMe ? null : Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 18 : 4),
                      topRight: Radius.circular(isMe ? 4 : 18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      if (timeString.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isMe) SizedBox(width: 8),
        ],
      ),
    );
  }
}

// Custom Painter for Audio Wave Animation
class AudioWavePainter extends CustomPainter {
  final double animationValue;

  AudioWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00ff88).withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveHeight = size.height * 0.3;
    final centerY = size.height / 2;

    path.moveTo(0, centerY);

    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = x / size.width;
      final waveOffset =
          waveHeight *
          (0.5 + 0.5 * (animationValue * 2 - 1)) *
          (1 + 0.5 * normalizedX) *
          (1 - normalizedX);

      final y =
          centerY +
          waveOffset *
              (1 + 0.8 * (0.5 - (normalizedX - 0.5).abs())) *
              (0.8 + 0.4 * animationValue);

      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw additional wave lines for effect
    for (int i = 1; i <= 3; i++) {
      final fadePaint = Paint()
        ..color = const Color(0xFF00ff88).withOpacity(0.3 / i)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final fadePath = Path();
      fadePath.moveTo(0, centerY);

      for (double x = 0; x <= size.width; x += 2) {
        final normalizedX = x / size.width;
        final waveOffset =
            waveHeight *
            (0.5 + 0.5 * (animationValue * 2 - 1)) *
            (1 + 0.5 * normalizedX) *
            (1 - normalizedX) *
            (1 - i * 0.2);

        final y =
            centerY +
            waveOffset *
                (1 + 0.8 * (0.5 - (normalizedX - 0.5).abs())) *
                (0.8 + 0.4 * animationValue);

        fadePath.lineTo(x, y + i * 5);
      }

      canvas.drawPath(fadePath, fadePaint);
    }
  }

  @override
  bool shouldRepaint(AudioWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
