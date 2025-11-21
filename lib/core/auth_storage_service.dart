import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

/// Service to handle authentication token and user data storage
/// with 30-day auto-login support
class AuthStorageService {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _loginTimestampKey = 'login_timestamp';
  static const int _autoLoginDays = 30;

  /// Save user authentication data with 30-day expiry
  static Future<bool> saveAuthData({
    required String token,
    required User user,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save token
      await prefs.setString(_tokenKey, token);

      // Save user data as JSON
      final userData = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userData);

      // Save current timestamp for expiry check
      final loginTimestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_loginTimestampKey, loginTimestamp);

      print('✅ [AuthStorage] Data saved successfully');
      print('👤 [AuthStorage] User: ${user.name}');
      print('🔑 [AuthStorage] Token: ${token.substring(0, 20)}...');
      print('📅 [AuthStorage] Login timestamp: ${DateTime.now()}');

      return true;
    } catch (e) {
      print('❌ [AuthStorage] Failed to save auth data: $e');
      return false;
    }
  }

  /// Check if user has valid saved session (within 30 days)
  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if token exists
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        print('ℹ️ [AuthStorage] No saved token found');
        return false;
      }

      // Check if user data exists
      final userData = prefs.getString(_userKey);
      if (userData == null || userData.isEmpty) {
        print('ℹ️ [AuthStorage] No saved user data found');
        return false;
      }

      // Check if login timestamp exists
      final loginTimestamp = prefs.getInt(_loginTimestampKey);
      if (loginTimestamp == null) {
        print('ℹ️ [AuthStorage] No login timestamp found');
        return false;
      }

      // Check if session is still valid (within 30 days)
      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final now = DateTime.now();
      final daysSinceLogin = now.difference(loginDate).inDays;

      if (daysSinceLogin >= _autoLoginDays) {
        print('⏰ [AuthStorage] Session expired ($daysSinceLogin days old)');
        await clearAuthData(); // Clear expired data
        return false;
      }

      print('✅ [AuthStorage] Valid session found');
      print('📅 [AuthStorage] Login date: $loginDate');
      print(
        '⏱️ [AuthStorage] Days since login: $daysSinceLogin/$_autoLoginDays',
      );

      return true;
    } catch (e) {
      print('❌ [AuthStorage] Error checking session: $e');
      return false;
    }
  }

  /// Get saved authentication token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('❌ [AuthStorage] Error getting token: $e');
      return null;
    }
  }

  /// Get saved user data
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData == null || userData.isEmpty) {
        return null;
      }

      final userMap = jsonDecode(userData) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      print('❌ [AuthStorage] Error getting user: $e');
      return null;
    }
  }

  /// Clear all authentication data
  static Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_loginTimestampKey);

      print('🗑️ [AuthStorage] All auth data cleared');

      return true;
    } catch (e) {
      print('❌ [AuthStorage] Error clearing auth data: $e');
      return false;
    }
  }

  /// Get days remaining until session expiry
  static Future<int?> getDaysRemaining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTimestamp = prefs.getInt(_loginTimestampKey);

      if (loginTimestamp == null) {
        return null;
      }

      final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final now = DateTime.now();
      final daysSinceLogin = now.difference(loginDate).inDays;

      return _autoLoginDays - daysSinceLogin;
    } catch (e) {
      print('❌ [AuthStorage] Error getting days remaining: $e');
      return null;
    }
  }
}
