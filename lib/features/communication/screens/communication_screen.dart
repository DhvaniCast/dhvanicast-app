import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../../injection.dart';
import '../../../shared/services/communication_service.dart';
import '../../../core/websocket_client.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({Key? key}) : super(key: key);

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen>
    with TickerProviderStateMixin {
  late CommunicationService _commService;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isMuted = false;
  bool _isSpeakerOn = false;

  Map<String, dynamic>? groupData;
  String? _currentUserId; // Store current user ID
  String? _chatStorageKey; // Unique key for storing chat messages
  bool _isInitialized = false; // Track if chat is initialized

  // Local state for messages and active users/members
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _activeUsers = [];

  // Signal strength tracking
  int _signalBars = 3;
  String _signalQuality = 'Good';

  @override
  void initState() {
    super.initState();

    // Get Services from DI
    _commService = getIt<CommunicationService>();

    print('🚀 CommunicationScreen: Initializing...');

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

  // Load chat messages from local storage
  Future<void> _loadChatFromStorage() async {
    print('💾 [STORAGE] ====== LOADING CHAT FROM STORAGE ======');
    print('💾 [STORAGE] Storage key: $_chatStorageKey');

    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = _chatStorageKey ?? '';

      if (chatKey.isEmpty) {
        print('❌ [STORAGE] No storage key available');
        return;
      }

      final chatData = prefs.getString(chatKey);
      print('💾 [STORAGE] Raw data from key "$chatKey": $chatData');
      print('💾 [STORAGE] Data length: ${chatData?.length ?? 0}');

      if (chatData != null && chatData.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(chatData);
        print('💾 [STORAGE] Decoded ${decodedList.length} messages');

        // Ensure current user ID is loaded
        final currentUserId = _getCurrentUserId();
        print('💾 [STORAGE] Current User ID for comparison: $currentUserId');

        setState(() {
          _messages = decodedList.map((item) {
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

        print('✅ [STORAGE] Loaded ${_messages.length} messages from storage');

        // Scroll to bottom after loading
        Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
      } else {
        print('💾 [STORAGE] No saved chat found (data is null or empty)');
      }
    } catch (e, stackTrace) {
      print('❌ [STORAGE] Error loading chat: $e');
      print('❌ [STORAGE] Stack trace: $stackTrace');
    }

    print('💾 [STORAGE] ====== LOAD COMPLETE ======');
  }

  // Save chat messages to local storage
  Future<void> _saveChatToStorage() async {
    print('💾 [SAVE] ====== SAVING CHAT TO STORAGE ======');
    print('💾 [SAVE] Storage key: $_chatStorageKey');
    print('💾 [SAVE] Messages count: ${_messages.length}');

    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = _chatStorageKey ?? '';

      if (chatKey.isEmpty) {
        print('❌ [SAVE] No storage key available');
        return;
      }

      final chatData = jsonEncode(_messages);
      print('💾 [SAVE] Encoded data length: ${chatData.length}');

      await prefs.setString(chatKey, chatData);
      print('✅ [SAVE] Saved ${_messages.length} messages to storage');

      // Verify save
      final verifyData = prefs.getString(chatKey);
      print('✅ [SAVE] Verification - Data exists: ${verifyData != null}');
      print('✅ [SAVE] Verification - Data length: ${verifyData?.length ?? 0}');
    } catch (e, stackTrace) {
      print('❌ [SAVE] Error saving chat: $e');
      print('❌ [SAVE] Stack trace: $stackTrace');
    }

    print('💾 [SAVE] ====== SAVE COMPLETE ======');
  }

  // Clear chat from local storage
  Future<void> _clearChatFromStorage() async {
    print('🗑️ [CLEAR] ====== CLEARING CHAT FROM STORAGE ======');
    print('🗑️ [CLEAR] Storage key: $_chatStorageKey');

    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = _chatStorageKey ?? '';

      if (chatKey.isEmpty) {
        print('❌ [CLEAR] No storage key available');
        return;
      }

      await prefs.remove(chatKey);
      print('✅ [CLEAR] Chat cleared from storage with key: $chatKey');

      // Verify clear
      final verifyData = prefs.getString(chatKey);
      print('✅ [CLEAR] Verification - Data exists: ${verifyData != null}');

      // Also clear messages in memory - ONLY if still mounted
      if (mounted) {
        setState(() {
          _messages.clear();
        });
        print('✅ [CLEAR] Cleared ${_messages.length} messages from memory');
      } else {
        print('⚠️ [CLEAR] Widget not mounted, skipping setState');
        _messages.clear(); // Clear without setState
      }
    } catch (e, stackTrace) {
      print('❌ [CLEAR] Error clearing chat: $e');
      print('❌ [CLEAR] Stack trace: $stackTrace');
    }

    print('🗑️ [CLEAR] ====== CLEAR COMPLETE ======');
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

    print('🔄 [DID CHANGE] didChangeDependencies called');
    print('🔄 [DID CHANGE] _isInitialized: $_isInitialized');

    // Only initialize once
    if (_isInitialized) {
      print('⏭️ [DID CHANGE] Already initialized, skipping...');
      return;
    }

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
        _chatStorageKey = 'chat_$frequencyId';
        print('🔑 [STORAGE KEY] Set to: $_chatStorageKey');

        // Initialize active users from arguments
        if (args['activeUsers'] != null) {
          _activeUsers = List<Map<String, dynamic>>.from(args['activeUsers']);
          print(
            '👥 [INIT] Loaded ${_activeUsers.length} active users from arguments',
          );
        } else {
          print('⚠️ [INIT] No active users in arguments');
        }

        // Ensure user ID is loaded before loading chat
        _ensureUserIdAndLoadChat();

        _setupFrequencyChat(frequencyId);
        _isInitialized = true;
        print('✅ [INIT] Frequency chat initialized');
      } else if (groupId != null) {
        print('💬 Setting up GROUP CHAT');
        _chatStorageKey = 'chat_group_$groupId';
        print('🔑 [STORAGE KEY] Set to: $_chatStorageKey');

        // Ensure user ID is loaded before loading chat
        _ensureUserIdAndLoadChat();

        _loadGroupData(groupId);
        _isInitialized = true;
        print('✅ [INIT] Group chat initialized');
      } else {
        print('⚠️ No valid chat target found!');
      }
    }
  }

  // Ensure user ID is loaded before loading chat from storage
  Future<void> _ensureUserIdAndLoadChat() async {
    print('🔄 [ENSURE] Ensuring user ID is loaded...');

    // If user ID is not loaded yet, wait for it
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print('⏳ [ENSURE] User ID not loaded yet, loading now...');
      await _loadCurrentUserId();
    }

    print('✅ [ENSURE] User ID confirmed: $_currentUserId');

    // Now load chat with correct user ID
    await _loadChatFromStorage();
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
      print('💬 [FREQUENCY] ====== RECEIVED CHAT MESSAGE ======');
      print('💬 [FREQUENCY] Full data: $data');

      if (mounted) {
        final messageType = data['messageType'] ?? 'text';
        final messageId = data['id'];
        final messageText = data['message'] ?? data['text'] ?? '';
        final senderId = data['sender']?['id'] ?? '';
        final senderName = data['sender']?['name'] ?? 'Unknown';

        print('💬 [FREQUENCY] Message ID: $messageId');
        print('💬 [FREQUENCY] Message Type: $messageType');
        print('💬 [FREQUENCY] Message Text: $messageText');
        print('💬 [FREQUENCY] Sender ID: $senderId');
        print('💬 [FREQUENCY] Sender Name: $senderName');

        // Get current user ID for comparison
        final currentUserId = _getCurrentUserId();
        print('💬 [FREQUENCY] Current User ID: $currentUserId');
        print('💬 [FREQUENCY] Comparing: $senderId == $currentUserId');

        // CRITICAL FIX: If sender is current user, skip this message
        // We already added it optimistically when user pressed send
        if (senderId == currentUserId) {
          print(
            '⚠️ [FREQUENCY] 🚫 SKIPPING - This is MY OWN message coming back from server',
          );
          print(
            '⚠️ [FREQUENCY] 🚫 Already displayed on RIGHT side (optimistic update)',
          );
          return;
        }

        print('✅ [FREQUENCY] ✅ This is from ANOTHER user');
        print('✅ [FREQUENCY] ✅ Adding to LEFT side');

        // This is a message from another user, add it to the left side
        setState(() {
          final newMessage = {
            'id': data['id'],
            'senderId': senderId,
            'sender': senderName,
            'senderName': senderName,
            'message': messageText,
            'text': messageText,
            'timestamp': data['timestamp'],
            'time': _formatTime(data['timestamp']),
            'type': messageType,
            'messageType': messageType,
            'isMe': false, // Messages from server are always from other users
          };

          // Add audio-specific fields
          if (messageType == 'audio') {
            print('🎤 [FREQUENCY] Audio message received');
            print('🎤 [FREQUENCY] Duration: ${data['duration']}');
            print('🎤 [FREQUENCY] Audio URL: ${data['audioUrl']}');

            newMessage['duration'] = data['duration'] ?? '0:00';
            newMessage['audioUrl'] = data['audioUrl'];
          }

          // Add image-specific fields
          if (messageType == 'image') {
            print('🖼️ [FREQUENCY] Image message received');
            print(
              '🖼️ [FREQUENCY] Image Data Length: ${data['imageData']?.length ?? 0}',
            );

            newMessage['imageData'] = data['imageData'];
          }

          _messages.add(newMessage);
          print('✅ [FREQUENCY] Added message from other user: $senderName');
        });

        // Save to local storage
        _saveChatToStorage();

        _scrollToBottom();
      }

      print('💬 [FREQUENCY] ====== MESSAGE PROCESSING COMPLETE ======');
    });

    wsClient.on('frequency_chat_history', (data) {
      print('📜 [HISTORY] ====== CHAT HISTORY RECEIVED ======');
      print('📜 [HISTORY] Messages count: ${data['messages']?.length ?? 0}');
      print('📜 [HISTORY] Current messages count: ${_messages.length}');

      if (mounted && data['messages'] != null) {
        final currentUserId = _getCurrentUserId();
        print('📜 [HISTORY] Current User ID: $currentUserId');

        // Convert server messages
        final serverMessages = (data['messages'] as List).map((msg) {
          final messageType = msg['messageType'] ?? msg['type'] ?? 'text';

          final newMsg = {
            'id': msg['id'],
            'senderId': msg['sender']['id'],
            'sender': msg['sender']['name'],
            'senderName': msg['sender']['name'],
            'message': msg['message'],
            'text': msg['message'],
            'timestamp': msg['timestamp'],
            'time': _formatTime(msg['timestamp']),
            'type': messageType,
            'messageType': messageType,
            'isMe': msg['sender']['id'] == currentUserId,
          };

          // Add image-specific data
          if (messageType == 'image' && msg['imageData'] != null) {
            newMsg['imageData'] = msg['imageData'];
            print(
              '🖼️ [HISTORY] Image message with data length: ${msg['imageData'].length}',
            );
          }

          // Add audio-specific data
          if (messageType == 'audio') {
            newMsg['duration'] = msg['duration'] ?? '0:00';
            newMsg['audioUrl'] = msg['audioUrl'];
            print('🎤 [HISTORY] Audio message: ${msg['duration']}');
          }

          print(
            '📨 [HISTORY] Processed message: ${newMsg['message']} from ${newMsg['senderName']} (type: $messageType)',
          );
          return newMsg;
        }).toList();

        print(
          '📜 [HISTORY] Processed ${serverMessages.length} server messages',
        );

        setState(() {
          // Merge with local storage messages (avoid duplicates)
          final existingIds = _messages.map((m) => m['id']).toSet();
          print('📜 [HISTORY] Existing IDs: $existingIds');

          final newMessages = serverMessages
              .where((m) => !existingIds.contains(m['id']))
              .toList();

          print('📜 [HISTORY] New messages to add: ${newMessages.length}');

          _messages.addAll(newMessages);

          // Sort by timestamp
          _messages.sort((a, b) {
            try {
              final timeA = DateTime.parse(a['timestamp'] ?? '');
              final timeB = DateTime.parse(b['timestamp'] ?? '');
              return timeA.compareTo(timeB);
            } catch (e) {
              return 0;
            }
          });

          print('📜 [HISTORY] Total messages after merge: ${_messages.length}');
        });

        // Save merged messages to storage
        _saveChatToStorage();

        Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
      }

      print('📜 [HISTORY] ====== HISTORY PROCESSING COMPLETE ======');
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
      if (mounted && data['user'] != null) {
        setState(() {
          final userId = data['user']['id'] ?? data['user']['_id'];
          final userExists = _activeUsers.any(
            (u) => (u['id'] ?? u['_id']) == userId,
          );
          if (!userExists) {
            _activeUsers.add(data['user']);
            print('✅ [FREQUENCY] Added user. Total: ${_activeUsers.length}');
          } else {
            print('ℹ️ [FREQUENCY] User already exists');
          }
        });
      }
    });

    wsClient.on('user_left_frequency', (data) {
      print('👤 [FREQUENCY] User left: ${data['userId']}');
      if (mounted && data['userId'] != null) {
        setState(() {
          final beforeCount = _activeUsers.length;
          _activeUsers.removeWhere(
            (u) => (u['id'] ?? u['_id']) == data['userId'],
          );
          final afterCount = _activeUsers.length;
          print(
            '✅ [FREQUENCY] Removed user. Count: $beforeCount → $afterCount',
          );
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

        // Update speaker state based on backend response
        if (data['isSpeakerOn'] != null) {
          setState(() {
            _isSpeakerOn = data['isSpeakerOn'];
          });
          print(
            '🔊 [VOL] Speaker state updated: ${_isSpeakerOn ? "ON" : "OFF"}',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: const Color(0xFF00ff88),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });

    // Listen for volume status from other users
    wsClient.on('user_volume_status', (data) {
      print(
        '🔊 [VOL] User ${data['userName']} volume: ${data['isSpeakerOn'] ? "SPEAKER" : "EARPIECE"}',
      );
      // You can show a toast or update UI if needed
    });

    // Signal status updates
    wsClient.on('signal_status', (data) {
      if (mounted) {
        print(
          '✅ [SIG] Signal: ${data['signalBars']}/5 bars (${data['signalQuality']})',
        );
        print('✅ [SIG] Active users: ${data['activeUsers']}');

        // Update signal state
        setState(() {
          _signalBars = data['signalBars'] ?? 3;
          _signalQuality = data['signalQuality'] ?? 'Good';
        });

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
    print('🚪 [DISPOSE] CommunicationScreen disposing...');

    // DON'T clear chat from local storage on dispose
    // Messages will be cleared only when explicitly leaving the channel

    // Remove service listener
    _commService.removeListener(_onServiceUpdate);

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();

    print('✅ [DISPOSE] CommunicationScreen disposed successfully');
  }

  // Show attachment options (Gallery, Camera, Poll)
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2a2a2a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose an option',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: const Color(0xFF00ff88),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),

                // Camera
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: const Color(0xFF4a90e2),
                  onTap: () {
                    Navigator.pop(context);
                    _openCamera();
                  },
                ),

                // Poll
                _buildAttachmentOption(
                  icon: Icons.poll,
                  label: 'Poll',
                  color: const Color(0xFFff9800),
                  onTap: () {
                    Navigator.pop(context);
                    _createPoll();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color, size: 35),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Pick image from gallery
  void _pickFromGallery() async {
    print('📷 Opening gallery...');

    // Request photos permission (Android 13+) or storage permission (older Android)
    PermissionStatus status;

    if (await Permission.photos.isGranted) {
      status = PermissionStatus.granted;
    } else {
      // Try photos permission first (Android 13+)
      status = await Permission.photos.request();

      // If photos not available, try storage (older Android)
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      print('❌ Gallery permission denied: $status');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery permission is required to select photos'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print('✅ Gallery permission granted');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ Image selected from gallery: ${image.path}');
        print('📏 File size: ${await image.length()} bytes');

        // Show preview and send confirmation
        _showImagePreview(image);
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open camera
  void _openCamera() async {
    print('📸 Opening camera...');

    // Request camera permission
    final status = await Permission.camera.request();

    if (status.isDenied) {
      print('❌ Camera permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to take photos'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        print('✅ Photo captured: ${photo.path}');
        print('📏 File size: ${await photo.length()} bytes');

        // Show preview and send confirmation
        _showImagePreview(photo);
      } else {
        print('❌ No photo captured');
      }
    } catch (e) {
      print('❌ Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show image preview before sending
  void _showImagePreview(XFile image) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2a2a2a),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview image
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.file(File(image.path), fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  // Send button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendImageMessage(image);
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ff88),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Send image message
  Future<void> _sendImageMessage(XFile image) async {
    print('📤 [SEND IMAGE] ===== SENDING IMAGE MESSAGE =====');

    try {
      // Read image file
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('📷 [SEND IMAGE] Image path: ${image.path}');
      print('📏 [SEND IMAGE] Image size: ${bytes.length} bytes');
      print('🔤 [SEND IMAGE] Base64 length: ${base64Image.length}');

      // Get frequency ID
      final frequencyId = groupData?['frequencyId'] as String?;

      if (frequencyId == null) {
        print('❌ [SEND IMAGE] No frequency ID found');
        return;
      }

      print('📡 [SEND IMAGE] Frequency ID: $frequencyId');

      // Create optimistic message for immediate UI update
      final currentUserId = _getCurrentUserId();
      final timestamp = DateTime.now().toIso8601String();
      final messageId =
          'msg_${DateTime.now().millisecondsSinceEpoch}_${(base64Image.hashCode).toRadixString(36)}';

      final optimisticMessage = {
        'id': messageId,
        'senderId': currentUserId,
        'sender': 'You',
        'senderName': 'You',
        'message': 'Image',
        'messageType': 'image',
        'imageData': base64Image, // Store base64 for display
        'timestamp': timestamp,
        'time': _formatTime(timestamp),
        'isMe': true,
      };

      // Add to UI immediately (optimistic update)
      if (mounted) {
        setState(() {
          _messages.add(optimisticMessage);
        });
        print('✅ [SEND IMAGE] Added image to local messages');
        _saveChatToStorage();
        _scrollToBottom();
      }

      // Send via WebSocket
      final wsClient = getIt<WebSocketClient>();
      wsClient.sendFrequencyChat(
        frequencyId,
        'Image',
        messageType: 'image',
        imageData: base64Image, // Send base64 image data
      );

      print('📡 [SEND IMAGE] WebSocket message sent with image data');
      print('✅ [SEND IMAGE] ===== IMAGE MESSAGE SENT =====');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sent successfully!'),
            backgroundColor: Color(0xFF00ff88),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ [SEND IMAGE] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create poll
  void _createPoll() async {
    Navigator.pop(context); // Close the bottom sheet
    print('📊 Creating poll...');

    // TODO: Implement poll creation dialog with:
    // - Question field
    // - Multiple option fields (min 2, max 5)
    // - Duration picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Poll feature coming soon!'),
        backgroundColor: Color(0xFFff9800),
      ),
    );
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
      print('📡 ====== SENDING FREQUENCY CHAT MESSAGE ======');
      print('📡 Message: $message');

      // Add optimistic message for immediate UI feedback
      final currentUserId = _getCurrentUserId();
      final timestamp = DateTime.now().toIso8601String();
      final messageId =
          'msg_${DateTime.now().millisecondsSinceEpoch}_${message.hashCode.toRadixString(36)}';

      print('📡 Generated Message ID: $messageId');
      print('📡 Current User ID: $currentUserId');
      print('📡 Timestamp: $timestamp');

      final optimisticMessage = {
        'id': messageId,
        'senderId': currentUserId,
        'sender': 'You',
        'senderName': 'You',
        'message': message,
        'text': message,
        'messageType': 'text',
        'timestamp': timestamp,
        'time': _formatTime(timestamp),
        'isMe': true,
      };

      if (mounted) {
        setState(() {
          _messages.add(optimisticMessage);
        });
        print(
          '✅ [SEND MSG] ✅ Added OPTIMISTIC message to RIGHT side (isMe: true)',
        );
        print('✅ [SEND MSG] Total messages now: ${_messages.length}');
        _saveChatToStorage();
      }

      // Send via WebSocket
      final wsClient = getIt<WebSocketClient>();
      wsClient.sendFrequencyChat(frequencyId, message);
      print('✅ [SEND MSG] Message sent to backend via WebSocket');
      print('📡 ====== SEND MESSAGE COMPLETE ======');
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
    return WillPopScope(
      onWillPop: () async {
        // Don't clear chat when going back - messages will persist
        print('🔙 [BACK] Back button pressed - Chat messages will be saved');
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1a1a),
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              // Don't clear chat when going back - messages will persist
              print(
                '🔙 [BACK] Back arrow pressed - Chat messages will be saved',
              );
              Navigator.pop(context);
            },
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_activeUsers.length} Active Unit${_activeUsers.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF00ff88),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.circle, size: 3, color: Colors.white54),
                  const SizedBox(width: 6),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Leave Channel Button
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: IconButton(
                onPressed: () async {
                  // Show confirmation dialog before leaving channel
                  final shouldLeave = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2a2a2a),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: Color(0xFFff4444),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Leave Channel',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Are you sure you want to leave this channel?',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '⚠️ All chat messages will be cleared',
                            style: TextStyle(
                              color: Color(0xFFffaa00),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFff4444),
                          ),
                          child: const Text(
                            'LEAVE CHANNEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLeave == true) {
                    print(
                      '🔙 [LEAVE] User confirmed leaving channel - Clearing chat',
                    );
                    await _clearChatFromStorage();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFff4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFff4444),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Color(0xFFff4444),
                    size: 16,
                  ),
                ),
              ),
            ),
            // User Icon
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _showMembersSheet,
                icon: const Icon(Icons.person, color: Colors.white, size: 24),
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
                        icon: Icons.speaker_phone,
                        label: 'SPK',
                        isActive: _isSpeakerOn,
                        onPressed: () {
                          setState(() {
                            _isSpeakerOn = true;
                          });

                          // Send speaker status to backend
                          final frequencyId = groupData?['frequencyId'];
                          if (frequencyId != null) {
                            final wsClient = getIt<WebSocketClient>();
                            wsClient.toggleVolume(frequencyId, true);
                            print('🔊 [SPK] Speaker ON');
                          }
                        },
                      ),
                      _buildRadioControlButton(
                        icon: Icons.phone_in_talk,
                        label: 'EAR',
                        isActive: !_isSpeakerOn,
                        onPressed: () {
                          setState(() {
                            _isSpeakerOn = false;
                          });

                          // Send earpiece status to backend
                          final frequencyId = groupData?['frequencyId'];
                          if (frequencyId != null) {
                            final wsClient = getIt<WebSocketClient>();
                            wsClient.toggleVolume(frequencyId, false);
                            print('📱 [EAR] Earpiece ON');
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
                  // Input Row
                  Row(
                    children: [
                      // Attachment Button (Gallery, Camera, Poll)
                      GestureDetector(
                        onTap: _showAttachmentOptions,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF333333), Color(0xFF222222)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFF00ff88),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF00ff88,
                                ).withOpacity(0.15),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF00ff88),
                            size: 28,
                          ),
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
                                color: const Color(
                                  0xFF00ff88,
                                ).withOpacity(0.25),
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
              child:
                  message['type'] == 'audio' ||
                      message['messageType'] == 'audio'
                  ? _buildAudioMessage(message, isMe)
                  : message['messageType'] == 'image'
                  ? _buildImageMessage(message, isMe)
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

  Widget _buildImageMessage(Map<String, dynamic> message, bool isMe) {
    final imageData = message['imageData'] as String?;

    print('🖼️ [IMAGE WIDGET] Building image message');
    print('🖼️ [IMAGE WIDGET] Message: $message');
    print('🖼️ [IMAGE WIDGET] Image data exists: ${imageData != null}');
    print('🖼️ [IMAGE WIDGET] Image data length: ${imageData?.length ?? 0}');

    if (imageData == null || imageData.isEmpty) {
      print('❌ [IMAGE WIDGET] No image data - showing loading text');
      return const Text(
        'Image (loading...)',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    try {
      // Decode base64 image
      final bytes = base64Decode(imageData);
      print('✅ [IMAGE WIDGET] Successfully decoded ${bytes.length} bytes');

      return GestureDetector(
        onTap: () {
          // Show full screen image
          _showFullScreenImage(bytes);
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('❌ [IMAGE] Error displaying image: $error');
                return Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: isMe ? Colors.black54 : Colors.white54,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image unavailable',
                        style: TextStyle(
                          color: isMe ? Colors.black54 : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ [IMAGE] Error decoding base64: $e');
      return Text(
        'Image (error)',
        style: TextStyle(
          color: isMe ? Colors.black54 : Colors.white54,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
  }

  void _showFullScreenImage(Uint8List bytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMessage(Map<String, dynamic> message, bool isMe) {
    return GestureDetector(
      onTap: () {
        // Audio playback removed - feature disabled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio messages are currently disabled'),
            backgroundColor: Color(0xFF00ff88),
          ),
        );
      },
      child: Row(
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
      ),
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
                            // Human illustration
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2a2a),
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(
                                  color: const Color(0xFF555555),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Multiple user silhouettes
                                  Positioned(
                                    left: 20,
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  Positioned(
                                    right: 20,
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Active Users',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Waiting for users to join...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 14,
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
