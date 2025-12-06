import 'package:flutter/material.dart';
import 'dart:async';
import '../../../injection.dart';
import '../../../shared/services/livekit_service.dart';
import '../../../core/websocket_client.dart';

class ActiveCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;
  final Function() onEndCall;
  final DateTime? callStartTime; // When call was answered, not initiated

  const ActiveCallScreen({
    Key? key,
    required this.callData,
    required this.onEndCall,
    this.callStartTime,
  }) : super(key: key);

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen>
    with SingleTickerProviderStateMixin {
  final LiveKitService _livekitService = getIt<LiveKitService>();
  final WebSocketClient _wsClient = WebSocketClient();
  late AnimationController _waveController;
  Timer? _callDurationTimer;
  int _callDurationSeconds = 0;
  bool _isSpeakerOn = true;
  bool _isCallAnswered = false; // Track if call has been answered

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Calculate initial seconds if call was already started (receiver side)
    if (widget.callStartTime != null) {
      _callDurationSeconds = DateTime.now()
          .difference(widget.callStartTime!)
          .inSeconds;
      _isCallAnswered =
          true; // Call is already answered if start time is provided
    }

    _startCallDurationTimer();
    _setupCallEndListener();
    _setupCallAnsweredListener();
  }

  void _setupCallAnsweredListener() {
    // Listen for call_answered event (sent when receiver accepts the call)
    _wsClient.socket?.on('call_answered', (data) {
      print('✅ [ACTIVE_CALL] Call answered by friend: $data');

      if (mounted && !_isCallAnswered) {
        setState(() {
          _isCallAnswered = true;
          _callDurationSeconds = 0; // Reset timer
        });
      }
    });
  }

  void _setupCallEndListener() {
    print('🎧 [ACTIVE_CALL] Setting up call_ended listener');

    _wsClient.socket?.on('call_ended', (data) {
      print('📴 [ACTIVE_CALL] Call ended by other user: $data');

      if (mounted) {
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call ended by friend'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        // End the call automatically
        widget.onEndCall();
      }
    });
  }

  void _startCallDurationTimer() {
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Only increment if call has been answered
      if (_isCallAnswered) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatCallDuration() {
    // Show "Calling..." if call hasn't been answered yet
    if (!_isCallAnswered) {
      return 'Calling...';
    }

    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _waveController.dispose();
    _callDurationTimer?.cancel();
    _wsClient.socket?.off('call_ended');
    _wsClient.socket?.off('call_answered');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendName = widget.callData['friendName'] ?? 'Friend';
    final friendAvatar = widget.callData['friendAvatar'] ?? '👤';

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00ff88).withOpacity(0.15),
                    const Color(0xFF1a1a1a),
                  ],
                ),
              ),
            ),

            // Content - Make scrollable to prevent overflow
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),

                      // Call status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00ff88).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00ff88),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Voice Call Active',
                              style: TextStyle(
                                color: Color(0xFF00ff88),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.06,
                      ),

                      // Friend avatar with animated waves
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated wave rings
                          if (!_livekitService.isMuted)
                            ...List.generate(3, (index) {
                              return AnimatedBuilder(
                                animation: _waveController,
                                builder: (context, child) {
                                  final delay = index * 0.3;
                                  final scale =
                                      1.0 +
                                      (_waveController.value - delay).clamp(
                                            0.0,
                                            1.0,
                                          ) *
                                          0.5;
                                  final opacity =
                                      (1.0 - (_waveController.value - delay))
                                          .clamp(0.0, 1.0);

                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.35,
                                      height:
                                          MediaQuery.of(context).size.width *
                                          0.35,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(
                                            0xFF00ff88,
                                          ).withOpacity(opacity * 0.5),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),

                          // Avatar
                          Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00ff88),
                                width: 3,
                              ),
                              color: const Color(0xFF2a2a2a),
                            ),
                            child: Center(
                              child: Text(
                                friendAvatar,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03,
                      ),

                      // Friend name
                      Text(
                        friendName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Call duration
                      Text(
                        _formatCallDuration(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),

                      const Spacer(),

                      // Control buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            // Additional controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildControlButton(
                                  icon: _isSpeakerOn
                                      ? Icons.volume_up
                                      : Icons.volume_down,
                                  label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                                  isActive: _isSpeakerOn,
                                  onTap: () {
                                    setState(() {
                                      _isSpeakerOn = !_isSpeakerOn;
                                    });
                                    _livekitService.setSpeakerPhone(
                                      _isSpeakerOn,
                                    );
                                  },
                                ),
                                _buildControlButton(
                                  icon: _livekitService.isMuted
                                      ? Icons.mic_off
                                      : Icons.mic,
                                  label: _livekitService.isMuted
                                      ? 'Muted'
                                      : 'Mute',
                                  isActive: !_livekitService.isMuted,
                                  isDanger: _livekitService.isMuted,
                                  onTap: () async {
                                    await _livekitService.toggleMute();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),

                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.06,
                            ),

                            // End call button
                            GestureDetector(
                              onTap: widget.onEndCall,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.call_end,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'End Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.08,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isDanger
                  ? Colors.red.withOpacity(0.2)
                  : isActive
                  ? const Color(0xFF00ff88).withOpacity(0.2)
                  : const Color(0xFF2a2a2a),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDanger
                    ? Colors.red
                    : isActive
                    ? const Color(0xFF00ff88)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isDanger
                  ? Colors.red
                  : isActive
                  ? const Color(0xFF00ff88)
                  : Colors.white70,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDanger
                  ? Colors.red
                  : isActive
                  ? const Color(0xFF00ff88)
                  : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
