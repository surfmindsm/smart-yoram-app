class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final int churchId;
  final String role;
  final bool isActive;
  final bool isFirst;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.churchId,
    required this.role,
    required this.isActive,
    required this.isFirst,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      churchId: json['church_id'] ?? 0,
      role: json['role'] ?? 'member',
      isActive: json['is_active'] ?? true,
      isFirst: json['is_first'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'church_id': churchId,
      'role': role,
      'is_active': isActive,
      'is_first': isFirst,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, fullName: $fullName, role: $role)';
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }
}
