import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/services/signup_service.dart';

/// 이메일 인증 컴포넌트
class EmailVerificationField extends StatefulWidget {
  final TextEditingController emailController;
  final Function(bool) onVerificationChanged;

  const EmailVerificationField({
    super.key,
    required this.emailController,
    required this.onVerificationChanged,
  });

  @override
  State<EmailVerificationField> createState() => _EmailVerificationFieldState();
}

class _EmailVerificationFieldState extends State<EmailVerificationField> {
  final SignupService _signupService = SignupService();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isCodeSent = false;
  bool _isVerified = false;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }

  // 이메일 유효성 검사
  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  // 인증 코드 발송
  Future<void> _sendVerificationCode() async {
    final email = widget.emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = '이메일을 먼저 입력해주세요.';
        _successMessage = null;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = '올바른 이메일 형식을 입력해주세요.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Supabase Edge Function을 통해 인증 코드 발송
      final result = await _signupService.sendVerificationCode(email);

      setState(() {
        if (result.success) {
          _isCodeSent = true;
          _successMessage = result.message;
          _errorMessage = null;
        } else {
          _errorMessage = result.message;
          _successMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '인증 코드 발송에 실패했습니다.';
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // 인증 코드 확인
  Future<void> _verifyCode() async {
    final code = _verificationCodeController.text.trim();
    final email = widget.emailController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = '인증 코드를 입력해주세요.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Supabase Edge Function을 통해 인증 코드 확인
      final result = await _signupService.verifyCode(email, code);

      setState(() {
        if (result.success) {
          _isVerified = true;
          _successMessage = result.message;
          _errorMessage = null;
          widget.onVerificationChanged(true);
        } else {
          _errorMessage = result.message;
          _successMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '인증 코드가 올바르지 않습니다.';
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이메일 입력 필드
        Row(
          children: [
            Expanded(
              child: Container(
                height: 54.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: _isVerified ? NewAppColor.success00 : Colors.white,
                  border: Border.all(
                    color: _isVerified
                        ? NewAppColor.success600
                        : NewAppColor.primary300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.emailController,
                        enabled: !_isVerified,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: '이메일을 입력하세요',
                          hintStyle: figmaStyles.body1.copyWith(
                            color: NewAppColor.neutral200,
                            fontFamily: 'Pretendard Variable',
                            letterSpacing: -0.38,
                          ),
                          border: InputBorder.none,
                        ),
                        style: figmaStyles.body1.copyWith(
                          color: NewAppColor.neutral900,
                          fontFamily: 'Pretendard Variable',
                          letterSpacing: -0.38,
                        ),
                      ),
                    ),
                    if (_isVerified)
                      Icon(
                        Icons.check_circle,
                        color: NewAppColor.success600,
                        size: 20.w,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _isVerified || _isSending ? null : _sendVerificationCode,
              child: Container(
                height: 54.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: _isVerified || _isSending
                      ? NewAppColor.neutral200
                      : NewAppColor.primary600,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: _isSending
                      ? SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '인증코드',
                          style: figmaStyles.bodyText2.copyWith(
                            color: Colors.white,
                            fontFamily: 'Pretendard Variable',
                            letterSpacing: -0.35,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),

        // 인증 코드 입력 필드 (발송 후 표시)
        if (_isCodeSent && !_isVerified) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 54.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: NewAppColor.primary300,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: TextFormField(
                    controller: _verificationCodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '인증 코드 6자리 입력',
                      hintStyle: figmaStyles.body1.copyWith(
                        color: NewAppColor.neutral200,
                        fontFamily: 'Pretendard Variable',
                        letterSpacing: -0.38,
                      ),
                      border: InputBorder.none,
                    ),
                    style: figmaStyles.body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontFamily: 'Pretendard Variable',
                      letterSpacing: -0.38,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _isVerifying ? null : _verifyCode,
                child: Container(
                  height: 54.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: _isVerifying
                        ? NewAppColor.neutral200
                        : NewAppColor.primary600,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: _isVerifying
                        ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '확인',
                            style: figmaStyles.bodyText2.copyWith(
                              color: Colors.white,
                              fontFamily: 'Pretendard Variable',
                              letterSpacing: -0.35,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],

        // 에러/성공 메시지
        if (_errorMessage != null || _successMessage != null) ...[
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _errorMessage != null
                  ? NewAppColor.danger100
                  : NewAppColor.success00,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: _errorMessage != null
                    ? NewAppColor.danger600
                    : NewAppColor.success600,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _errorMessage != null
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  size: 16.w,
                  color: _errorMessage != null
                      ? NewAppColor.danger600
                      : NewAppColor.success600,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _errorMessage ?? _successMessage ?? '',
                    style: figmaStyles.captionText1.copyWith(
                      color: _errorMessage != null
                          ? NewAppColor.danger600
                          : NewAppColor.success600,
                      fontFamily: 'Pretendard Variable',
                      letterSpacing: -0.30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
