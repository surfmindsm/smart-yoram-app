import 'dart:convert';
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

      // SharedPreferences에서 저장된 사용자 정보 로드
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null && userJson.isNotEmpty) {
        try {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          _currentUser = app_user.User.fromJson(userData);
          print('✅ 저장된 인증 정보 로드 성공: ${_currentUser!.email}');
          return true;
        } catch (e) {
          print('❌ 사용자 정보 파싱 실패: $e');
          // 파싱 실패 시 저장된 정보 삭제
          await clearStoredAuth();
        }
      }

      // Supabase 세션 복구 시도 (백업)
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

  // 로그인 (Custom Users 테이블 + Supabase Auth)
  Future<ApiResponse<AuthResponse>> login(String identifier, String password) async {
    try {
      // 이메일인지 전화번호인지 판단
      final isEmail = identifier.contains('@');
      final loginType = isEmail ? '이메일' : '전화번호';

      print('🔐 AUTH_SERVICE: $loginType 로그인 시도 - $identifier');
      print('🔐 AUTH_SERVICE: 입력한 비밀번호 길이: ${password.length}자');

      // 1. Custom users 테이블에서 사용자 검색 (이메일 또는 전화번호)
      var query = _supabaseService.client
          .from('users')
          .select('*')
          .eq('is_active', true);

      // 이메일 또는 전화번호로 조회
      List<dynamic> responseList;
      if (isEmail) {
        responseList = await query.eq('email', identifier).limit(1);
      } else {
        // 전화번호: "-" 없는 형식과 "-" 있는 형식 모두 조회
        final phoneClean = identifier.replaceAll('-', '');

        // "-" 포함 형식으로 변환
        String phoneWithHyphen = phoneClean;
        if (phoneClean.length == 11) {
          // 010-1234-5678 형식
          phoneWithHyphen = '${phoneClean.substring(0, 3)}-${phoneClean.substring(3, 7)}-${phoneClean.substring(7)}';
        } else if (phoneClean.length == 10) {
          // 02-1234-5678 형식 (서울 지역번호)
          phoneWithHyphen = '${phoneClean.substring(0, 2)}-${phoneClean.substring(2, 6)}-${phoneClean.substring(6)}';
        }

        print('🔍 AUTH_SERVICE: 전화번호 조회 - clean: $phoneClean, with hyphen: $phoneWithHyphen');

        // 두 가지 형식 모두 조회 (or 조건) - 여러 행이 있을 수 있으므로 limit 추가
        responseList = await query.or('phone.eq.$phoneClean,phone.eq.$phoneWithHyphen').limit(1);
      }

      print('🔍 AUTH_SERVICE: DB 쿼리 결과 - 행 개수: ${responseList.length}');

      final response = responseList.isNotEmpty ? responseList.first : null;

      if (response != null) {
        final userData = response as Map<String, dynamic>;
        print('📋 AUTH_SERVICE: 사용자 정보 조회 성공');
        print('   - User ID: ${userData['id']}');
        print('   - Email: ${userData['email']}');
        print('   - Username: ${userData['username']}');
        print('   - is_active: ${userData['is_active']}');
        print('   - is_first: ${userData['is_first']}');
        print('   - role: ${userData['role']}');

        final storedPassword = userData['hashed_password'] as String;
        print('🔑 AUTH_SERVICE: 저장된 비밀번호 길이: ${storedPassword.length}자');
        print('🔑 AUTH_SERVICE: 비밀번호 첫 2자 비교 - 입력: ${password.substring(0, password.length >= 2 ? 2 : password.length)}, 저장: ${storedPassword.substring(0, storedPassword.length >= 2 ? 2 : storedPassword.length)}');
        print('🔑 AUTH_SERVICE: 비밀번호 완전 일치 여부: ${password == storedPassword}');

        // 2. 비밀번호 확인 (단순 문자열 비교)
        if (password == storedPassword) {
          print('✅ AUTH_SERVICE: Custom users 테이블 인증 성공');

          // User 객체 생성
          final user = app_user.User.fromJson(userData);
          _currentUser = user;
          await _saveUser(user);
          await setAutoLoginEnabled(true);

          // 3. Supabase Auth 로그인 시도 (JWT 토큰 발급용) - 이메일 로그인인 경우만
          if (isEmail) {
            try {
              print('🔑 AUTH_SERVICE: Supabase Auth 로그인 시도...');
              final authResponse = await _supabaseService.client.auth.signInWithPassword(
                email: identifier,
                password: password,
              );

              if (authResponse.session != null) {
                print('✅ AUTH_SERVICE: Supabase Auth 로그인 성공');
                print('🔑 AUTH_SERVICE: JWT 토큰 발급됨 (길이: ${authResponse.session!.accessToken.length})');
              }
            } catch (authError) {
              print('⚠️ AUTH_SERVICE: Supabase Auth 로그인 실패 - $authError');
              print('ℹ️ AUTH_SERVICE: Auth 계정 없음 - Custom users 인증만으로 진행');
              // Auth 계정이 없어도 Custom users 인증이 성공했으므로 계속 진행
            }
          } else {
            print('ℹ️ AUTH_SERVICE: 전화번호 로그인 - Supabase Auth 건너뜀 (Custom users 인증만 사용)');
          }

          // 5. Custom users 테이블 인증이 성공했으므로 로그인 성공 반환
          AuthResponse? mockAuthResponse;

          return ApiResponse<AuthResponse>(
            success: true,
            message: '로그인 성공',
            data: mockAuthResponse,
          );
        } else {
          print('❌ AUTH_SERVICE: 비밀번호 불일치');
          print('   - 입력한 비밀번호: "$password" (${password.length}자)');
          print('   - 저장된 비밀번호: "$storedPassword" (${storedPassword.length}자)');
          return ApiResponse<AuthResponse>(
            success: false,
            message: '로그인 실패: 잘못된 $loginType 또는 비밀번호',
            data: null,
          );
        }
      } else {
        print('❌ AUTH_SERVICE: 사용자를 찾을 수 없습니다');
        print('   - 조회한 $loginType: $identifier');
        print('   - is_active=true 조건으로 검색했으나 결과 없음');
        return ApiResponse<AuthResponse>(
          success: false,
          message: '로그인 실패: 사용자를 찾을 수 없습니다',
          data: null,
        );
      }
    } catch (e) {
      print('❌ AUTH_SERVICE: 로그인 오류 - $e');
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

  // 비밀번호 재설정 요청 (Supabase Edge Function + Resend 사용)
  Future<ApiResponse<String>> requestPasswordReset(String email, String phone) async {
    try {
      print('🔐 AUTH_SERVICE: 비밀번호 재설정 요청 - email: $email, phone: $phone');

      // Supabase Edge Function 호출 (reset-password)
      final response = await _supabaseService.client.functions.invoke(
        'reset-password',
        body: {
          'email': email,
          'phone': phone,
        },
      );

      print('📧 AUTH_SERVICE: Edge Function 응답 - ${response.data}');

      // Edge Function 응답 파싱
      final responseData = response.data as Map<String, dynamic>?;

      if (responseData != null && responseData['success'] == true) {
        return ApiResponse<String>(
          success: true,
          message: responseData['message'] ?? '임시 비밀번호가 이메일로 전송되었습니다.',
          data: 'success',
        );
      } else {
        return ApiResponse<String>(
          success: false,
          message: responseData?['message'] ?? '비밀번호 재설정에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      print('❌ AUTH_SERVICE: 비밀번호 재설정 오류 - $e');
      return ApiResponse<String>(
        success: false,
        message: '비밀번호 재설정 요청 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
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

      // DB에서 최신 사용자 정보 가져오기 (members 테이블 조인)
      if (_currentUser != null) {
        print('👤 AUTH_SERVICE: DB에서 최신 사용자 정보 조회 - ID: ${_currentUser!.id}');

        // users 테이블과 members 테이블 LEFT JOIN
        final response = await _supabaseService.client
            .from('users')
            .select('*, members!left(phone, address, name)')
            .eq('id', _currentUser!.id)
            .single();

        print('👤 AUTH_SERVICE: DB 응답 데이터: $response');

        // members 테이블의 phone, address, name 정보를 users 데이터에 병합
        final userData = Map<String, dynamic>.from(response);
        if (userData['members'] != null) {
          final memberData = userData['members'];
          if (memberData is List && memberData.isNotEmpty) {
            final member = memberData.first;
            userData['phone'] = member['phone'] ?? userData['phone'];
            userData['address'] = member['address'] ?? userData['address'];
            userData['full_name'] = member['name'] ?? userData['full_name'];
          } else if (memberData is Map) {
            userData['phone'] = memberData['phone'] ?? userData['phone'];
            userData['address'] = memberData['address'] ?? userData['address'];
            userData['full_name'] = memberData['name'] ?? userData['full_name'];
          }
        }
        userData.remove('members'); // members 필드 제거

        final updatedUser = app_user.User.fromJson(userData);
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

  // 사용자 정보 업데이트 (members 테이블 업데이트)
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

      print('📝 AUTH_SERVICE: 사용자 정보 업데이트 시작 - user_id: ${_currentUser!.id}');

      // members 테이블 업데이트 (user_id로 조회)
      final memberUpdateData = <String, dynamic>{};
      if (fullName != null) memberUpdateData['name'] = fullName;
      if (phone != null) memberUpdateData['phone'] = phone;
      if (address != null) memberUpdateData['address'] = address;

      if (memberUpdateData.isNotEmpty) {
        print('📝 AUTH_SERVICE: members 테이블 업데이트 데이터: $memberUpdateData');

        await _supabaseService.client
            .from('members')
            .update(memberUpdateData)
            .eq('user_id', _currentUser!.id);

        print('✅ AUTH_SERVICE: members 테이블 업데이트 완료');
      }

      // 업데이트된 정보 다시 조회
      return await getCurrentUser(forceRefresh: true);
    } catch (e) {
      print('❌ AUTH_SERVICE: 사용자 정보 업데이트 오류: $e');
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
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      print('✅ 사용자 정보 저장 완료: ${user.email}');
    } catch (e) {
      print('❌ 사용자 정보 저장 실패: $e');
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
