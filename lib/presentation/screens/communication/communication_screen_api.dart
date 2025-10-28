import 'package:flutter/material.dart';
import '../../../injection.dart';
import '../../services/communication_service.dart';

/// This is the API-integrated version of CommunicationScreen
/// Replace the old communication_screen.dart with this file
///
/// Steps:
/// 1. Delete old communication_screen.dart
/// 2. Rename this file to communication_screen.dart
/// 3. Test the API integration

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
  String? _groupId;

  @override
  void initState() {
    super.initState();

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

    _commService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    print('📡 CommunicationScreen: Service updated');
    print('💬 Messages count: ${_commService.messages.length}');

    if (_commService.error != null) {
      print('❌ Error: ${_commService.error}');
    }

    setState(() {});
    _scrollToBottom();
  }

  Future<void> _loadGroupData(String groupId) async {
    print('📥 CommunicationScreen: Loading group data for $groupId');

    await _commService.loadGroupDetails(groupId);
    print('✅ Group loaded: ${_commService.currentGroup?.name}');

    // Load messages - fixed parameters
    await _commService.loadMessages(
      recipientType: 'group',
      recipientId: groupId,
    );
    print('✅ Messages loaded: ${_commService.messages.length}');

    _commService.setupSocketListeners();
    print('✅ WebSocket listeners setup complete');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      groupData = args;
      _groupId = args['id'] ?? args['groupId'];

      print('📦 Received group data: ${groupData}');
      print('🆔 Group ID: $_groupId');

      if (_groupId != null) {
        _loadGroupData(_groupId!);
      }
    }
  }

  @override
  void dispose() {
    _commService.removeListener(_onServiceUpdate);
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

    print('🎤 Recording started');
  }

  void _stopRecording() async {
    setState(() {
      _isRecording = false;
    });
    _audioWaveController.stop();
    _pulseController.stop();

    print('🎤 Recording stopped - Sending audio message via API...');

    if (_groupId != null) {
      // Send audio message via API
      final success = await _commService.sendAudioMessage(
        recipientType: 'group',
        recipientId: _groupId!,
        audioData: {'data': 'mock_audio_data'}, // TODO: Replace with actual audio data
      );

      if (success) {
        print('✅ Audio message sent successfully');
      } else {
        print('❌ Failed to send audio message');
      }
    }

    _scrollToBottom();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && _groupId != null) {
      print('📤 Sending message via API: ${_messageController.text.trim()}');

      final success = await _commService.sendTextMessage(
        recipientType: 'group',
        recipientId: _groupId!,
        text: _messageController.text.trim(),
      );

      if (success) {
        print('✅ Message sent successfully');
        _messageController.clear();
        _scrollToBottom();
      } else {
        print('❌ Failed to send message: ${_commService.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${_commService.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final activeUsers =
        _commService.currentGroup?.members.where((m) => m.isOnline).length ?? 0;

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
              _commService.currentGroup?.name ??
                  groupData?['name'] ??
                  'Radio Channel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '$activeUsers Active Units • Signal Strong',
              style: const TextStyle(
                color: Color(0xFF00ff88),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () {
                print('🚨 Emergency button pressed');
              },
              icon: const Icon(
                Icons.emergency,
                color: Color(0xFFff4444),
                size: 20,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showMembersSheet(),
              icon: const Icon(Icons.settings, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: _commService.isLoading && _commService.messages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00ff88)),
            )
          : Column(
              children: [
                // Radio Status Panel
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2a2a2a), Color(0xFF1f1f1f)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ff88).withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRadioControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            label: _isMuted ? 'Muted' : 'Mic',
                            isActive: !_isMuted,
                            onPressed: () {
                              setState(() {
                                _isMuted = !_isMuted;
                              });
                              print('🎤 Mic ${_isMuted ? "muted" : "unmuted"}');
                            },
                          ),
                          _buildRadioControlButton(
                            icon: _isSpeakerOn
                                ? Icons.volume_up
                                : Icons.volume_off,
                            label: 'Speaker',
                            isActive: _isSpeakerOn,
                            onPressed: () {
                              setState(() {
                                _isSpeakerOn = !_isSpeakerOn;
                              });
                              print(
                                '🔊 Speaker ${_isSpeakerOn ? "on" : "off"}',
                              );
                            },
                          ),
                          _buildRadioControlButton(
                            icon: Icons.people,
                            label: 'Members',
                            isActive: false,
                            onPressed: _showMembersSheet,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Messages Area - FROM API
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0f0f0f),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _commService.messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet\nSend first message to start',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _commService.messages.length,
                            itemBuilder: (context, index) {
                              final message = _commService.messages[index];
                              return _buildRadioMessageBubble(message);
                            },
                          ),
                  ),
                ),

                // Radio Input Area
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2a2a2a), Color(0xFF1f1f1f)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ff88).withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Text Input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00ff88).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Type message...',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            IconButton(
                              onPressed: _sendMessage,
                              icon: const Icon(
                                Icons.send,
                                color: Color(0xFF00ff88),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // PTT Button
                      GestureDetector(
                        onTapDown: (_) => _startRecording(),
                        onTapUp: (_) => _stopRecording(),
                        onTapCancel: () => _stopRecording(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isRecording
                                  ? [
                                      const Color(0xFFff4444),
                                      const Color(0xFFcc0000),
                                    ]
                                  : [
                                      const Color(0xFF00ff88),
                                      const Color(0xFF00cc66),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRecording ? Icons.mic : Icons.mic_none,
                                color: Colors.black,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isRecording ? 'RECORDING...' : 'PUSH TO TALK',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }) {
    final Color buttonColor = isActive
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
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioMessageBubble(dynamic message) {
    // Handle both MessageModel and Map
    final isMe = message.senderId == 'current_user_id'; // TODO: Get from auth
    final messageText = message.content?.text ?? message.content ?? '';
    final time = message.createdAt?.toString().substring(11, 16) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF00ff88) : const Color(0xFF2a2a2a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMe ? Colors.transparent : const Color(0xFF555555),
                width: 0.5,
              ),
            ),
            child: Text(
              messageText,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              time,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersSheet() {
    final members = _commService.currentGroup?.members ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2a2a2a),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Group Members (${members.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No members found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ...members.map((member) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: member.isOnline
                              ? const Color(0xFF00ff88)
                              : const Color(0xFF666666),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            member.userId.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.userId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              member.role,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: member.isOnline
                              ? const Color(0xFF00ff88).withOpacity(0.2)
                              : const Color(0xFF666666).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          member.isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: member.isOnline
                                ? const Color(0xFF00ff88)
                                : const Color(0xFF666666),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
