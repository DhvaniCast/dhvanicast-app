import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../injection.dart';
import '../../../models/frequency_model.dart';
import '../../../shared/services/dialer_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final ScrollController _frequencySelectorController = ScrollController();
  final ScrollController _quickSelectController = ScrollController();

  double _frequency = 450.0; // Changed to 350-650 range
  bool _isConnected = false;
  bool _isRecording = false;
  String _selectedBand = 'UHF'; // UHF for 350-650 MHz range

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Get DialerService from DI
    _dialerService = getIt<DialerService>();

    print('🚀 DialerScreen: Initializing...');

    // Ensure frequency is within valid range
    if (_frequency < 350.0 || _frequency > 650.0) {
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

    // Setup periodic refresh every 10 seconds to keep data updated
    _setupPeriodicRefresh();

    // Scroll to current frequency after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentFrequency();
    });
  }

  void _onServiceUpdate() {
    print('📡 DialerScreen: Service updated');
    print('📊 Frequencies count: ${_dialerService.frequencies.length}');
    print('👥 Groups count: ${_dialerService.groups.length}');

    // Log frequency details
    print('📋 ====== FREQUENCIES DETAILS ======');
    for (var freq in _dialerService.frequencies) {
      print('📋 Frequency: ${freq.frequency} MHz');
      print('📋   - ID: ${freq.id}');
      print('📋   - Band: ${freq.band}');
      print('📋   - Active Users: ${freq.activeUsers.length}');
      if (freq.activeUsers.isNotEmpty) {
        for (var user in freq.activeUsers) {
          print(
            '📋     * User: ${user.userName ?? user.callSign ?? user.userId}',
          );
        }
      }
    }

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

  // Setup periodic refresh to keep data updated
  void _setupPeriodicRefresh() {
    print('⏰ Setting up periodic refresh (every 30 seconds)');
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      print('🔄 Periodic refresh triggered');
      try {
        await _dialerService.loadFrequencies(isPublic: true, forceRefresh: true);
        await _dialerService.loadUserGroups();
        print('✅ Periodic refresh complete');
      } catch (e) {
        print('⚠️ Periodic refresh error (will retry): $e');
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _dialerService.removeListener(_onServiceUpdate);
    _pulseController.dispose();
    _dialController.dispose();
    _frequencySelectorController.dispose();
    _quickSelectController.dispose();
    super.dispose();
  }

  // Scroll to current frequency in the selector
  void _scrollToCurrentFrequency() {
    if (!_frequencySelectorController.hasClients ||
        !_quickSelectController.hasClients)
      return;

    // Calculate the index of current frequency
    final index = ((_frequency - 350.0) / 0.1).round();
    final itemWidth = 64.0; // 60 width + 4 margin
    final scrollPosition =
        (index * itemWidth) -
        (MediaQuery.of(context).size.width / 2) +
        (itemWidth / 2);

    // Scroll main selector
    _frequencySelectorController.animateTo(
      scrollPosition.clamp(
        0.0,
        _frequencySelectorController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    // Scroll quick select
    _quickSelectController.animateTo(
      scrollPosition.clamp(
        0.0,
        _quickSelectController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
      // Keep frequency within valid slider range (350-650 MHz)
      if (_selectedBand == 'VHF') {
        _frequency = 350.0; // Lowest UHF frequency for now
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

  void _quickFrequencySet(double freq) {
    setState(() {
      // Ensure frequency is within valid UHF range
      if (freq >= 350.0 && freq <= 650.0) {
        _frequency = freq;
      } else {
        _frequency = 450.0; // Default UHF frequency
      }
    });
    // Scroll to new frequency
    _scrollToCurrentFrequency();
  }

  // Missing functions - Add back
  void _showActiveGroupsPopup() async {
    print('👥 [GROUPS] ====== SHOWING GROUPS POPUP ======');
    print('👥 [GROUPS] Refreshing data before showing popup...');

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00ff88)),
        ),
      );
    }

    // Refresh data to get latest active users - load ALL frequencies
    // ✅ Don't use hasActiveUsers filter - let frontend filter locally for better real-time updates
    await _dialerService.loadFrequencies(
      isPublic: true,
      // hasActiveUsers: true, // ❌ Removed - causes timing issues when users leave
    );
    await _dialerService.loadUserGroups();

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    print('👥 [GROUPS] ====== DATA LOADED ======');
    print('👥 [GROUPS] Total groups from API: ${_dialerService.groups.length}');
    print(
      '👥 [GROUPS] Total frequencies: ${_dialerService.frequencies.length}',
    );

    // Create frequency-based groups from frequencies with active users
    List<Map<String, dynamic>> frequencyGroups = [];

    for (var freq in _dialerService.frequencies) {
      print('🔍 [GROUPS] ====== CHECKING FREQUENCY ======');
      print('🔍 [GROUPS] Frequency: ${freq.frequency} MHz');
      print('🔍 [GROUPS] Frequency ID: ${freq.id}');
      print('🔍 [GROUPS] Band: ${freq.band}');
      print('🔍 [GROUPS] Is Public: ${freq.isPublic}');
      print('🔍 [GROUPS] User Count: ${freq.userCount}');
      print('🔍 [GROUPS] Active Users Length: ${freq.activeUsers.length}');

      // Log each active user
      if (freq.activeUsers.isNotEmpty) {
        print(
          '🔍 [GROUPS] ====== ACTIVE USERS ON ${freq.frequency} MHz ======',
        );
        for (var i = 0; i < freq.activeUsers.length; i++) {
          final user = freq.activeUsers[i];
          print('🔍 [GROUPS]   User $i:');
          print('🔍 [GROUPS]     - User ID: ${user.userId}');
          print('🔍 [GROUPS]     - User Name: ${user.userName}');
          print('🔍 [GROUPS]     - Call Sign: ${user.callSign}');
        }
      }

      if (freq.activeUsers.isNotEmpty) {
        print(
          '✅ [GROUPS] Creating group for ${freq.frequency} MHz with ${freq.activeUsers.length} users',
        );

        frequencyGroups.add({
          'id': freq.id,
          'frequencyId': freq.id,
          'name': '${freq.frequency.toStringAsFixed(1)} MHz Channel',
          'frequency': freq.frequency,
          'members': freq.activeUsers.map((u) => u.userId).toList(),
          'status': 'active',
          'icon': Icons.radio,
          'color': const Color(0xFF00ff88),
          'type': 'frequency', // Important: to identify it's frequency chat
          'activeUsers': freq.activeUsers.length,
        });
      } else {
        print('⏭️ [GROUPS] Skipping ${freq.frequency} MHz - no active users');
      }
    }

    print(
      '📊 [GROUPS] Total frequency groups created: ${frequencyGroups.length}',
    );
    print('📊 [GROUPS] API groups: ${_dialerService.groups.length}');

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
                  Expanded(
                    child: Text(
                      'Active Channels (${frequencyGroups.length + _dialerService.groups.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Manual refresh button
                  IconButton(
                    onPressed: () async {
                      print('🔄 [GROUPS] Manual refresh triggered');
                      // Force refresh from API
                      await _dialerService.loadFrequencies(isPublic: true, forceRefresh: true);
                      Navigator.pop(context); // Close current popup
                      await Future.delayed(const Duration(milliseconds: 300));
                      _showActiveGroupsPopup(); // Reopen with fresh data
                    },
                    icon: const Icon(Icons.refresh, color: Color(0xFF00ff88)),
                    tooltip: 'Refresh Channels',
                  ),
                ],
              ),
            ),

            // Section: Frequency Channels
            if (frequencyGroups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radio, color: Color(0xFF00ff88), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Frequency Channels (${frequencyGroups.length})',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...frequencyGroups.map((group) {
                print('🎨 [GROUPS] Building card for: ${group['name']}');
                return _buildGroupCard(group);
              }),
              const SizedBox(height: 12),
            ],

            // Section: Regular Groups
            if (_dialerService.groups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group, color: Color(0xFF00ff88), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Your Groups (${_dialerService.groups.length})',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ..._dialerService.groups.map((group) {
                print('🎨 [GROUPS] Building card for group: ${group.name}');
                // Convert GroupModel to Map for _buildGroupCard
                return _buildGroupCard({
                  'id': group.id,
                  'groupId': group.id,
                  'name': group.name,
                  'members': group.members.map((m) => m.userId).toList(),
                  'status': group.members.any((m) => m.isOnline)
                      ? 'active'
                      : 'idle',
                  'icon': Icons.group,
                  'color': Colors.blue,
                  'frequency': 450.0,
                  'type': 'group', // Important: to identify it's group chat
                });
              }),
            ],

            // Loading state
            if (_dialerService.isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Color(0xFF00ff88)),
              ),

            // Empty state
            if (frequencyGroups.isEmpty &&
                _dialerService.groups.isEmpty &&
                !_dialerService.isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No active channels found',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    print('👥 [GROUPS] ====== POPUP DISPLAYED ======');
  }

  void _showFrequencyUsersPopup() async {
    print('📞 [USERS] ====== OPENING USERS/CONTACTS POPUP ======');
    print('📞 [USERS] Current frequency: ${_frequency.toStringAsFixed(1)} MHz');
    print('📞 [USERS] Current band: $_selectedBand');

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00ff88)),
        ),
      );
    }

    // Refresh frequency data to get latest users
    print('📞 [USERS] Refreshing frequencies to get latest user data...');

    // Load all frequencies - frontend will filter for active users
    await _dialerService.loadFrequencies(
      isPublic: true,
      // hasActiveUsers: true, // ❌ Removed - let frontend filter locally
    );

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    print('📞 [USERS] ====== DATA LOADED ======');
    print(
      '📞 [USERS] Total frequencies in service: ${_dialerService.frequencies.length}',
    );

    // Log all frequencies with their user counts
    print('📞 [USERS] ====== ALL FREQUENCIES ======');
    for (var freq in _dialerService.frequencies) {
      print(
        '📞 [USERS]   - ${freq.frequency} MHz: ${freq.activeUsers.length} users',
      );
    }

    // Get ALL users from ALL active frequencies
    final allActiveUsers = _getAllActiveUsers();
    print('📞 [USERS] ====== USERS RETRIEVED ======');
    print(
      '📞 [USERS] Total active users across all frequencies: ${allActiveUsers.length}',
    );

    if (allActiveUsers.isEmpty) {
      print('⚠️ [USERS] WARNING: No active users found on any frequency');
    } else {
      print('✅ [USERS] Found ${allActiveUsers.length} active user(s):');
      for (var user in allActiveUsers) {
        print('✅ [USERS]   - "${user['name']}" on ${user['frequency']} MHz');
      }
    }

    // Generate shareable link
    final shareableLink = _generateFrequencyShareLink();
    print('📞 [USERS] Generated link: $shareableLink');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF2a2a2a),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF00ff88)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share Frequency',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Send ${_frequency.toStringAsFixed(1)} MHz to users',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: () async {
                      print('🔄 [USERS] Refresh button clicked');
                      await _dialerService.loadFrequencies(
                        band: _selectedBand,
                        isPublic: true,
                      );
                      print('🔄 [USERS] Frequencies reloaded');
                      // Close and reopen popup to show updated data
                      Navigator.pop(context);
                      _showFrequencyUsersPopup();
                    },
                    icon: const Icon(Icons.refresh, color: Color(0xFF00ff88)),
                    tooltip: 'Refresh Users',
                  ),
                  // Share to phone contacts button
                  IconButton(
                    onPressed: () {
                      print('📱 [USERS] Share to phone contacts clicked');
                      _shareToPhoneContacts(shareableLink);
                    },
                    icon: const Icon(
                      Icons.contact_phone,
                      color: Color(0xFF00ff88),
                    ),
                    tooltip: 'Share to Phone Contacts',
                  ),
                  IconButton(
                    onPressed: () {
                      print('❌📞 [USERS] Closing contacts popup');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Share Link Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00ff88).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Color(0xFF00ff88), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shareableLink,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        print('📋 [USERS] Copy link clicked');
                        _copyLinkToClipboard(shareableLink);
                      },
                      icon: const Icon(
                        Icons.copy,
                        color: Color(0xFF00ff88),
                        size: 18,
                      ),
                      tooltip: 'Copy Link',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF00ff88), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Active Users (${allActiveUsers.length})',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Users List
            Expanded(
              child: allActiveUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No active users found',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Users will appear here when they join frequencies',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: allActiveUsers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final user = allActiveUsers[index];
                        print('👤 [USERS] Building user card: ${user['name']}');

                        return _buildFrequencyUserCard(user, shareableLink);
                      },
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    print('📞 [USERS] ====== CONTACTS POPUP DISPLAYED ======');
  }

  // Get ALL active users from ALL frequencies
  List<Map<String, dynamic>> _getAllActiveUsers() {
    print('🔍 [ALL-USERS] ====== GETTING ALL ACTIVE USERS ======');
    print(
      '🔍 [ALL-USERS] Total frequencies loaded: ${_dialerService.frequencies.length}',
    );

    List<Map<String, dynamic>> allUsers = [];

    for (var freq in _dialerService.frequencies) {
      print(
        '🔍 [ALL-USERS] Checking frequency: ${freq.frequency} MHz (${freq.activeUsers.length} users)',
      );

      for (var activeUser in freq.activeUsers) {
        print(
          '👤 [ALL-USERS] Processing user: ${activeUser.userName ?? activeUser.callSign ?? activeUser.userId}',
        );

        // Get display name
        String displayName;
        if (activeUser.userName != null && activeUser.userName!.isNotEmpty) {
          displayName = activeUser.userName!;
        } else if (activeUser.callSign != null &&
            activeUser.callSign!.isNotEmpty) {
          displayName = activeUser.callSign!;
        } else if (activeUser.avatar != null &&
            activeUser.avatar!.isNotEmpty &&
            activeUser.avatar != '📻') {
          displayName = activeUser.avatar!;
        } else {
          displayName = 'User ${activeUser.userId.substring(0, 8)}';
        }

        // Get avatar text
        String avatarText;
        if (activeUser.avatar != null &&
            activeUser.avatar!.length >= 2 &&
            activeUser.avatar != '📻') {
          avatarText = activeUser.avatar!.substring(0, 2).toUpperCase();
        } else if (displayName.length >= 2) {
          avatarText = displayName.substring(0, 2).toUpperCase();
        } else {
          avatarText = 'U';
        }

        allUsers.add({
          'id': activeUser.userId,
          'userId': activeUser.userId,
          'name': displayName,
          'avatar': avatarText,
          'isOnline': true,
          'joinedAt': activeUser.joinedAt.toIso8601String(),
          'callSign': activeUser.callSign,
          'isTransmitting': activeUser.isTransmitting,
          'frequency': freq.frequency, // Include frequency info
          'frequencyId': freq.id,
        });
      }
    }

    print('✅ [ALL-USERS] Total active users: ${allUsers.length}');
    return allUsers;
  }

  // Get users on current frequency
  List<Map<String, dynamic>> _getUsersOnCurrentFrequency() {
    print('🔍 [FREQUENCY-USERS] ====== GETTING USERS ON FREQUENCY ======');
    print(
      '🔍 [FREQUENCY-USERS] Target frequency: ${_frequency.toStringAsFixed(1)} MHz',
    );
    print(
      '🔍 [FREQUENCY-USERS] Total frequencies loaded: ${_dialerService.frequencies.length}',
    );

    // Log all available frequencies with detailed info
    print('📋 [FREQUENCY-USERS] ====== ALL FREQUENCIES DETAILED ======');
    for (var freq in _dialerService.frequencies) {
      print(
        '📋 [FREQUENCY-USERS] - Freq: ${freq.frequency} MHz, ID: ${freq.id}, Band: ${freq.band}',
      );
      print(
        '📋 [FREQUENCY-USERS]   User Count: ${freq.userCount}, Active Users: ${freq.activeUsers.length}',
      );
      if (freq.activeUsers.isNotEmpty) {
        for (var user in freq.activeUsers) {
          print(
            '📋 [FREQUENCY-USERS]     * ${user.userName ?? user.callSign ?? user.userId}',
          );
        }
      }
    }

    // Find the frequency in loaded data with exact match (0.05 tolerance)
    final frequencyData = _dialerService.frequencies.firstWhere(
      (f) {
        final difference = (f.frequency - _frequency).abs();
        print(
          '🔍 [FREQUENCY-USERS] Checking freq ${f.frequency} MHz - Difference: $difference',
        );
        return difference <=
            0.05; // Changed from 0.5 to 0.05 for exact 0.1 increments
      },
      orElse: () {
        print(
          '⚠️ [FREQUENCY-USERS] No matching frequency found! Creating empty model.',
        );
        return FrequencyModel(
          id: '',
          frequency: _frequency,
          band: _selectedBand,
          isPublic: true,
          activeUsers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      },
    );

    print('🔍 [FREQUENCY-USERS] ====== FOUND FREQUENCY ======');
    print('🔍 [FREQUENCY-USERS] Frequency ID: ${frequencyData.id}');
    print(
      '🔍 [FREQUENCY-USERS] Frequency Value: ${frequencyData.frequency} MHz',
    );
    print(
      '🔍 [FREQUENCY-USERS] Active users count: ${frequencyData.activeUsers.length}',
    );

    print('🔍 [FREQUENCY-USERS] ====== FOUND FREQUENCY ======');
    print('🔍 [FREQUENCY-USERS] Frequency ID: ${frequencyData.id}');
    print(
      '🔍 [FREQUENCY-USERS] Frequency Value: ${frequencyData.frequency} MHz',
    );
    print(
      '🔍 [FREQUENCY-USERS] Active users count: ${frequencyData.activeUsers.length}',
    );

    // Log each active user details
    print('👥 [FREQUENCY-USERS] ====== ACTIVE USERS RAW DATA ======');
    for (var i = 0; i < frequencyData.activeUsers.length; i++) {
      final user = frequencyData.activeUsers[i];
      print('👤 [FREQUENCY-USERS] User #$i:');
      print('   - User ID: ${user.userId}');
      print('   - User Name: ${user.userName}');
      print('   - Call Sign: ${user.callSign}');
      print('   - Avatar: ${user.avatar}');
      print('   - Is Transmitting: ${user.isTransmitting}');
      print('   - Joined At: ${user.joinedAt}');
    }

    // WORKAROUND: If no users found on exact frequency, search all frequencies for ANY with active users
    if (frequencyData.activeUsers.isEmpty) {
      print(
        '⚠️ [FREQUENCY-USERS] No users on target frequency, checking ALL frequencies...',
      );
      for (var freq in _dialerService.frequencies) {
        if (freq.activeUsers.isNotEmpty) {
          print(
            '✅ [FREQUENCY-USERS] Found frequency with users: ${freq.frequency} MHz',
          );
          print('✅ [FREQUENCY-USERS] User count: ${freq.activeUsers.length}');
          for (var user in freq.activeUsers) {
            print(
              '✅ [FREQUENCY-USERS]   - ${user.userName ?? user.callSign ?? user.userId}',
            );
          }
        }
      }
    }

    // Convert active users to user list
    final users = frequencyData.activeUsers.map((activeUser) {
      print('👤 [FREQUENCY-USERS] ====== PROCESSING USER ======');
      print('👤 [FREQUENCY-USERS] User ID: ${activeUser.userId}');
      print('👤 [FREQUENCY-USERS] User Name: ${activeUser.userName}');
      print('👤 [FREQUENCY-USERS] Call Sign: ${activeUser.callSign}');
      print('👤 [FREQUENCY-USERS] Avatar: ${activeUser.avatar}');

      // Try to get name from multiple sources with priority
      String displayName;

      print('🔍 [FREQUENCY-USERS] ====== NAME RESOLUTION ======');

      // Priority 1: userName
      if (activeUser.userName != null && activeUser.userName!.isNotEmpty) {
        displayName = activeUser.userName!;
        print('✅ [FREQUENCY-USERS] Using userName: "$displayName"');
      }
      // Priority 2: callSign
      else if (activeUser.callSign != null && activeUser.callSign!.isNotEmpty) {
        displayName = activeUser.callSign!;
        print('✅ [FREQUENCY-USERS] Using callSign: "$displayName"');
      }
      // Priority 3: avatar (if it's text, not emoji)
      else if (activeUser.avatar != null &&
          activeUser.avatar!.isNotEmpty &&
          activeUser.avatar != '📻') {
        displayName = activeUser.avatar!;
        print('✅ [FREQUENCY-USERS] Using avatar as name: "$displayName"');
      }
      // Fallback: Use shortened User ID
      else {
        displayName = 'User ${activeUser.userId.substring(0, 8)}';
        print('⚠️ [FREQUENCY-USERS] Using fallback name: "$displayName"');
      }

      // Get avatar text for display
      String avatarText;
      if (activeUser.avatar != null &&
          activeUser.avatar!.length >= 2 &&
          activeUser.avatar != '📻') {
        avatarText = activeUser.avatar!.substring(0, 2).toUpperCase();
        print('🎨 [FREQUENCY-USERS] Avatar from avatar field: "$avatarText"');
      } else if (displayName.length >= 2) {
        avatarText = displayName.substring(0, 2).toUpperCase();
        print('🎨 [FREQUENCY-USERS] Avatar from displayName: "$avatarText"');
      } else {
        avatarText = 'U';
        print('🎨 [FREQUENCY-USERS] Avatar fallback: "$avatarText"');
      }

      print('👤 [FREQUENCY-USERS] ====== FINAL USER DATA ======');
      print('👤 [FREQUENCY-USERS] Final display name: "$displayName"');
      print('👤 [FREQUENCY-USERS] Final avatar text: "$avatarText"');

      final userMap = {
        'id': activeUser.userId,
        'userId': activeUser.userId,
        'name': displayName,
        'avatar': avatarText,
        'isOnline': true, // They are active on frequency
        'joinedAt': activeUser.joinedAt.toIso8601String(),
        'callSign': activeUser.callSign,
        'isTransmitting': activeUser.isTransmitting,
      };

      print('✅ [FREQUENCY-USERS] Created user map: $userMap');

      return userMap;
    }).toList();

    print('✅ [FREQUENCY-USERS] ====== FINAL USERS LIST ======');
    print('✅ [FREQUENCY-USERS] Total users to display: ${users.length}');
    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      print(
        '✅ [FREQUENCY-USERS] User #$i: "${user['name']}" (ID: ${user['userId']})',
      );
    }

    return users;
  }

  // Generate shareable frequency link
  String _generateFrequencyShareLink() {
    print('🔗 [LINK] ====== GENERATING SHARE LINK ======');

    final frequency = _frequency.toStringAsFixed(1);
    final band = _selectedBand;

    // Create deep link
    final link = 'https://dhvanicast.app/join?freq=$frequency&band=$band';

    print('🔗 [LINK] Frequency: $frequency MHz');
    print('🔗 [LINK] Band: $band');
    print('🔗 [LINK] Generated link: $link');

    return link;
  }

  // Copy link to clipboard
  void _copyLinkToClipboard(String link) {
    print('📋 [CLIPBOARD] ====== COPYING LINK ======');
    print('📋 [CLIPBOARD] Link: $link');

    // TODO: Add clipboard package and implement
    // Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: Color(0xFF00ff88),
        duration: Duration(seconds: 2),
      ),
    );

    print('✅ [CLIPBOARD] Link copied successfully');
  }

  // Share to phone contacts - Shows options dialog
  void _shareToPhoneContacts(String link) {
    print('📱 [PHONE-SHARE] ====== SHARE TO PHONE CONTACTS ======');
    print('📱 [PHONE-SHARE] Frequency: ${_frequency.toStringAsFixed(1)} MHz');
    print('📱 [PHONE-SHARE] Link: $link');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share, size: 64, color: Color(0xFF00ff88)),
              const SizedBox(height: 16),
              const Text(
                'Share Frequency',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Share via Apps Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareViaApps(link);
                  },
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text(
                    'SHARE VIA APPS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ff88),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Share to Contacts Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareToContacts(link);
                  },
                  icon: const Icon(Icons.contacts, size: 20),
                  label: const Text(
                    'SHARE TO CONTACTS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00ff88),
                    side: const BorderSide(color: Color(0xFF00ff88), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Close Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    print('✅ [PHONE-SHARE] Share dialog opened');
  }

  // Share via any app (WhatsApp, SMS, etc.)
  Future<void> _shareViaApps(String link) async {
    final message =
        '🎙️ Join me on Dhvani Cast!\n\n'
        'Frequency: ${_frequency.toStringAsFixed(1)} MHz\n'
        'Band: $_selectedBand\n\n'
        'Join now: $link';

    try {
      await Share.share(
        message,
        subject: 'Join ${_frequency.toStringAsFixed(1)} MHz on Dhvani Cast',
      );
    } catch (e) {
      print('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to share'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share to contacts
  Future<void> _shareToContacts(String link) async {
    try {
      final permission = await Permission.contacts.request();

      if (permission.isGranted) {
        if (await FlutterContacts.requestPermission()) {
          final contacts = await FlutterContacts.getContacts(
            withProperties: true,
            withPhoto: false,
          );

          if (contacts.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📱 No contacts found on your device'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          if (mounted) {
            _showContactPicker(contacts, link);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Contacts permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Contacts permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error accessing contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to open contacts'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show contact picker
  void _showContactPicker(List<Contact> contacts, String link) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.contacts,
                    color: Color(0xFF00ff88),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Contact',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final hasPhone = contact.phones.isNotEmpty;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00ff88),
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: hasPhone
                          ? Text(
                              contact.phones.first.number,
                              style: const TextStyle(color: Colors.white54),
                            )
                          : const Text(
                              'No phone number',
                              style: TextStyle(color: Colors.white30),
                            ),
                      trailing: hasPhone
                          ? const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF00ff88),
                              size: 16,
                            )
                          : null,
                      onTap: hasPhone
                          ? () {
                              Navigator.pop(context);
                              _shareToSelectedContact(contact, link);
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Share to selected contact
  Future<void> _shareToSelectedContact(Contact contact, String link) async {
    final message =
        'Hi ${contact.displayName}! \n\n'
        '🎙️ Join me on Dhvani Cast!\n\n'
        'Frequency: ${_frequency.toStringAsFixed(1)} MHz\n'
        'Band: $_selectedBand\n\n'
        'Join now: $link';

    try {
      await Share.share(
        message,
        subject: 'Join ${_frequency.toStringAsFixed(1)} MHz on Dhvani Cast',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Shared with ${contact.displayName}'),
            backgroundColor: const Color(0xFF00ff88),
          ),
        );
      }
    } catch (e) {
      print('Error sharing to contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to share'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build frequency user card (users on current frequency)
  Widget _buildFrequencyUserCard(
    Map<String, dynamic> user,
    String shareableLink,
  ) {
    print('🎴 [USER-CARD] ====== BUILDING USER CARD ======');
    print('🎴 [USER-CARD] Name: ${user['name']}');
    print('🎴 [USER-CARD] User ID: ${user['userId']}');
    print('🎴 [USER-CARD] Frequency: ${user['frequency']} MHz');

    final isOnline = user['isOnline'] as bool;
    final isTransmitting = user['isTransmitting'] as bool? ?? false;
    final frequency = user['frequency'] as double?;

    print('🎴 [USER-CARD] Status: ${isOnline ? 'Online' : 'Offline'}');
    print('🎴 [USER-CARD] Transmitting: $isTransmitting');

    return GestureDetector(
      onTap: () {
        print('💬 [USER-CARD] ====== USER TAPPED ======');
        print('💬 [USER-CARD] Opening chat with: ${user['name']}');
        print('💬 [USER-CARD] User ID: ${user['userId']}');

        // Close the popup
        Navigator.pop(context);

        // Navigate to communication screen to chat with user
        _openChatWithFrequencyUser(user, shareableLink);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTransmitting
                ? const Color(0xFF00ff88).withOpacity(0.6)
                : const Color(0xFF00ff88).withOpacity(0.3),
            width: isTransmitting ? 2 : 1,
          ),
          boxShadow: isTransmitting
              ? [
                  BoxShadow(
                    color: const Color(0xFF00ff88).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Avatar with transmitting indicator
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: isTransmitting
                      ? const Color(0xFF00ff88)
                      : const Color(0xFF444444),
                  radius: 24,
                  child: Text(
                    user['avatar'],
                    style: TextStyle(
                      color: isTransmitting ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOnline)
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
                          color: const Color(0xFF1a1a1a),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
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
                          user['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTransmitting) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ff88).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic,
                                size: 10,
                                color: Color(0xFF00ff88),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFF00ff88),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    frequency != null
                        ? 'On ${frequency.toStringAsFixed(1)} MHz'
                        : user['callSign'] ?? 'Unknown frequency',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Share button
            IconButton(
              onPressed: () {
                print(
                  '📤 [USER-CARD] Share button clicked for: ${user['name']}',
                );
                _shareFrequencyToUser(user, shareableLink);
              },
              icon: const Icon(Icons.share, color: Color(0xFF00ff88), size: 20),
              tooltip: 'Share frequency',
            ),
          ],
        ),
      ),
    );
  }

  // Open chat with frequency user
  void _openChatWithFrequencyUser(
    Map<String, dynamic> user,
    String shareableLink,
  ) {
    print('💬 [CHAT] ====== OPENING CHAT WITH FREQUENCY USER ======');
    print('💬 [CHAT] User: ${user['name']}');
    print('💬 [CHAT] User ID: ${user['userId']}');
    print('💬 [CHAT] Frequency: ${_frequency.toStringAsFixed(1)} MHz');

    // Navigate to communication screen with user data
    final chatArguments = {
      'name': user['name'],
      'frequency': _frequency,
      'type': 'user',
      'status': 'active',
      'members': [user['name']],
      'color': const Color(0xFF00ff88),
      'icon': Icons.person,
      'userId': user['userId'],
      'callSign': user['callSign'],
    };

    print('💬 [CHAT] Navigation arguments prepared: $chatArguments');
    print('💬 [CHAT] Navigating to /communication screen...');

    Navigator.pushNamed(
      context,
      '/communication',
      arguments: chatArguments,
    ).then((_) {
      print('💬 [CHAT] Returned from communication screen');
    });

    print('💬 [CHAT] ====== NAVIGATION INITIATED ======');
  }

  // Share frequency link to specific user
  void _shareFrequencyToUser(Map<String, dynamic> user, String shareableLink) {
    print('📤 [SHARE-USER] ====== SHARING TO USER ======');
    print('📤 [SHARE-USER] Target user: ${user['name']}');
    print('📤 [SHARE-USER] Link: $shareableLink');

    final message =
        '🎙️ Join me on ${_frequency.toStringAsFixed(1)} MHz!\n\n'
        'Band: $_selectedBand\n'
        'Link: $shareableLink';

    print('📤 [SHARE-USER] Message: $message');

    // Close popup and open chat with pre-filled message
    Navigator.pop(context);

    final chatArguments = {
      'name': user['name'],
      'frequency': _frequency,
      'type': 'user',
      'status': 'active',
      'members': [user['name']],
      'color': const Color(0xFF00ff88),
      'icon': Icons.person,
      'userId': user['userId'],
      'initialMessage': message,
      'isFrequencyShare': true,
    };

    Navigator.pushNamed(context, '/communication', arguments: chatArguments);

    print('✅ [SHARE-USER] Chat opened with pre-filled message');
  }

  void _showJoinDialog() async {
    print(
      '🔗 Attempting to join frequency: ${_frequency.toStringAsFixed(1)} MHz',
    );

    // Load only the selected frequency by value (avoid fetching full list)
    print('🔄 Loading single frequency by value before join...');
    await _dialerService.loadFrequencyByValue(_frequency);
    print(
      '✅ loadFrequencyByValue complete. Frequencies in service: ${_dialerService.frequencies.length}',
    );

    // Try currentFrequency first (service may have loaded exact item)
    FrequencyModel? frequencyToJoin = _dialerService.currentFrequency;

    // If not present, try to find by value in the cached list (small fallback)
    if (frequencyToJoin == null) {
      frequencyToJoin = _dialerService.frequencies
          .where((f) => (f.frequency - _frequency).abs() <= 0.05)
          .firstOrNull;
    }

    print(
      '🔍 Frequency search: Looking for ${_frequency.toStringAsFixed(1)} MHz',
    );
    print(
      '🔍 Frequency search result: ${frequencyToJoin != null ? "FOUND (${frequencyToJoin.id}, ${frequencyToJoin.frequency} MHz)" : "NOT FOUND"}',
    );

    // If not found with exact match, try to find closest frequency
    if (frequencyToJoin == null && _dialerService.frequencies.isNotEmpty) {
      print('⚠️ Exact match not found, searching for closest frequency...');

      // Find the closest frequency
      double minDiff = double.infinity;
      FrequencyModel? closestFreq;

      for (var freq in _dialerService.frequencies) {
        double diff = (freq.frequency - _frequency).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestFreq = freq;
        }
      }

      if (closestFreq != null && minDiff <= 0.5) {
        frequencyToJoin = closestFreq;
        print(
          '✅ Using closest frequency: ${closestFreq.frequency} MHz (diff: $minDiff)',
        );
      } else {
        print('❌ No suitable frequency found within 0.5 MHz range');
      }
    }

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
                    ? 'Frequency not available'
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

                      // Check if frequency exists
                      if (frequencyToJoin == null) {
                        Navigator.pop(context);
                        print('❌ Frequency not found in backend');
                        print(
                          '❌ Requested: ${_frequency.toStringAsFixed(1)} MHz',
                        );
                        print(
                          '❌ Available frequencies: ${_dialerService.frequencies.length}',
                        );

                        // Show first few available frequencies for debugging
                        if (_dialerService.frequencies.isNotEmpty) {
                          print('📋 First 5 available:');
                          for (
                            var i = 0;
                            i < 5 && i < _dialerService.frequencies.length;
                            i++
                          ) {
                            print(
                              '   - ${_dialerService.frequencies[i].frequency} MHz (${_dialerService.frequencies[i].id})',
                            );
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Frequency ${_frequency.toStringAsFixed(1)} MHz not found.\n'
                              'Available: ${_dialerService.frequencies.length} frequencies\n'
                              'Backend may need restart.',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      print(
                        '✅ Joining frequency: ${frequencyToJoin.frequency} MHz (ID: ${frequencyToJoin.id})',
                      );

                      // Now join the frequency
                      final success = await _dialerService.joinFrequency(
                        frequencyToJoin.id,
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
                            'frequencyId': frequencyToJoin.id,
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
    print('🎨 [CARD] ====== BUILDING GROUP CARD ======');
    print('🎨 [CARD] Group: ${group['name']}');
    print('🎨 [CARD] Type: ${group['type']}');
    print('🎨 [CARD] Members: ${group['members']?.length ?? 0}');
    print('🎨 [CARD] Frequency: ${group['frequency']}');

    return GestureDetector(
      onTap: () {
        print('🖱️ [CARD] Card tapped: ${group['name']}');

        // Check if it's a frequency group (either by type or by presence of frequency field)
        if (group['type'] == 'frequency' || group.containsKey('frequency')) {
          print('🖱️ [CARD] Joining frequency: ${group['frequency']}');
          Navigator.pop(context); // Close popup
          
          setState(() {
            _frequency = (group['frequency'] as num).toDouble();
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            _showJoinDialog();
          });
        } else {
          print('🖱️ [CARD] Navigating to communication screen...');
          print('🖱️ [CARD] Arguments: $group');

          // Navigate to communication screen with group data
          Navigator.pushNamed(context, '/communication', arguments: group).then((
            _,
          ) {
            print('🔙 [CARD] Returned from communication screen');
          });
        }
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
                    '${group['frequency'].toStringAsFixed(1)} MHz • ${group['members'].length} members',
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

                // Audio Controls Row (Recording + Friends + Band)
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/friends');
                          },
                          icon: const Icon(Icons.people_alt, size: 18),
                          label: const Text('FRIENDS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFff9800),
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
                      const SizedBox(width: 12),
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

                      // Horizontal Scrollable Frequency List
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00ff88).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListView.builder(
                          controller: _frequencySelectorController,
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              3001, // 350.0 to 650.0 with 0.1 steps = 3001 items
                          itemBuilder: (context, index) {
                            final freq = 350.0 + (index * 0.1);
                            final isSelected = (_frequency - freq).abs() < 0.05;
                            final isMajor = freq % 10 == 0; // Every 10 MHz
                            final isHalfMajor = freq % 5 == 0; // Every 5 MHz

                            return GestureDetector(
                              onTap: () {
                                print(
                                  '🎯 [FREQ] Selected: ${freq.toStringAsFixed(1)} MHz',
                                );
                                setState(() {
                                  _frequency = freq;
                                });
                                _scrollToCurrentFrequency();
                              },
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00ff88)
                                      : isMajor
                                      ? const Color(0xFF2a2a2a)
                                      : isHalfMajor
                                      ? const Color(0xFF252525)
                                      : const Color(0xFF1a1a1a),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00ff88)
                                        : isMajor
                                        ? const Color(
                                            0xFF00ff88,
                                          ).withOpacity(0.3)
                                        : const Color(
                                            0xFF444444,
                                          ).withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00ff88,
                                            ).withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Frequency value
                                    Text(
                                      freq.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : isMajor
                                            ? const Color(0xFF00ff88)
                                            : Colors.white70,
                                        fontSize: isSelected
                                            ? 18
                                            : isMajor
                                            ? 16
                                            : 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : isMajor
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // MHz label
                                    Text(
                                      'MHz',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black54
                                            : const Color(0xFF888888),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Visual indicator bar
                                    Container(
                                      height: isMajor
                                          ? 40
                                          : isHalfMajor
                                          ? 30
                                          : 20,
                                      width: 3,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.black
                                            : isMajor
                                            ? const Color(0xFF00ff88)
                                            : const Color(0xFF666666),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // JOIN Button
                      Center(
                        child: GestureDetector(
                          onTap: _showJoinDialog,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF00ff88), Color(0xFF00cc6a)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00ff88,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'JOIN FREQUENCY',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
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
                      // Horizontal scrollable frequency list
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          controller: _quickSelectController,
                          scrollDirection: Axis.horizontal,
                          itemCount: 3001, // 350.0 to 650.0 with 0.1 steps
                          itemBuilder: (context, index) {
                            final freq = 350.0 + (index * 0.1);
                            final isSelected = (_frequency - freq).abs() < 0.05;

                            return GestureDetector(
                              onTap: () {
                                print(
                                  '🎯 [QUICK] Selected: ${freq.toStringAsFixed(1)} MHz',
                                );
                                _quickFrequencySet(freq);
                              },
                              child: Container(
                                width: 65,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00ff88)
                                      : const Color(0xFF333333),
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
                                            color: const Color(
                                              0xFF00ff88,
                                            ).withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      freq.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'MHz',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black54
                                            : Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Action Buttons (GROUPS, USERS, PRIVATE FREQUENCY)
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
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showActiveGroupsPopup,
                              icon: const Icon(Icons.group, size: 18),
                              label: const Text('GROUPS'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF444444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                      const SizedBox(height: 12),
                      // Private Frequency Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/private-frequency');
                          },
                          icon: const Icon(Icons.lock, size: 18),
                          label: const Text('PRIVATE FREQUENCY'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00ff88),
                            foregroundColor: Colors.black,
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
}

// Advanced Frequency Scale Painter (not used anymore, can be removed)
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

    // Draw frequency scale from 350 to 650 MHz (UHF range)
    const minFreq = 350.0;
    const maxFreq = 650.0;
    const freqRange = maxFreq - minFreq;

    // Calculate current frequency position
    final currentPos = ((frequency - minFreq) / freqRange) * size.width;

    // Draw marks every 10 MHz (major) and every 1 MHz (minor visible only near current)
    for (double freq = minFreq; freq <= maxFreq; freq += 10) {
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

      // Distance from current position
      final distanceFromCurrent = (position - currentPos).abs();

      if (isMajor && distanceFromCurrent > 40) {
        // Draw major frequency labels (only if far from current)
        textPainter.text = TextSpan(
          text: freq.toInt().toString(),
          style: const TextStyle(
            color: Color(0xFF00ff88),
            fontSize: 12,
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

    // Draw fine marks (0.1 MHz increments) only near current frequency
    // Show range: current - 2.0 MHz to current + 2.0 MHz (with fade effect)
    for (double freq = frequency - 2.0; freq <= frequency + 2.0; freq += 0.1) {
      if (freq < minFreq || freq > maxFreq) continue;

      final position = ((freq - minFreq) / freqRange) * size.width;
      final distanceFromCurrent = (freq - frequency).abs();

      // Fade effect based on distance (stronger fade as you go further)
      final opacity = (1.0 - (distanceFromCurrent / 2.0)).clamp(0.0, 1.0);

      if (opacity > 0.05) {
        // Draw the tick mark
        final tickHeight = distanceFromCurrent < 0.5 ? 25.0 : 22.0;
        canvas.drawLine(
          Offset(position, size.height - tickHeight),
          Offset(position, size.height - 20),
          Paint()
            ..color = Color(0xFF888888).withOpacity(opacity * 0.7)
            ..strokeWidth = 1,
        );

        // Draw frequency label for every 0.5 MHz near current
        if (freq % 0.5 == 0 &&
            distanceFromCurrent <= 1.5 &&
            distanceFromCurrent > 0.2) {
          textPainter.text = TextSpan(
            text: freq.toStringAsFixed(1),
            style: TextStyle(
              color: Color(0xFF888888).withOpacity(opacity * 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(position - textPainter.width / 2, size.height - 60),
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
    for (int freq = 350; freq <= 650; freq += 50) {
      double angle = ((freq - 350) / 300) * 2 * math.pi - math.pi / 2;

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

    for (int freq = 350; freq <= 650; freq += 10) {
      if ((freq - 350) % 50 != 0) {
        // Skip major marks
        double angle = ((freq - 350) / 300) * 2 * math.pi - math.pi / 2;

        double x1 = center.dx + (radius - 6) * math.cos(angle);
        double y1 = center.dy + (radius - 6) * math.sin(angle);
        double x2 = center.dx + radius * math.cos(angle);
        double y2 = center.dy + radius * math.sin(angle);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), minorMarkPaint);
      }
    }

    // Draw current frequency indicator
    double currentAngle = ((frequency - 350) / 300) * 2 * math.pi - math.pi / 2;

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
