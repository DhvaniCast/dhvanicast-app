import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;
  final Function(bool accepted) onCallResponse;

  const IncomingCallScreen({
    Key? key,
    required this.callData,
    required this.onCallResponse,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _callTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _playRingtone();
    _startCallTimer();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });

      // Auto-reject after 30 seconds
      if (_secondsElapsed >= 30) {
        _rejectCall();
      }
    });
  }

  Future<void> _playRingtone() async {
    try {
      // Try to play ringtone from assets
      // If file doesn't exist, it will fail silently
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.7);

      // You can add a ringtone.mp3 file to assets/sounds/ folder
      // For now, it will catch the error if file doesn't exist
      try {
        await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
        print('🔔 [CALL] Playing ringtone');
      } catch (e) {
        print('⚠️ [CALL] Ringtone file not found, using silent mode');
        // Continue without sound - visual notification is still shown
      }
    } catch (e) {
      print('⚠️ [CALL] Audio player error: $e');
    }
  }

  void _stopRingtone() {
    _audioPlayer.stop();
    _callTimer?.cancel();
  }

  void _acceptCall() {
    _stopRingtone();
    widget.onCallResponse(true);
  }

  void _rejectCall() {
    _stopRingtone();
    widget.onCallResponse(false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.callData['callerName'] ?? 'Unknown';
    final callerAvatar = widget.callData['callerAvatar'] ?? '👤';

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
                    const Color(0xFF00ff88).withOpacity(0.1),
                    const Color(0xFF1a1a1a),
                  ],
                ),
              ),
            ),

            // Content
            Column(
              children: [
                const SizedBox(height: 60),

                // Call type label
                const Text(
                  'Incoming Voice Call',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 40),

                // Caller avatar with pulse animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00ff88),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00ff88).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          callerAvatar,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Caller name
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Calling status with animated dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Calling',
                      style: TextStyle(
                        color: const Color(0xFF00ff88),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildAnimatedDots(),
                  ],
                ),

                const Spacer(),

                // Buttons section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Quick action buttons (optional)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.message,
                            label: 'Message',
                            onTap: () {
                              // TODO: Open chat
                              _rejectCall();
                            },
                          ),
                          _buildQuickActionButton(
                            icon: Icons.alarm,
                            label: 'Remind Me',
                            onTap: () {
                              // TODO: Set reminder
                              _rejectCall();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      // Main action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline button
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _rejectCall,
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
                                'Decline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          // Accept button
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _acceptCall,
                                child: Container(
                                  width: 75,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00ff88),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00ff88,
                                        ).withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call,
                                    color: Colors.black,
                                    size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Accept',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildAnimatedDots() {
    return Row(
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 200)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: const Color(0xFF00ff88),
                    fontSize: 18,
                  ),
                ),
              ),
            );
          },
          onEnd: () {
            if (mounted) {
              setState(() {});
            }
          },
        );
      }),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2a2a2a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white70, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
