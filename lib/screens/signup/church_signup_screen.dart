import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/components/app_toast.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/components/email_verification_field.dart';
import 'package:smart_yoram_app/screens/privacy_policy_screen.dart';
import 'package:smart_yoram_app/screens/terms_of_service_screen.dart';
import 'package:smart_yoram_app/services/signup_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 교회 관리자 가입 신청 화면
class ChurchSignupScreen extends StatefulWidget {
  const ChurchSignupScreen({super.key});

  @override
  State<ChurchSignupScreen> createState() => _ChurchSignupScreenState();
}

class _ChurchSignupScreenState extends State<ChurchSignupScreen> {
  final SignupService _signupService = SignupService();
  final _formKey = GlobalKey<FormState>();

  // 섹션 1: 기본 정보
  final TextEditingController _churchNameController = TextEditingController();
  final TextEditingController _pastorNameController = TextEditingController();
  String? _selectedDenomination;
  final TextEditingController _establishedYearController =
      TextEditingController();
  final TextEditingController _churchAddressController =
      TextEditingController();
  final TextEditingController _churchPhoneController = TextEditingController();

  // 섹션 2: 계정 정보
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _adminPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailVerified = false;

  // 섹션 3: 추가 정보
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _businessNoController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _homepageUrlController = TextEditingController();
  final TextEditingController _youtubeChannelController = TextEditingController();
  final TextEditingController _memberCountController = TextEditingController();

  // 섹션 4: 약관 동의
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _churchNameController.dispose();
    _pastorNameController.dispose();
    _establishedYearController.dispose();
    _churchAddressController.dispose();
    _churchPhoneController.dispose();
    _adminNameController.dispose();
    _adminPhoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _businessNoController.dispose();
    _websiteController.dispose();
    _homepageUrlController.dispose();
    _youtubeChannelController.dispose();
    _memberCountController.dispose();
    super.dispose();
  }

  // 폼 검증
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (!_isEmailVerified) {
      _showError('이메일 인증을 완료해주세요.');
      return false;
    }

    if (!_agreeTerms || !_agreePrivacy) {
      _showError('필수 약관에 동의해주세요.');
      return false;
    }

    return true;
  }

  // 가입 신청 제출
  Future<void> _submitApplication() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Supabase Edge Function을 통해 교회 가입 신청
      final result = await _signupService.submitChurchApplication(
        churchName: _churchNameController.text.trim(),
        pastorName: _pastorNameController.text.trim(),
        adminName: _adminNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _adminPhoneController.text.trim(),
        address: _churchAddressController.text.trim(),
        description: _descriptionController.text.trim(),
        agreeTerms: _agreeTerms,
        agreePrivacy: _agreePrivacy,
        agreeMarketing: _agreeMarketing,
        businessNo: _businessNoController.text.trim().isNotEmpty
            ? _businessNoController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        homepageUrl: _homepageUrlController.text.trim().isNotEmpty
            ? _homepageUrlController.text.trim()
            : null,
        youtubeChannel: _youtubeChannelController.text.trim().isNotEmpty
            ? _youtubeChannelController.text.trim()
            : null,
        establishedYear: _establishedYearController.text.trim().isNotEmpty
            ? int.tryParse(_establishedYearController.text.trim())
            : null,
        denomination: _selectedDenomination,
        memberCount: _memberCountController.text.trim().isNotEmpty
            ? int.tryParse(_memberCountController.text.trim())
            : null,
      );

      if (mounted) {
        if (result.success) {
          Navigator.pushReplacementNamed(
            context,
            '/signup/success',
            arguments: {
              'type': 'church',
              'title': '교회 가입 신청이 성공적으로 제출되었습니다.',
            },
          );
        } else {
          _showError(result.message);
        }
      }
    } catch (e) {
      _showError('가입 신청 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교회 관리자 가입',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 안내 카드
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: NewAppColor.skyTint,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Church Round 교회 관리자 가입',
                        style: figmaStyles.subtitle2.copyWith(
                          color: NewAppColor.skyDeep,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '교회 정보를 등록하고 Church Round 시스템을 이용하실 수 있습니다.',
                        style: figmaStyles.body2.copyWith(
                          color: NewAppColor.skyDeep,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '가입 승인 후 churchround.com에서 교회 관리 기능을 사용하실 수 있습니다.',
                        style: figmaStyles.body2.copyWith(
                          color: NewAppColor.skyPrimary,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // 섹션 1: 기본 정보
                _buildSection(
                  title: '기본 정보',
                  children: [
                    _buildTextField(
                      label: '교회명',
                      controller: _churchNameController,
                      hintText: '○○교회',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '담임 목사명',
                      controller: _pastorNameController,
                      hintText: '담임 목사님 성함',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildDropdownField(
                      label: '교단/교파',
                      value: _selectedDenomination,
                      items: _getDenominations(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDenomination = value;
                        });
                      },
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '설립연도',
                      controller: _establishedYearController,
                      hintText: '1900',
                      keyboardType: TextInputType.number,
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '교회 주소',
                      controller: _churchAddressController,
                      hintText: '교회 상세 주소',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '교회 대표 번호',
                      controller: _churchPhoneController,
                      hintText: '02-1234-5678',
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 섹션 2: 계정 정보
                _buildSection(
                  title: '계정 정보 (최고 관리자)',
                  children: [
                    _buildTextField(
                      label: '계정 사용자명',
                      controller: _adminNameController,
                      hintText: '실제 시스템 관리할 사용자 이름',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '계정 사용자 연락처',
                      controller: _adminPhoneController,
                      hintText: '010-0000-0000',
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('계정 사용자 이메일 (로그인 ID)', true),
                        SizedBox(height: 6.h),
                        EmailVerificationField(
                          emailController: _emailController,
                          onVerificationChanged: (verified) {
                            setState(() {
                              _isEmailVerified = verified;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 섹션 3: 교회 소개
                _buildSection(
                  title: '교회 소개',
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('교회 소개', true),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                            height: 1.5,
                          ),
                          decoration:
                              _inputDecoration('교회 소개 및 특징을 자세히 작성해주세요'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '교회 소개를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 섹션 4: 추가 정보
                _buildSection(
                  title: '추가 정보',
                  children: [
                    _buildTextField(
                      label: '사업자등록번호',
                      controller: _businessNoController,
                      hintText: '123-45-67890',
                      isRequired: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '웹사이트',
                      controller: _websiteController,
                      hintText: 'https://church.org',
                      keyboardType: TextInputType.url,
                      isRequired: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '홈페이지 URL',
                      controller: _homepageUrlController,
                      hintText: 'https://church.org',
                      keyboardType: TextInputType.url,
                      isRequired: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '유튜브 채널',
                      controller: _youtubeChannelController,
                      hintText: 'https://youtube.com/@church',
                      keyboardType: TextInputType.url,
                      isRequired: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '교인 수',
                      controller: _memberCountController,
                      hintText: '대략적인 교인 수',
                      keyboardType: TextInputType.number,
                      isRequired: false,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 섹션 5: 약관 동의
                _buildSection(
                  title: '약관 동의',
                  children: [
                    _buildCheckbox(
                      label: '서비스 이용약관 동의',
                      value: _agreeTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                        });
                      },
                      isRequired: true,
                      onDetail: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildCheckbox(
                      label: '개인정보처리방침 동의',
                      value: _agreePrivacy,
                      onChanged: (value) {
                        setState(() {
                          _agreePrivacy = value ?? false;
                        });
                      },
                      isRequired: true,
                      onDetail: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildCheckbox(
                      label: '마케팅 정보 수신 동의',
                      value: _agreeMarketing,
                      onChanged: (value) {
                        setState(() {
                          _agreeMarketing = value ?? false;
                        });
                      },
                      isRequired: false,
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // 제출 버튼
                GestureDetector(
                  onTap: _isLoading ? null : _submitApplication,
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: _isLoading ? 0.5 : 1.0,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      decoration: BoxDecoration(
                        color: NewAppColor.skyPrimary,
                        borderRadius: BorderRadius.circular(13.r),
                        boxShadow: [
                          BoxShadow(
                            color: NewAppColor.skyPrimary.withOpacity(0.30),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              '가입 신청하기',
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

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 섹션 빌더
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    const figmaStyles = FigmaTextStyles();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: figmaStyles.headline4.copyWith(
              color: NewAppColor.textStrong,
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.50,
            ),
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  // 텍스트 필드 빌더
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isRequired,
    TextInputType? keyboardType,
  }) {
    const figmaStyles = FigmaTextStyles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
          decoration: _inputDecoration(hintText),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label을(를) 입력해주세요';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  // 드롭다운 필드 빌더 — 박스를 탭하면 1.2.0 시트로 선택
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isRequired,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: () => _showSelectSheet(
            title: label,
            items: items,
            selected: value,
            onSelected: onChanged,
          ),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: NewAppColor.borderHair, width: 1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : '선택하세요',
                    style: TextStyle(
                      color: hasValue
                          ? NewAppColor.textStrong
                          : NewAppColor.textTertiary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                Icon(LucideIcons.chevronDown,
                    color: NewAppColor.textTertiary, size: 20.sp),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 1.2.0 선택 시트 — 핸들바 + 제목 + 라디오 리스트
  void _showSelectSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required Function(String?) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: NewAppColor.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 14.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Container(height: 1, color: NewAppColor.borderHair),
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == selected;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 22.w, vertical: 14.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: isSelected
                                          ? NewAppColor.skyDeep
                                          : NewAppColor.textStrong,
                                      fontSize: 15.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(LucideIcons.check,
                                      color: NewAppColor.skyPrimary,
                                      size: 20.sp),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 6.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1.2.0 공용 입력 데코레이션 — 흰 fill + borderHair + 포커스 sky 1.5
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: NewAppColor.textTertiary,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        fontFamily: 'Pretendard',
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: NewAppColor.borderHair, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: NewAppColor.borderHair, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: NewAppColor.skyPrimary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
    );
  }

  // 1.2.0 입력 라벨 — textSecondary 13sp/700 (디자인 정책 §3.1 표준)
  Widget _buildLabel(String label, bool isRequired) {
    return Row(
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
        if (isRequired) ...[
          SizedBox(width: 3.w),
          Text(
            '*',
            style: TextStyle(
              color: NewAppColor.danger700,
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ],
    );
  }

  // 체크박스 빌더 — onDetail 있으면 우측에 "보기 >" 링크 노출
  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    required bool isRequired,
    VoidCallback? onDetail,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: value ? NewAppColor.skyPrimary : Colors.white,
              border: Border.all(
                color: value
                    ? NewAppColor.skyPrimary
                    : NewAppColor.borderStrong,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: value
                ? Icon(
                    LucideIcons.check,
                    size: 14.w,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: NewAppColor.textBody,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                if (isRequired) ...[
                  SizedBox(width: 3.w),
                  Text(
                    '*',
                    style: TextStyle(
                      color: NewAppColor.danger700,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (onDetail != null)
          GestureDetector(
            onTap: onDetail,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Row(
                children: [
                  Text(
                    '보기',
                    style: TextStyle(
                      color: NewAppColor.skyPrimary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  Icon(LucideIcons.chevronRight,
                      size: 16.sp, color: NewAppColor.skyPrimary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 교단 목록
  List<String> _getDenominations() {
    return [
      '기독교대한감리회',
      '기독교대한성결교회',
      '기독교대한하나님의성회(여의도순복음)',
      '기독교대한하나님의성회(서대문)',
      '기독교대한하나님의성회(광명)',
      '기독교대한하나님의성회(순복음)',
      '기독교한국루터회',
      '기독교한국침례회',
      '대한예수교장로회(개혁)',
      '대한예수교장로회(개혁총연)',
      '대한예수교장로회(고신)',
      '대한예수교장로회(대신)',
      '대한예수교장로회(대신수호)',
      '대한예수교장로회(백석)',
      '대한예수교장로회(백석대신)',
      '대한예수교장로회(보수)',
      '대한예수교장로회(서서울)',
      '대한예수교장로회(순장)',
      '대한예수교장로회(에덴)',
      '대한예수교장로회(통합)',
      '대한예수교장로회(합동)',
      '대한예수교장로회(합동보수)',
      '대한예수교장로회(합신)',
      '대한예수교장로회(호헌)',
      '대한예수교장로회(기타)',
      '대한예수교침례회',
      '성결교회(대한성결)',
      '성결교회(예수교성결)',
      '성결교회(나성)',
      '성결교회(기타)',
      '예수교대한하나님의교회',
      '예수교대한성결교회',
      '예수교한국침례회',
      '한국기독교장로회',
      '한국구세군',
      '한국루터회',
      '한국복음교회',
      '한국침례회',
      '독립교회',
      '무교단',
    ];
  }
}
