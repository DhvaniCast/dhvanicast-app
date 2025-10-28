import 'package:flutter/foundation.dart';
import '../../data/repositories/communication_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/network/websocket_client.dart';
import '../../data/models/message_model.dart';
import '../../data/models/group_model.dart';

class CommunicationService extends ChangeNotifier {
  final CommunicationRepository _commRepo = CommunicationRepository();
  final GroupRepository _groupRepo = GroupRepository();
  final WebSocketClient _socketClient = WebSocketClient();

  List<MessageModel> _messages = [];
  GroupModel? _currentGroup;
  bool _isLoading = false;
  String? _error;
  Map<String, bool> _typingUsers = {};

  // Getters
  List<MessageModel> get messages => _messages;
  GroupModel? get currentGroup => _currentGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, bool> get typingUsers => _typingUsers;

  /// Load group details
  Future<void> loadGroupDetails(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _groupRepo.getGroupById(groupId);

      if (response.success && response.data != null) {
        _currentGroup = response.data!;
        _error = null;

        // Join group via WebSocket
        _socketClient.joinGroup(groupId);
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load group: $e';
      if (kDebugMode) {
        print('Error loading group: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages
  Future<void> loadMessages({
    required String recipientType,
    required String recipientId,
    int page = 1,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _commRepo.getMessages(
        recipientType: recipientType,
        recipientId: recipientId,
        page: page,
        limit: limit,
      );

      if (response.success && response.data != null) {
        _messages = response.data!;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load messages: $e';
      if (kDebugMode) {
        print('Error loading messages: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send text message
  Future<bool> sendTextMessage({
    required String recipientType,
    required String recipientId,
    required String text,
    String priority = 'normal',
    String? replyTo,
  }) async {
    try {
      // Send via WebSocket for real-time
      _socketClient.sendMessage({
        'recipientType': recipientType,
        'recipientId': recipientId,
        'messageType': 'text',
        'content': {'text': text},
        'priority': priority,
        if (replyTo != null) 'replyTo': replyTo,
      });

      return true;
    } catch (e) {
      _error = 'Failed to send message: $e';
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      notifyListeners();
      return false;
    }
  }

  /// Send audio message
  Future<bool> sendAudioMessage({
    required String recipientType,
    required String recipientId,
    required Map<String, dynamic> audioData,
  }) async {
    try {
      _socketClient.sendAudioMessage({
        'recipientType': recipientType,
        'recipientId': recipientId,
        'audioData': audioData,
      });

      return true;
    } catch (e) {
      _error = 'Failed to send audio message: $e';
      if (kDebugMode) {
        print('Error sending audio message: $e');
      }
      notifyListeners();
      return false;
    }
  }

  /// Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    try {
      _socketClient.addReaction(messageId, emoji);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding reaction: $e');
      }
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String messageId) async {
    try {
      final response = await _commRepo.deleteMessage(messageId);

      if (response.success) {
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to delete message: $e';
      if (kDebugMode) {
        print('Error deleting message: $e');
      }
      notifyListeners();
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead({
    List<String>? messageIds,
    String? recipientType,
    String? recipientId,
  }) async {
    try {
      await _commRepo.markAsRead(
        messageIds: messageIds,
        recipientType: recipientType,
        recipientId: recipientId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error marking messages as read: $e');
      }
    }
  }

  /// Typing indicators
  void startTyping(String recipientType, String recipientId) {
    _socketClient.typingStart(recipientType, recipientId);
  }

  void stopTyping(String recipientType, String recipientId) {
    _socketClient.typingStop(recipientType, recipientId);
  }

  /// Setup WebSocket listeners
  void setupSocketListeners() {
    // Listen for new messages
    _socketClient.on('message_received', (data) {
      try {
        final message = MessageModel.fromJson(data);
        _messages.add(message);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error processing received message: $e');
        }
      }
    });

    // Listen for typing indicators
    _socketClient.on('typing_indicator', (data) {
      try {
        final userId = data['userId'] as String;
        final isTyping = data['isTyping'] as bool;
        _typingUsers[userId] = isTyping;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error processing typing indicator: $e');
        }
      }
    });

    // Listen for reactions
    _socketClient.on('reaction_added', (data) {
      try {
        final messageId = data['messageId'] as String;
        final reaction = MessageReaction.fromJson(data['reaction']);

        final messageIndex = _messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final updatedReactions = List<MessageReaction>.from(
            _messages[messageIndex].reactions,
          );
          updatedReactions.add(reaction);

          _messages[messageIndex] = MessageModel(
            id: _messages[messageIndex].id,
            senderId: _messages[messageIndex].senderId,
            senderName: _messages[messageIndex].senderName,
            senderMobile: _messages[messageIndex].senderMobile,
            recipientType: _messages[messageIndex].recipientType,
            recipientId: _messages[messageIndex].recipientId,
            messageType: _messages[messageIndex].messageType,
            content: _messages[messageIndex].content,
            priority: _messages[messageIndex].priority,
            replyTo: _messages[messageIndex].replyTo,
            mentions: _messages[messageIndex].mentions,
            reactions: updatedReactions,
            readBy: _messages[messageIndex].readBy,
            isDeleted: _messages[messageIndex].isDeleted,
            createdAt: _messages[messageIndex].createdAt,
            updatedAt: _messages[messageIndex].updatedAt,
          );

          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing reaction: $e');
        }
      }
    });

    // Listen for message deletions
    _socketClient.on('message_deleted', (data) {
      try {
        final messageId = data['messageId'] as String;
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error processing message deletion: $e');
        }
      }
    });
  }

  /// Leave group
  Future<void> leaveGroup(String groupId) async {
    try {
      await _groupRepo.leaveGroup(groupId);
      _socketClient.leaveGroup(groupId);
      _currentGroup = null;
      _messages.clear();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error leaving group: $e');
      }
    }
  }

  /// Clean up
  @override
  void dispose() {
    _socketClient.off('message_received');
    _socketClient.off('typing_indicator');
    _socketClient.off('reaction_added');
    _socketClient.off('message_deleted');
    super.dispose();
  }
}
