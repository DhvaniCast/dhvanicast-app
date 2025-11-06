import '../models/api_response.dart';
import '../models/user.dart';
import '../shared/constants/api_endpoints.dart';
import '../shared/services/http_client.dart';

class AuthService {
  final HttpClient _httpClient = HttpClient();

  /// Register a new user
  ///
  /// [name] - Full name of the user
  /// [mobile] - 10-digit mobile number
  /// [state] - State name
  ///
  /// Returns [ApiResponse<OtpResponse>] with OTP details
  Future<ApiResponse<OtpResponse>> register({
    required String name,
    required String mobile,
    required String state,
  }) async {
    try {
      final response = await _httpClient.post<OtpResponse>(
        ApiEndpoints.register,
        body: {
          'name': name.trim(),
          'mobile': mobile.trim(),
          'state': state.trim(),
        },
        fromJson: (json) => OtpResponse.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Send OTP for login
  ///
  /// [mobile] - 10-digit mobile number
  ///
  /// Returns [ApiResponse<OtpResponse>] with OTP details
  Future<ApiResponse<OtpResponse>> sendOtpForLogin({
    required String mobile,
  }) async {
    try {
      final response = await _httpClient.post<OtpResponse>(
        ApiEndpoints.sendOtp,
        body: {'mobile': mobile.trim()},
        fromJson: (json) => OtpResponse.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP and complete login/registration
  ///
  /// [mobile] - 10-digit mobile number
  /// [otp] - 6-digit OTP code
  ///
  /// Returns [ApiResponse<AuthResponse>] with JWT token and user details
  Future<ApiResponse<AuthResponse>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await _httpClient.post<AuthResponse>(
        ApiEndpoints.verifyOtp,
        body: {'mobile': mobile.trim(), 'otp': otp.trim()},
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      // Set the auth token for future requests
      if (response.success && response.data != null) {
        _httpClient.setAuthToken(response.data!.token);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user profile
  ///
  /// Requires authentication token
  ///
  /// Returns [ApiResponse<User>] with user details
  Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await _httpClient.get<User>(
        ApiEndpoints.profile,
        fromJson: (json) => User.fromJson(json['user'] ?? json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  ///
  /// [name] - Optional new name
  /// [state] - Optional new state
  ///
  /// Requires authentication token
  ///
  /// Returns [ApiResponse<User>] with updated user details
  Future<ApiResponse<User>> updateProfile({String? name, String? state}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        body['name'] = name.trim();
      }
      if (state != null && state.trim().isNotEmpty) {
        body['state'] = state.trim();
      }

      final response = await _httpClient.put<User>(
        ApiEndpoints.updateProfile,
        body: body,
        fromJson: (json) => User.fromJson(json['user'] ?? json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  ///
  /// Returns [ApiResponse<void>] with logout status
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _httpClient.post<void>(
        ApiEndpoints.logout,
        fromJson: null,
      );

      // Clear the auth token from http client
      _httpClient.clearAuthToken();

      return response;
    } catch (e) {
      // Even if API call fails, clear local token
      _httpClient.clearAuthToken();
      rethrow;
    }
  }

  /// Set authentication token
  ///
  /// [token] - JWT token
  void setAuthToken(String token) {
    _httpClient.setAuthToken(token);
  }

  /// Check if backend server is healthy
  ///
  /// Returns true if server is running
  Future<bool> checkServerHealth() async {
    return await _httpClient.checkHealth();
  }

  /// Validate mobile number format
  ///
  /// Returns true if mobile number is valid (10 digits)
  bool isValidMobile(String mobile) {
    final cleanMobile = mobile.trim().replaceAll(RegExp(r'\D'), '');
    return cleanMobile.length == 10 &&
        RegExp(r'^[0-9]{10}$').hasMatch(cleanMobile);
  }

  /// Validate OTP format
  ///
  /// Returns true if OTP is valid (6 digits)
  bool isValidOtp(String otp) {
    final cleanOtp = otp.trim().replaceAll(RegExp(r'\D'), '');
    return cleanOtp.length == 6 && RegExp(r'^[0-9]{6}$').hasMatch(cleanOtp);
  }

  /// Validate name format
  ///
  /// Returns true if name is valid (2-50 characters, letters and spaces only)
  bool isValidName(String name) {
    final trimmedName = name.trim();
    return trimmedName.length >= 2 &&
        trimmedName.length <= 50 &&
        RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedName);
  }

  /// Clean mobile number (remove non-digits)
  ///
  /// Returns cleaned mobile number
  String cleanMobileNumber(String mobile) {
    return mobile.replaceAll(RegExp(r'\D'), '');
  }

  /// Format mobile number for display
  ///
  /// Returns formatted mobile number (e.g., +91 98765 43210)
  String formatMobile(String mobile) {
    final cleanMobile = cleanMobileNumber(mobile);
    if (cleanMobile.length == 10) {
      return '+91 ${cleanMobile.substring(0, 5)} ${cleanMobile.substring(5)}';
    }
    return mobile;
  }
}
