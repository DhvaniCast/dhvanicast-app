import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/api_endpoints.dart';

class SocialService {
  static String get baseUrl => '${ApiEndpoints.baseUrl}/social';

  // Cache for friends list
  static List<Map<String, dynamic>>? _cachedFriendsList;
  static DateTime? _friendsListCacheTime;
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  // Cache for friend requests
  static List<Map<String, dynamic>>? _cachedFriendRequests;
  static DateTime? _friendRequestsCacheTime;

  // Prevent multiple simultaneous requests
  static bool _isFetchingFriends = false;
  static bool _isFetchingRequests = false;

  // Get auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ===================== REPORT APIs =====================

  /// Submit a report against a user or frequency
  Future<Map<String, dynamic>> submitReport({
    String? reportedUserId,
    required String reason,
    String? details,
    String? frequency,
    String? frequencyName,
    String? reportType, // 'user' or 'frequency'
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Determine report type
      final type =
          reportType ?? (reportedUserId != null ? 'user' : 'frequency');

      print('📡 [REPORT] Submitting $type report');
      if (reportedUserId != null) {
        print('📡 [REPORT] Reported user: $reportedUserId');
      }
      if (frequency != null) {
        print('📡 [REPORT] Frequency: $frequency - $frequencyName');
      }
      print('📡 [REPORT] Reason: $reason');

      final body = <String, dynamic>{
        'reportType': type,
        'reason': reason,
        'details': details ?? '',
      };

      // Add fields based on report type
      if (type == 'user' && reportedUserId != null) {
        body['reportedUserId'] = reportedUserId;
      }
      if (frequency != null) {
        body['frequency'] = frequency;
      }
      if (frequencyName != null) {
        body['frequencyName'] = frequencyName;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('📥 [REPORT] Response Status: ${response.statusCode}');
      print('📥 [REPORT] Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit report');
      }
    } catch (e) {
      print('❌ [REPORT] Error: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  // ===================== FRIEND REQUEST APIs =====================

  /// Send friend request
  Future<Map<String, dynamic>> sendFriendRequest({
    required String receiverId,
    String? message,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('📡 [FRIEND] Sending friend request to: $receiverId');

      final response = await http.post(
        Uri.parse('$baseUrl/friends/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'receiverId': receiverId, 'message': message ?? ''}),
      );

      print('📥 [FRIEND] Response Status: ${response.statusCode}');
      print('📥 [FRIEND] Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to send friend request');
      }
    } catch (e) {
      print('❌ [FRIEND] Error: $e');
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Get received friend requests with caching
  Future<List<Map<String, dynamic>>> getReceivedRequests({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid
    if (!forceRefresh &&
        _cachedFriendRequests != null &&
        _friendRequestsCacheTime != null &&
        DateTime.now().difference(_friendRequestsCacheTime!) <
            _cacheValidDuration) {
      print('✅ [FRIEND] Returning cached friend requests');
      return _cachedFriendRequests!;
    }

    if (_isFetchingRequests) {
      print('⏳ [FRIEND] Already fetching requests, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_cachedFriendRequests != null) {
        return _cachedFriendRequests!;
      }
    }

    _isFetchingRequests = true;

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/friends/requests/received'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final requests = List<Map<String, dynamic>>.from(data['data']);

            _cachedFriendRequests = requests;
            _friendRequestsCacheTime = DateTime.now();

            _isFetchingRequests = false;
            return requests;
          } else if (response.statusCode == 429) {
            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(Duration(milliseconds: 1000 * retryCount));
              continue;
            }
            if (_cachedFriendRequests != null) {
              _isFetchingRequests = false;
              return _cachedFriendRequests!;
            }
            throw Exception(
              'Rate limit exceeded. Please try again in a moment.',
            );
          } else {
            final error = json.decode(response.body);
            throw Exception(error['message'] ?? 'Failed to fetch requests');
          }
        } on http.ClientException catch (e) {
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            continue;
          }
          if (_cachedFriendRequests != null) {
            _isFetchingRequests = false;
            return _cachedFriendRequests!;
          }
          rethrow;
        }
      }

      if (_cachedFriendRequests != null) {
        _isFetchingRequests = false;
        return _cachedFriendRequests!;
      }

      throw Exception('Failed to fetch requests after multiple attempts');
    } catch (e) {
      print('❌ [FRIEND] Error fetching requests: $e');
      _isFetchingRequests = false;

      if (_cachedFriendRequests != null) {
        return _cachedFriendRequests!;
      }

      throw Exception('Failed to fetch friend requests: $e');
    }
  }

  /// Clear cache (call after accepting/rejecting requests or removing friends)
  static void clearCache() {
    _cachedFriendsList = null;
    _friendsListCacheTime = null;
    _cachedFriendRequests = null;
    _friendRequestsCacheTime = null;
    print('🗑️ [FRIEND] Cache cleared');
  }

  /// Get sent friend requests
  Future<List<Map<String, dynamic>>> getSentRequests() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/friends/requests/sent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch requests');
      }
    } catch (e) {
      print('❌ [FRIEND] Error fetching sent requests: $e');
      throw Exception('Failed to fetch sent requests: $e');
    }
  }

  /// Accept friend request
  Future<Map<String, dynamic>> acceptFriendRequest(String requestId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/friends/request/$requestId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        clearCache(); // Clear cache to fetch fresh data
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to accept request');
      }
    } catch (e) {
      print('❌ [FRIEND] Error accepting request: $e');
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Reject friend request
  Future<Map<String, dynamic>> rejectFriendRequest(String requestId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/friends/request/$requestId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        clearCache(); // Clear cache to fetch fresh data
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reject request');
      }
    } catch (e) {
      print('❌ [FRIEND] Error rejecting request: $e');
      throw Exception('Failed to reject friend request: $e');
    }
  }

  /// Get friends list with caching and retry logic
  Future<List<Map<String, dynamic>>> getFriendsList({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh &&
        _cachedFriendsList != null &&
        _friendsListCacheTime != null &&
        DateTime.now().difference(_friendsListCacheTime!) <
            _cacheValidDuration) {
      print('✅ [FRIEND] Returning cached friends list');
      return _cachedFriendsList!;
    }

    // Prevent multiple simultaneous requests
    if (_isFetchingFriends) {
      print('⏳ [FRIEND] Already fetching friends, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_cachedFriendsList != null) {
        return _cachedFriendsList!;
      }
    }

    _isFetchingFriends = true;

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Retry logic with exponential backoff
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/friends'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final friendsList = List<Map<String, dynamic>>.from(data['data']);

            // Update cache
            _cachedFriendsList = friendsList;
            _friendsListCacheTime = DateTime.now();

            print('✅ [FRIEND] Fetched ${friendsList.length} friends');
            _isFetchingFriends = false;
            return friendsList;
          } else if (response.statusCode == 429) {
            // Rate limit error - wait and retry
            retryCount++;
            if (retryCount < maxRetries) {
              final waitTime = Duration(milliseconds: 1000 * retryCount);
              print(
                '⏳ [FRIEND] Rate limited, retrying in ${waitTime.inMilliseconds}ms...',
              );
              await Future.delayed(waitTime);
              continue;
            }
            // If we have cached data, return it even if expired
            if (_cachedFriendsList != null) {
              print('✅ [FRIEND] Returning stale cache due to rate limit');
              _isFetchingFriends = false;
              return _cachedFriendsList!;
            }
            throw Exception(
              'Rate limit exceeded. Please try again in a moment.',
            );
          } else {
            final error = json.decode(response.body);
            throw Exception(error['message'] ?? 'Failed to fetch friends');
          }
        } on http.ClientException catch (e) {
          print('❌ [FRIEND] Network error: $e');
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            continue;
          }
          if (_cachedFriendsList != null) {
            print('✅ [FRIEND] Returning cached data due to network error');
            _isFetchingFriends = false;
            return _cachedFriendsList!;
          }
          rethrow;
        }
      }

      if (_cachedFriendsList != null) {
        print('✅ [FRIEND] Returning cached data after retries exhausted');
        _isFetchingFriends = false;
        return _cachedFriendsList!;
      }

      throw Exception('Failed to fetch friends after multiple attempts');
    } catch (e) {
      print('❌ [FRIEND] Error fetching friends: $e');
      _isFetchingFriends = false;

      if (_cachedFriendsList != null) {
        print('✅ [FRIEND] Returning cached data due to error');
        return _cachedFriendsList!;
      }

      throw Exception('Failed to fetch friends list: $e');
    }
  }

  /// Remove friend
  Future<void> removeFriend(String friendId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/friends/$friendId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to remove friend');
      }

      clearCache(); // Clear cache to fetch fresh data
    } catch (e) {
      print('❌ [FRIEND] Error removing friend: $e');
      throw Exception('Failed to remove friend: $e');
    }
  }
}
