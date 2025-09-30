import '../models/api_response.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();

  /// 현재 사용자 정보 조회 (AuthService 사용)
  Future<ApiResponse<User>> getCurrentUser() async {
    print('👤 USER_SERVICE: getCurrentUser 호출');
    return await _authService.getCurrentUser();
  }

  /// 첫 로그인 완료 처리 (is_first를 false로 업데이트)
  Future<ApiResponse<User>> completeFirstLogin() async {
    print('🔧 USER_SERVICE: completeFirstLogin 시작');

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ApiResponse<User>(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      // users 테이블의 is_first를 false로 업데이트
      await _supabaseService.client
          .from('users')
          .update({'is_first': false})
          .eq('id', currentUser.id);

      print('✅ USER_SERVICE: is_first 업데이트 완료');

      // 업데이트된 사용자 정보 반환
      return await _authService.getCurrentUser(forceRefresh: true);
    } catch (e) {
      print('❌ USER_SERVICE: completeFirstLogin 실패 - $e');
      return ApiResponse<User>(
        success: false,
        message: '첫 로그인 완료 처리 실패: $e',
        data: null,
      );
    }
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