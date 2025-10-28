import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../injection.dart';
import '../../../data/models/frequency_model.dart';
import '../../services/dialer_service.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({Key? key}) : super(key: key);

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dialController;
  late DialerService _dialerService;

  double _frequency = 450.0; // Changed to 320-650 range
  bool _isConnected = false;
  bool _isAutoTune = false;
  bool _isRecording = false;
  double _volume = 0.7;
  String _selectedBand = 'UHF'; // UHF for 320-650 MHz range

  @override
  void initState() {
    super.initState();

    // Get DialerService from DI
    _dialerService = getIt<DialerService>();

    print('🚀 DialerScreen: Initializing...');

    // Ensure frequency is within valid range
    if (_frequency < 320.0 || _frequency > 650.0) {
      _frequency = 450.0; // Reset to default UHF frequency
    }

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _dialController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (_isConnected) {
      _pulseController.repeat(reverse: true);
    }

    // Listen to service changes
    _dialerService.addListener(_onServiceUpdate);

    // Load initial data from API
    _loadInitialData();
  }

  void _onServiceUpdate() {
    print('📡 DialerScreen: Service updated');
    print('📊 Frequencies count: ${_dialerService.frequencies.length}');
    print('👥 Groups count: ${_dialerService.groups.length}');

    if (_dialerService.error != null) {
      print('❌ Error: ${_dialerService.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_dialerService.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _loadInitialData() async {
    print('📥 DialerScreen: Loading initial data from API...');

    // Load frequencies
    await _dialerService.loadFrequencies(band: _selectedBand, isPublic: true);
    print('✅ Frequencies loaded: ${_dialerService.frequencies.length}');

    // Load groups
    await _dialerService.loadUserGroups();
    print('✅ Groups loaded: ${_dialerService.groups.length}');

    // Setup WebSocket listeners
    _dialerService.setupSocketListeners();
    print('✅ WebSocket listeners setup complete');
  }

  @override
  void dispose() {
    _dialerService.removeListener(_onServiceUpdate);
    _pulseController.dispose();
    _dialController.dispose();
    super.dispose();
  }

  int _getUsersOnFrequency(double frequency) {
    // Get users from API data
    final freq = _dialerService.frequencies.firstWhere(
      (f) => (f.frequency - frequency).abs() <= 0.5,
      orElse: () => FrequencyModel(
        id: '',
        frequency: frequency,
        band: _selectedBand,
        isPublic: true,
        activeUsers: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    int userCount = freq.activeUsers.length;
    print('👥 Users on ${frequency.toStringAsFixed(1)} MHz: $userCount');
    return userCount;
  }

  // Dynamic button functions
  void _toggleAutoTune() {
    setState(() {
      _isAutoTune = !_isAutoTune;
    });
    if (_isAutoTune) {
      _autoTuneToStrongestSignal();
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording ? 'Recording Started' : 'Recording Stopped'),
        backgroundColor: _isRecording
            ? const Color(0xFF00ff88)
            : const Color(0xFFff4444),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _switchBand() {
    setState(() {
      _selectedBand = _selectedBand == 'UHF' ? 'VHF' : 'UHF';
      // Keep frequency within valid slider range (320-650 MHz)
      if (_selectedBand == 'VHF') {
        _frequency = 320.0; // Lowest UHF frequency for now
      } else {
        _frequency = 450.0; // UHF range
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Switched to $_selectedBand band - ${_frequency.toStringAsFixed(1)} MHz',
        ),
        backgroundColor: const Color(0xFF00ff88),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _autoTuneToStrongestSignal() {
    // Find frequency with most users from API data
    if (_dialerService.frequencies.isEmpty) {
      print('⚠️ No frequencies available for auto-tune');
      return;
    }

    final strongestFreq = _dialerService.frequencies.reduce(
      (a, b) => a.activeUsers.length > b.activeUsers.length ? a : b,
    );

    setState(() {
      _frequency = strongestFreq.frequency;
    });

    print(
      '🎯 Auto-tuned to ${strongestFreq.frequency.toStringAsFixed(1)} MHz with ${strongestFreq.activeUsers.length} users',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Auto-tuned to ${strongestFreq.frequency.toStringAsFixed(1)} MHz (${strongestFreq.activeUsers.length} users)',
        ),
        backgroundColor: const Color(0xFF00ff88),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _quickFrequencySet(double freq) {
    setState(() {
      // Ensure frequency is within valid UHF range
      if (freq >= 320.0 && freq <= 650.0) {
        _frequency = freq;
      } else {
        _frequency = 450.0; // Default UHF frequency
      }
    });
  }

  // Missing functions - Add back
  void _showActiveGroupsPopup() {
    print('👥 Showing ${_dialerService.groups.length} active groups from API');

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Color(0xFF00ff88)),
                  const SizedBox(width: 12),
                  Text(
                    'Active Groups (${_dialerService.groups.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Use API data instead of static data
            if (_dialerService.isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Color(0xFF00ff88)),
              )
            else if (_dialerService.groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No active groups found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ..._dialerService.groups.map((group) {
                // Convert GroupModel to Map for _buildGroupCard
                return _buildGroupCard({
                  'id': group.id,
                  'name': group.name,
                  'members': group.members.map((m) => m.userId).toList(),
                  'status': group.members.any((m) => m.isOnline)
                      ? 'active'
                      : 'idle',
                  'icon': Icons.group,
                  'color': Colors.blue,
                  'frequency': 450.0, // Default frequency
                });
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFrequencyUsersPopup() {
    final currentUsers = _getUsersOnFrequency(_frequency);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF00ff88)),
                  const SizedBox(width: 12),
                  Text(
                    'Users on ${_frequency.toStringAsFixed(1)} MHz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (currentUsers > 0) ...[
              ...List.generate(
                currentUsers,
                (index) => GestureDetector(
                  onTap: () {
                    // Close the popup first
                    Navigator.pop(context);
                    // Navigate to communication screen with user data
                    Navigator.pushNamed(
                      context,
                      '/communication',
                      arguments: {
                        'name': 'User ${index + 1}',
                        'frequency': _frequency,
                        'type': 'user',
                        'status': 'active',
                        'members': ['User ${index + 1}'],
                        'color': const Color(0xFF00ff88),
                        'icon': Icons.person,
                      },
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF00ff88),
                          radius: 16,
                          child: Text(
                            'U${index + 1}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Active on ${_frequency.toStringAsFixed(1)} MHz',
                                style: const TextStyle(
                                  color: Color(0xFF888888),
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
                            color: const Color(0xFF00ff88).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              color: Color(0xFF00ff88),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white54,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(40),
                child: const Text(
                  'No users active on this frequency',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog() async {
    print(
      '🔗 Attempting to join frequency: ${_frequency.toStringAsFixed(1)} MHz',
    );

    // Find the frequency in loaded data
    FrequencyModel? frequencyToJoin = _dialerService.frequencies
        .where((f) => (f.frequency - _frequency).abs() <= 0.5)
        .firstOrNull;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF2a2a2a),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00ff88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.radio,
                  color: Color(0xFF00ff88),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Joining Frequency ${_frequency.toStringAsFixed(1)} MHz',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                frequencyToJoin == null
                    ? 'Creating new frequency...'
                    : 'Connecting to channel...',
                style: const TextStyle(color: Color(0xFF888888)),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isConnected = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFff4444),
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      print('🎯 JOIN button pressed - Calling API...');

                      // If frequency doesn't exist, create it first
                      if (frequencyToJoin == null) {
                        print('📝 Creating new frequency...');
                        final newFrequency = await _dialerService.createFrequency(
                          frequency: _frequency,
                          name: '${_frequency.toStringAsFixed(1)} MHz',
                          band: _selectedBand,
                          description:
                              'Public ${_selectedBand} frequency at ${_frequency.toStringAsFixed(1)} MHz',
                          isPublic: true,
                        );

                        if (newFrequency == null) {
                          Navigator.pop(context);
                          print('❌ Failed to create frequency');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to create frequency: ${_dialerService.error}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        frequencyToJoin = newFrequency;
                        print('✅ Frequency created: ${newFrequency.id}');
                      }

                      // Now join the frequency
                      final success = await _dialerService.joinFrequency(
                        frequencyToJoin!.id,
                        userInfo: {
                          'frequency': _frequency,
                          'band': _selectedBand,
                        },
                      );

                      Navigator.pop(context);

                      if (success) {
                        print('✅ Successfully joined frequency via API');

                        setState(() {
                          _isConnected = true;
                        });

                        // Navigate to live radio screen
                        Navigator.pushNamed(
                          context,
                          '/live_radio',
                          arguments: {
                            'frequency': _frequency.toStringAsFixed(1),
                            'name': 'Dhvani Cast Live',
                            'frequencyId': frequencyToJoin!.id,
                          },
                        );
                      } else {
                        print('❌ Failed to join frequency via API');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to join: ${_dialerService.error}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ff88),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Join'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    return GestureDetector(
      onTap: () {
        // Navigate to communication screen with group data
        Navigator.pushNamed(context, '/communication', arguments: group);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (group['color'] as Color).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (group['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                group['icon'] as IconData,
                color: group['color'] as Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${group['frequency']} MHz • ${group['members'].length} members',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: group['status'] == 'active'
                    ? const Color(0xFF00ff88).withOpacity(0.2)
                    : const Color(0xFF666666).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group['status'].toString().toUpperCase(),
                style: TextStyle(
                  color: group['status'] == 'active'
                      ? const Color(0xFF00ff88)
                      : const Color(0xFF888888),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
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
              Row(
                children: [
                  const Icon(Icons.volume_up, color: Color(0xFF00ff88)),
                  const SizedBox(width: 12),
                  const Text(
                    'Volume Control',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                      activeColor: const Color(0xFF00ff88),
                      inactiveColor: const Color(0xFF444444),
                    ),
                  ),
                  Text(
                    '${(_volume * 100).round()}%',
                    style: const TextStyle(color: Color(0xFF00ff88)),
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
                      style: TextStyle(color: Color(0xFF00ff88)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: const Text(
          'Dhvani Cast',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top spacing
                const SizedBox(height: 16),

                // Frequency Display Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2a2a2a), Color(0xFF1a1a1a)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00ff88).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Digital frequency display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00ff88),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00ff88).withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _frequency.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00ff88),
                                fontFamily: 'monospace',
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'MHz',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF00ff88),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Audio Controls Row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00ff88).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleAutoTune,
                          icon: Icon(
                            _isAutoTune
                                ? Icons.auto_awesome
                                : Icons.auto_awesome_outlined,
                            size: 18,
                          ),
                          label: const Text('AUTO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAutoTune
                                ? const Color(0xFF00ff88)
                                : const Color(0xFF444444),
                            foregroundColor: _isAutoTune
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleRecording,
                          icon: Icon(
                            _isRecording
                                ? Icons.radio_button_on
                                : Icons.radio_button_off,
                            size: 18,
                          ),
                          label: const Text('REC'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording
                                ? const Color(0xFFff4444)
                                : const Color(0xFF444444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showVolumeControl,
                          icon: const Icon(Icons.volume_up, size: 18),
                          label: const Text('VOL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF444444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _switchBand,
                          icon: const Icon(Icons.radio, size: 18),
                          label: Text(_selectedBand),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF444444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Frequency Slider Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00ff88).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'FREQUENCY SELECTOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Custom Frequency Scale
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomPaint(
                          painter: AdvancedFrequencyScalePainter(_frequency),
                          size: const Size(double.infinity, 80),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Circular Frequency Dial
                      Container(
                        height: 180,
                        width: 180,
                        child: GestureDetector(
                          onPanStart: (details) {
                            // Store initial position for better tracking
                          },
                          onPanUpdate: (details) {
                            // Get the center position of the dial widget
                            RenderBox? box =
                                context.findRenderObject() as RenderBox?;
                            if (box == null) return;

                            // Get the global position of the container
                            Offset globalPosition = box.localToGlobal(
                              Offset.zero,
                            );

                            // Calculate center of the dial in global coordinates
                            double centerX =
                                globalPosition.dx + 90; // Half of 180
                            double centerY =
                                globalPosition.dy + 90; // Half of 180

                            // Calculate angle from center using global coordinates
                            double dx = details.globalPosition.dx - centerX;
                            double dy = details.globalPosition.dy - centerY;

                            // Check if touch is within reasonable distance from center
                            double distance = math.sqrt(dx * dx + dy * dy);
                            if (distance < 30 || distance > 90)
                              return; // Expanded touch area

                            // Calculate angle - adjust for dial starting position
                            double angle = math.atan2(dy, dx);
                            // Convert to 0-360 degrees, starting from top (12 o'clock position)
                            angle =
                                angle +
                                math.pi / 2; // Adjust for starting at top
                            if (angle < 0) angle += 2 * math.pi;
                            if (angle > 2 * math.pi) angle -= 2 * math.pi;

                            // Convert angle to frequency (320-650 MHz range)
                            double normalizedAngle = angle / (2 * math.pi);
                            double newFrequency =
                                320.0 + (normalizedAngle * 330.0);

                            setState(() {
                              _frequency = newFrequency.clamp(320.0, 650.0);
                            });
                          },
                          child: CustomPaint(
                            painter: CircularDialPainter(_frequency),
                            child: Center(
                              child: GestureDetector(
                                onTap: _showJoinDialog,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF00ff88),
                                        Color(0xFF00cc6a),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00ff88,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'JOIN',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Frequency Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00ff88).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'QUICK SELECT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildQuickFreqButton('350', 350.0)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildQuickFreqButton('450', 450.0)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildQuickFreqButton('550', 550.0)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildQuickFreqButton('630', 630.0)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Action Buttons (GROUPS, USERS)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00ff88).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showActiveGroupsPopup,
                          icon: const Icon(Icons.group, size: 18),
                          label: const Text('GROUPS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF444444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showFrequencyUsersPopup,
                          icon: const Icon(Icons.people, size: 18),
                          label: const Text('USERS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF444444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFreqButton(String label, double frequency) {
    final isSelected = (_frequency - frequency).abs() < 1.0;

    return GestureDetector(
      onTap: () => _quickFrequencySet(frequency),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00ff88) : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00ff88)
                : const Color(0xFF555555),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00ff88).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MHz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.black54 : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Advanced Frequency Scale Painter
class AdvancedFrequencyScalePainter extends CustomPainter {
  final double frequency;

  AdvancedFrequencyScalePainter(this.frequency);

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw main frequency line
    canvas.drawLine(
      Offset(0, size.height - 20),
      Offset(size.width, size.height - 20),
      Paint()
        ..color = const Color(0xFF444444)
        ..strokeWidth = 1,
    );

    // Draw frequency scale from 320 to 650 MHz (UHF range)
    const minFreq = 320;
    const maxFreq = 650;
    const freqRange = maxFreq - minFreq;

    // Calculate current frequency position to avoid overlapping text
    final currentPos = ((frequency - minFreq) / freqRange) * size.width;

    // Major marks every 50 MHz, minor marks every 10 MHz
    for (int freq = minFreq; freq <= maxFreq; freq += 10) {
      final position = ((freq - minFreq) / freqRange) * size.width;
      final isMajor = freq % 50 == 0;

      // Scale lines
      canvas.drawLine(
        Offset(position, size.height - (isMajor ? 40 : 30)),
        Offset(position, size.height - 20),
        Paint()
          ..color = isMajor ? const Color(0xFF00ff88) : const Color(0xFF666666)
          ..strokeWidth = isMajor ? 2 : 1,
      );

      if (isMajor) {
        // Check if this green label would overlap with red current frequency label
        final distanceFromCurrent = (position - currentPos).abs();

        // Only draw green label if it's far enough from the red current frequency label
        if (distanceFromCurrent > 30) {
          // 30 pixels minimum distance
          // Frequency numbers for major marks
          textPainter.text = TextSpan(
            text: freq.toString(),
            style: const TextStyle(
              color: Color(0xFF00ff88),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(position - textPainter.width / 2, size.height - 70),
          );
        }
      }
    }

    // Draw current frequency indicator
    canvas.drawLine(
      Offset(currentPos, 0),
      Offset(currentPos, size.height - 20),
      Paint()
        ..color = const Color(0xFFff4444)
        ..strokeWidth = 3,
    );

    // Current frequency label
    textPainter.text = TextSpan(
      text: frequency.toStringAsFixed(1),
      style: const TextStyle(
        color: Color(0xFFff4444),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(currentPos - textPainter.width / 2, 10));
  }

  @override
  bool shouldRepaint(AdvancedFrequencyScalePainter oldDelegate) {
    return oldDelegate.frequency != frequency;
  }
}

// Circular Dial Painter for Frequency Control
class CircularDialPainter extends CustomPainter {
  final double frequency;

  CircularDialPainter(this.frequency);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15; // Reduced padding for smaller dial

    // Draw outer ring
    final outerRingPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6; // Reduced stroke width
    canvas.drawCircle(center, radius, outerRingPaint);

    // Draw frequency markings
    final markPaint = Paint()
      ..color = const Color(0xFF00ff88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw major frequency marks (every 50 MHz)
    for (int freq = 320; freq <= 650; freq += 50) {
      double angle = ((freq - 320) / 330) * 2 * math.pi - math.pi / 2;

      // Major mark line
      double x1 = center.dx + (radius - 12) * math.cos(angle);
      double y1 = center.dy + (radius - 12) * math.sin(angle);
      double x2 = center.dx + radius * math.cos(angle);
      double y2 = center.dy + radius * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), markPaint);

      // Frequency labels (smaller for compact design)
      textPainter.text = TextSpan(
        text: freq.toString(),
        style: const TextStyle(
          color: Color(0xFF00ff88),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      double labelX =
          center.dx + (radius - 25) * math.cos(angle) - textPainter.width / 2;
      double labelY =
          center.dy + (radius - 25) * math.sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(labelX, labelY));
    }

    // Draw minor marks (every 10 MHz)
    final minorMarkPaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int freq = 320; freq <= 650; freq += 10) {
      if ((freq - 320) % 50 != 0) {
        // Skip major marks
        double angle = ((freq - 320) / 330) * 2 * math.pi - math.pi / 2;

        double x1 = center.dx + (radius - 6) * math.cos(angle);
        double y1 = center.dy + (radius - 6) * math.sin(angle);
        double x2 = center.dx + radius * math.cos(angle);
        double y2 = center.dy + radius * math.sin(angle);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), minorMarkPaint);
      }
    }

    // Draw current frequency indicator
    double currentAngle = ((frequency - 320) / 330) * 2 * math.pi - math.pi / 2;

    // Indicator line
    final indicatorPaint = Paint()
      ..color = const Color(0xFFff4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3; // Slightly thinner

    double indicatorX = center.dx + (radius - 18) * math.cos(currentAngle);
    double indicatorY = center.dy + (radius - 18) * math.sin(currentAngle);
    canvas.drawLine(center, Offset(indicatorX, indicatorY), indicatorPaint);

    // Draw indicator dot
    final dotPaint = Paint()
      ..color = const Color(0xFFff4444)
      ..style = PaintingStyle.fill;

    double dotX = center.dx + (radius - 8) * math.cos(currentAngle);
    double dotY = center.dy + (radius - 8) * math.sin(currentAngle);
    canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint); // Smaller dot

    // Draw center frequency display (smaller for JOIN button)
    final centerBgPaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 35, centerBgPaint); // Reduced from 50

    final centerBorderPaint = Paint()
      ..color = const Color(0xFF00ff88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 35, centerBorderPaint); // Reduced from 50

    // Current frequency text (smaller)
    textPainter.text = TextSpan(
      text: '${frequency.toStringAsFixed(1)}\nMHz',
      style: const TextStyle(
        color: Color(0xFF00ff88),
        fontSize: 10, // Smaller font
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 10, // Adjusted positioning
      ),
    );
  }

  @override
  bool shouldRepaint(CircularDialPainter oldDelegate) {
    return oldDelegate.frequency != frequency;
  }
}
