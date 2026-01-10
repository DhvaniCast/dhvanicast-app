import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../core/auth_repository.dart';
import '../shared/services/http_client.dart';
import '../models/user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthOtpVerifyRequested>(_onOtpVerifyRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthTokenSetRequested>(_onTokenSetRequested);
    on<AuthProfileRequested>(_onProfileRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthTemporaryDeleteRequested>(_onTemporaryDeleteRequested);
    on<AuthPermanentDeleteRequested>(_onPermanentDeleteRequested);
  }

  // Handle login request (send OTP)
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('========== AUTH BLOC: LOGIN REQUESTED ==========');
    print('Email: ${event.email}');

    emit(AuthLoading());

    try {
      // Validate email
      if (!_authService.isValidEmail(event.email)) {
        print('ERROR: Email validation failed');
        emit(
          AuthError(
            message: 'Please enter a valid email address',
            field: 'email',
            statusCode: 400,
          ),
        );
        return;
      }

      print('Calling API to send OTP...');
      final response = await _authService.sendOtpForLogin(email: event.email);
      print('API Response - Success: ${response.success}');

      if (response.success && response.data != null) {
        print('OTP sent successfully to ${response.data!.email}');
        emit(
          AuthOtpSent(
            email: response.data!.email,
            userId: response.data!.userId,
            expiresAt: response.data!.otpExpiresAt,
            message: response.message,
          ),
        );
      } else {
        print('OTP send failed: ${response.message}');
        emit(
          AuthError(message: response.message, statusCode: response.statusCode),
        );
      }
    } on ApiException catch (e) {
      print('API Exception: ${e.userFriendlyMessage}');
      emit(
        AuthError(
          message: e.userFriendlyMessage,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      print('Unexpected error: $e');
      if (kDebugMode) {
        print('Login error: $e');
      }
      emit(
        AuthError(
          message: 'An unexpected error occurred. Please try again.',
          statusCode: 0,
        ),
      );
    }
  }

  // Handle registration request
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Validate inputs
      if (!_authService.isValidName(event.name)) {
        emit(
          AuthError(
            message:
                'Please enter a valid name (2-50 characters, letters only)',
            field: 'name',
            statusCode: 400,
          ),
        );
        return;
      }

      if (!_authService.isValidEmail(event.email)) {
        emit(
          AuthError(
            message: 'Please enter a valid email address',
            field: 'email',
            statusCode: 400,
          ),
        );
        return;
      }

      if (!_authService.isValidAge(event.age)) {
        emit(
          AuthError(
            message: 'Minimum required age is 18 years',
            field: 'age',
            statusCode: 400,
          ),
        );
        return;
      }

      if (event.state.trim().isEmpty) {
        emit(
          AuthError(
            message: 'Please enter your state',
            field: 'state',
            statusCode: 400,
          ),
        );
        return;
      }

      final response = await _authService.register(
        name: event.name,
        email: event.email,
        age: event.age,
        state: event.state,
        mobile: event.mobile,
      );

      if (response.success && response.data != null) {
        emit(
          AuthOtpSent(
            email: response.data!.email,
            userId: response.data!.userId,
            expiresAt: response.data!.otpExpiresAt,
            message: response.message,
          ),
        );
      } else {
        emit(
          AuthError(message: response.message, statusCode: response.statusCode),
        );
      }
    } on ApiException catch (e) {
      emit(
        AuthError(
          message: e.userFriendlyMessage,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      emit(
        AuthError(
          message: 'An unexpected error occurred. Please try again.',
          statusCode: 0,
        ),
      );
    }
  }

  // Handle OTP verification
  Future<void> _onOtpVerifyRequested(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('========== AUTH BLOC: OTP VERIFY REQUESTED ==========');
    print('Email: ${event.email}');

    emit(AuthLoading());

    try {
      // Validate inputs
      if (!_authService.isValidEmail(event.email)) {
        print('ERROR: Email validation failed');
        emit(
          AuthError(
            message: 'Invalid credentials',
            field: 'email',
            statusCode: 400,
          ),
        );
        return;
      }

      if (!_authService.isValidOtp(event.otp)) {
        print('ERROR: OTP validation failed');
        emit(
          AuthError(
            message: 'Invalid credentials',
            field: 'otp',
            statusCode: 400,
          ),
        );
        return;
      }

      print('Calling API to verify OTP...');
      final response = await _authService.verifyOtp(
        email: event.email,
        otp: event.otp,
      );
      print('API Response - Success: ${response.success}');

      if (response.success && response.data != null) {
        print('OTP verified successfully for ${response.data!.user.email}');
        emit(
          AuthSuccess(
            user: response.data!.user,
            token: response.data!.token,
            message: response.message,
          ),
        );
      } else {
        print('OTP verification failed: ${response.message}');
        emit(
          AuthError(
            message: 'Invalid credentials',
            statusCode: response.statusCode,
          ),
        );
      }
    } on ApiException catch (e) {
      print('API Exception: ${e.userFriendlyMessage}');
      // Don't auto-logout on 401 - just show error message
      emit(
        AuthError(
          message: e.statusCode == 401 || e.statusCode == 400
              ? 'Invalid credentials'
              : e.userFriendlyMessage,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      print('Unexpected error: $e');
      if (kDebugMode) {
        print('OTP verification error: $e');
      }
      emit(
        AuthError(
          message: 'An unexpected error occurred. Please try again.',
          statusCode: 0,
        ),
      );
    }
  }

  // Handle logout
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _authService.logout();
      emit(AuthLoggedOut());
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
      emit(AuthLoggedOut(message: 'Logged out with errors'));
    }
  }

  // Handle token setting
  Future<void> _onTokenSetRequested(
    AuthTokenSetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _authService.setAuthToken(event.token);
      // Optionally fetch user profile after setting token
      add(AuthProfileRequested());
    } catch (e) {
      if (kDebugMode) {
        print('Token set error: $e');
      }
    }
  }

  // Handle profile fetch
  Future<void> _onProfileRequested(
    AuthProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authService.getProfile();

      if (response.success && response.data != null) {
        emit(AuthProfileLoaded(user: response.data!));
      } else {
        emit(
          AuthError(message: response.message, statusCode: response.statusCode),
        );
      }
    } on ApiException catch (e) {
      emit(
        AuthError(
          message: e.userFriendlyMessage,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Profile fetch error: $e');
      }
      emit(
        AuthError(
          message: 'Failed to load profile. Please try again.',
          statusCode: 0,
        ),
      );
    }
  }

  // Handle profile update
  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Validate inputs if provided
      if (event.name != null && !_authService.isValidName(event.name!)) {
        emit(
          AuthError(
            message:
                'Please enter a valid name (2-50 characters, letters only)',
            field: 'name',
            statusCode: 400,
          ),
        );
        return;
      }

      final response = await _authService.updateProfile(
        name: event.name,
        state: event.country,
        avatar: event.avatar,
      );

      if (response.success && response.data != null) {
        emit(AuthProfileLoaded(user: response.data!));
      } else {
        emit(
          AuthError(message: response.message, statusCode: response.statusCode),
        );
      }
    } on ApiException catch (e) {
      emit(
        AuthError(
          message: e.userFriendlyMessage,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Profile update error: $e');
      }
      emit(
        AuthError(
          message: 'Failed to update profile. Please try again.',
          statusCode: 0,
        ),
      );
    }
  }

  // Handle temporary delete account request
  Future<void> _onTemporaryDeleteRequested(
    AuthTemporaryDeleteRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authService.temporaryDeleteAccount();

      if (response.success) {
        emit(AuthLoggedOut(message: response.message));
      } else {
        emit(
          AuthError(message: response.message, statusCode: response.statusCode),
        );
      }
    } on ApiException catch (e) {
      emit(
        AuthError(
          message: e.userFriendlyMessage,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Temporary delete error: $e');
      }
      emit(
        AuthError(
          message: 'Failed to deactivate account. Please try again.',
          statusCode: 0,
        ),
      );
    }
  }

  // Handle permanent delete account request
  Future<void> _onPermanentDeleteRequested(
    AuthPermanentDeleteRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final response = await _authService.permanentDeleteAccount();

      if (response.success) {
        emit(AuthLoggedOut(message: response.message));
      } else {
        emit(
          AuthError(message: response.message, statusCode: response.statusCode),
        );
      }
    } on ApiException catch (e) {
      emit(
        AuthError(
          message: e.userFriendlyMessage,
          statusCode: e.statusCode,
          errors: e.errors,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Permanent delete error: $e');
      }
      emit(
        AuthError(
          message: 'Failed to delete account. Please try again.',
          statusCode: 0,
        ),
      );
    }
  }

  // Helper method to check if user is authenticated
  bool get isAuthenticated {
    return state is AuthSuccess || state is AuthProfileLoaded;
  }

  // Helper method to get current user
  User? get currentUser {
    if (state is AuthSuccess) {
      return (state as AuthSuccess).user;
    } else if (state is AuthProfileLoaded) {
      return (state as AuthProfileLoaded).user;
    }
    return null;
  }
}
