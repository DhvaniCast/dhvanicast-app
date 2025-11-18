class PrivateFrequencyModel {
  final String frequencyNumber;
  final double frequencyValue;
  final String name;
  final String createdBy;
  final CreatorDetails? creatorDetails;
  final DateTime expiresAt;
  final bool isActive;
  final List<ActiveUser> activeUsers;
  final DateTime createdAt;

  PrivateFrequencyModel({
    required this.frequencyNumber,
    required this.frequencyValue,
    required this.name,
    required this.createdBy,
    this.creatorDetails,
    required this.expiresAt,
    this.isActive = true,
    this.activeUsers = const [],
    required this.createdAt,
  });

  factory PrivateFrequencyModel.fromJson(Map<String, dynamic> json) {
    return PrivateFrequencyModel(
      frequencyNumber: json['frequencyNumber'] ?? '',
      frequencyValue: (json['frequencyValue'] ?? 630.0).toDouble(),
      name: json['name'] ?? '',
      createdBy: json['createdBy'] ?? '',
      creatorDetails: json['creatorDetails'] != null
          ? CreatorDetails.fromJson(json['creatorDetails'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      activeUsers:
          (json['activeUsers'] as List<dynamic>?)
              ?.map((u) => ActiveUser.fromJson(u))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequencyNumber': frequencyNumber,
      'frequencyValue': frequencyValue,
      'name': name,
      'createdBy': createdBy,
      'creatorDetails': creatorDetails?.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
      'activeUsers': activeUsers.map((u) => u.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());

  String get formattedFrequency => '${frequencyValue.toStringAsFixed(1)} MHz';
}

class CreatorDetails {
  final String? name;
  final String? callSign;
  final String? email;

  CreatorDetails({this.name, this.callSign, this.email});

  factory CreatorDetails.fromJson(Map<String, dynamic> json) {
    return CreatorDetails(
      name: json['name'],
      callSign: json['callSign'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'callSign': callSign, 'email': email};
  }
}

class ActiveUser {
  final String userId;
  final String? userName;
  final String? callSign;
  final String? avatar;
  final DateTime joinedAt;
  final bool isTransmitting;

  ActiveUser({
    required this.userId,
    this.userName,
    this.callSign,
    this.avatar,
    required this.joinedAt,
    this.isTransmitting = false,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      userId: json['userId'] ?? '',
      userName: json['userName'],
      callSign: json['callSign'],
      avatar: json['avatar'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      isTransmitting: json['isTransmitting'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'callSign': callSign,
      'avatar': avatar,
      'joinedAt': joinedAt.toIso8601String(),
      'isTransmitting': isTransmitting,
    };
  }
}
