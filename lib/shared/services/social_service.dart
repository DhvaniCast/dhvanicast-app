import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/api_endpoints.dart';

class SocialService {
  static String get baseUrl => '${ApiEndpoints.baseUrl}/social';

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

  /// Get received friend requests
  Future<List<Map<String, dynamic>>> getReceivedRequests() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/friends/requests/received'),
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
      print('❌ [FRIEND] Error fetching requests: $e');
      throw Exception('Failed to fetch friend requests: $e');
    }
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

  /// Get friends list
  Future<List<Map<String, dynamic>>> getFriendsList() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/friends'),
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
        throw Exception(error['message'] ?? 'Failed to fetch friends');
      }
    } catch (e) {
      print('❌ [FRIEND] Error fetching friends: $e');
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
    } catch (e) {
      print('❌ [FRIEND] Error removing friend: $e');
      throw Exception('Failed to remove friend: $e');
    }
  }
}
