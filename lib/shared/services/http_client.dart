import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../models/api_response.dart';
import '../constants/api_endpoints.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  static const int _timeoutDuration = 30;
  static const int _maxRetries = 2; // Retry cold start failures
  static const int _retryDelay = 1500; // 1.5 seconds between retries
  String? _authToken;

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  // Get default headers
  Map<String, String> get _defaultHeaders {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Handle HTTP errors
  ApiException _handleHttpError(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      final message = responseBody['message'] ?? 'An error occurred';
      final errors = responseBody['errors'];

      return ApiException(
        message: message,
        statusCode: response.statusCode,
        errors: errors,
      );
    } catch (e) {
      return ApiException(
        message: 'Network error occurred',
        statusCode: response.statusCode,
      );
    }
  }

  // Log request for debugging
  void _logRequest(
    String method,
    String url,
    Map<String, String> headers,
    dynamic body,
  ) {
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🌐 HTTP Request: $method $url');
      print('📋 Headers: $headers');
      if (body != null) {
        print('📦 Body: $body');
      }
      print('🌍 Environment: ${ApiEndpoints.environmentName}');
      print('🔗 Base URL: ${ApiEndpoints.baseUrl}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // Log response for debugging
  void _logResponse(http.Response response) {
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📨 HTTP Response: ${response.statusCode}');
      print('📄 Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  // Generic HTTP request method with retry logic
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
    T Function(dynamic)? fromJson,
  }) async {
    int attemptCount = 0;

    while (attemptCount <= _maxRetries) {
      try {
        final headers = {..._defaultHeaders};
        if (additionalHeaders != null) {
          headers.addAll(additionalHeaders);
        }

        final encodedBody = body != null ? jsonEncode(body) : null;
        _logRequest(method, url, headers, encodedBody);

        late http.Response response;

        switch (method.toLowerCase()) {
          case 'get':
            response = await http
                .get(Uri.parse(url), headers: headers)
                .timeout(const Duration(seconds: _timeoutDuration));
            break;
          case 'post':
            response = await http
                .post(Uri.parse(url), headers: headers, body: encodedBody)
                .timeout(const Duration(seconds: _timeoutDuration));
            break;
          case 'put':
            response = await http
                .put(Uri.parse(url), headers: headers, body: encodedBody)
                .timeout(const Duration(seconds: _timeoutDuration));
            break;
          case 'delete':
            response = await http
                .delete(Uri.parse(url), headers: headers)
                .timeout(const Duration(seconds: _timeoutDuration));
            break;
          default:
            throw ApiException(
              message: 'Unsupported HTTP method: $method',
              statusCode: 0,
            );
        }

        _logResponse(response);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseBody = jsonDecode(response.body);
          return ApiResponse.fromJson(responseBody, fromJson);
        } else {
          print('❌ HTTP Error: ${response.statusCode}');
          print('❌ Response Body: ${response.body}');
          throw _handleHttpError(response);
        }
      } on TimeoutException {
        attemptCount++;
        if (attemptCount > _maxRetries) {
          print('❌ Request timeout after $attemptCount attempts');
          throw ApiException(
            message: 'Request timeout. Please check your internet connection.',
            statusCode: 408,
          );
        }
        print('⏱️ Timeout on attempt $attemptCount, retrying...');
        await Future.delayed(const Duration(milliseconds: _retryDelay));
      } on SocketException catch (e) {
        attemptCount++;
        if (attemptCount > _maxRetries) {
          print('❌ Socket Exception after $attemptCount attempts: $e');
          throw ApiException(
            message: 'No internet connection. Please check your network.',
            statusCode: 0,
          );
        }
        print('🌐 Network error on attempt $attemptCount, retrying...');
        await Future.delayed(const Duration(milliseconds: _retryDelay));
      } on HttpException catch (e) {
        attemptCount++;
        if (attemptCount > _maxRetries) {
          print('❌ HTTP Exception after $attemptCount attempts: $e');
          throw ApiException(
            message: 'Network error occurred. Please try again.',
            statusCode: 0,
          );
        }
        print(
          '🔴 HTTP error on attempt $attemptCount (cold start), retrying...',
        );
        await Future.delayed(const Duration(milliseconds: _retryDelay));
      } on HandshakeException catch (e) {
        attemptCount++;
        if (attemptCount > _maxRetries) {
          print('❌ Handshake Exception after $attemptCount attempts: $e');
          throw ApiException(
            message: 'Secure connection failed. Please try again.',
            statusCode: 0,
          );
        }
        print(
          '🔒 SSL error on attempt $attemptCount (cold start), retrying...',
        );
        await Future.delayed(const Duration(milliseconds: _retryDelay));
      } on FormatException catch (e) {
        print('❌ Format Exception: $e');
        throw ApiException(
          message: 'Invalid response format received.',
          statusCode: 0,
        );
      } catch (e) {
        if (e is ApiException) {
          rethrow;
        }

        // Handle connection closed specifically
        if (e.toString().contains('Connection closed')) {
          attemptCount++;
          if (attemptCount > _maxRetries) {
            print('❌ Connection closed after $attemptCount attempts: $e');
            throw ApiException(
              message:
                  'Server connection closed unexpectedly. Please try again.',
              statusCode: 503,
            );
          }
          print(
            '🔴 Connection closed on attempt $attemptCount (cold start), retrying...',
          );
          await Future.delayed(const Duration(milliseconds: _retryDelay));
          continue;
        }

        print('❌ Unexpected Error: $e');
        throw ApiException(
          message: 'An unexpected error occurred: ${e.toString()}',
          statusCode: 0,
        );
      }
    }

    // Should never reach here due to throw in loop
    throw ApiException(
      message: 'Request failed after maximum retries.',
      statusCode: 500,
    );
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String url, {
    Map<String, String>? additionalHeaders,
    T Function(dynamic)? fromJson,
  }) async {
    return _makeRequest<T>(
      'GET',
      url,
      additionalHeaders: additionalHeaders,
      fromJson: fromJson,
    );
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
    T Function(dynamic)? fromJson,
  }) async {
    return _makeRequest<T>(
      'POST',
      url,
      body: body,
      additionalHeaders: additionalHeaders,
      fromJson: fromJson,
    );
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
    T Function(dynamic)? fromJson,
  }) async {
    return _makeRequest<T>(
      'PUT',
      url,
      body: body,
      additionalHeaders: additionalHeaders,
      fromJson: fromJson,
    );
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String url, {
    Map<String, String>? additionalHeaders,
    T Function(dynamic)? fromJson,
  }) async {
    return _makeRequest<T>(
      'DELETE',
      url,
      additionalHeaders: additionalHeaders,
      fromJson: fromJson,
    );
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await get<Map<String, dynamic>>(ApiEndpoints.health);
      return response.success;
    } catch (e) {
      if (kDebugMode) {
        print('Health check failed: $e');
      }
      return false;
    }
  }
}

// Custom API Exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic errors;

  ApiException({required this.message, required this.statusCode, this.errors});

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }

  // Get user-friendly error message
  String get userFriendlyMessage {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Please check your connection and try again.'; // Changed to avoid auto-logout
      case 403:
        return 'You are not authorized to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 0:
        return message; // Custom messages for network errors
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
