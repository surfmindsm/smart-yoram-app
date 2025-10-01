import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user.dart' as app_user;
import 'supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  app_user.User? _currentUser;

  static const String _userKey = 'user_data';
  static const String _devModeKey = 'dev_mode_disable_auto_login';

  app_user.User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _supabaseService.isAuthenticated;
  
  // 개발 모드: 자동 로그인 비활성화 플래그
  Future<bool> get isAutoLoginDisabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_devModeKey) ?? false;
  }
  
  // 개발 모드: 자동 로그인 활성화/비활성화
  Future<void> setAutoLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devModeKey, !enabled);
  }

  // 앱 시작 시 저장된 인증 정보 로드
  Future<bool> loadStoredAuth() async {
    try {
      // 개발 모드에서 자동 로그인이 비활성화되어 있으면 건너뛰기
      if (await isAutoLoginDisabled) {
        print('개발 모드: 자동 로그인이 비활성화되어 있습니다.');
        return false;
      }

      // Supabase 세션 복구 시도
      final session = _supabaseService.currentSession;
      if (session != null) {
        // 세션이 있으면 현재 사용자 정보 가져오기
        final response = await getCurrentUser();
        if (response.success && response.data != null) {
          _currentUser = response.data;
          return true;
        }
      }

      return false;
    } catch (e) {
      print('저장된 인증 정보 로드 실패: $e');
      return false;
    }
  }

  // 로그인 (Custom Users 테이블 사용)
  Future<ApiResponse<AuthResponse>> login(String email, String password) async {
    try {
      // Custom users 테이블에서 사용자 검색
      final response = await _supabaseService.client
          .from('users')
          .select('*')
          .eq('email', email)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        final userData = response as Map<String, dynamic>;
        final storedPassword = userData['hashed_password'] as String;

        // 비밀번호 확인 (단순 문자열 비교)
        if (password == storedPassword) {
          // User 객체 생성
          final user = app_user.User.fromJson(userData);
          _currentUser = user;
          await _saveUser(user);
          await setAutoLoginEnabled(true);

          // 간단한 Mock AuthResponse
          AuthResponse? mockAuthResponse;

          return ApiResponse<AuthResponse>(
            success: true,
            message: '로그인 성공',
            data: mockAuthResponse,
          );
        } else {
          return ApiResponse<AuthResponse>(
            success: false,
            message: '로그인 실패: 잘못된 이메일 또는 비밀번호',
            data: null,
          );
        }
      } else {
        return ApiResponse<AuthResponse>(
          success: false,
          message: '로그인 실패: 사용자를 찾을 수 없습니다',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: '로그인 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }

  // 회원가입 (Supabase Auth 사용)
  Future<ApiResponse<AuthResponse>> signUp(String email, String password, {String? fullName}) async {
    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        return ApiResponse<AuthResponse>(
          success: true,
          message: '회원가입 성공. 이메일을 확인해주세요.',
          data: response,
        );
      } else {
        return ApiResponse<AuthResponse>(
          success: false,
          message: '회원가입 실패',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: '회원가입 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }

  // 비밀번호 재설정 요청 (Supabase Auth 사용)
  Future<ApiResponse<String>> requestPasswordReset(String email) async {
    try {
      await _supabaseService.client.auth.resetPasswordForEmail(email);

      return ApiResponse<String>(
        success: true,
        message: '비밀번호 재설정 이메일이 전송되었습니다.',
        data: 'success',
      );
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: '비밀번호 재설정 요청 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }

  // 현재 사용자 정보 조회 (Custom users 테이블 사용)
  Future<ApiResponse<app_user.User>> getCurrentUser({bool forceRefresh = false}) async {
    try {
      // 강제 새로고침이 아니고 이미 로그인된 사용자가 있으면 반환
      if (!forceRefresh && _currentUser != null) {
        print('👤 AUTH_SERVICE: 캐시된 사용자 정보 반환');
        return ApiResponse<app_user.User>(
          success: true,
          message: '성공',
          data: _currentUser!,
        );
      }

      // DB에서 최신 사용자 정보 가져오기
      if (_currentUser != null) {
        print('👤 AUTH_SERVICE: DB에서 최신 사용자 정보 조회 - ID: ${_currentUser!.id}');

        final response = await _supabaseService.client
            .from('users')
            .select('*')
            .eq('id', _currentUser!.id)
            .single();

        print('👤 AUTH_SERVICE: DB 응답 데이터: $response');

        final updatedUser = app_user.User.fromJson(response);
        _currentUser = updatedUser;
        await _saveUser(updatedUser);

        print('👤 AUTH_SERVICE: 업데이트된 사용자 정보 - 전화번호: ${updatedUser.phone}, 주소: ${updatedUser.address}');

        return ApiResponse<app_user.User>(
          success: true,
          message: '성공',
          data: updatedUser,
        );
      }

      // 저장된 정보가 없는 경우
      return ApiResponse<app_user.User>(
        success: false,
        message: '로그인이 필요합니다',
        data: null,
      );
    } catch (e) {
      print('❌ AUTH_SERVICE: 사용자 정보 조회 오류: $e');
      return ApiResponse<app_user.User>(
        success: false,
        message: '사용자 정보 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 사용자 정보 업데이트 (Custom users 테이블 사용)
  Future<ApiResponse<app_user.User>> updateUserProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    try {
      if (_currentUser == null) {
        return ApiResponse<app_user.User>(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseService.client
          .from('users')
          .update(updateData)
          .eq('id', _currentUser!.id)
          .select()
          .single();

      final updatedUser = app_user.User.fromJson(response);
      _currentUser = updatedUser;
      await _saveUser(updatedUser);

      return ApiResponse<app_user.User>(
        success: true,
        message: '사용자 정보가 성공적으로 업데이트되었습니다.',
        data: updatedUser,
      );
    } catch (e) {
      return ApiResponse<app_user.User>(
        success: false,
        message: '사용자 정보 업데이트 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }

  // 비밀번호 변경 (Custom users 테이블 사용)
  Future<ApiResponse<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) {
        return ApiResponse<String>(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      // 현재 비밀번호 확인
      final userResponse = await _supabaseService.client
          .from('users')
          .select('hashed_password')
          .eq('id', _currentUser!.id)
          .single();

      final storedPassword = userResponse['hashed_password'] as String;

      if (currentPassword != storedPassword) {
        return ApiResponse<String>(
          success: false,
          message: '현재 비밀번호가 일치하지 않습니다',
          data: null,
        );
      }

      // 새 비밀번호로 업데이트
      await _supabaseService.client
          .from('users')
          .update({
            'hashed_password': newPassword,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      return ApiResponse<String>(
        success: true,
        message: '비밀번호가 성공적으로 변경되었습니다.',
        data: 'success',
      );
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: '비밀번호 변경 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }

  // 로그아웃 (Supabase Auth 사용)
  Future<void> logout() async {
    try {
      await _supabaseService.client.auth.signOut();
      _currentUser = null;
      await clearStoredAuth();
      // 로그아웃 시 자동 로그인 비활성화
      await setAutoLoginEnabled(false);
      print('로그아웃 완료 - 자동 로그인 비활성화됨');
    } catch (e) {
      print('로그아웃 중 오류: $e');
    }
  }

  // Supabase에서는 토큰을 자동으로 관리하므로 더 이상 필요하지 않음
  // 하지만 호환성을 위해 유지

  // 호환성을 위한 토큰 조회 메서드 (Supabase 세션 토큰 반환)
  Future<String?> getStoredToken() async {
    try {
      final session = _supabaseService.currentSession;
      return session?.accessToken;
    } catch (e) {
      print('토큰 조회 실패: $e');
      return null;
    }
  }

  // 사용자 정보 저장
  Future<void> _saveUser(app_user.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJson().toString());
    } catch (e) {
      print('사용자 정보 저장 실패: $e');
    }
  }

  // 저장된 인증 정보 삭제
  Future<void> clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('저장된 인증 정보 삭제 실패: $e');
    }
  }

  // Temp Token 생성 (Edge Function 인증용)
  String? getTempToken() {
    if (_currentUser == null) return null;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'temp_token_${_currentUser!.id}_$timestamp';
  }

  // 권한 확인
  bool hasRole(String role) {
    if (_currentUser == null) return false;
    return _currentUser!.role == role;
  }

  bool get isAdmin => hasRole('admin');
  bool get isPastor => hasRole('pastor') || isAdmin;
  bool get isMember => hasRole('member') || isPastor;
}
