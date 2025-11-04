import 'package:flutter/foundation.dart';
import '../../data/repositories/frequency_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/network/websocket_client.dart';
import '../../data/models/frequency_model.dart';
import '../../data/models/group_model.dart';

class DialerService extends ChangeNotifier {
  final FrequencyRepository _frequencyRepo = FrequencyRepository();
  final GroupRepository _groupRepo = GroupRepository();
  final WebSocketClient _socketClient = WebSocketClient();

  List<FrequencyModel> _frequencies = [];
  List<GroupModel> _groups = [];
  FrequencyModel? _currentFrequency;
  bool _isLoading = false;
  String? _error;

  DialerService() {
    _setupAutomaticSocketListeners();
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
          loadFrequencies().then((_) {
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
          loadFrequencies().then((_) {
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

    print('✅ [DIALER-SERVICE] Automatic WebSocket listeners setup complete');
  }

  // Getters
  List<FrequencyModel> get frequencies => _frequencies;
  List<GroupModel> get groups => _groups;
  FrequencyModel? get currentFrequency => _currentFrequency;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all frequencies
  Future<void> loadFrequencies({String? band, bool? isPublic}) async {
    print('📥 [LOAD-FREQ] ====== LOADING FREQUENCIES ======');
    print('📥 [LOAD-FREQ] Band filter: $band');
    print('📥 [LOAD-FREQ] Public filter: $isPublic');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _frequencyRepo.getAllFrequencies(
        band: band,
        isPublic: isPublic ?? true,
        page: 1,
        limit: 100,
      );

      print('📥 [LOAD-FREQ] API Response:');
      print('📥 [LOAD-FREQ] - Success: ${response.success}');
      print('📥 [LOAD-FREQ] - Message: ${response.message}');
      print('📥 [LOAD-FREQ] - Data count: ${response.data?.length ?? 0}');

      if (response.success && response.data != null) {
        _frequencies = response.data!;
        _error = null;

        print('✅ [LOAD-FREQ] Loaded ${_frequencies.length} frequencies:');
        for (var freq in _frequencies) {
          print('✅ [LOAD-FREQ]   - ${freq.frequency} MHz (ID: ${freq.id})');
          print('✅ [LOAD-FREQ]     Active Users: ${freq.activeUsers.length}');
          for (var user in freq.activeUsers) {
            print(
              '✅ [LOAD-FREQ]       * ${user.userName ?? user.callSign ?? user.userId}',
            );
          }
        }
      } else {
        _error = response.message;
        print('❌ [LOAD-FREQ] Error: ${response.message}');
      }
    } catch (e) {
      _error = 'Failed to load frequencies: $e';
      print('❌ [LOAD-FREQ] Exception: $e');
      if (kDebugMode) {
        print('Error loading frequencies: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      print('📥 [LOAD-FREQ] Loading complete. isLoading: $_isLoading');
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

  /// Load user's groups
  Future<void> loadUserGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _groupRepo.getUserGroups(page: 1, limit: 50);

      if (response.success && response.data != null) {
        _groups = response.data!;
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

  /// Clean up
  void dispose() {
    _socketClient.off('user_joined');
    _socketClient.off('user_left');
    _socketClient.off('transmission_started');
    _socketClient.off('transmission_stopped');
    super.dispose();
  }
}
