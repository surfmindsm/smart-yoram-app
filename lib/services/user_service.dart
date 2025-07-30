import '../models/api_response.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiService _apiService = ApiService();

  /// 현재 사용자 정보 조회
  Future<ApiResponse<User>> getCurrentUser() async {
    return await _apiService.get<User>(
      '/users/me',
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// 사용자 목록 조회 (관리자만)
  Future<ApiResponse<List<User>>> getUsers({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _apiService.get<List<dynamic>>(
      '/users/?skip=$skip&limit=$limit',
    );

    if (response.success && response.data != null) {
      final users = response.data!
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<User>>(
        success: true,
        message: response.message,
        data: users,
      );
    }

    return ApiResponse<List<User>>(
      success: false,
      message: response.message,
      data: null,
    );
  }

  /// 새 사용자 생성 (관리자만)
  Future<ApiResponse<User>> createUser({
    required String username,
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    final body = {
      'username': username,
      'email': email,
      'full_name': fullName,
      'password': password,
      'role': role,
    };

    return await _apiService.post<User>(
      '/users/',
      body: body,
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// 사용자 정보 수정
  Future<ApiResponse<User>> updateUser({
    required int userId,
    String? username,
    String? email,
    String? fullName,
    String? role,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (fullName != null) body['full_name'] = fullName;
    if (role != null) body['role'] = role;
    if (isActive != null) body['is_active'] = isActive;

    return await _apiService.put<User>(
      '/users/$userId',
      body: body,
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// 사용자 삭제
  Future<ApiResponse<void>> deleteUser(int userId) async {
    return await _apiService.delete<void>('/users/$userId');
  }

  /// 비밀번호 변경
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = {
      'current_password': currentPassword,
      'new_password': newPassword,
    };

    return await _apiService.put<void>(
      '/users/me/password',
      body: body,
    );
  }

  /// 사용자 권한 레벨 확인
  static bool hasPermission(String userRole, String requiredRole) {
    const roleHierarchy = ['member', 'pastor', 'admin'];
    final userRoleIndex = roleHierarchy.indexOf(userRole);
    final requiredRoleIndex = roleHierarchy.indexOf(requiredRole);
    
    return userRoleIndex >= requiredRoleIndex;
  }

  /// 권한 레벨 목록
  static List<String> get roles => ['admin', 'pastor', 'member'];
}
