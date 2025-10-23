// Auth Events
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String mobile;

  AuthLoginRequested({required this.mobile});
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String mobile;
  final String state;

  AuthRegisterRequested({
    required this.name,
    required this.mobile,
    required this.state,
  });
}

class AuthOtpVerifyRequested extends AuthEvent {
  final String mobile;
  final String otp;

  AuthOtpVerifyRequested({required this.mobile, required this.otp});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthTokenSetRequested extends AuthEvent {
  final String token;

  AuthTokenSetRequested({required this.token});
}

class AuthProfileRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? name;
  final String? state;

  AuthProfileUpdateRequested({this.name, this.state});
}
