import '../models/api_response.dart';
import '../models/message_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/http_client.dart';

class CommunicationRepository {
  final HttpClient _httpClient = HttpClient();

  /// Get messages for a specific recipient
  Future<ApiResponse<List<MessageModel>>> getMessages({
    required String recipientType,
    required String recipientId,
    int page = 1,
    int limit = 50,
    String? messageType,
    String? priority,
    DateTime? since,
    DateTime? before,
  }) async {
    try {
      final params = <String, dynamic>{
        'recipientType': recipientType,
        'recipientId': recipientId,
        'page': page,
        'limit': limit,
        if (messageType != null) 'messageType': messageType,
        if (priority != null) 'priority': priority,
        if (since != null) 'since': since.toIso8601String(),
        if (before != null) 'before': before.toIso8601String(),
      };

      final url = _buildUrl(ApiEndpoints.messages, params);

      final response = await _httpClient.get<List<MessageModel>>(
        url,
        fromJson: (json) {
          final data = json as List;
          return data.map((item) => MessageModel.fromJson(item)).toList();
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Send a message
  Future<ApiResponse<MessageModel>> sendMessage({
    required String recipientType,
    required String recipientId,
    required String messageType,
    required Map<String, dynamic> content,
    String priority = 'normal',
    String? replyTo,
    List<String>? mentions,
  }) async {
    try {
      final response = await _httpClient.post<MessageModel>(
        ApiEndpoints.sendMessage,
        body: {
          'recipientType': recipientType,
          'recipientId': recipientId,
          'messageType': messageType,
          'content': content,
          'priority': priority,
          if (replyTo != null) 'replyTo': replyTo,
          if (mentions != null) 'mentions': mentions,
        },
        fromJson: (json) => MessageModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Add reaction to a message
  Future<ApiResponse<MessageModel>> addReaction(
    String messageId,
    String emoji,
  ) async {
    try {
      final response = await _httpClient.post<MessageModel>(
        ApiEndpoints.addReaction(messageId),
        body: {'emoji': emoji},
        fromJson: (json) => MessageModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove reaction from a message
  Future<ApiResponse<MessageModel>> removeReaction(
    String messageId,
    String emoji,
  ) async {
    try {
      final response = await _httpClient.delete<MessageModel>(
        _buildUrl(ApiEndpoints.removeReaction(messageId), {'emoji': emoji}),
        fromJson: (json) => MessageModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message
  Future<ApiResponse<void>> deleteMessage(String messageId) async {
    try {
      final response = await _httpClient.delete<void>(
        ApiEndpoints.deleteMessage(messageId),
        fromJson: (json) => null,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Forward a message
  Future<ApiResponse<MessageModel>> forwardMessage(
    String messageId,
    String recipientType,
    String recipientId,
  ) async {
    try {
      final response = await _httpClient.post<MessageModel>(
        ApiEndpoints.forwardMessage,
        body: {
          'messageId': messageId,
          'recipientType': recipientType,
          'recipientId': recipientId,
        },
        fromJson: (json) => MessageModel.fromJson(json),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Search messages
  Future<ApiResponse<List<MessageModel>>> searchMessages({
    required String query,
    String? recipientType,
    String? recipientId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
        if (recipientType != null) 'recipientType': recipientType,
        if (recipientId != null) 'recipientId': recipientId,
      };

      final url = _buildUrl(ApiEndpoints.searchMessages, params);

      final response = await _httpClient.get<List<MessageModel>>(
        url,
        fromJson: (json) {
          final data = json as List;
          return data.map((item) => MessageModel.fromJson(item)).toList();
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get message statistics
  Future<ApiResponse<Map<String, dynamic>>> getMessageStats({
    String? recipientType,
    String? recipientId,
  }) async {
    try {
      final params = <String, dynamic>{
        if (recipientType != null) 'recipientType': recipientType,
        if (recipientId != null) 'recipientId': recipientId,
      };

      final url = _buildUrl(ApiEndpoints.messageStats, params);

      final response = await _httpClient.get<Map<String, dynamic>>(
        url,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count
  Future<ApiResponse<Map<String, dynamic>>> getUnreadCount({
    String? recipientType,
    String? recipientId,
  }) async {
    try {
      final params = <String, dynamic>{
        if (recipientType != null) 'recipientType': recipientType,
        if (recipientId != null) 'recipientId': recipientId,
      };

      final url = _buildUrl(ApiEndpoints.unreadCount, params);

      final response = await _httpClient.get<Map<String, dynamic>>(
        url,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark messages as read
  Future<ApiResponse<Map<String, dynamic>>> markAsRead({
    List<String>? messageIds,
    String? recipientType,
    String? recipientId,
  }) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        ApiEndpoints.markAsRead,
        body: {
          if (messageIds != null) 'messageIds': messageIds,
          if (recipientType != null) 'recipientType': recipientType,
          if (recipientId != null) 'recipientId': recipientId,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to build URL with query parameters
  String _buildUrl(String baseUrl, Map<String, dynamic> params) {
    if (params.isEmpty) return baseUrl;

    final uri = Uri.parse(baseUrl);
    final queryParams = params.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return uri.replace(queryParameters: queryParams).toString();
  }
}
