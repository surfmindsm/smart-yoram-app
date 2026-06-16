import 'package:flutter/material.dart';
// // import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/member_service.dart';
import '../services/presence_service.dart';
import '../models/api_response.dart';
import '../services/user_service.dart';
import '../components/login_type_toggle.dart';
import '../components/app_input.dart';
import '../components/app_toast.dart';
import '../screens/settings/profile_image_setup_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final MemberService _memberService = MemberService();
  final PresenceService _presenceService = PresenceService();
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

      // 전화번호 유효성 검사 (9자리 이상)
      _isPhoneValid = _usernameController.text.isNotEmpty &&
          RegExp(r'^\d{9,}$').hasMatch(_usernameController.text);

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
    final bool canSubmit =
        (((_loginType == 'email' && _isEmailValid) ||
                (_loginType == 'phone' && _isPhoneValid)) &&
            _isPasswordValid &&
            !isLoading);

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
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 24.h),
                  // 로고 + 카피
                  Center(
                    child: Image.asset(
                      'assets/images/logo_type3_white.png',
                      height: 80.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Center(
                    child: Text(
                      '교회 생활의 새로운 시작',
                      style: TextStyle(
                        color: NewAppColor.textSecondary,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  // 로그인 방식 토글
                  LoginTypeToggle(
                    selectedType: _loginType,
                    onTypeChanged: (type) =>
                        setState(() => _loginType = type),
                  ),
                  SizedBox(height: 22.h),
                  // 이메일/전화번호 라벨
                  _buildFieldLabel(
                      _loginType == 'email' ? '이메일' : '전화번호'),
                  SizedBox(height: 8.h),
                  _buildIdentifierField(),
                  SizedBox(height: 16.h),
                  _buildFieldLabel('비밀번호'),
                  SizedBox(height: 8.h),
                  _buildPasswordField(canSubmit),
                  SizedBox(height: 14.h),
                  // 아이디 저장 / 비밀번호 찾기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _saveId = !_saveId),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: _saveId
                                    ? NewAppColor.skyPrimary
                                    : Colors.white,
                                border: Border.all(
                                  color: _saveId
                                      ? NewAppColor.skyPrimary
                                      : NewAppColor.borderStrong,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: _saveId
                                  ? Icon(LucideIcons.check,
                                      size: 14.w, color: Colors.white)
                                  : null,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '아이디 저장',
                              style: TextStyle(
                                color: NewAppColor.textSecondary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _forgotPassword,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Text(
                              '비밀번호 찾기',
                              style: TextStyle(
                                color: NewAppColor.skyPrimary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            Icon(LucideIcons.chevronRight,
                                size: 16.sp,
                                color: NewAppColor.skyPrimary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 26.h),
                  // 로그인 버튼 (주)
                  _buildPrimaryButton(canSubmit),
                  SizedBox(height: 12.h),
                  // 회원가입 버튼 (보조)
                  _buildSecondaryButton(),
                  SizedBox(height: 22.h),
                  // 관리자 안내 박스
                  _buildAdminHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: NewAppColor.textStrong,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'Pretendard',
      ),
    );
  }

  Widget _buildIdentifierField() {
    return AppInput(
      controller: _usernameController,
      placeholder:
          _loginType == 'email' ? '이메일을 입력하세요' : '전화번호를 입력하세요',
      prefixIcon: _loginType == 'email'
          ? LucideIcons.mail
          : LucideIcons.phone,
      keyboardType: _loginType == 'email'
          ? TextInputType.emailAddress
          : TextInputType.phone,
    );
  }

  Widget _buildPasswordField(bool canSubmit) {
    return AppInput(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      placeholder: '비밀번호를 입력하세요',
      prefixIcon: LucideIcons.lock,
      suffixIcon: obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
      onSuffixIconTap: () =>
          setState(() => obscurePassword = !obscurePassword),
      obscureText: obscurePassword,
      onSubmitted: (_) {
        if (canSubmit) _login();
      },
    );
  }

  Widget _buildPrimaryButton(bool enabled) {
    return GestureDetector(
      onTap: enabled ? _login : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          decoration: BoxDecoration(
            color: NewAppColor.skyPrimary,
            borderRadius: BorderRadius.circular(13.r),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: NewAppColor.skyPrimary.withOpacity(0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '로그인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/signup/selection'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(color: NewAppColor.borderStrong, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '회원가입',
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildAdminHint() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: NewAppColor.canvasAlt,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info,
              size: 16.sp, color: NewAppColor.textTertiary),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '관리자는 웹사이트를 이용해 주세요',
                  style: TextStyle(
                    color: NewAppColor.textSecondary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'churchround.com',
                  style: TextStyle(
                    color: NewAppColor.skyPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
        ],
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

      // 프로필 이미지 설정 완료 여부 확인 (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final profileSetupKey = 'profile_setup_completed_${currentUser.id}';
      final hasCompletedSetup = prefs.getBool(profileSetupKey) ?? false;

      if (hasCompletedSetup) {
        print('🖼️ LOGIN: 이미 프로필 이미지 설정 완료 - 홈으로 이동');
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

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

            // 프로필 이미지 설정 완료 후 플래그 저장 (건너뛰기 포함)
            if (result == true) {
              await prefs.setBool(profileSetupKey, true);
              print('🖼️ LOGIN: 프로필 이미지 설정 완료 플래그 저장');
            }

            // 프로필 이미지 설정 후 홈으로 이동
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        } else {
          // 이미 프로필 이미지가 설정되어 있으면 플래그 저장하고 홈으로 이동
          print('🖼️ LOGIN: 모바일 프로필 이미지 이미 설정됨 - 플래그 저장 후 홈으로 이동');
          await prefs.setBool(profileSetupKey, true);
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
        AppToast.error(context, '로그인 오류가 발생했습니다');
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

        // Presence 추적 시작
        try {
          _presenceService.startTracking();
          print('🔑 LOGIN: Presence 추적 시작됨');
        } catch (e) {
          print('⚠️ LOGIN: Presence 추적 시작 실패 (계속 진행) - $e');
        }

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

        AppToast.error(context, '로그인 실패: $errorMessage');
      }
    }
  }

  Future<void> _forgotPassword() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) =>
          _ForgotPasswordSheet(authService: _authService),
    );
  }

  // 첫 로그인 시 비밀번호 변경 시트
  void _showPasswordChangeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) => _PasswordChangeSheet(
        onComplete: _checkAndNavigateToProfileSetup,
      ),
    );
  }
}

// 비밀번호 변경 시트 (첫 로그인) — 1.2.0
class _PasswordChangeSheet extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _PasswordChangeSheet({required this.onComplete});

  @override
  State<_PasswordChangeSheet> createState() => _PasswordChangeSheetState();
}

class _PasswordChangeSheetState extends State<_PasswordChangeSheet> {
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 18.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    color: NewAppColor.skyTint,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.lock,
                      color: NewAppColor.skyDeep, size: 26.sp),
                ),
                SizedBox(height: 16.h),
                Text(
                  '비밀번호를 변경해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '보안을 위해 첫 로그인 시\n비밀번호 변경이 필요해요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NewAppColor.textMuted,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    height: 1.55,
                  ),
                ),
                SizedBox(height: 22.h),
                AppPasswordInput(
                  label: '현재 비밀번호',
                  placeholder: '현재 비밀번호를 입력하세요',
                  controller: _currentPasswordController,
                  required: true,
                ),
                SizedBox(height: 14.h),
                AppPasswordInput(
                  label: '새 비밀번호',
                  placeholder: '새 비밀번호를 입력하세요 (최소 6자)',
                  controller: _newPasswordController,
                  required: true,
                ),
                SizedBox(height: 14.h),
                AppPasswordInput(
                  label: '비밀번호 확인',
                  placeholder: '새 비밀번호를 다시 입력하세요',
                  controller: _confirmPasswordController,
                  required: true,
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await widget.onComplete();
                              },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          decoration: BoxDecoration(
                            color: NewAppColor.borderSoft,
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '나중에',
                            style: TextStyle(
                              color: NewAppColor.textSecondary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _changePassword,
                        behavior: HitTestBehavior.opaque,
                        child: Opacity(
                          opacity: _isLoading ? 0.5 : 1.0,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            decoration: BoxDecoration(
                              color: NewAppColor.skyPrimary,
                              borderRadius: BorderRadius.circular(13.r),
                              boxShadow: [
                                BoxShadow(
                                  color: NewAppColor.skyPrimary
                                      .withOpacity(0.30),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Text(
                                    '변경하기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    // 수동 검증
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      AppToast.error(context, '현재 비밀번호를 입력해주세요');
      return;
    }

    if (newPassword.isEmpty) {
      AppToast.error(context, '새 비밀번호를 입력해주세요');
      return;
    }

    if (newPassword.length < 6) {
      AppToast.error(context, '비밀번호는 최소 6자 이상이어야 합니다');
      return;
    }

    if (confirmPassword.isEmpty) {
      AppToast.error(context, '비밀번호 확인을 입력해주세요');
      return;
    }

    if (newPassword != confirmPassword) {
      AppToast.error(context, '비밀번호가 일치하지 않습니다');
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

          AppToast.success(context, '비밀번호가 성공적으로 변경되었습니다');

          // 비밀번호 변경 성공 후 프로필 이미지 확인 후 이동
          Navigator.pop(context);
          await widget.onComplete();
        } else {
          AppToast.error(context, '비밀번호 변경 실패: ${result.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '오류가 발생했습니다');
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

// 비밀번호 찾기 시트 — 1.2.0
class _ForgotPasswordSheet extends StatefulWidget {
  final AuthService authService;

  const _ForgotPasswordSheet({required this.authService});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 18.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    color: NewAppColor.skyTint,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(LucideIcons.key,
                      color: NewAppColor.skyDeep, size: 26.sp),
                ),
                SizedBox(height: 16.h),
                Text(
                  '비밀번호 찾기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '등록된 이메일과 전화번호를 입력하면\n임시 비밀번호를 이메일로 보내드려요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NewAppColor.textMuted,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    height: 1.55,
                  ),
                ),
                SizedBox(height: 22.h),
                AppInput(
                  label: '이메일',
                  placeholder: 'your-email@example.com',
                  controller: _emailController,
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),
                SizedBox(height: 14.h),
                AppInput(
                  label: '전화번호',
                  placeholder: '01012345678 (숫자만)',
                  controller: _phoneController,
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  required: true,
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          decoration: BoxDecoration(
                            color: NewAppColor.borderSoft,
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color: NewAppColor.textSecondary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _sendResetLink,
                        behavior: HitTestBehavior.opaque,
                        child: Opacity(
                          opacity: _isLoading ? 0.5 : 1.0,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            decoration: BoxDecoration(
                              color: NewAppColor.skyPrimary,
                              borderRadius: BorderRadius.circular(13.r),
                              boxShadow: [
                                BoxShadow(
                                  color: NewAppColor.skyPrimary
                                      .withOpacity(0.30),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Text(
                                    '전송',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // 이메일 검증
    if (email.isEmpty) {
      AppToast.error(context, '이메일을 입력해주세요');
      return;
    }

    if (!email.contains('@')) {
      AppToast.error(context, '유효한 이메일 주소를 입력해주세요');
      return;
    }

    // 전화번호 검증
    if (phone.isEmpty) {
      AppToast.error(context, '전화번호를 입력해주세요');
      return;
    }

    // 전화번호에서 숫자만 추출
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phoneDigits.length < 9 || phoneDigits.length > 11) {
      AppToast.error(context, '유효한 전화번호를 입력해주세요 (9-11자리)');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 비밀번호 재설정 API 호출 (이메일 + 전화번호)
      final result =
          await widget.authService.requestPasswordReset(email, phoneDigits);

      if (mounted) {
        Navigator.pop(context);
        if (result.success) {
          AppToast.success(context, result.message);
        } else {
          AppToast.error(context, result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppToast.error(context, '오류가 발생했습니다');
      }
    }
  }
}
