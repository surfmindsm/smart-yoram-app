import 'package:flutter/material.dart';
// // import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/member_service.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../services/user_service.dart';
import '../components/login_type_toggle.dart';
import '../components/app_dialog.dart';
import '../components/app_input.dart';
import '../components/app_button.dart' hide IconButton;
import '../screens/settings/profile_image_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final MemberService _memberService = MemberService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool isLoading = false;
  bool obscurePassword = true;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isPhoneValid = false;
  bool _saveId = false;

  // 로그인 방식
  String _loginType = 'email'; // 'email' 또는 'phone'

  @override
  void initState() {
    super.initState();
    _loadSavedId(); // 저장된 아이디 불러오기
    _checkExistingLogin();

    // 텍스트 필드 리스너 추가
    _usernameController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  // 저장된 아이디 불러오기
  Future<void> _loadSavedId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_username');
      final saveIdEnabled = prefs.getBool('save_id_enabled') ?? false;

      if (savedId != null && saveIdEnabled) {
        setState(() {
          _usernameController.text = savedId;
          _saveId = true;
        });
        print('📱 LOGIN: 저장된 아이디 불러오기 성공 - $savedId');
      }
    } catch (e) {
      print('📱 LOGIN: 저장된 아이디 불러오기 실패 - $e');
    }
  }

  // 아이디 저장 처리
  Future<void> _saveIdIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_saveId) {
        // 아이디 저장
        await prefs.setString(
            'saved_username', _usernameController.text.trim());
        await prefs.setBool('save_id_enabled', true);
        print('📱 LOGIN: 아이디 저장 완료 - ${_usernameController.text.trim()}');
      } else {
        // 아이디 저장 해제
        await prefs.remove('saved_username');
        await prefs.setBool('save_id_enabled', false);
        print('📱 LOGIN: 저장된 아이디 삭제');
      }
    } catch (e) {
      print('📱 LOGIN: 아이디 저장 실패 - $e');
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_validateInputs);
    _passwordController.removeListener(_validateInputs);
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // 이메일과 비밀번호 유효성 검사
  void _validateInputs() {
    setState(() {
      // 이메일 유효성 검사
      _isEmailValid = _usernameController.text.isNotEmpty &&
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(_usernameController.text);

      // 전화번호 유효성 검사 (11자리)
      _isPhoneValid = _usernameController.text.isNotEmpty &&
          RegExp(r'^\d{9}$').hasMatch(_usernameController.text);

      // 비밀번호 유효성 검사 (6자 이상)
      _isPasswordValid = _passwordController.text.isNotEmpty &&
          _passwordController.text.length >= 6;
    });
  }

  // 기존 로그인 상태 확인
  Future<void> _checkExistingLogin() async {
    // 자동 로그인이 비활성화되어 있으면 건너뛰기
    final isAutoLoginDisabled = await _authService.isAutoLoginDisabled;
    if (isAutoLoginDisabled) {
      print('자동 로그인이 비활성화되어 있어 로그인 화면을 표시합니다.');
      return;
    }

    final hasStoredAuth = await _authService.loadStoredAuth();
    if (hasStoredAuth && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 80.h),

                // 메인 컨텐츠 영역
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 타이틀 섹션
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/logo_type3_white.png',
                              height: 96.h,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              '교회 생활의 새로운 시작',
                              style: figmaStyles.headline4.copyWith(
                                color: NewAppColor.neutral600,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.50,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // 로그인 타입 토글
                      LoginTypeToggle(
                        selectedType: _loginType,
                        onTypeChanged: (type) =>
                            setState(() => _loginType = type),
                      ),

                      SizedBox(height: 24.h),

                      // 입력 필드들
                      Column(
                        children: [
                          // 이메일/전화번호 입력 필드
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _loginType == 'email' ? '이메일' : '전화번호',
                                style: figmaStyles.bodyText2.copyWith(
                                  color: Colors.black,
                                  fontFamily: 'Pretendard Variable',
                                  letterSpacing: -0.35,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: NewAppColor.primary300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: TextFormField(
                                  controller: _usernameController,
                                  keyboardType: _loginType == 'email'
                                      ? TextInputType.emailAddress
                                      : TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context)
                                        .requestFocus(_passwordFocusNode);
                                  },
                                  decoration: InputDecoration(
                                    hintText: _loginType == 'email'
                                        ? '이메일을 입력하세요'
                                        : '전화번호를 입력하세요',
                                    hintStyle: figmaStyles.body1.copyWith(
                                      color: NewAppColor.neutral200,
                                      fontFamily: 'Pretendard Variable',
                                      letterSpacing: -0.38,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 16.h),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '${_loginType == 'email' ? '이메일' : '전화번호'}을 입력하세요';
                                    }
                                    if (_loginType == 'email' &&
                                        !value.contains('@')) {
                                      return '올바른 이메일 주소를 입력하세요';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          // 비밀번호 입력 필드
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '비밀번호',
                                style: figmaStyles.bodyText2.copyWith(
                                  color: Colors.black,
                                  fontFamily: 'Pretendard Variable',
                                  letterSpacing: -0.35,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: NewAppColor.primary300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (((_loginType == 'email' &&
                                                _isEmailValid) ||
                                            (_loginType == 'phone' &&
                                                _isPhoneValid)) &&
                                        _isPasswordValid &&
                                        !isLoading) {
                                      _login();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: '비밀번호를 입력하세요',
                                    hintStyle: figmaStyles.body1.copyWith(
                                      color: NewAppColor.neutral200,
                                      fontFamily: 'Pretendard Variable',
                                      letterSpacing: -0.38,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 16.h),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20.sp,
                                        color: NewAppColor.neutral700,
                                      ),
                                      onPressed: () => setState(() =>
                                          obscurePassword = !obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '비밀번호를 입력하세요';
                                    }
                                    if (value.length < 6) {
                                      return '비밀번호는 6자 이상이어야 합니다';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h),

                          // 체크박스와 링크
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _saveId = !_saveId),
                                    child: Container(
                                      width: 20.w,
                                      height: 20.h,
                                      decoration: BoxDecoration(
                                        color: _saveId
                                            ? NewAppColor.primary600
                                            : Colors.white,
                                        border: Border.all(
                                          color: _saveId
                                              ? NewAppColor.primary600
                                              : NewAppColor.neutral300,
                                          width: 1.5,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                      ),
                                      child: _saveId
                                          ? Icon(
                                              Icons.check,
                                              size: 14.w,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '아이디 저장',
                                    style: figmaStyles.captionText1.copyWith(
                                      color: NewAppColor.neutral500,
                                      fontFamily: 'Pretendard Variable',
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _forgotPassword,
                                child: Row(
                                  children: [
                                    Text(
                                      '아이디/비밀번호 찾기',
                                      style: figmaStyles.captionText1.copyWith(
                                        color: NewAppColor.neutral500,
                                        fontFamily: 'Pretendard Variable',
                                        letterSpacing: -0.30,
                                      ),
                                    ),
                                    Container(
                                      width: 12.w,
                                      height: 12.h,
                                      child: Icon(
                                        Icons.keyboard_arrow_right,
                                        size: 10.w,
                                        color: NewAppColor.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 48.h),

                      // 로그인 버튼
                      GestureDetector(
                        onTap: (((_loginType == 'email' && _isEmailValid) ||
                                    (_loginType == 'phone' && _isPhoneValid)) &&
                                _isPasswordValid &&
                                !isLoading)
                            ? _login
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            color: (((_loginType == 'email' && _isEmailValid) ||
                                        (_loginType == 'phone' &&
                                            _isPhoneValid)) &&
                                    _isPasswordValid)
                                ? NewAppColor.primary600
                                : Color(0xFFF1F4FF),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    '로그인',
                                    style: figmaStyles.subtitle2.copyWith(
                                      color: (((_loginType == 'email' &&
                                                      _isEmailValid) ||
                                                  (_loginType == 'phone' &&
                                                      _isPhoneValid)) &&
                                              _isPasswordValid)
                                          ? Colors.white
                                          : Color(0xFF9FB2F2),
                                      fontFamily: 'Pretendard Variable',
                                      letterSpacing: -0.40,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // 회원가입 버튼
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/signup/selection');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: NewAppColor.primary600,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '회원가입',
                              style: figmaStyles.subtitle2.copyWith(
                                color: NewAppColor.primary600,
                                fontFamily: 'Pretendard Variable',
                                letterSpacing: -0.40,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 32.h),

                      // 관리자 안내 문구
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: NewAppColor.neutral100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '관리자는 웹사이트를 이용해 주세요',
                              style: figmaStyles.body3.copyWith(
                                color: NewAppColor.neutral900,
                                fontFamily: 'Pretendard Variable',
                                letterSpacing: -0.30,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'churchround.com',
                              style: figmaStyles.body3.copyWith(
                                color: NewAppColor.primary600,
                                fontFamily: 'Pretendard Variable',
                                letterSpacing: -0.30,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h), // 하단 여백 추가
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 프로필 이미지 설정 확인 및 네비게이션
  Future<void> _checkAndNavigateToProfileSetup() async {
    try {
      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        // 사용자 정보를 가져올 수 없으면 홈으로 이동
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      final currentUser = userResponse.data!;

      // Member 정보 가져오기
      final memberResponse = await _memberService.getMemberByUserId(currentUser.id);

      if (memberResponse.success && memberResponse.data != null) {
        final member = memberResponse.data!;

        // mobile_profile_image_url이 null이거나 빈 문자열이면 프로필 이미지 설정 화면으로 이동
        if (member.mobileProfileImageUrl == null || member.mobileProfileImageUrl!.isEmpty) {
          print('🖼️ LOGIN: 모바일 프로필 이미지 미설정 - 설정 화면으로 이동');

          if (mounted) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileImageSetupScreen(
                  member: member,
                  isFirstSetup: true,
                ),
              ),
            );

            // 프로필 이미지 설정 후 홈으로 이동
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        } else {
          // 이미 프로필 이미지가 설정되어 있으면 바로 홈으로 이동
          print('🖼️ LOGIN: 모바일 프로필 이미지 이미 설정됨 - 홈으로 이동');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Member 정보를 가져올 수 없으면 홈으로 이동
        print('⚠️ LOGIN: Member 정보 조회 실패 - 홈으로 이동');
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('❌ LOGIN: 프로필 이미지 체크 중 오류 발생 - $e');
      // 오류 발생 시에도 홈으로 이동
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String username = _usernameController.text.trim();

      // 새로운 멤버 API는 이메일/전화번호 모두 지원
      print('🔑 LOGIN: $_loginType 로그인 시도 - username: $username');

      // 전화번호인 경우 숫자만 전송 (사용자 테이블의 phone 필드와 매치)
      if (_loginType == 'phone') {
        username = username.replaceAll(RegExp(r'[^0-9]'), ''); // 숫자만 추출
        print('🔑 LOGIN: 전화번호 정규화: $username');
      }

      final result =
          await _authService.login(username, _passwordController.text);

      await _handleLoginSuccess(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 오류: $e'),
            backgroundColor: Color.fromARGB(255, 191, 156, 163),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 로그인 성공 처리
  Future<void> _handleLoginSuccess(ApiResponse<dynamic> result) async {
    if (mounted) {
      if (result.success) {
        print('🔑 LOGIN: 로그인 성공');

        // 아이디 저장 처리
        await _saveIdIfEnabled();

        // FCM 토큰 재등록 (Supabase device_tokens 테이블에 저장)
        try {
          await FCMService.instance.refreshTokenRegistration();
          print('🔑 LOGIN: FCM 토큰 재등록 완료');
        } catch (e) {
          print('⚠️ LOGIN: FCM 토큰 재등록 실패 (계속 진행) - $e');
        }

        // 로그인 성공 후 사용자 정보 가져오기
        final userResponse = await _authService.getCurrentUser();
        if (userResponse.success && userResponse.data != null) {
          final currentUser = userResponse.data!;
          print(
              '🔑 LOGIN: User ID: ${currentUser.id}, is_first: ${currentUser.isFirst}');

          // 첫 로그인 처리
          if (currentUser.isFirst) {
            print('🔑 LOGIN: 첫 로그인 사용자 - 비밀번호 변경 다이얼로그 표시');
            _showPasswordChangeDialog();
          } else {
            print('🔑 LOGIN: 기존 사용자 - 프로필 이미지 확인 후 이동');
            await _checkAndNavigateToProfileSetup();
          }
        } else {
          print('🔑 LOGIN: 사용자 정보 가져오기 실패, 홈으로 이동');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        String errorMessage = result.message;
        if (errorMessage.isEmpty) {
          errorMessage = '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $errorMessage'),
            backgroundColor: Color.fromARGB(255, 191, 156, 163),
          ),
        );
      }
    }
  }

  Future<void> _forgotPassword() async {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('비밀번호 찾기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('등록된 이메일을 입력하시면\n비밀번호 재설정 링크를 전송해드립니다.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'your-email@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이메일을 입력해주세요')),
                        );
                        return;
                      }

                      if (!email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('유효한 이메일 주소를 입력해주세요')),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // 비밀번호 재설정 API 호출
                        final result =
                            await _authService.requestPasswordReset(email);

                        if (mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor:
                                  result.success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('오류가 발생했습니다: $e'),
                              backgroundColor:
                                  Color.fromARGB(255, 191, 156, 163),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('전송'),
            ),
          ],
        ),
      ),
    );
  }

  void _requestAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 생성 요청'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('교회 관리자에게 계정 생성을 요청합니다.'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: '전화번호',
                hintText: '010-0000-0000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: '요청 메시지 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계정 생성 요청이 전송되었습니다')),
              );
            },
            child: const Text('요청'),
          ),
        ],
      ),
    );
  }

  // 개발용: 자동 로그인 활성화
  Future<void> _enableAutoLogin() async {
    try {
      await _authService.setAutoLoginEnabled(true);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('자동 로그인이 활성화되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 변경 실패: $e'),
            backgroundColor: Color.fromARGB(255, 191, 156, 163),
          ),
        );
      }
    }
  }

  // 첫 로그인 시 비밀번호 변경 다이얼로그
  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 밖 클릭으로 닫기 방지
      builder: (context) => _PasswordChangeDialog(
        onComplete: _checkAndNavigateToProfileSetup,
      ),
    );
  }
}

// 비밀번호 변경 다이얼로그 위젯
class _PasswordChangeDialog extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _PasswordChangeDialog({required this.onComplete});

  @override
  _PasswordChangeDialogState createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final AuthService _authService = AuthService();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '비밀번호 변경',
      description: '보안상 첫 로그인 시 비밀번호를 변경해주세요.',
      dismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 현재 비밀번호
          AppPasswordInput(
            label: '현재 비밀번호',
            placeholder: '현재 비밀번호를 입력하세요',
            controller: _currentPasswordController,
            required: true,
          ),
          const SizedBox(height: 16),
          // 새 비밀번호
          AppPasswordInput(
            label: '새 비밀번호',
            placeholder: '새 비밀번호를 입력하세요 (최소 6자)',
            controller: _newPasswordController,
            required: true,
          ),
          const SizedBox(height: 16),
          // 비밀번호 확인
          AppPasswordInput(
            label: '비밀번호 확인',
            placeholder: '새 비밀번호를 다시 입력하세요',
            controller: _confirmPasswordController,
            required: true,
          ),
        ],
      ),
      actions: [
        AppButton(
          text: '나중에',
          variant: ButtonVariant.ghost,
          onPressed: _isLoading
              ? null
              : () async {
                  // 나중에 변경하기 - 프로필 이미지 확인 후 이동
                  Navigator.pop(context);
                  await widget.onComplete();
                },
        ),
        AppButton(
          text: '변경하기',
          variant: ButtonVariant.primary,
          onPressed: _isLoading ? null : _changePassword,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    // 수동 검증
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 비밀번호를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새 비밀번호를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호는 최소 6자 이상이어야 합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호 확인을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        if (result.success) {
          print('🔑 PASSWORD_CHANGE: 비밀번호 변경 성공, is_first 상태 업데이트 시작');

          try {
            // UserService를 사용하여 첫 로그인 완료 처리
            final userService = UserService();
            final firstLoginResult = await userService.completeFirstLogin();

            if (firstLoginResult.success && firstLoginResult.data != null) {
              final updatedUser = firstLoginResult.data!;
              print(
                  '🔑 PASSWORD_CHANGE: is_first 업데이트 성공 - 새 상태: ${updatedUser.isFirst}');

              // AuthService에도 업데이트된 사용자 정보 반영
              await _authService.getCurrentUser();
            } else {
              print(
                  '⚠️ PASSWORD_CHANGE: is_first 업데이트 실패: ${firstLoginResult.message}');
              // 실패해도 비밀번호 변경은 성공했으므로 계속 진행
            }
          } catch (e) {
            print('⚠️ PASSWORD_CHANGE: is_first 업데이트 예외: $e');
            // 예외가 발생해도 비밀번호 변경은 성공했으므로 계속 진행
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('비밀번호가 성공적으로 변경되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );

          // 비밀번호 변경 성공 후 프로필 이미지 확인 후 이동
          Navigator.pop(context);
          await widget.onComplete();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('비밀번호 변경 실패: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
