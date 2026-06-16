import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/app_toast.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/auth_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 1.2.0 C 방향: 비밀번호 변경 화면
///
/// 시안 §193-211 — AppBar + skyWash 안내 박스 + 3개 입력 필드 + 변경하기 버튼.
/// 새 비밀번호 입력 중에는 강도 안내 라벨이 아래에 표시된다.
class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _authService = AuthService();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _currentObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 포커스 변경 시 보더/링 갱신용 리빌드
    _currentFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
    _newController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// 새 비밀번호 강도: 6자 이상이면 안전, 영문+숫자 조합이면 더 안전
  ({bool valid, String message, Color color, IconData icon}) _newPasswordStatus() {
    final value = _newController.text;
    if (value.isEmpty) {
      return (
        valid: false,
        message: '',
        color: NewAppColor.textTertiary,
        icon: LucideIcons.circle,
      );
    }
    if (value.length < 6) {
      return (
        valid: false,
        message: '6자 이상 입력해주세요',
        color: NewAppColor.danger700,
        icon: LucideIcons.circleAlert,
      );
    }
    return (
      valid: true,
      message: '안전한 비밀번호예요',
      color: NewAppColor.skyDeep,
      icon: LucideIcons.circleCheck,
    );
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      AppToast.error(context, '현재 비밀번호를 입력해주세요.');
      _currentFocus.requestFocus();
      return;
    }
    if (next.isEmpty) {
      AppToast.error(context, '새 비밀번호를 입력해주세요.');
      _newFocus.requestFocus();
      return;
    }
    if (next.length < 6) {
      AppToast.error(context, '새 비밀번호는 6자 이상이어야 합니다.');
      _newFocus.requestFocus();
      return;
    }
    if (next != confirm) {
      AppToast.error(context, '새 비밀번호와 확인 비밀번호가 일치하지 않습니다.');
      _confirmFocus.requestFocus();
      return;
    }
    if (current == next) {
      AppToast.error(context, '현재 비밀번호와 새 비밀번호가 동일합니다.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _authService.changePassword(
        currentPassword: current,
        newPassword: next,
      );

      if (!mounted) return;
      if (response.success) {
        AppToast.success(context, '비밀번호가 성공적으로 변경되었습니다.');
        Navigator.pop(context, true);
      } else {
        AppToast.error(
          context,
          response.message.isNotEmpty
              ? response.message
              : '비밀번호 변경에 실패했습니다.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '비밀번호 변경 중 오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '비밀번호 변경',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 안내 박스 — skyWash + skyTint 보더 + shield
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: NewAppColor.skyWash,
                        border: Border.all(
                            color: NewAppColor.skyTint, width: 1),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            size: 19.sp,
                            color: NewAppColor.skyDeep,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              '안전한 사용을 위해 6자 이상, 영문·숫자를 조합한 비밀번호를 사용하세요.',
                              style: TextStyle(
                                color: NewAppColor.textSecondary,
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),

                    // 현재 비밀번호
                    _buildPasswordField(
                      label: '현재 비밀번호',
                      controller: _currentController,
                      focusNode: _currentFocus,
                      obscure: _currentObscure,
                      onToggleObscure: () => setState(
                          () => _currentObscure = !_currentObscure),
                      placeholder: '현재 비밀번호를 입력하세요',
                    ),
                    SizedBox(height: 16.h),

                    // 새 비밀번호 + 강도 안내
                    _buildPasswordField(
                      label: '새 비밀번호',
                      controller: _newController,
                      focusNode: _newFocus,
                      obscure: _newObscure,
                      onToggleObscure: () =>
                          setState(() => _newObscure = !_newObscure),
                      placeholder: '새 비밀번호 (최소 6자)',
                    ),
                    if (_newController.text.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Builder(
                        builder: (_) {
                          final s = _newPasswordStatus();
                          return Row(
                            children: [
                              Icon(s.icon, size: 14.sp, color: s.color),
                              SizedBox(width: 5.w),
                              Text(
                                s.message,
                                style: TextStyle(
                                  color: s.color,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    SizedBox(height: 16.h),

                    // 비밀번호 확인
                    _buildPasswordField(
                      label: '비밀번호 확인',
                      controller: _confirmController,
                      focusNode: _confirmFocus,
                      obscure: _confirmObscure,
                      onToggleObscure: () => setState(
                          () => _confirmObscure = !_confirmObscure),
                      placeholder: '새 비밀번호를 다시 입력',
                    ),
                  ],
                ),
              ),
            ),

            // 하단 변경하기 버튼
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: Material(
                color: NewAppColor.skyPrimary,
                borderRadius: BorderRadius.circular(13.r),
                child: InkWell(
                  onTap: _isSubmitting ? null : _submit,
                  borderRadius: BorderRadius.circular(13.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13.r),
                      boxShadow: [
                        BoxShadow(
                          color: NewAppColor.skyPrimary.withOpacity(0.32),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
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
      ),
    );
  }

  // 1.2.0: 비밀번호 입력 필드 — 라벨 + lock prefix + eye 토글 + 포커스 시 스카이 링
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String placeholder,
  }) {
    final hasFocus = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: NewAppColor.textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: hasFocus
                  ? NewAppColor.skyPrimary
                  : NewAppColor.borderStrong,
              width: hasFocus ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(11.r),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: NewAppColor.skyPrimary.withOpacity(0.12),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.lock,
                size: 18.sp,
                color: hasFocus
                    ? NewAppColor.skyDeep
                    : NewAppColor.textTertiary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  obscuringCharacter: '•',
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                    letterSpacing: obscure ? 2 : 0,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      color: NewAppColor.textTertiary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                      letterSpacing: 0,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggleObscure,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                  child: Icon(
                    obscure
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye,
                    size: 18.sp,
                    color: NewAppColor.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
