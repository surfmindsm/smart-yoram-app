import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  User? _currentUser;
  
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _devModeKey = 'dev_mode_disable_auto_login';

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _apiService.isAuthenticated;
  
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
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userKey);
      
      if (token != null && userData != null) {
        _apiService.setToken(token);
        
        // 저장된 사용자 정보는 토큰 검증 후 다시 받아옴
        
        // 토큰 유효성 검증
        final response = await getCurrentUser();
        if (response.success && response.data != null) {
          _currentUser = response.data;
          return true;
        } else {
          // 토큰이 만료되었으면 저장된 데이터 삭제
          await clearStoredAuth();
        }
      }
      
      return false;
    } catch (e) {
      print('저장된 인증 정보 로드 실패: $e');
      return false;
    }
  }

  // 로그인
  Future<ApiResponse<LoginResponse>> login(String username, String password) async {
    try {
      final formData = {
        'username': username,
        'password': password,
      };

      final response = await _apiService.postForm<LoginResponse>(
        ApiConfig.authLogin,
        formData,
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        final loginData = response.data!;
        _apiService.setToken(loginData.accessToken);
        
        // 토큰 저장
        await _saveToken(loginData.accessToken);
        
        // 사용자 정보 가져오기
        final userResponse = await getCurrentUser();
        if (userResponse.success && userResponse.data != null) {
          _currentUser = userResponse.data;
          await _saveUser(_currentUser!);
        }
      }

      return response;
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: '로그인 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }

  // 현재 사용자 정보 조회
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiService.get<User>(
        ApiConfig.usersMe,
        fromJson: (json) => User.fromJson(json),
      );

      if (response.success && response.data != null) {
        _currentUser = response.data;
      }

      return response;
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: '사용자 정보 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 로그아웃
  Future<void> logout() async {
    try {
      _apiService.clearToken();
      _currentUser = null;
      await clearStoredAuth();
    } catch (e) {
      print('로그아웃 중 오류: $e');
    }
  }

  // 토큰 저장
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('토큰 저장 실패: $e');
    }
  }

  // 사용자 정보 저장
  Future<void> _saveUser(User user) async {
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
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      print('저장된 인증 정보 삭제 실패: $e');
    }
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
