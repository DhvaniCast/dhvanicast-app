import '../../../data/models/user.dart';
import '../../../data/models/api_response.dart';

// Auth States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String mobile;
  final String userId;
  final DateTime expiresAt;
  final String message;

  AuthOtpSent({
    required this.mobile,
    required this.userId,
    required this.expiresAt,
    required this.message,
  });
}

class AuthSuccess extends AuthState {
  final User user;
  final String token;
  final String message;

  AuthSuccess({required this.user, required this.token, required this.message});
}

class AuthProfileLoaded extends AuthState {
  final User user;

  AuthProfileLoaded({required this.user});
}

class AuthError extends AuthState {
  final String message;
  final String? field;
  final List<ApiError>? errors;
  final int? statusCode;

  AuthError({required this.message, this.field, this.errors, this.statusCode});

  // Check if error is related to network
  bool get isNetworkError => statusCode == 0;

  // Check if error is related to authentication
  bool get isAuthError => statusCode == 401;

  // Check if error is related to validation
  bool get isValidationError => statusCode == 400 && errors != null;

  // Get user-friendly error message
  String get userFriendlyMessage {
    if (isNetworkError) {
      return 'No internet connection. Please check your network.';
    } else if (isAuthError) {
      return 'Session expired. Please login again.';
    } else if (isValidationError && errors != null && errors!.isNotEmpty) {
      return errors!.map((e) => e.message).join('\n');
    }
    return message;
  }
}

class AuthLoggedOut extends AuthState {
  final String message;

  AuthLoggedOut({this.message = 'Logged out successfully'});
}
