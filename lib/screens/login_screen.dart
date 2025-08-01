import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/text_style.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../services/user_service.dart';
import '../widget/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // 로그인 방식
  String _loginType = 'email'; // 'email' 또는 'phone'

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 기존 로그인 상태 확인
  Future<void> _checkExistingLogin() async {
    final hasStoredAuth = await _authService.loadStoredAuth();
    if (hasStoredAuth && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back_image.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // 이미지 위에 반투명 오버레이 추가
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 600 ? 60.w : 24.w,
                    vertical: 24.h,
                  ),
                  child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: constraints.maxWidth > 600 ? 80.h : 60.h),

                    // 앱 로고 및 제목
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: constraints.maxWidth > 600 ? 120.w : 100.w,
                            height: constraints.maxWidth > 600 ? 120.w : 100.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.church,
                              size: constraints.maxWidth > 600 ? 60.w : 50.w,
                              color: AppColor.primary900,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            '스마트 교회요람',
                            style: AppTextStyle(color: Colors.white)
                                .title1(),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '교회 생활의 새로운 시작',
                            style:
                                AppTextStyle(color: Colors.white).b2(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 50.h),

                    // 로그인 방식 선택 탭
                    Container(
                      decoration: BoxDecoration(
                        color: AppColor.secondary01,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _loginType = 'email'),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  color: _loginType == 'email'
                                      ? AppColor.primary900
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  '이메일 로그인',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle(
                                    color: _loginType == 'email'
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    weight: _loginType == 'email'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ).h3(),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _loginType = 'phone'),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  color: _loginType == 'phone'
                                      ? AppColor.primary900
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '전화번호 로그인',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle(
                                    color: _loginType == 'phone'
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    weight: _loginType == 'phone'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ).h3(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // 사용자명/이메일/전화번호 입력
                    CustomFormField(
                      label: _loginType == 'email' ? '이메일' : '전화번호',
                      labelStyle:
                          AppTextStyle(color: AppColor.secondary07).b2(),
                      controller: _usernameController,
                      hintText: _loginType == 'email'
                          ? 'user@example.com'
                          : '01012345678',
                      hintStyle: AppTextStyle(color: AppColor.secondary03).b2(),
                      prefixIcon: Icon(
                        _loginType == 'email' ? Icons.email : Icons.phone,
                      ),
                      prefixIconColor: AppColor.secondary03,
                      fillColor: AppColor.secondary01,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColor.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide:
                            BorderSide(color: AppColor.primary900, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColor.transparent),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      keyboardType: _loginType == 'email'
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '${_loginType == 'email' ? '이메일' : '전화번호'}를 입력해주세요';
                        }
                        if (_loginType == 'email' && !value.contains('@')) {
                          return '유효한 이메일 주소를 입력해주세요';
                        }
                        if (_loginType == 'phone' &&
                            !RegExp(r'^[0-9-+]+$').hasMatch(value)) {
                          return '유효한 전화번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20.h),

                    // 비밀번호 입력
                    CustomFormField(
                      label: '비밀번호',
                      labelStyle:
                          AppTextStyle(color: AppColor.secondary07).b2(),
                      controller: _passwordController,
                      hintText: '비밀번호를 입력하세요',
                      hintStyle: AppTextStyle(color: AppColor.secondary03).b2(),
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: AppColor.secondary03,
                      fillColor: AppColor.secondary01,
                      filled: true,
                      obscureText: obscurePassword,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColor.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide:
                            BorderSide(color: AppColor.primary900, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColor.transparent),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 30.h),

                    // 로그인 버튼
                    CommonButton(
                      text: '로그인',
                      fontStyle: AppTextStyle(
                        color: Colors.white,
                      ).buttonLarge(),
                      type: ButtonType.primary,
                      width: double.infinity,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _login,
                    ),

                    SizedBox(height: 20.h),

                    // 개발자 옵션: 자동 로그인 상태 표시 및 활성화
                    FutureBuilder<bool>(
                      future: _authService.isAutoLoginDisabled,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 20.h),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: Colors.orange.shade700, size: 20.w),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    '개발 모드: 자동 로그인 비활성화됨',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _enableAutoLogin,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 4.h),
                                  ),
                                  child: Text(
                                    '활성화',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // 비밀번호 찾기
                    Center(
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          '비밀번호를 잊으셨나요?',
                          style: TextStyle(
                            fontSize:
                                constraints.maxWidth > 600 ? 16.sp : 14.sp,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 50.h),

                    // 교회 가입 안내
                    // Container(
                    //   padding: const EdgeInsets.all(20),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blue[50],
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(color: Colors.blue[200]!),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Icon(
                    //         Icons.info_outline,
                    //         color: Colors.blue[700],
                    //         size: 32,
                    //       ),
                    //       const SizedBox(height: 12),
                    //       Text(
                    //         '처음 이용하시나요?',
                    //         style: TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.bold,
                    //           color: Colors.blue[700],
                    //         ),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       const Text(
                    //         '교회 관리자에게 계정 생성을 요청하거나\n초대장을 받아 가입하실 수 있습니다.',
                    //         textAlign: TextAlign.center,
                    //         style: TextStyle(fontSize: 14),
                    //       ),
                    //       const SizedBox(height: 16),
                    //       SizedBox(
                    //         width: double.infinity,
                    //         child: OutlinedButton(
                    //           onPressed: _requestAccount,
                    //           style: OutlinedButton.styleFrom(
                    //             side: BorderSide(color: Colors.blue[700]!),
                    //             shape: RoundedRectangleBorder(
                    //               borderRadius: BorderRadius.circular(8),
                    //             ),
                    //           ),
                    //           child: Text(
                    //             '계정 생성 요청',
                    //             style: TextStyle(
                    //               color: Colors.blue[700],
                    //               fontWeight: FontWeight.w500,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
        ),
      ),
    );
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
            backgroundColor: Colors.red,
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
  Future<void> _handleLoginSuccess(ApiResponse<LoginResponse> result) async {
    if (mounted) {
      if (result.success) {
        print('🔑 LOGIN: 로그인 성공');

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
            print('🔑 LOGIN: 기존 사용자 - 홈 화면으로 이동');
            Navigator.pushReplacementNamed(context, '/home');
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
            backgroundColor: Colors.red,
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
                              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
      builder: (context) => _PasswordChangeDialog(),
    );
  }
}

// 비밀번호 변경 다이얼로그 위젯
class _PasswordChangeDialog extends StatefulWidget {
  @override
  _PasswordChangeDialogState createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Column(
        children: [
          Icon(Icons.lock_reset, size: 40, color: Colors.orange),
          SizedBox(height: 8),
          Text('첫 로그인 - 비밀번호 변경'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '보안상 첫 로그인 시 비밀번호를 변경해주세요.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // 현재 비밀번호
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '현재 비밀번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 새 비밀번호
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '새 비밀번호를 입력해주세요';
                }
                if (value.length < 6) {
                  return '비밀번호는 최소 6자 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 비밀번호 확인
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호 확인을 입력해주세요';
                }
                if (value != _newPasswordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  // 나중에 변경하기 - 홈으로 이동
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home');
                },
          child: const Text('나중에'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('변경하기'),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
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

          // 비밀번호 변경 성공 후 홈으로 이동
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/home');
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
