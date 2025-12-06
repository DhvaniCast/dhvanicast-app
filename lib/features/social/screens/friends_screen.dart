import 'package:flutter/material.dart';
import '../../../injection.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/services/livekit_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../core/auth_storage_service.dart';
import '../../../core/websocket_client.dart';
import 'incoming_call_screen.dart';
import 'active_call_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = getIt<SocialService>();
  final LiveKitService _livekitService = getIt<LiveKitService>();
  final WebSocketClient _socketClient = WebSocketClient();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendsData();
    _setupCallListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _removeCallListeners();
    super.dispose();
  }

  void _setupCallListeners() {
    print('🔔 [FRIENDS] Setting up call listeners');

    // NOTE: incoming_call is handled by GlobalCallListener globally
    // No need to register it here to avoid conflicts

    // Listen for call accepted
    _socketClient.socket?.on('call_accepted', (data) {
      print('✅ [FRIENDS] Call accepted: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['acceptedByName']} answered the call'),
          backgroundColor: const Color(0xFF00ff88),
        ),
      );
    });

    // Listen for call rejected
    _socketClient.socket?.on('call_rejected', (data) {
      print('❌ [FRIENDS] Call rejected: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['rejectedByName']} declined the call'),
          backgroundColor: Colors.orange,
        ),
      );
      _livekitService.disconnect();
    });

    // Listen for call ended
    _socketClient.socket?.on('call_ended', (data) {
      print('📴 [FRIENDS] Call ended: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['endedByName']} ended the call'),
          backgroundColor: Colors.grey,
        ),
      );
      _livekitService.disconnect();
      // Stop ringtone when call ends
      final notificationService = NotificationService();
      notificationService.stopRingtone();
    });
  }

  void _removeCallListeners() {
    // incoming_call is NOT removed here as it's handled by GlobalCallListener
    _socketClient.socket?.off('call_accepted');
    _socketClient.socket?.off('call_rejected');
    _socketClient.socket?.off('call_ended');
  }

  void _showIncomingCallDialog(Map<String, dynamic> callData) {
    final callerName = callData['callerName'] ?? 'Unknown';
    final callerAvatar = callData['callerAvatar'] ?? '👤';
    final callerId = callData['callerId'];
    final callId = callData['callId'];
    final callerEmail = callData['callerEmail'];

    // Navigate to full-screen incoming call UI
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
    print('✅ [FRIENDS] Accepting call: $callId');

    // Send accept event to backend
    _socketClient.socket?.emit('accept_call', {
      'callId': callId,
      'callerId': callerId,
    });

    // Join the call via LiveKit
    try {
      final authToken = await AuthStorageService.getToken();
      if (authToken == null) {
        throw Exception('Not authenticated');
      }

      await _livekitService.connectToFriendCall(callerEmail, authToken);

      // Navigate to active call screen (receiver side - call starts now)
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
      print('❌ [FRIENDS] Failed to join call: $e');
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
    print('❌ [FRIENDS] Rejecting call: $callId');

    // Send reject event to backend
    _socketClient.socket?.emit('reject_call', {
      'callId': callId,
      'callerId': callerId,
    });
  }

  Future<void> _loadFriendsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📥 [FRIENDS] Loading friends list...');
      final friendsData = await _socialService.getFriendsList();

      print('📥 [FRIENDS] Loading friend requests...');
      final requestsData = await _socialService.getReceivedRequests();

      setState(() {
        _friends = friendsData;
        _friendRequests = requestsData;
        _isLoading = false;
      });

      print('✅ [FRIENDS] Loaded ${_friends.length} friends');
      print('✅ [FRIENDS] Loaded ${_friendRequests.length} requests');
    } catch (e) {
      print('❌ [FRIENDS] Error loading data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    try {
      print('✅ [FRIENDS] Accepting request: $requestId');
      await _socialService.acceptFriendRequest(requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Friend request accepted!'),
          backgroundColor: Color(0xFF00ff88),
        ),
      );

      _loadFriendsData();
    } catch (e) {
      print('❌ [FRIENDS] Error accepting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    try {
      print('❌ [FRIENDS] Rejecting request: $requestId');
      await _socialService.rejectFriendRequest(requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadFriendsData();
    } catch (e) {
      print('❌ [FRIENDS] Error rejecting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFriendChat(Map<String, dynamic> friend) {
    print('💬 [FRIENDS] Opening chat with: ${friend['name']}');

    Navigator.pushNamed(
      context,
      '/friend-chat',
      arguments: {
        'friendId': friend['_id'] ?? friend['id'],
        'friendName': friend['name'] ?? 'Friend',
        'friendAvatar': friend['avatar'] ?? '👤',
        'friendEmail': friend['email'],
        'isOnline': friend['isOnline'] ?? false,
      },
    );
  }

  void _callFriend(Map<String, dynamic> friend) async {
    final friendName = friend['name'] ?? 'Friend';
    final friendEmail = friend['email'];
    final friendAvatar = friend['avatar'] ?? '👤';
    final friendId = friend['_id'] ?? friend['id'];
    final isOnline = friend['isOnline'] ?? false;

    if (friendEmail == null || friendEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Friend email not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('📞 [FRIENDS] Calling: $friendName (Email: $friendEmail)');

    // Generate unique room name
    final roomName = 'friend_call_${DateTime.now().millisecondsSinceEpoch}';

    // Send call initiation to backend
    _socketClient.socket?.emit('initiate_call', {
      'friendId': friendId,
      'callType': 'voice',
      'roomName': roomName,
    });

    // Start the call and navigate to active call screen
    try {
      final authToken = await AuthStorageService.getToken();
      if (authToken == null) {
        throw Exception('Not authenticated');
      }

      await _livekitService.connectToFriendCall(friendEmail, authToken);

      // Navigate to active call screen (caller side - no start time yet)
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => ActiveCallScreen(
              callData: {
                'friendName': friendName,
                'friendAvatar': friendAvatar,
                'friendId': friendId,
                'callId': roomName,
                'isCaller': true,
              },
              onEndCall: () async {
                await _endCall(friendId, roomName);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              callStartTime: null, // Timer won't start until call is answered
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ [FRIENDS] Failed to initiate call: $e');
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
      print('📞 [FRIENDS] Ending call');

      // Send end call event to backend
      _socketClient.socket?.emit('end_call', {
        'callId': callId,
        'friendId': friendId,
      });

      await _livekitService.disconnect();
      print('✅ [FRIENDS] Call ended');
    } catch (e) {
      print('❌ [FRIENDS] Error ending call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2a2a2a),
        elevation: 0,
        title: const Text(
          'Friends',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00ff88),
          labelColor: const Color(0xFF00ff88),
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 20),
                  const SizedBox(width: 8),
                  Text('Friends (${_friends.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, size: 20),
                  const SizedBox(width: 8),
                  Text('Requests (${_friendRequests.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00ff88)),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadFriendsData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ff88),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Friends List Tab
                _buildFriendsList(),
                // Friend Requests Tab
                _buildRequestsList(),
              ],
            ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No friends yet',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add friends to start chatting!',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00ff88),
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final friendName = friend['name'] ?? 'Unknown';
    final friendAvatar = friend['avatar'] ?? '👤';
    final isOnline = friend['isOnline'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF00ff88).withOpacity(0.3)
              : Colors.white10,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ff88).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOnline
                          ? const Color(0xFF00ff88)
                          : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      friendAvatar,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
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
            const SizedBox(width: 16),
            // Friend Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friendName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline ? '🟢 Online' : '⚪ Offline',
                    style: TextStyle(
                      color: isOnline
                          ? const Color(0xFF00ff88)
                          : Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat Button
                Material(
                  color: const Color(0xFF9c27b0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openFriendChat(friend),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.chat_bubble,
                        color: Color(0xFF9c27b0),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Call Button
                Material(
                  color: const Color(0xFF00ff88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _callFriend(friend),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.call,
                        color: Color(0xFF00ff88),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No pending requests',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00ff88),
      onRefresh: _loadFriendsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final sender = request['sender'] ?? {};
    final requestId = request['_id'] ?? '';
    final senderName = sender['name'] ?? 'Unknown';
    final senderAvatar = sender['avatar'] ?? '👤';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00ff88).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ff88).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      senderAvatar,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'wants to be your friend',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectFriendRequest(requestId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptFriendRequest(requestId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ff88),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
