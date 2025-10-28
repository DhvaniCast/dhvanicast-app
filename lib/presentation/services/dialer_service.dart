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

  // Getters
  List<FrequencyModel> get frequencies => _frequencies;
  List<GroupModel> get groups => _groups;
  FrequencyModel? get currentFrequency => _currentFrequency;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all frequencies
  Future<void> loadFrequencies({String? band, bool? isPublic}) async {
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

      if (response.success && response.data != null) {
        _frequencies = response.data!;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load frequencies: $e';
      if (kDebugMode) {
        print('Error loading frequencies: $e');
      }
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
      final response = await _frequencyRepo.joinFrequency(frequencyId);

      if (response.success && response.data != null) {
        _currentFrequency = response.data!;

        // Connect via WebSocket
        _socketClient.joinFrequency(frequencyId, userInfo: userInfo);

        notifyListeners();
        return true;
      } else {
        _error = response.message;
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
