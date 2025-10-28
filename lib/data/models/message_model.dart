class MessageModel {
  final String id;
  final String senderId;
  final String? senderName;
  final String? senderMobile;
  final String recipientType; // 'frequency', 'group', 'user'
  final String recipientId;
  final String messageType; // 'text', 'audio', 'emergency'
  final MessageContent content;
  final String priority; // 'normal', 'high', 'emergency'
  final String? replyTo;
  final List<String> mentions;
  final List<MessageReaction> reactions;
  final List<String> readBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    this.senderName,
    this.senderMobile,
    required this.recipientType,
    required this.recipientId,
    required this.messageType,
    required this.content,
    this.priority = 'normal',
    this.replyTo,
    this.mentions = const [],
    this.reactions = const [],
    this.readBy = const [],
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: sender is String ? sender : sender?['_id'] ?? '',
      senderName: sender is Map ? sender['name'] : json['senderName'],
      senderMobile: sender is Map ? sender['mobile'] : json['senderMobile'],
      recipientType: json['recipientType'] ?? 'frequency',
      recipientId: json['recipientId'] is String
          ? json['recipientId']
          : json['recipientId']?['_id'] ?? '',
      messageType: json['messageType'] ?? 'text',
      content: MessageContent.fromJson(json['content'] ?? {}),
      priority: json['priority'] ?? 'normal',
      replyTo: json['replyTo'],
      mentions:
          (json['mentions'] as List<dynamic>?)
              ?.map((m) => m.toString())
              .toList() ??
          [],
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((r) => MessageReaction.fromJson(r))
              .toList() ??
          [],
      readBy:
          (json['readBy'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': senderId,
      'senderName': senderName,
      'senderMobile': senderMobile,
      'recipientType': recipientType,
      'recipientId': recipientId,
      'messageType': messageType,
      'content': content.toJson(),
      'priority': priority,
      'replyTo': replyTo,
      'mentions': mentions,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'readBy': readBy,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class MessageContent {
  final String? text;
  final AudioData? audio;

  MessageContent({this.text, this.audio});

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      text: json['text'],
      audio: json['audio'] != null ? AudioData.fromJson(json['audio']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (text != null) 'text': text,
      if (audio != null) 'audio': audio!.toJson(),
    };
  }
}

class AudioData {
  final String url;
  final int duration;
  final String? format;

  AudioData({required this.url, required this.duration, this.format});

  factory AudioData.fromJson(Map<String, dynamic> json) {
    return AudioData(
      url: json['url'] ?? '',
      duration: json['duration'] ?? 0,
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'duration': duration,
      if (format != null) 'format': format,
    };
  }
}

class MessageReaction {
  final String userId;
  final String? userName;
  final String emoji;
  final DateTime timestamp;

  MessageReaction({
    required this.userId,
    this.userName,
    required this.emoji,
    required this.timestamp,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return MessageReaction(
      userId: user is String ? user : user?['_id'] ?? json['userId'] ?? '',
      userName: user is Map ? user['name'] : json['userName'],
      emoji: json['emoji'] ?? '👍',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'userName': userName,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
