import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/api_endpoints.dart';
import '../../../shared/services/ios_iap_service.dart';

class PrivateFrequencyService {
  static String get baseUrl => '${ApiEndpoints.baseUrl}/private-frequencies';

  // Get auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Changed from 'authToken' to 'token'
  }

  // Create Razorpay order
  Future<Map<String, dynamic>> createPaymentOrder() async {
    try {
      final token = await _getToken();
      print(
        '🔑 Auth Token: ${token != null ? "Found (${token.substring(0, 20)}...)" : "NOT FOUND"}',
      );

      if (token == null) {
        throw Exception('Authentication required');
      }

      print('📡 Calling create-order API: $baseUrl/create-order');
      final response = await http.post(
        Uri.parse('$baseUrl/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create payment order');
      }
    } catch (e) {
      print('❌ Payment Order Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Verify payment and create frequency
  Future<Map<String, dynamic>> verifyPaymentAndCreate({
    required String orderId,
    required String paymentId,
    required String signature,
    required String password,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create frequency');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Verify iOS IAP and create frequency
  Future<Map<String, dynamic>> verifyIosIapAndCreate({
    required String receiptData,
    required String transactionId,
    required String password,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('📡 Calling iOS IAP verify API: $baseUrl/create-ios');
      final response = await http.post(
        Uri.parse('$baseUrl/create-ios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'receiptData': receiptData,
          'transactionId': transactionId,
          'password': password,
        }),
      );

      print('📥 iOS IAP Response Status: ${response.statusCode}');
      print('📥 iOS IAP Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create frequency');
      }
    } catch (e) {
      print('❌ iOS IAP Verification Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Join private frequency
  Future<Map<String, dynamic>> joinFrequency({
    required String frequencyNumber,
    required String password,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'frequencyNumber': frequencyNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to join frequency');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get private frequency details
  Future<Map<String, dynamic>> getFrequencyDetails(
    String frequencyNumber,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$frequencyNumber'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get frequency details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Leave private frequency
  Future<void> leaveFrequency(String frequencyNumber) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$frequencyNumber/leave'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to leave frequency');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get my created frequencies
  Future<List<Map<String, dynamic>>> getMyFrequencies() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/my/frequencies'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['frequencies']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get frequencies');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
