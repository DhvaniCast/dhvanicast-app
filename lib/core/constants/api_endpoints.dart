// Environment enum
enum Environment { local, production }

class ApiEndpoints {
  // =====================================================
  // 🌍 ENVIRONMENT CONFIGURATION
  // =====================================================
  // ⚡ Change this line to switch between LOCAL and PRODUCTION
  // static const Environment _currentEnvironment = Environment.production; // Production (Render.com)
  static const Environment _currentEnvironment =
      Environment.local; // Local Testing

  // Environment URLs
  static String get baseUrl {
    switch (_currentEnvironment) {
      case Environment.local:
        // return 'http://10.0.2.2:5000/api'; // Android Emulator
        return 'http://localhost:5000/api'; // Real Device (use your computer's IP for real device)
      // return 'http://192.168.1.X:5000/api'; // Replace X with your computer's IP
      case Environment.production:
        return 'https://dhvani-cast-radio-backend.onrender.com/api';
    }
  }

  static String get socketUrl {
    switch (_currentEnvironment) {
      case Environment.local:
        // return 'http://10.0.2.2:5000'; // Android Emulator
        return 'http://localhost:5000'; // Real Device (use your computer's IP for real device)
      // return 'http://192.168.1.X:5000'; // Replace X with your computer's IP
      case Environment.production:
        return 'https://dhvani-cast-radio-backend.onrender.com';
    }
  }

  // Environment info
  static bool get isProduction => _currentEnvironment == Environment.production;
  static bool get isLocal => _currentEnvironment == Environment.local;
  static String get environmentName =>
      _currentEnvironment.toString().split('.').last.toUpperCase();

  // Authentication Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get profile => '$baseUrl/auth/profile';
  static String get updateProfile => '$baseUrl/auth/profile';
  static String get logout => '$baseUrl/auth/logout';

  // Frequency Endpoints
  static String get frequencies => '$baseUrl/frequencies';
  static String frequencyById(String id) => '$baseUrl/frequencies/$id';
  static String get popularFrequencies => '$baseUrl/frequencies/popular';
  static String frequenciesByBand(String band) =>
      '$baseUrl/frequencies/band/$band';
  static String joinFrequency(String id) => '$baseUrl/frequencies/$id/join';
  static String leaveFrequency(String id) => '$baseUrl/frequencies/$id/leave';
  static String frequencyStats(String id) => '$baseUrl/frequencies/$id/stats';
  static String get searchFrequencies => '$baseUrl/frequencies/search';

  // Group Endpoints
  static String get groups => '$baseUrl/groups';
  static String groupById(String id) => '$baseUrl/groups/$id';
  static String joinGroup(String id) => '$baseUrl/groups/$id/join';
  static String leaveGroup(String id) => '$baseUrl/groups/$id/leave';
  static String inviteToGroup(String id) => '$baseUrl/groups/$id/invite';
  static String updateMemberRole(String id) =>
      '$baseUrl/groups/$id/members/role';
  static String removeMember(String id) => '$baseUrl/groups/$id/members/remove';
  static String groupStats(String id) => '$baseUrl/groups/$id/stats';
  static String get searchGroups => '$baseUrl/groups/search';

  // Communication/Message Endpoints
  static String get messages => '$baseUrl/communication/messages';
  static String get sendMessage => '$baseUrl/communication/send';
  static String addReaction(String id) => '$baseUrl/communication/$id/reaction';
  static String removeReaction(String id) =>
      '$baseUrl/communication/$id/reaction';
  static String deleteMessage(String id) => '$baseUrl/communication/$id';
  static String get forwardMessage => '$baseUrl/communication/forward';
  static String get searchMessages => '$baseUrl/communication/search';
  static String get messageStats => '$baseUrl/communication/stats';
  static String get unreadCount => '$baseUrl/communication/unread';
  static String get markAsRead => '$baseUrl/communication/mark-read';

  // Health Check
  static String get health {
    switch (_currentEnvironment) {
      case Environment.local:
        return 'http://10.0.2.2:5000/health';
      case Environment.production:
        return 'https://dhvani-cast-radio-backend.onrender.com/health';
    }
  }

  // API Documentation
  static String get apiDocs {
    switch (_currentEnvironment) {
      case Environment.local:
        return 'http://10.0.2.2:5000/api-docs';
      case Environment.production:
        return 'https://dhvani-cast-radio-backend.onrender.com/api-docs';
    }
  }

  static String get socketDocs => '$baseUrl/docs/socket';
}
