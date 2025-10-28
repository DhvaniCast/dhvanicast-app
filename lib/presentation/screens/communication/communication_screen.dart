import 'package:flutter/material.dart';
import '../../../injection.dart';
import '../../services/communication_service.dart';

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
  bool _isVideoOn = true;
  bool _isSpeakerOn = false;
  bool _isRecording = false;

  Map<String, dynamic>? groupData;
  String? _groupId;

  // Local state for messages and active users/members
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _activeUsers = [];
  List<Map<String, dynamic>> _activeMembers = [];

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

    setState(() {});
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
    if (args != null && args is Map<String, dynamic>) {
      groupData = args;
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
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'id': _messages.length + 1,
          'sender': 'Me',
          'message': _messageController.text.trim(),
          'time':
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'type': 'text',
          'isMe': true,
        });
      });

      _messageController.clear();
      _scrollToBottom();
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
              groupData?['name'] ?? 'Radio Channel 99.9 MHz',
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
                        const Text(
                          'CHANNEL 99.9 MHz',
                          style: TextStyle(
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Header with call sign and time
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor, width: 0.5),
                    ),
                    child: Text(
                      message['sender'] ?? 'Unknown',
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  message['time'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ff88).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00ff88),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'CTRL',
                      style: TextStyle(
                        color: Color(0xFF00ff88),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF00ff88).withOpacity(0.08)
                  : const Color(0xFF333333),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMe
                    ? const Color(0xFF00ff88).withOpacity(0.2)
                    : priorityColor.withOpacity(0.2),
              ),
            ),
            child: message['type'] == 'audio'
                ? _buildAudioMessage(message)
                : _buildTextMessage(message, isMe, priorityColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(
    Map<String, dynamic> message,
    bool isMe,
    Color priorityColor,
  ) {
    return Text(
      message['message'] ?? '',
      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
    );
  }

  Widget _buildAudioMessage(Map<String, dynamic> message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow, color: Color(0xFF00ff88), size: 18),
        const SizedBox(width: 6),
        const Text(
          'Audio Message',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          message['duration'] ?? '0:00',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
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
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF555555),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Group Members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ..._activeMembers
                .map((member) => _buildMemberTile(member))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF555555), width: 0.5),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00ff88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  member['avatar'],
                  color: const Color(0xFF00ff88),
                  size: 18,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: member['isOnline']
                        ? const Color(0xFF00ff88)
                        : const Color(0xFF666666),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFF2a2a2a),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  member['role'],
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(member['status']).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getStatusColor(member['status']),
                width: 0.5,
              ),
            ),
            child: Text(
              member['status'],
              style: TextStyle(
                color: _getStatusColor(member['status']),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'speaking':
        return const Color(0xFF00ff88);
      case 'listening':
        return const Color(0xFF00aaff);
      case 'muted':
        return const Color(0xFFff4444);
      default:
        return const Color(0xFF666666);
    }
  }
}
