import 'package:flutter/material.dart';
import 'dart:async';
import '../../../injection.dart';
import '../../../shared/services/livekit_service.dart';
import '../../../core/websocket_client.dart';

class ActiveCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;
  final Function() onEndCall;

  const ActiveCallScreen({
    Key? key,
    required this.callData,
    required this.onEndCall,
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

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _startCallDurationTimer();
    _setupCallEndListener();
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
      setState(() {
        _callDurationSeconds++;
      });
    });
  }

  String _formatCallDuration() {
    final minutes = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _waveController.dispose();
    _callDurationTimer?.cancel();
    _wsClient.socket?.off('call_ended');
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

            // Content
            Column(
              children: [
                const SizedBox(height: 40),

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

                const SizedBox(height: 60),

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
                                (1.0 - (_waveController.value - delay)).clamp(
                                  0.0,
                                  1.0,
                                );

                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 140,
                                height: 140,
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
                      width: 120,
                      height: 120,
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
                          style: const TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Friend name
                Text(
                  friendName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Call duration
                Text(
                  _formatCallDuration(),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
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
                              _livekitService.setSpeakerPhone(_isSpeakerOn);
                            },
                          ),
                          _buildControlButton(
                            icon: _livekitService.isMuted
                                ? Icons.mic_off
                                : Icons.mic,
                            label: _livekitService.isMuted ? 'Muted' : 'Mute',
                            isActive: !_livekitService.isMuted,
                            isDanger: _livekitService.isMuted,
                            onTap: () async {
                              await _livekitService.toggleMute();
                              setState(() {});
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      // End call button
                      GestureDetector(
                        onTap: widget.onEndCall,
                        child: Container(
                          width: 75,
                          height: 75,
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
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'End Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
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
