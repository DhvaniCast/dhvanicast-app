// Auth Events
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;

  AuthLoginRequested({required this.email});
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final int age;
  final String state;
  final String mobile;

  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.age,
    required this.state,
    required this.mobile,
  });
}

class AuthOtpVerifyRequested extends AuthEvent {
  final String email;
  final String otp;

  AuthOtpVerifyRequested({required this.email, required this.otp});
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

class AuthTemporaryDeleteRequested extends AuthEvent {}

class AuthPermanentDeleteRequested extends AuthEvent {}
