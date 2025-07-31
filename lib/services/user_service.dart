import '../models/api_response.dart';
import '../models/user.dart';
import '../config/api_config.dart';
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

  /// 첫 로그인 상태 업데이트 (새 엔드포인트 사용)
  Future<ApiResponse<User>> updateIsFirst(bool isFirst) async {
    print('🔧 USER_SERVICE: updateIsFirst 시작 - 설정할 값: $isFirst');
  
    final body = {
      'is_first': isFirst,
    };
  
    print('🔧 USER_SERVICE: 요청 데이터: $body');
    print('🔧 USER_SERVICE: API 호출 - POST ${ApiConfig.usersUpdateFirstLogin}');

    final result = await _apiService.post<User>(
      ApiConfig.usersUpdateFirstLogin,
      body: body,
      fromJson: (json) => User.fromJson(json),
    );
  
    print('🔧 USER_SERVICE: API 응답 - success: ${result.success}');
    if (result.success && result.data != null) {
      print('🔧 USER_SERVICE: 응답 데이터 - is_first: ${result.data!.isFirst}');
    } else {
      print('🔧 USER_SERVICE: 응답 실패 - message: ${result.message}');
    }
  
    return result;
  }

  /// 첫 로그인 완료 처리 (비밀번호 변경 후 호출)
  Future<ApiResponse<User>> completeFirstLogin() async {
    return await updateIsFirst(false);
  }

  /// 대체 옵션 1: 기존 PUT /users/me 사용 (JSON 객체)
  Future<ApiResponse<User>> updateIsFirstViaPUT(bool isFirst) async {
    print('🔧 USER_SERVICE: updateIsFirstViaPUT 시작 - 설정할 값: $isFirst');
  
    final body = {
      'is_first': isFirst,
    };
  
    print('🔧 USER_SERVICE: 요청 데이터: $body');
    print('🔧 USER_SERVICE: API 호출 - PUT /users/me');

    final result = await _apiService.put<User>(
      ApiConfig.usersMe,
      body: body,
      fromJson: (json) => User.fromJson(json),
    );
  
    print('🔧 USER_SERVICE: API 응답 - success: ${result.success}');
    if (result.success && result.data != null) {
      print('🔧 USER_SERVICE: 응답 데이터 - is_first: ${result.data!.isFirst}');
    } else {
      print('🔧 USER_SERVICE: 응답 실패 - message: ${result.message}');
    }
  
    return result;
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
