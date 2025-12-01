import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../injection.dart';
import '../../../models/frequency_model.dart';
import '../../../core/websocket_client.dart';
import '../../../shared/services/dialer_service.dart';
import '../../../shared/services/livekit_service.dart';
import '../../../shared/services/social_service.dart';

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
  late LiveKitService _livekitService;

  bool _isMuted = false;
  bool _isConnected = true;
  bool _isSpeakerOn =
      true; // Speaker output mode (true = loudspeaker, false = earpiece)
  String _frequency = "505.1";
  String _stationName = "Dhvani Cast Station";
  String? _frequencyId;
  bool _showChat = false;

  // Signal strength tracking
  int _signalBars = 3;
  String _signalQuality = 'Good';

  FrequencyModel? _currentFrequency;
  List<Map<String, dynamic>> _connectedUsers = [];

  // Chat related
  List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Map<String, bool> _typingUsers = {};
  bool _isSendingMessage = false;
  String? _currentUserId; // Store current user ID
  String? _chatStorageKey; // Unique key for storing chat messages

  // Private frequency users list
  List<FrequencyUser> _privateFrequencyUsers = [];

  @override
  void initState() {
    super.initState();

    _dialerService = getIt<DialerService>();
    _wsClient = getIt<WebSocketClient>();
    _livekitService = getIt<LiveKitService>();

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
      // Check if it's a private frequency
      final isPrivate = widget.groupData!['isPrivate'] ?? false;

      if (isPrivate) {
        // ================= PRIVATE FREQUENCY INITIALIZATION =================
        print('🔒 [PRIVATE INIT] Starting private frequency initialization');
        // Prefer explicit backend id if provided by API response
        final backendId =
            widget.groupData!['frequencyId'] ?? widget.groupData!['_id'];
        final frequencyNumber = widget.groupData!['frequencyNumber'];
        _frequency =
            widget.groupData!['frequencyValue']?.toString() ??
            frequencyNumber?.toString() ??
            _frequency;
        _stationName =
            widget.groupData!['frequencyName'] ??
            widget.groupData!['name'] ??
            'Private ${_frequency} MHz';
        // Use backend id when available; otherwise synthetic id with prefix
        _frequencyId = backendId != null
            ? backendId.toString()
            : 'private_${frequencyNumber}';

        print('🔒 [PRIVATE INIT] frequencyNumber: $frequencyNumber');
        print('🔒 [PRIVATE INIT] backendId: $backendId');
        print('🔒 [PRIVATE INIT] assigned _frequencyId: $_frequencyId');
        print('📡 [PRIVATE INIT] Frequency: $_frequency MHz');
        print('📻 [PRIVATE INIT] Station: $_stationName');

        // Initialize private users if available in groupData
        if (widget.groupData!['members'] != null) {
          try {
            final membersRaw = widget.groupData!['members'];
            print(
              '👥 [PRIVATE INIT] Raw members data type: ${membersRaw.runtimeType}',
            );
            final members = membersRaw as List;
            _privateFrequencyUsers = members.map((m) {
              // Handle both GroupMember JSON and simple user JSON
              final user = m is Map ? (m['user'] ?? m) : {};
              final uid = user['_id'] ?? user['id'] ?? '';
              final uname = user['name'] ?? user['userName'] ?? 'Unknown';
              final avatar = user['avatar'] ?? '📻';
              print(
                '🔄 [PRIVATE INIT] Mapping member -> userId=$uid name=$uname avatar=$avatar',
              );
              return FrequencyUser(
                userId: uid,
                userName: uname,
                avatar: avatar,
                joinedAt: DateTime.now(),
                isTransmitting: false,
                signalStrength: 3,
              );
            }).toList();
            print(
              '👥 [PRIVATE INIT] Mapped ${_privateFrequencyUsers.length} private users',
            );
          } catch (e) {
            print('❌ [PRIVATE INIT] Error initializing private users: $e');
          }
        } else {
          print('⚠️ [PRIVATE INIT] No members array found in groupData');
        }
      } else {
        // Public frequency data
        _frequency = widget.groupData!['frequency']?.toString() ?? _frequency;
        _stationName = widget.groupData!['name'] ?? _stationName;
        _frequencyId = widget.groupData!['frequencyId'];

        print('📡 PUBLIC FREQUENCY JOINED');
        print('📡 Frequency: $_frequency MHz');
        print('📻 Station: $_stationName');
        print('🆔 Frequency ID: $_frequencyId');
      }

      _loadFrequencyData();

      // Load chat history
      if (_frequencyId != null) {
        _chatStorageKey = 'chat_$_frequencyId';
        _loadChatFromStorage(); // Load from local storage first
        _wsClient.getFrequencyChatHistory(_frequencyId!);
      }
    }

    _dialerService.addListener(_onServiceUpdate);
    _setupWebSocketListeners();

    // Initialize LiveKit voice call after frequency join
    _initializeLiveKit();
  }

  Future<void> _initializeLiveKit() async {
    if (_frequencyId == null) {
      print('⚠️ [LiveKit] Cannot initialize - missing frequencyId');
      return;
    }

    try {
      // Get user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user');
      final token = prefs.getString('token');

      if (userDataString == null || token == null) {
        print('⚠️ [LiveKit] Cannot initialize - missing user data or token');
        return;
      }

      final userData = jsonDecode(userDataString);
      final userName = userData['name'] ?? 'User';

      print('🎙️ [LiveKit] Initializing for frequency: $_frequencyId');
      print('👤 [LiveKit] User: $userName');

      // Enable wakelock to keep audio working when screen is off
      try {
        await WakelockPlus.enable();
        print(
          '🔓 [LiveKit] Wakelock enabled - audio will work with screen off',
        );
      } catch (e) {
        print('⚠️ [LiveKit] Could not enable wakelock: $e');
      }

      // Connect to LiveKit
      await _livekitService.connectToFrequency(_frequencyId!, userName, token);

      // Update mute state from service
      setState(() {
        _isMuted = _livekitService.isMuted;
      });

      print('✅ [LiveKit] Initialization complete');
    } catch (e) {
      print('❌ [LiveKit] Initialization error: $e');
    }
  }

  void _setupWebSocketListeners() {
    final wsClient = getIt<WebSocketClient>();

    bool _isSameFrequency(dynamic freqData) {
      if (freqData == null) return false;
      final dataId = freqData['id'] ?? freqData['_id'];
      final dataNumber = freqData['frequencyNumber'];
      final matchesId = (dataId != null && dataId.toString() == _frequencyId);
      // For synthetic private id (private_<number>) also allow matching by number
      final isSyntheticPrivate = _frequencyId?.startsWith('private_') ?? false;
      final syntheticNumber = isSyntheticPrivate
          ? _frequencyId!.replaceFirst('private_', '')
          : null;
      final matchesNumber =
          isSyntheticPrivate &&
          dataNumber != null &&
          dataNumber.toString() == syntheticNumber;
      final result = matchesId || matchesNumber;
      print(
        '🧪 [FREQ MATCH] dataId=$dataId dataNumber=$dataNumber synthetic=$syntheticNumber -> result=$result',
      );
      return result;
    }

    // Listen for user joined events
    wsClient.on('user_joined_frequency', (data) {
      print('🔔 [WS] User joined frequency event: $data');
      if (_isSameFrequency(data['frequency'])) {
        print('✅ [WS] Event matches current frequency');
        if (_frequencyId != null && _frequencyId!.startsWith('private_')) {
          _handlePrivateUserJoin(data);
        }
        _refreshFrequencyData();
      } else {
        print('⛔ [WS] Event does not match current frequencyId=$_frequencyId');
      }
    });

    // Listen for user left events
    wsClient.on('user_left_frequency', (data) {
      print('🔔 [WS] User left frequency event: $data');
      if (_isSameFrequency(data['frequency'])) {
        print('✅ [WS] Leave event matches current frequency');
        if (_frequencyId != null && _frequencyId!.startsWith('private_')) {
          _handlePrivateUserLeave(data);
        }
        _refreshFrequencyData();
      } else {
        print(
          '⛔ [WS] Leave event does not match current frequencyId=$_frequencyId',
        );
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
            'imageData': data['imageData'], // Add image data support
            'timestamp': data['timestamp'],
            'isMe': isMe,
          };

          _chatMessages.add(newMessage);
          print(
            '✅ Message added to list. Total messages: ${_chatMessages.length}',
          );
          print('📋 All messages: $_chatMessages');
        });

        // Save to local storage
        _saveChatToStorage();

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

        // Convert server messages
        final serverMessages = messages.map((msg) {
          final newMsg = {
            'id': msg['id'],
            'senderId': msg['sender']['id'],
            'senderName': msg['sender']['name'],
            'senderAvatar': msg['sender']['avatar'] ?? '👤',
            'message': msg['message'],
            'imageData': msg['imageData'], // Add image data support
            'timestamp': msg['timestamp'],
            'isMe': msg['sender']['id'] == _getCurrentUserId(),
          };
          print('📨 Processed message: $newMsg');
          return newMsg;
        }).toList();

        setState(() {
          // Merge with local storage messages (avoid duplicates)
          final existingIds = _chatMessages.map((m) => m['id']).toSet();
          final newMessages = serverMessages
              .where((m) => !existingIds.contains(m['id']))
              .toList();

          _chatMessages.addAll(newMessages);

          // Sort by timestamp
          _chatMessages.sort((a, b) {
            try {
              final timeA = DateTime.parse(a['timestamp']);
              final timeB = DateTime.parse(b['timestamp']);
              return timeA.compareTo(timeB);
            } catch (e) {
              return 0;
            }
          });

          print(
            '✅ Chat history loaded. Total messages: ${_chatMessages.length}',
          );
        });

        // Save merged messages to storage
        _saveChatToStorage();

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
      // For private frequencies, we don't fetch from API as they might not be in the public list
      if (_frequencyId!.startsWith('private_')) {
        _loadFrequencyData();
        return;
      }

      try {
        // Load just the current frequency by id to avoid loading the full list
        await _dialerService.loadFrequencyById(_frequencyId!);
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
          print(
            '❌ [LOAD] Frequency not found in service! Creating private/public fallback model',
          );
          final activeUsers = _frequencyId!.startsWith('private_')
              ? _privateFrequencyUsers
              : <FrequencyUser>[];
          return FrequencyModel(
            id: _frequencyId!,
            frequency: double.tryParse(_frequency) ?? 505.1,
            band: 'UHF',
            isPublic: !_frequencyId!.startsWith('private_'),
            activeUsers: activeUsers,
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
        print('👥 [DEBUG] Active users details:');
        for (var i = 0; i < _currentFrequency!.activeUsers.length; i++) {
          final user = _currentFrequency!.activeUsers[i];
          print('   [User $i]');
          print('      userId: ${user.userId}');
          print('      userName: ${user.userName}');
          print('      callSign: ${user.callSign}');
          print('      avatar: ${user.avatar}');
          print('      isTransmitting: ${user.isTransmitting}');
          print('      signalStrength: ${user.signalStrength}');
        }
      }

      // Convert activeUsers to connectedUsers format for display
      _connectedUsers = _currentFrequency!.activeUsers.map((user) {
        // Prefer userName over callSign for display
        final displayName = user.userName ?? user.callSign ?? 'Unknown';
        print(
          '🔄 [MAPPING] userId: ${user.userId} → displayName: $displayName',
        );
        print('   userName: ${user.userName}, callSign: ${user.callSign}');

        return {
          'userId': user.userId, // Add userId for friend requests
          'name': displayName,
          'avatar': user.avatar ?? '📻',
          'isActive': user.isTransmitting,
          'signalStrength': user.signalStrength,
        };
      }).toList();

      // Update signal strength based on user count and average strength
      _updateSignalStrength();

      print(
        '✅ Current frequency users: ${_currentFrequency?.activeUsers.length ?? 0}',
      );
      print('👥 Connected users for display: ${_connectedUsers.length}');
      setState(() {});
    } else {
      print('❌ Frequency ID is null!');
    }
  }

  void _updateSignalStrength() {
    if (_connectedUsers.isEmpty) {
      _signalBars = 1;
      _signalQuality = 'Poor';
    } else if (_connectedUsers.length == 1) {
      _signalBars = 1;
      _signalQuality = 'Poor';
    } else if (_connectedUsers.length == 2) {
      _signalBars = 2;
      _signalQuality = 'Fair';
    } else if (_connectedUsers.length == 3) {
      _signalBars = 3;
      _signalQuality = 'Good';
    } else if (_connectedUsers.length == 4) {
      _signalBars = 4;
      _signalQuality = 'Strong';
    } else {
      _signalBars = 5;
      _signalQuality = 'Excellent';
    }
  }

  void _handlePrivateUserJoin(dynamic data) {
    try {
      final user = data['user'];
      if (user != null) {
        final newUser = FrequencyUser(
          userId: user['_id'] ?? user['id'] ?? '',
          userName: user['name'] ?? 'Unknown',
          avatar: user['avatar'],
          joinedAt: DateTime.now(),
          isTransmitting: false,
          signalStrength: 3,
        );

        // Check if user already exists
        final index = _privateFrequencyUsers.indexWhere(
          (u) => u.userId == newUser.userId,
        );
        if (index == -1) {
          setState(() {
            _privateFrequencyUsers.add(newUser);
          });
          print('✅ Added user to private list: ${newUser.userName}');
        }
      }
    } catch (e) {
      print('❌ Error handling private user join: $e');
    }
  }

  void _handlePrivateUserLeave(dynamic data) {
    try {
      final userId = data['userId'];
      if (userId != null) {
        setState(() {
          _privateFrequencyUsers.removeWhere((u) => u.userId == userId);
        });
        print('✅ Removed user from private list: $userId');
      }
    } catch (e) {
      print('❌ Error handling private user leave: $e');
    }
  }

  @override
  void dispose() {
    _dialerService.removeListener(_onServiceUpdate);
    _chatController.dispose();
    _chatScrollController.dispose();
    _waveController.dispose();
    _pulseController.dispose();

    // Disconnect from LiveKit
    _livekitService.disconnect();

    // Disable wakelock when leaving
    WakelockPlus.disable();

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

        // If we're in a private frequency and we have no members list from server, add self
        if (_frequencyId != null && _frequencyId!.startsWith('private_')) {
          final alreadyExists = _privateFrequencyUsers.any(
            (u) => u.userId == _currentUserId,
          );
          if (!alreadyExists) {
            final selfUser = FrequencyUser(
              userId: _currentUserId ?? 'unknown_self',
              userName: userData['name'] ?? 'Me',
              avatar: '📻',
              joinedAt: DateTime.now(),
              isTransmitting: false,
              signalStrength: 3,
            );
            _privateFrequencyUsers.add(selfUser);
            print('👤 [PRIVATE SELF ADD] Added current user to private list');
            // Reload mapping so avatar appears immediately
            await _loadFrequencyData();
          } else {
            print('👤 [PRIVATE SELF ADD] Current user already in private list');
          }
        }
      } else {
        print('❌ [USER ID] No user data found in storage');
      }
    } catch (e) {
      print('❌ [USER ID] Error loading current user ID: $e');
    }
  }

  void _toggleMute() async {
    // Toggle LiveKit microphone
    await _livekitService.toggleMute();

    setState(() {
      _isMuted = _livekitService.isMuted;
    });

    print('🎤 [LiveKit] Mic ${_isMuted ? 'muted' : 'unmuted'}');
  }

  void _toggleSpeaker() async {
    // Toggle speaker output between loudspeaker and earpiece
    await _livekitService.setSpeakerPhone(!_isSpeakerOn);

    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });

    print(
      '🔊 [LiveKit] Audio output: ${_isSpeakerOn ? 'Loudspeaker' : 'Earpiece'}',
    );

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSpeakerOn
              ? '🔊 Switched to Loudspeaker'
              : '📱 Switched to Earpiece',
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF00aaff),
      ),
    );
  }

  String _getCurrentUserId() {
    final userId = _currentUserId ?? '';
    print('👤 [GET USER ID] Returning: $userId');
    return userId;
  }

  // Load chat messages from local storage
  Future<void> _loadChatFromStorage() async {
    print('💾 [STORAGE] Loading chat from local storage...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = _chatStorageKey ?? '';

      if (chatKey.isEmpty) {
        print('❌ [STORAGE] No storage key available');
        return;
      }

      final chatData = prefs.getString(chatKey);
      print('💾 [STORAGE] Data from key "$chatKey": $chatData');

      if (chatData != null) {
        final List<dynamic> decodedList = jsonDecode(chatData);

        // Ensure current user ID is loaded
        final currentUserId = _getCurrentUserId();
        print('💾 [STORAGE] Current User ID for comparison: $currentUserId');

        setState(() {
          _chatMessages = decodedList.map((item) {
            final msg = Map<String, dynamic>.from(item as Map);

            // Verify and fix the isMe flag based on current user ID
            final senderId = msg['senderId'] ?? '';
            final isMe = senderId == currentUserId;
            msg['isMe'] = isMe;

            print(
              '💾 [STORAGE] Message from ${msg['senderName']}: isMe=$isMe (senderId=$senderId)',
            );

            return msg;
          }).toList();
        });
        print(
          '✅ [STORAGE] Loaded ${_chatMessages.length} messages from storage',
        );

        // Scroll to bottom after loading
        Future.delayed(Duration(milliseconds: 100), _scrollChatToBottom);
      } else {
        print('💾 [STORAGE] No saved chat found for this frequency');
      }
    } catch (e) {
      print('❌ [STORAGE] Error loading chat: $e');
    }
  }

  // Save chat messages to local storage
  Future<void> _saveChatToStorage() async {
    print('💾 [STORAGE] Saving chat to local storage...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = _chatStorageKey ?? '';

      if (chatKey.isEmpty) {
        print('❌ [STORAGE] No storage key available');
        return;
      }

      final chatData = jsonEncode(_chatMessages);
      await prefs.setString(chatKey, chatData);
      print('✅ [STORAGE] Saved ${_chatMessages.length} messages to storage');
    } catch (e) {
      print('❌ [STORAGE] Error saving chat: $e');
    }
  }

  // Clear chat from local storage
  Future<void> _clearChatFromStorage() async {
    print('🗑️ [STORAGE] Clearing chat from local storage...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = _chatStorageKey ?? '';

      if (chatKey.isEmpty) {
        print('❌ [STORAGE] No storage key available');
        return;
      }

      await prefs.remove(chatKey);
      print('✅ [STORAGE] Chat cleared from storage');
    } catch (e) {
      print('❌ [STORAGE] Error clearing chat: $e');
    }
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFff4444).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  color: Color(0xFFff4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Leave Channel?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All chat messages will be cleared',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        print('👋 [LEAVE] ====== LEAVING FREQUENCY ======');
                        print('👋 [LEAVE] Frequency ID: $_frequencyId');
                        print('👋 [LEAVE] Frequency: $_frequency MHz');

                        if (_frequencyId != null) {
                          try {
                            // 1. Leave frequency via service
                            print(
                              '👋 [LEAVE] Step 1: Calling leaveFrequency API...',
                            );

                            // Check if it's a private frequency
                            if (_frequencyId!.startsWith('private_')) {
                              print(
                                '🔒 [LEAVE] Private frequency detected. Skipping standard API call.',
                              );
                              // For private frequencies, we just notify via socket if needed,
                              // but don't call the standard leave endpoint which expects a MongoDB ID
                            } else {
                              final success = await _dialerService
                                  .leaveFrequency(_frequencyId!);

                              if (success) {
                                print(
                                  '✅ [LEAVE] Successfully left frequency via API',
                                );
                              } else {
                                print('⚠️ [LEAVE] Leave API returned false');
                              }
                            }

                            // 2. Clear local chat storage
                            print(
                              '👋 [LEAVE] Step 2: Clearing local chat storage...',
                            );
                            await _clearChatFromStorage();
                            print('✅ [LEAVE] Chat cleared from local storage');

                            // 3. Clear in-memory chat messages
                            print(
                              '👋 [LEAVE] Step 3: Clearing in-memory messages...',
                            );
                            setState(() {
                              _chatMessages.clear();
                            });
                            print('✅ [LEAVE] In-memory messages cleared');

                            // 4. Notify via WebSocket
                            print(
                              '👋 [LEAVE] Step 4: Notifying via WebSocket...',
                            );
                            _wsClient.leaveFrequency(_frequencyId!);
                            print('✅ [LEAVE] WebSocket notification sent');
                          } catch (e) {
                            print('❌ [LEAVE] Error leaving frequency: $e');
                          }
                        }

                        // 5. Close dialog and navigate back
                        print('👋 [LEAVE] Step 5: Navigating back...');
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Leave channel screen
                        print(
                          '✅ [LEAVE] ====== LEFT FREQUENCY SUCCESSFULLY ======',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFff4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Leave',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
        'activeUsers': _connectedUsers, // Pass active users list
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
        title: Column(
          children: [
            Text(
              'Radio Frequency $_frequency',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_connectedUsers.length} Active User${_connectedUsers.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF00ff88),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.circle, size: 4, color: Colors.white54),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 1.5),
                    width: 2.5,
                    height: 8 + (index * 1.5),
                    decoration: BoxDecoration(
                      color: index < _signalBars
                          ? const Color(0xFF00ff88)
                          : const Color(0xFF555555),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  _signalQuality,
                  style: const TextStyle(
                    color: Color(0xFF00ff88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
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
                            childAspectRatio:
                                0.8, // Adjusted to fit name below avatar
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
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
                            const SizedBox(width: 16),
                            _buildControlButton(
                              icon: Icons.chat,
                              label: 'Chat',
                              color: const Color(0xFF9c27b0),
                              onPressed: _openChat,
                            ),
                            const SizedBox(width: 16),
                            _buildControlButton(
                              icon: _isSpeakerOn
                                  ? Icons.volume_up
                                  : Icons.phone_in_talk,
                              label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                              color: const Color(0xFF00aaff),
                              onPressed: _toggleSpeaker,
                            ),
                            const SizedBox(width: 16),
                            _buildControlButton(
                              icon: Icons.exit_to_app,
                              label: 'Disconnect',
                              color: const Color(0xFFff4444),
                              onPressed: _leaveChannel,
                            ),
                          ],
                        ),
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
    final isActive = (user['isActive'] as bool?) ?? false;
    final userName = (user['name'] ?? 'Unknown').toString();
    final avatar = (user['avatar'] ?? '📻').toString();
    final userId = (user['userId'] ?? user['_id'] ?? '').toString();

    print(
      '🎨 [AVATAR] Building avatar widget -> name="$userName" active=$isActive avatar=$avatar full=$user',
    );

    return GestureDetector(
      onTap: () {
        print('👆 [TAP] Avatar tapped for user: $userName');
        print('👆 [TAP] userId: $userId');
        print('👆 [TAP] _currentUserId: $_currentUserId');

        // Always show action sheet - Report is available for everyone
        _showUserActionSheet(context, user);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [
                          const Color(0xFF00ff88).withOpacity(0.35),
                          const Color(0xFF00aaff).withOpacity(0.35),
                        ]
                      : [const Color(0xFF333333), const Color(0xFF444444)],
                ),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF00ff88)
                      : const Color(0xFF555555),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(avatar, style: const TextStyle(fontSize: 26)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              userName,
              style: TextStyle(
                color: isActive ? const Color(0xFF00ff88) : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Show user action bottom sheet with Report and Add Friend options
  void _showUserActionSheet(BuildContext context, Map<String, dynamic> user) {
    final userName = (user['name'] ?? 'Unknown').toString();
    final avatar = (user['avatar'] ?? '📻').toString();
    final userId = (user['userId'] ?? user['_id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2a2a2a),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // User info header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00ff88), Color(0xFF00aaff)],
                        ),
                        border: Border.all(
                          color: const Color(0xFF00ff88),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'In $_stationName',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF444444), height: 1),

              // Add Friend Option (only show for other users)
              if (userId != _currentUserId) ...[
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _addFriend(userId, userName);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ff88).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Color(0xFF00ff88),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Friend',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Send friend request',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0xFF444444), height: 1),
              ],

              // Report User Option (only show for other users)
              if (userId != _currentUserId) ...[
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog(context, userId, userName);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Report inappropriate behavior',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0xFF444444), height: 1),
              ],

              // Report Frequency Option (available for everyone)
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showFrequencyReportDialog(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.report_problem,
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Report Frequency',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Report issues with $_stationName',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white38,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Show frequency report dialog
  void _showFrequencyReportDialog(BuildContext context) {
    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    final List<Map<String, String>> reportReasons = [
      {'icon': '🚫', 'title': 'Spam or Misleading Content', 'value': 'spam'},
      {'icon': '😡', 'title': 'Harassment in Frequency', 'value': 'harassment'},
      {
        'icon': '🔞',
        'title': 'Inappropriate Content',
        'value': 'inappropriate',
      },
      {'icon': '⚠️', 'title': 'Technical Issues', 'value': 'technical'},
      {'icon': '🤥', 'title': 'False Information', 'value': 'false_info'},
      {'icon': '📻', 'title': 'Other', 'value': 'other'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF2a2a2a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.report_problem,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Report Frequency',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _stationName,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Why are you reporting this frequency?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Report reasons
                      ...reportReasons.map((reason) {
                        final isSelected = selectedReason == reason['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedReason = reason['value'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange.withOpacity(0.15)
                                  : const Color(0xFF1a1a1a),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange
                                    : const Color(0xFF444444),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  reason['icon']!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    reason['title']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.orange,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // Additional details
                      const Text(
                        'Additional Details (Optional)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: detailsController,
                        maxLines: 3,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Describe the issue...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1a1a1a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF444444),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF444444),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.orange,
                              width: 2,
                            ),
                          ),
                          counterStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedReason == null
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _submitFrequencyReport(
                                        selectedReason!,
                                        detailsController.text,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                disabledBackgroundColor: Colors.orange
                                    .withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Submit Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Submit frequency report
  Future<void> _submitFrequencyReport(String reason, String details) async {
    final socialService = SocialService();

    try {
      print('📻 [FREQUENCY REPORT] Reporting frequency: $_stationName');
      print('📻 [FREQUENCY REPORT] Frequency: $_frequency MHz');
      print('📻 [FREQUENCY REPORT] Reason: $reason');
      print('📻 [FREQUENCY REPORT] Details: $details');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Submitting report...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );

      // Call API
      await socialService.submitReport(
        reason: reason,
        details: details,
        frequency: _frequency,
        frequencyName: _stationName,
        reportType: 'frequency',
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Frequency report submitted successfully',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2a2a2a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.orange, width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [FREQUENCY REPORT] Error: $e');

      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2a2a2a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show report dialog with reasons
  void _showReportDialog(BuildContext context, String userId, String userName) {
    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    final List<Map<String, String>> reportReasons = [
      {'icon': '🚫', 'title': 'Spam or Misleading', 'value': 'spam'},
      {
        'icon': '😡',
        'title': 'Harassment or Hate Speech',
        'value': 'harassment',
      },
      {
        'icon': '🔞',
        'title': 'Inappropriate Content',
        'value': 'inappropriate',
      },
      {'icon': '🤥', 'title': 'False Information', 'value': 'false_info'},
      {'icon': '⚠️', 'title': 'Other', 'value': 'other'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF2a2a2a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.flag,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Report User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Why are you reporting this user?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Report reasons
                      ...reportReasons.map((reason) {
                        final isSelected = selectedReason == reason['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedReason = reason['value'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red.withOpacity(0.15)
                                  : const Color(0xFF1a1a1a),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red
                                    : const Color(0xFF444444),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  reason['icon']!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    reason['title']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // Additional details
                      const Text(
                        'Additional Details (Optional)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: detailsController,
                        maxLines: 3,
                        maxLength: 200,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Describe the issue...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1a1a1a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF444444),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF444444),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          counterStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedReason == null
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _submitReport(
                                        userId,
                                        userName,
                                        selectedReason!,
                                        detailsController.text,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                disabledBackgroundColor: Colors.red.withOpacity(
                                  0.3,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Submit Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Handle friend request
  Future<void> _addFriend(String userId, String userName) async {
    final socialService = SocialService();

    try {
      print('🤝 [ADD FRIEND] Sending friend request to userId: $userId');

      // Call API
      await socialService.sendFriendRequest(receiverId: userId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00ff88)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Friend request sent to $userName',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2a2a2a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF00ff88), width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [ADD FRIEND] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2a2a2a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Submit report
  Future<void> _submitReport(
    String userId,
    String userName,
    String reason,
    String details,
  ) async {
    final socialService = SocialService();

    try {
      print('🚩 [REPORT] Reporting userId: $userId');
      print('🚩 [REPORT] Reason: $reason');
      print('🚩 [REPORT] Details: $details');

      // Call API
      await socialService.submitReport(
        reportedUserId: userId,
        reason: reason,
        details: details,
        frequency: _frequency,
        frequencyName: _stationName,
        reportType: 'user',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00ff88)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Report submitted successfully',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2a2a2a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Color(0xFF00ff88), width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [REPORT] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2a2a2a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

  // Build chat message bubble
  Widget _buildChatMessage(Map<String, dynamic> message) {
    print('🎨 [BUILD MESSAGE] Building message bubble...');
    print('🎨 [BUILD MESSAGE] Message data: $message');

    final bool isMe = message['isMe'] ?? false;
    final String senderName = message['senderName'] ?? 'Unknown';
    final String senderAvatar = message['senderAvatar'] ?? '👤';
    final String messageText = message['message'] ?? '';
    final String timestamp = message['timestamp'] ?? '';
    final String? imageData = message['imageData'];
    final bool hasImage = imageData != null && imageData.isNotEmpty;

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
                      // Display image if present
                      if (hasImage) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(imageData),
                            width: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[800],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[600],
                                  size: 48,
                                ),
                              );
                            },
                          ),
                        ),
                        if (messageText.isNotEmpty) SizedBox(height: 8),
                      ],
                      // Display text message
                      if (messageText.isNotEmpty)
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
