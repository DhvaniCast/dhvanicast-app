import 'package:flutter/material.dart';
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

  bool _isMuted = false;
  bool _isConnected = true;
  double _volume = 0.8;
  String _frequency = "505.1";
  String _stationName = "Dhvani Cast Station";
  String? _frequencyId;

  FrequencyModel? _currentFrequency;
  List<Map<String, dynamic>> _connectedUsers = [];

  @override
  void initState() {
    super.initState();

    _dialerService = getIt<DialerService>();

    print('🚀 LiveRadioScreen: Initializing...');

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
    if (_frequencyId != null) {
      // Get frequency details from already loaded data
      _currentFrequency = _dialerService.frequencies.firstWhere(
        (f) => f.id == _frequencyId,
        orElse: () => FrequencyModel(
          id: _frequencyId!,
          frequency: double.tryParse(_frequency) ?? 505.1,
          band: 'UHF',
          isPublic: true,
          activeUsers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

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
    }
  }

  @override
  void dispose() {
    _dialerService.removeListener(_onServiceUpdate);
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
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
    // Navigate to communication screen with current frequency data
    Navigator.pushNamed(
      context,
      '/communication',
      arguments: {
        'name': _stationName,
        'frequency': _frequency,
        'color': const Color(0xFF00ff88),
        'status': 'active',
        'icon': Icons.radio,
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
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Connected Users Grid
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
