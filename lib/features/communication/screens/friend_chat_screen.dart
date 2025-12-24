import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../injection.dart';
import '../../../core/websocket_client.dart';
import '../../../core/auth_storage_service.dart';
import '../../../shared/services/livekit_service.dart';
import '../../social/screens/active_call_screen.dart';

class FriendChatScreen extends StatefulWidget {
  final Map<String, dynamic>? friendData;

  const FriendChatScreen({Key? key, this.friendData}) : super(key: key);

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  late WebSocketClient _wsClient;
  late LiveKitService _livekitService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _friendId = '';
  String _friendName = 'Friend';
  String _friendAvatar = '👤';
  String? _friendEmail;
  bool _isOnline = false;
  String? _currentUserId;

  List<Map<String, dynamic>> _messages = [];
  bool _isSendingMessage = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    _wsClient = getIt<WebSocketClient>();
    _livekitService = getIt<LiveKitService>();

    print('🔍 [DEBUG] friendData received: ${widget.friendData}');

    if (widget.friendData != null) {
      _friendId = widget.friendData!['friendId'] ?? '';
      _friendName = widget.friendData!['friendName'] ?? 'Friend';
      _friendAvatar = widget.friendData!['friendAvatar'] ?? '👤';
      _friendEmail = widget.friendData!['friendEmail'];
      _isOnline = widget.friendData!['isOnline'] ?? false;

      print('🔍 [DEBUG] Parsed friendId: "$_friendId"');
      print('🔍 [DEBUG] Parsed friendName: "$_friendName"');
      print('🔍 [DEBUG] Parsed friendEmail: "$_friendEmail"');
    } else {
      print('❌ [ERROR] friendData is null!');
    }

    _loadCurrentUserId();
    _loadChatHistory();
    _setupWebSocketListeners();
    _setupCallEndListener();

    print('💬 [FRIEND CHAT] Opened chat with: $_friendName (ID: $_friendId)');
  }

  void _setupCallEndListener() {
    print('🎧 [FRIEND_CHAT] Setting up call_ended listener');

    _wsClient.socket?.on('call_ended', (data) {
      print('📴 [FRIEND_CHAT] Call ended by other user: $data');

      if (mounted) {
        // Disconnect LiveKit if connected
        _livekitService.disconnect();

        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call ended by friend'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsClient.socket?.off('call_ended');
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user');

      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _currentUserId = userData['id'] ?? userData['_id'];
        });
        print('👤 [FRIEND CHAT] Current User ID: $_currentUserId');
      }
    } catch (e) {
      print('❌ [FRIEND CHAT] Error loading user ID: $e');
    }
  }

  void _setupWebSocketListeners() {
    // Listen for direct messages
    _wsClient.on('direct_message', (data) {
      print('💬 [FRIEND CHAT] Received message: $data');

      if (mounted) {
        final senderId =
            data['senderId'] ?? data['sender']?['id'] ?? data['sender']?['_id'];
        final senderInfo = data['senderInfo'] ?? data['sender'] ?? {};

        // Check if message is from this friend
        if (senderId == _friendId) {
          // Parse content - handle both string and object
          String messageText = '';
          if (data['content'] is String) {
            messageText = data['content'];
          } else if (data['content'] is Map) {
            messageText = data['content']['text'] ?? data['content'].toString();
          } else {
            messageText = data['message'] ?? '';
          }

          final newMessage = {
            'id':
                data['messageId'] ??
                data['_id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'senderId': senderId,
            'senderName': senderInfo['name'] ?? _friendName,
            'senderAvatar': senderInfo['avatar'] ?? '👤',
            'message': messageText,
            'timestamp':
                data['timestamp'] ??
                data['createdAt'] ??
                DateTime.now().toIso8601String(),
            'isMe': false,
            'messageType': data['messageType'] ?? 'text',
          };

          setState(() {
            _messages.add(newMessage);
          });

          _scrollToBottom();
          _saveChatToStorage();

          // Mark message as read
          _wsClient.socket?.emit('mark_friend_messages_read', {
            'friendId': _friendId,
          });
        }
      }
    });

    // Listen for message sent confirmation
    _wsClient.on('message_sent', (data) {
      print('✅ [FRIEND CHAT] Message sent confirmation: $data');
    });

    // Listen for message delivered confirmation
    _wsClient.on('message_delivered', (data) {
      print('✅ [FRIEND CHAT] Message delivered: $data');
    });

    // Listen for message history
    _wsClient.on('friend_messages', (data) {
      print(
        '📥 [FRIEND CHAT] Received messages: ${data['count'] ?? data['messages']?.length ?? 0} messages',
      );
      final friendId = data['friendId'];
      if (mounted && friendId == _friendId) {
        final List<dynamic> messages = data['messages'] ?? [];
        setState(() {
          _messages = messages.map((msg) {
            // Parse content properly
            String messageText = '';
            if (msg['content'] is String) {
              messageText = msg['content'];
            } else if (msg['content'] is Map) {
              messageText = msg['content']['text'] ?? '';
            }

            return {
              'id': msg['_id'] ?? msg['id'],
              'senderId': msg['sender']['_id'] ?? msg['sender']['id'],
              'senderName':
                  msg['senderInfo']?['name'] ??
                  msg['sender']?['name'] ??
                  'Unknown',
              'senderAvatar': msg['senderInfo']?['avatar'] ?? '👤',
              'message': messageText,
              'timestamp': msg['createdAt'] ?? msg['timestamp'],
              'isMe':
                  (msg['sender']['_id'] ?? msg['sender']['id']) ==
                  _currentUserId,
              'messageType': msg['messageType'] ?? 'text',
            };
          }).toList();
        });
        _saveChatToStorage();
        _scrollToBottom();
      }
    });

    // Listen for typing indicator
    _wsClient.on('typing_indicator', (data) {
      final senderId = data['userId'] ?? data['senderId'];
      if (mounted && senderId == _friendId) {
        setState(() {
          _isTyping = data['isTyping'] == true;
        });
      }
    });

    // Also listen to user_typing for backward compatibility
    _wsClient.on('user_typing', (data) {
      final senderId = data['userId'] ?? data['senderId'];
      if (mounted && senderId == _friendId) {
        setState(() {
          _isTyping = data['isTyping'] == true;
        });
      }
    });

    // Listen for online status
    _wsClient.on('user_status_changed', (data) {
      if (mounted && data['userId'] == _friendId) {
        setState(() {
          _isOnline = data['isOnline'] == true;
        });
      }
    });
  }

  Future<void> _loadChatHistory() async {
    print('📥 [FRIEND CHAT] Loading chat history...');

    try {
      // Load from local storage first
      final prefs = await SharedPreferences.getInstance();
      final chatKey = 'friend_chat_$_friendId';
      final chatData = prefs.getString(chatKey);

      if (chatData != null) {
        final List<dynamic> decodedList = jsonDecode(chatData);
        setState(() {
          _messages = decodedList.map((item) {
            final msg = Map<String, dynamic>.from(item as Map);
            msg['isMe'] = msg['senderId'] == _currentUserId;
            return msg;
          }).toList();
        });
        print(
          '✅ [FRIEND CHAT] Loaded ${_messages.length} messages from storage',
        );
      }

      // Request chat history from server
      _wsClient.socket?.emit('get_friend_messages', {
        'friendId': _friendId,
        'limit': 50,
      });

      Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      print('❌ [FRIEND CHAT] Error loading chat: $e');
    }
  }

  Future<void> _saveChatToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = 'friend_chat_$_friendId';
      final chatData = jsonEncode(_messages);
      await prefs.setString(chatKey, chatData);
    } catch (e) {
      print('❌ [FRIEND CHAT] Error saving chat: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();

    print('📤 [FRIEND CHAT] Sending message: "$message"');

    setState(() {
      _isSendingMessage = true;
    });

    // Add message to UI immediately (optimistic update)
    final tempMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'senderId': _currentUserId,
      'senderName': 'You',
      'senderAvatar': '👤',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'isMe': true,
      'messageType': 'text',
    };

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();
    _saveChatToStorage();

    // Send message via WebSocket
    print('📤 [DEBUG] friendId: "$_friendId"');
    print('📤 [DEBUG] content: "$message"');
    print('📤 [DEBUG] messageType: "text"');
    print('📤 [DEBUG] Socket connected: ${_wsClient.socket?.connected}');

    if (_friendId.isEmpty) {
      print('❌ [ERROR] Friend ID is empty!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Friend ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSendingMessage = false;
      });
      return;
    }

    _wsClient.socket?.emit('direct_message', {
      'friendId': _friendId,
      'content': message,
      'messageType': 'text',
    });

    // Clear input
    _messageController.clear();

    setState(() {
      _isSendingMessage = false;
    });

    // Stop typing indicator
    _wsClient.socket?.emit('user_typing', {
      'friendId': _friendId,
      'isTyping': false,
    });
  }

  void _onMessageTextChanged(String text) {
    // Send typing indicator
    if (text.isNotEmpty) {
      _wsClient.socket?.emit('user_typing', {
        'friendId': _friendId,
        'isTyping': true,
      });
    } else {
      _wsClient.socket?.emit('user_typing', {
        'friendId': _friendId,
        'isTyping': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2a2a2a),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ff88).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_friendAvatar, style: TextStyle(fontSize: 20)),
                  ),
                ),
                if (_isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00ff88),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2a2a2a),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _friendName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline
                          ? const Color(0xFF00ff88)
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     onPressed: _callFriend,
        //     icon: const Icon(Icons.call, color: Color(0xFF00ff88)),
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation with $_friendName!',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Typing Indicator
          if (_isTyping)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '$_friendName is typing',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00ff88),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2a2a2a),
              border: Border(top: BorderSide(color: Colors.white10, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onMessageTextChanged,
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
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSendingMessage ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00ff88), Color(0xFF00aaff)],
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isMe = message['isMe'] ?? false;
    final String senderName = message['senderName'] ?? 'Unknown';
    final String senderAvatar = message['senderAvatar'] ?? '👤';
    final String messageText = message['message'] ?? '';
    final String timestamp = message['timestamp'] ?? '';

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
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(0xFF00ff88).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(senderAvatar, style: TextStyle(fontSize: 18)),
              ),
            ),
            SizedBox(width: 8),
          ],
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
                            colors: [Color(0xFF9c27b0), Color(0xFFba68c8)],
                          )
                        : null,
                    color: isMe ? null : Color(0xFF3a3a3a),
                    border: isMe
                        ? null
                        : Border.all(
                            color: Color(0xFF00ff88).withOpacity(0.3),
                            width: 1,
                          ),
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

  void _callFriend() async {
    if (_friendEmail == null || _friendEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Friend email not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('📞 [FRIEND CHAT] Calling: $_friendName (Email: $_friendEmail)');

    // Generate unique room name
    final roomName = 'friend_call_${DateTime.now().millisecondsSinceEpoch}';

    // Send call initiation to backend
    _wsClient.socket?.emit('initiate_call', {
      'friendId': _friendId,
      'callType': 'voice',
      'roomName': roomName,
    });

    // Start the call and navigate to active call screen
    try {
      final authToken = await AuthStorageService.getToken();
      if (authToken == null) {
        throw Exception('Not authenticated');
      }

      await _livekitService.connectToFriendCall(_friendEmail!, authToken);

      // Navigate to active call screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => ActiveCallScreen(
              callData: {
                'friendName': _friendName,
                'friendAvatar': _friendAvatar,
                'friendId': _friendId,
                'callId': roomName,
              },
              onEndCall: () async {
                await _endCall(_friendId, roomName);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ [FRIEND CHAT] Failed to initiate call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endCall(String friendId, String callId) async {
    try {
      print('📞 [FRIEND CHAT] Ending call');

      // Send end call event to backend
      _wsClient.socket?.emit('end_call', {
        'callId': callId,
        'friendId': friendId,
      });

      await _livekitService.disconnect();
      print('✅ [FRIEND CHAT] Call ended');
    } catch (e) {
      print('❌ [FRIEND CHAT] Error ending call: $e');
    }
  }
}
