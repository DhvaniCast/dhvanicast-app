import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/frequency_repository.dart';
import '../../core/group_repository.dart';
import '../../core/websocket_client.dart';
import '../../models/frequency_model.dart';
import '../../models/group_model.dart';

class DialerService extends ChangeNotifier {
  final FrequencyRepository _frequencyRepo = FrequencyRepository();
  final GroupRepository _groupRepo = GroupRepository();
  final WebSocketClient _socketClient = WebSocketClient();

  List<FrequencyModel> _frequencies = [];
  List<GroupModel> _groups = [];
  FrequencyModel? _currentFrequency;
  bool _isLoading = false;
  String? _error;
  Timer? _connectionCheckTimer;

  DialerService() {
    _setupAutomaticSocketListeners();
    _startConnectionHealthCheck();
  }

  /// Start periodic connection health check
  void _startConnectionHealthCheck() {
    // Check connection every 30 seconds
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) {
      if (kDebugMode) {
        print('🏥 [HEALTH-CHECK] Checking socket connection...');
      }
      _socketClient.ensureConnection();
    });
  }

  /// Setup automatic WebSocket listeners for frequency updates
  void _setupAutomaticSocketListeners() {
    print('🔧 [DIALER-SERVICE] ====== SETTING UP WEBSOCKET LISTENERS ======');

    // Listen for user joined frequency
    _socketClient.on('user_joined_frequency', (data) {
      try {
        print('🔔 [WS] ====== USER_JOINED_FREQUENCY EVENT ======');
        print('🔔 [WS] Raw data: $data');

        final frequencyId = data['frequency']?['id'];
        final frequencyValue = data['frequency']?['frequency'];
        final user = data['user'];

        print('🔔 [WS] Frequency ID: $frequencyId');
        print('🔔 [WS] Frequency Value: $frequencyValue MHz');
        print('🔔 [WS] User Data: $user');

        if (frequencyId != null) {
          print('🔔 [WS] User joined frequency: $frequencyValue MHz');
          print('🔔 [WS] Refreshing frequencies to get updated user list...');

          // Refresh frequencies to get updated user counts
          loadFrequencies(forceRefresh: true).then((_) {
            print('✅ [WS] Frequencies refreshed after user join');
          });
        } else {
          print('⚠️ [WS] No frequency ID in event data');
        }
      } catch (e) {
        print('❌ [WS] Error processing user_joined_frequency: $e');
        if (kDebugMode) {
          print('Error processing user_joined_frequency: $e');
        }
      }
    });

    // Listen for user left frequency
    _socketClient.on('user_left_frequency', (data) {
      try {
        print('🔔 [WS] ====== USER_LEFT_FREQUENCY EVENT ======');
        print('🔔 [WS] Raw data: $data');

        final frequencyId = data['frequency']?['id'];
        final frequencyValue = data['frequency']?['frequency'];
        final userId = data['userId'];

        print('🔔 [WS] Frequency ID: $frequencyId');
        print('🔔 [WS] Frequency Value: $frequencyValue MHz');
        print('🔔 [WS] User ID who left: $userId');

        if (frequencyId != null) {
          print('🔔 [WS] User left frequency: $frequencyValue MHz');

          // First, immediately remove the user from local state
          final frequencyIndex = _frequencies.indexWhere(
            (f) => f.id == frequencyId,
          );

          if (frequencyIndex != -1) {
            final frequency = _frequencies[frequencyIndex];

            // Remove the user from active users list
            final updatedActiveUsers = frequency.activeUsers
                .where((user) => user.userId != userId)
                .toList();

            print(
              '🔔 [WS] Before removal: ${frequency.activeUsers.length} users',
            );
            print('🔔 [WS] After removal: ${updatedActiveUsers.length} users');

            // Create a new FrequencyModel with updated users
            _frequencies[frequencyIndex] = FrequencyModel(
              id: frequency.id,
              frequency: frequency.frequency,
              name: frequency.name,
              description: frequency.description,
              band: frequency.band,
              isPublic: frequency.isPublic,
              isActive: frequency.isActive,
              createdBy: frequency.createdBy,
              activeUsers: updatedActiveUsers,
              userCount: updatedActiveUsers.length,
              createdAt: frequency.createdAt,
              updatedAt: frequency.updatedAt,
              currentTransmitter: frequency.currentTransmitter,
            );

            print('✅ [WS] Removed user $userId from frequency active users');
            notifyListeners(); // Notify UI to update immediately
          }

          // Then refresh from server to ensure consistency
          print('🔔 [WS] Refreshing frequencies from server...');
          loadFrequencies(forceRefresh: true).then((_) {
            print('✅ [WS] Frequencies refreshed after user left');
          });
        } else {
          print('⚠️ [WS] No frequency ID in event data');
        }
      } catch (e) {
        print('❌ [WS] Error processing user_left_frequency: $e');
        if (kDebugMode) {
          print('Error processing user_left_frequency: $e');
        }
      }
    });

    // Listen for global frequency updates (for active channels list)
    _socketClient.on('frequency_updated', (data) {
      try {
        print('🔔 [WS] ====== FREQUENCY_UPDATED EVENT ======');
        print('🔔 [WS] Raw data: $data');

        final frequencyId = data['frequencyId'];
        final frequencyValue = data['frequency'];
        final currentUsers = data['currentUsers'];

        print('🔔 [WS] Frequency ID: $frequencyId');
        print('🔔 [WS] Frequency Value: $frequencyValue MHz');
        print('🔔 [WS] Current Users: $currentUsers');

        if (frequencyId != null) {
          print('🔔 [WS] Global update for frequency: $frequencyValue MHz');
          print(
            '🔔 [WS] Refreshing frequencies to update active channels list...',
          );

          // Refresh frequencies to get updated user counts and active channels
          loadFrequencies(forceRefresh: true).then((_) {
            print('✅ [WS] Frequencies refreshed after global update');
          });
        }
      } catch (e) {
        print('❌ [WS] Error processing frequency_updated: $e');
        if (kDebugMode) {
          print('Error processing frequency_updated: $e');
        }
      }
    });

    print('✅ [DIALER-SERVICE] Automatic WebSocket listeners setup complete');
  }

  // Getters
  List<FrequencyModel> get frequencies => _frequencies;
  List<GroupModel> get groups => _groups;
  FrequencyModel? get currentFrequency => _currentFrequency;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Filter out users who have been inactive for more than the threshold
  /// This helps remove stale/disconnected users that backend hasn't cleaned up yet
  List<FrequencyModel> _filterStaleUsers(
    List<FrequencyModel> frequencies, {
    Duration threshold = const Duration(minutes: 10),
  }) {
    final now = DateTime.now();
    print('🧹 [FILTER] ====== FILTERING STALE USERS ======');
    print('🧹 [FILTER] Threshold: ${threshold.inMinutes} minutes');
    print('🧹 [FILTER] Total frequencies to check: ${frequencies.length}');

    return frequencies.map((freq) {
      if (freq.activeUsers.isEmpty) {
        return freq;
      }

      final originalCount = freq.activeUsers.length;
      final filteredUsers = freq.activeUsers.where((user) {
        final timeSinceJoined = now.difference(user.joinedAt);
        final isStale = timeSinceJoined > threshold;

        if (isStale) {
          print(
            '🗑️ [FILTER] Removing stale user: ${user.userName ?? user.userId}',
          );
          print('🗑️ [FILTER]   Joined: ${user.joinedAt.toIso8601String()}');
          print(
            '🗑️ [FILTER]   Time since join: ${timeSinceJoined.inMinutes} min',
          );
        }
        return !isStale;
      }).toList();

      if (filteredUsers.length < originalCount) {
        print(
          '✂️ [FILTER] ${freq.frequency} MHz: Removed ${originalCount - filteredUsers.length} stale users',
        );
        return FrequencyModel(
          id: freq.id,
          frequency: freq.frequency,
          name: freq.name,
          description: freq.description,
          band: freq.band,
          isPublic: freq.isPublic,
          isActive: freq.isActive,
          createdBy: freq.createdBy,
          activeUsers: filteredUsers,
          userCount: filteredUsers.length,
          createdAt: freq.createdAt,
          updatedAt: freq.updatedAt,
          currentTransmitter: freq.currentTransmitter,
        );
      }

      return freq;
    }).toList();
  }

  /// Load all frequencies
  Future<void> loadFrequencies({
    String? band,
    bool? isPublic,
    bool? hasActiveUsers, // NEW: Filter for active frequencies
    bool forceRefresh = false, // NEW: Force refresh to bypass cache
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _frequencyRepo.getAllFrequencies(
        band: band,
        isPublic: isPublic ?? true,
        page: 1,
        limit: 100, // Reduced from 500 to 100 for faster initial load
        hasActiveUsers: hasActiveUsers,
        forceRefresh: forceRefresh,
      );

      if (response.success && response.data != null) {
        // Filter out stale/disconnected users before storing
        _frequencies = _filterStaleUsers(response.data!);
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load frequencies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load popular frequencies
  Future<void> loadPopularFrequencies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _frequencyRepo.getPopularFrequencies(limit: 20);

      if (response.success && response.data != null) {
        _frequencies = response.data!;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load popular frequencies: $e';
      if (kDebugMode) {
        print('Error loading popular frequencies: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter out offline/inactive members from groups
  /// This helps remove stale/disconnected users from group member lists
  List<GroupModel> _filterOfflineGroupMembers(List<GroupModel> groups) {
    print('🧹 [GROUP-FILTER] ====== FILTERING OFFLINE MEMBERS ======');
    print('🧹 [GROUP-FILTER] Total groups to check: ${groups.length}');

    return groups.map((group) {
      if (group.members.isEmpty) {
        return group;
      }

      final originalCount = group.members.length;
      // Only keep online members
      final onlineMembers = group.members.where((member) {
        if (!member.isOnline) {
          print(
            '🗑️ [GROUP-FILTER] Removing offline member: ${member.userName ?? member.userId}',
          );
        }
        return member.isOnline;
      }).toList();

      if (onlineMembers.length < originalCount) {
        print(
          '✂️ [GROUP-FILTER] ${group.name}: Removed ${originalCount - onlineMembers.length} offline members',
        );
        return GroupModel(
          id: group.id,
          name: group.name,
          description: group.description,
          avatar: group.avatar,
          owner: group.owner,
          members: onlineMembers,
          frequencyId: group.frequencyId,
          settings: group.settings,
          isActive: group.isActive,
          createdAt: group.createdAt,
          updatedAt: group.updatedAt,
          onlineCount: onlineMembers.length,
          totalMembers: group.totalMembers,
        );
      }

      return group;
    }).toList();
  }

  /// Load user's groups
  Future<void> loadUserGroups() async {
    // Check if user is logged in before making API call
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      // User is logged out, silently return without error
      if (kDebugMode) {
        print('ℹ️ DialerService: Skipping loadUserGroups - user not logged in');
      }
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _groupRepo.getUserGroups(page: 1, limit: 20);

      if (response.success && response.data != null) {
        // Filter out offline members before storing
        _groups = _filterOfflineGroupMembers(response.data!);
        _error = null;

        if (kDebugMode) {
          print('✅ DialerService: Loaded ${_groups.length} groups');
        }
      } else {
        _error = response.message;
        if (kDebugMode) {
          print('❌ DialerService: Failed to load groups - ${response.message}');
        }
      }
    } catch (e) {
      _error = 'Failed to load groups: $e';
      if (kDebugMode) {
        print('❌ DialerService Error loading groups: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Join a frequency
  Future<bool> joinFrequency(
    String frequencyId, {
    Map<String, dynamic>? userInfo,
  }) async {
    try {
      print('🔗 DialerService: Joining frequency $frequencyId...');

      final response = await _frequencyRepo.joinFrequency(frequencyId);

      if (response.success && response.data != null) {
        _currentFrequency = response.data!;

        print('✅ Join API Success! Updated frequency:');
        print('   - ID: ${_currentFrequency!.id}');
        print('   - Frequency: ${_currentFrequency!.frequency} MHz');
        print('   - Current Users: ${_currentFrequency!.userCount}');
        print('   - Active Users: ${_currentFrequency!.activeUsers.length}');

        // Update the frequency in the list with new user data
        final index = _frequencies.indexWhere((f) => f.id == frequencyId);
        if (index != -1) {
          print('📝 Updating frequency in list at index $index');
          _frequencies[index] = _currentFrequency!;
        } else {
          print('➕ Adding new frequency to list');
          _frequencies.add(_currentFrequency!);
        }

        // Connect via WebSocket
        _socketClient.joinFrequency(frequencyId, userInfo: userInfo);

        notifyListeners();
        return true;
      } else {
        _error = response.message;
        print('❌ Join API Failed: ${response.message}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to join frequency: $e';
      if (kDebugMode) {
        print('Error joining frequency: $e');
      }
      notifyListeners();
      return false;
    }
  }

  /// Leave current frequency
  Future<bool> leaveFrequency(String frequencyId) async {
    try {
      final response = await _frequencyRepo.leaveFrequency(frequencyId);

      if (response.success) {
        _socketClient.leaveFrequency(frequencyId);
        _currentFrequency = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to leave frequency: $e';
      if (kDebugMode) {
        print('Error leaving frequency: $e');
      }
      notifyListeners();
      return false;
    }
  }

  /// Create new frequency
  Future<FrequencyModel?> createFrequency({
    required double frequency,
    String? name,
    String? band,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      // Determine band based on frequency if not provided (UHF: 300-3000 MHz, VHF: 30-300 MHz)
      final frequencyBand = band ?? (frequency >= 300 ? 'UHF' : 'VHF');

      final response = await _frequencyRepo.createFrequency(
        name: name ?? 'Frequency ${frequency.toStringAsFixed(1)}',
        frequency: frequency.toStringAsFixed(1),
        band: frequencyBand,
        description: description,
        isPublic: isPublic,
      );

      if (response.success && response.data != null) {
        _frequencies.add(response.data!);
        notifyListeners();
        return response.data;
      } else {
        _error = response.message;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Failed to create frequency: $e';
      if (kDebugMode) {
        print('Error creating frequency: $e');
      }
      notifyListeners();
      return null;
    }
  }

  /// Search frequencies
  Future<void> searchFrequencies(String query) async {
    if (query.isEmpty) {
      await loadFrequencies();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _frequencyRepo.searchFrequencies(query);

      if (response.success && response.data != null) {
        _frequencies = response.data!;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to search frequencies: $e';
      if (kDebugMode) {
        print('Error searching frequencies: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get frequency by specific value
  FrequencyModel? getFrequencyByValue(double frequencyValue) {
    try {
      return _frequencies.firstWhere(
        (f) => (f.frequency - frequencyValue).abs() < 0.1,
      );
    } catch (e) {
      return null;
    }
  }

  /// Load a single frequency by its ID from backend and update local state
  Future<void> loadFrequencyById(String id) async {
    print('📥 [LOAD-FREQ] Loading single frequency by ID: $id');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _frequencyRepo.getFrequencyById(id);
      if (response.success && response.data != null) {
        _currentFrequency = response.data!;

        // update or insert into _frequencies
        final index = _frequencies.indexWhere((f) => f.id == id);
        if (index != -1) {
          _frequencies[index] = _currentFrequency!;
        } else {
          _frequencies.add(_currentFrequency!);
        }

        print(
          '✅ [LOAD-FREQ] Loaded frequency ${_currentFrequency!.frequency} MHz (id: ${_currentFrequency!.id})',
        );
      } else {
        _error = response.message;
        print(
          '❌ [LOAD-FREQ] Failed to load frequency by id: ${response.message}',
        );
      }
    } catch (e) {
      _error = 'Failed to load frequency by id: $e';
      if (kDebugMode) {
        print('❌ Error loading frequency by id: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a single frequency by exact value (uses min/max filters to request a tight range)
  Future<void> loadFrequencyByValue(double frequencyValue) async {
    print('📥 [LOAD-FREQ] Loading single frequency by value: $frequencyValue');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use minFrequency and maxFrequency equal to requested value to ask server for an exact match
      final response = await _frequencyRepo.getAllFrequencies(
        page: 1,
        limit: 1,
        minFrequency: frequencyValue,
        maxFrequency: frequencyValue,
      );

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final freq = response.data!.first;
        _currentFrequency = freq;

        final index = _frequencies.indexWhere((f) => f.id == freq.id);
        if (index != -1) {
          _frequencies[index] = freq;
        } else {
          _frequencies.add(freq);
        }

        print(
          '✅ [LOAD-FREQ] Loaded frequency by value: ${freq.frequency} MHz (id: ${freq.id})',
        );
      } else {
        _error = response.message;
        print('❌ [LOAD-FREQ] Frequency not found for value $frequencyValue');
      }
    } catch (e) {
      _error = 'Failed to load frequency by value: $e';
      if (kDebugMode) {
        print('❌ Error loading frequency by value: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user count on frequency
  int getUserCountOnFrequency(double frequencyValue) {
    final freq = getFrequencyByValue(frequencyValue);
    return freq?.userCount ?? 0;
  }

  /// Setup WebSocket listeners
  void setupSocketListeners({
    Function(dynamic)? onUserJoined,
    Function(dynamic)? onUserLeft,
    Function(dynamic)? onTransmissionStarted,
    Function(dynamic)? onTransmissionStopped,
  }) {
    if (onUserJoined != null) {
      _socketClient.on('user_joined', onUserJoined);
    }
    if (onUserLeft != null) {
      _socketClient.on('user_left', onUserLeft);
    }
    if (onTransmissionStarted != null) {
      _socketClient.on('transmission_started', onTransmissionStarted);
    }
    if (onTransmissionStopped != null) {
      _socketClient.on('transmission_stopped', onTransmissionStopped);
    }
  }

  /// Dispose resources and clean up
  @override
  void dispose() {
    // Cancel health check timer
    _connectionCheckTimer?.cancel();

    // Remove socket listeners
    _socketClient.off('user_joined');
    _socketClient.off('user_left');
    _socketClient.off('transmission_started');
    _socketClient.off('transmission_stopped');

    super.dispose();
  }
}
