class ApiEndpoints {
  // Base URL - Update this according to your backend
  static const String baseUrl =
      'http://10.0.2.2:5000/api'; // For Android Emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // For iOS Simulator
  // static const String baseUrl = 'http://192.168.1.100:5000/api'; // For Physical Device

  // Authentication Endpoints
  static const String register = '$baseUrl/auth/register';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String profile = '$baseUrl/auth/profile';
  static const String updateProfile = '$baseUrl/auth/profile';
  static const String logout = '$baseUrl/auth/logout';

  // Health Check
  static const String health = 'http://10.0.2.2:5000/health';

  // API Documentation
  static const String apiDocs = 'http://10.0.2.2:5000/api-docs';
}
