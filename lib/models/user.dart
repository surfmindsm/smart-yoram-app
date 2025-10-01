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
  final String? phone;
  final String? address;
  final DateTime? updatedAt;

  // 권한 체크 헬퍼
  bool get isAdmin => role == 'admin' ||
                      role == 'church_admin' ||
                      role == 'church_super_admin' ||
                      role == 'community_admin' ||
                      role == 'system_admin' ||
                      role == 'super_admin';
  bool get isMember => role == 'member';
  bool get hasAdminAccess => isAdmin;
  bool get hasChurch => churchId != 9998;

  // 커뮤니티 권한 체크
  bool get hasCommunityAccess =>
    role == 'member' ||
    role == 'community_admin' ||
    role == 'church_admin' ||
    role == 'church_super_admin' ||
    role == 'system_admin';

  bool get isCommunityAdmin => role == 'community_admin';

  bool get isChurchAdmin =>
    role == 'church_admin' ||
    role == 'church_super_admin' ||
    role == 'system_admin';

  // 네비게이션 메뉴 표시 여부
  bool get shouldShowBasicMenus => !isCommunityAdmin; // community_admin은 기본 메뉴 숨김

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
    this.phone,
    this.address,
    this.updatedAt,
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
      phone: json['phone'],
      address: json['address'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
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
      'phone': phone,
      'address': address,
      'updated_at': updatedAt?.toIso8601String(),
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

// 사용자 정보가 포함된 로그인 응답 모델
class LoginWithUserResponse {
  final String accessToken;
  final String tokenType;
  final User? user;
  final dynamic member; // Member 모델이 있다면 Member?로 변경 가능

  LoginWithUserResponse({
    required this.accessToken,
    required this.tokenType,
    this.user,
    this.member,
  });

  factory LoginWithUserResponse.fromJson(Map<String, dynamic> json) {
    return LoginWithUserResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      member: json['member'], // 여기서는 일단 dynamic으로 처리
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user?.toJson(),
      'member': member,
    };
  }

  @override
  String toString() {
    return 'LoginWithUserResponse(accessToken: ${accessToken.substring(0, 20)}..., user: $user)';
  }
}
