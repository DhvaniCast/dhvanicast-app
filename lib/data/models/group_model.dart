class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String owner;
  final List<GroupMember> members;
  final String? frequencyId;
  final GroupSettings settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int onlineCount;
  final int totalMembers;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    required this.owner,
    required this.members,
    this.frequencyId,
    required this.settings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.onlineCount = 0,
    this.totalMembers = 0,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      avatar: json['avatar'],
      owner: json['owner'] is String
          ? json['owner']
          : json['owner']?['_id'] ?? '',
      members:
          (json['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromJson(m))
              .toList() ??
          [],
      frequencyId: json['frequency'] is String
          ? json['frequency']
          : json['frequency']?['_id'],
      settings: json['settings'] != null
          ? GroupSettings.fromJson(json['settings'])
          : GroupSettings.defaultSettings(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      onlineCount: json['onlineCount'] ?? 0,
      totalMembers: json['totalMembers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'owner': owner,
      'members': members.map((m) => m.toJson()).toList(),
      'frequency': frequencyId,
      'settings': settings.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'onlineCount': onlineCount,
      'totalMembers': totalMembers,
    };
  }
}

class GroupMember {
  final String userId;
  final String? userName;
  final String? userMobile;
  final String role;
  final String? callSign;
  final bool isOnline;
  final String status;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    this.userName,
    this.userMobile,
    required this.role,
    this.callSign,
    this.isOnline = false,
    this.status = 'idle',
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return GroupMember(
      userId: user is String ? user : user?['_id'] ?? json['userId'] ?? '',
      userName: user is Map ? user['name'] : json['userName'],
      userMobile: user is Map ? user['mobile'] : json['userMobile'],
      role: json['role'] ?? 'member',
      callSign: json['callSign'],
      isOnline: json['isOnline'] ?? false,
      status: json['status'] ?? 'idle',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'userName': userName,
      'userMobile': userMobile,
      'role': role,
      'callSign': callSign,
      'isOnline': isOnline,
      'status': status,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

class GroupSettings {
  final bool isPublic;
  final bool allowMemberInvites;
  final bool requireApproval;
  final int? maxMembers;
  final bool muteNonModerators;

  GroupSettings({
    required this.isPublic,
    required this.allowMemberInvites,
    required this.requireApproval,
    this.maxMembers,
    this.muteNonModerators = false,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      isPublic: json['isPublic'] ?? true,
      allowMemberInvites: json['allowMemberInvites'] ?? true,
      requireApproval: json['requireApproval'] ?? false,
      maxMembers: json['maxMembers'],
      muteNonModerators: json['muteNonModerators'] ?? false,
    );
  }

  factory GroupSettings.defaultSettings() {
    return GroupSettings(
      isPublic: true,
      allowMemberInvites: true,
      requireApproval: false,
      muteNonModerators: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPublic': isPublic,
      'allowMemberInvites': allowMemberInvites,
      'requireApproval': requireApproval,
      'maxMembers': maxMembers,
      'muteNonModerators': muteNonModerators,
    };
  }
}
