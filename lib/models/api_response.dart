import 'user.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<ApiError>? errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'] != null
          ? (json['errors'] as List).map((e) => ApiError.fromJson(e)).toList()
          : null,
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors?.map((e) => e.toJson()).toList(),
      'statusCode': statusCode,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data, errors: $errors, statusCode: $statusCode)';
  }
}

class ApiError {
  final String field;
  final String message;
  final dynamic value;

  ApiError({required this.field, required this.message, this.value});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      field: json['field'] ?? json['param'] ?? '',
      message: json['message'] ?? json['msg'] ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'field': field, 'message': message, 'value': value};
  }

  @override
  String toString() {
    return 'ApiError(field: $field, message: $message, value: $value)';
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

class OtpResponse {
  final String userId;
  final String mobile;
  final DateTime otpExpiresAt;

  OtpResponse({
    required this.userId,
    required this.mobile,
    required this.otpExpiresAt,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      userId: json['userId'] ?? '',
      mobile: json['mobile'] ?? '',
      otpExpiresAt: DateTime.parse(json['otpExpiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mobile': mobile,
      'otpExpiresAt': otpExpiresAt.toIso8601String(),
    };
  }
}
