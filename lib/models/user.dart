class User {
  final String id;
  final String name;
  final String email;
  final int age;
  final String? mobile;
  final String state;
  final bool isVerified;
  final String role;
  final DateTime? lastLogin;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.mobile,
    required this.state,
    required this.isVerified,
    required this.role,
    this.lastLogin,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      mobile: json['mobile'],
      state: json['state'] ?? '',
      isVerified: json['isVerified'] ?? false,
      role: json['role'] ?? 'user',
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      if (mobile != null) 'mobile': mobile,
      'state': state,
      'isVerified': isVerified,
      'role': role,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? mobile,
    String? state,
    bool? isVerified,
    String? role,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      mobile: mobile ?? this.mobile,
      state: state ?? this.state,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, age: $age, state: $state, isVerified: $isVerified, role: $role)';
  }
}
