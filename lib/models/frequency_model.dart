class FrequencyModel {
  final String id;
  final double frequency;
  final String? name;
  final String? description;
  final String band;
  final bool isPublic;
  final bool isActive;
  final String? createdBy;
  final List<FrequencyUser> activeUsers;
  final int userCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? currentTransmitter;

  FrequencyModel({
    required this.id,
    required this.frequency,
    this.name,
    this.description,
    required this.band,
    this.isPublic = true,
    this.isActive = true,
    this.createdBy,
    this.activeUsers = const [],
    this.userCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.currentTransmitter,
  });

  factory FrequencyModel.fromJson(Map<String, dynamic> json) {
    print('🔍 [FrequencyModel.fromJson] ==== PARSING FREQUENCY ====');
    print('🔍 [FrequencyModel.fromJson] Frequency: ${json['frequency']} MHz');
    print('🔍 [FrequencyModel.fromJson] ID: ${json['_id'] ?? json['id']}');

    // Backend returns 'connectedUsers', frontend uses 'activeUsers'
    final usersData = json['connectedUsers'] ?? json['activeUsers'];
    print(
      '🔍 [FrequencyModel.fromJson] Users data type: ${usersData?.runtimeType}',
    );
    print(
      '🔍 [FrequencyModel.fromJson] Users count: ${usersData is List ? usersData.length : 0}',
    );

    if (usersData is List && usersData.isNotEmpty) {
      print('🔍 [FrequencyModel.fromJson] RAW USERS DATA:');
      for (var i = 0; i < usersData.length; i++) {
        print('   [User $i] Raw JSON: ${usersData[i]}');
      }
    }

    return FrequencyModel(
      id: json['_id'] ?? json['id'] ?? '',
      frequency: (json['frequency'] ?? 0).toDouble(),
      name: json['name'],
      description: json['description'],
      band: json['band'] ?? 'UHF',
      isPublic: json['isPublic'] ?? true,
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : json['createdBy']?['_id'],
      activeUsers:
          (usersData as List<dynamic>?)
              ?.map((u) => FrequencyUser.fromJson(u))
              .toList() ??
          [],
      userCount:
          json['currentUsers'] ??
          json['userCount'] ??
          (usersData is List ? usersData.length : 0),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      currentTransmitter: json['currentTransmitter'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'frequency': frequency,
      'name': name,
      'description': description,
      'band': band,
      'isPublic': isPublic,
      'isActive': isActive,
      'createdBy': createdBy,
      'activeUsers': activeUsers.map((u) => u.toJson()).toList(),
      'userCount': userCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'currentTransmitter': currentTransmitter,
    };
  }

  String get displayName => name ?? '${frequency.toStringAsFixed(1)} MHz';
}

class FrequencyUser {
  final String userId;
  final String? userName;
  final String? callSign;
  final String? location;
  final String? avatar;
  final int signalStrength;
  final bool isTransmitting;
  final DateTime joinedAt;

  FrequencyUser({
    required this.userId,
    this.userName,
    this.callSign,
    this.location,
    this.avatar,
    this.signalStrength = 3,
    this.isTransmitting = false,
    required this.joinedAt,
  });

  factory FrequencyUser.fromJson(Map<String, dynamic> json) {
    print('🔍 [FrequencyUser.fromJson] Raw JSON: $json');

    final user = json['user'];
    print('🔍 [FrequencyUser.fromJson] Extracted user: $user');
    print('🔍 [FrequencyUser.fromJson] user is String: ${user is String}');
    print('🔍 [FrequencyUser.fromJson] user is Map: ${user is Map}');

    // Extract userId
    final userId = user is String ? user : user?['_id'] ?? json['userId'] ?? '';

    // Extract userName - check multiple sources in priority order:
    // 1. Direct userName field (from backend activeUsers transformation)
    // 2. user.name (if user is populated object)
    // 3. fallback to null
    String? userName = json['userName'];
    if (userName == null && user is Map) {
      userName = user['name'];
    }

    // Extract avatar - check both direct field and nested user object
    String? avatar = json['avatar'];
    if (avatar == null && user is Map) {
      avatar = user['avatar'] ?? user['profile']?['avatar'];
    }

    final callSign = json['callSign'];

    print('🔍 [FrequencyUser.fromJson] Parsed userId: $userId');
    print('🔍 [FrequencyUser.fromJson] Parsed userName: $userName');
    print('🔍 [FrequencyUser.fromJson] Parsed callSign: $callSign');
    print('🔍 [FrequencyUser.fromJson] Parsed avatar: $avatar');

    return FrequencyUser(
      userId: userId,
      userName: userName,
      callSign: callSign,
      location: json['location'],
      avatar: avatar,
      signalStrength: json['signalStrength'] ?? 3,
      isTransmitting: json['isTransmitting'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'userName': userName,
      'callSign': callSign,
      'location': location,
      'avatar': avatar,
      'signalStrength': signalStrength,
      'isTransmitting': isTransmitting,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
