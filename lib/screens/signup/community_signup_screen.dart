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

/// 커뮤니티 가입 신청 화면
class CommunitySignupScreen extends StatefulWidget {
  const CommunitySignupScreen({super.key});

  @override
  State<CommunitySignupScreen> createState() => _CommunitySignupScreenState();
}

class _CommunitySignupScreenState extends State<CommunitySignupScreen> {
  final SignupService _signupService = SignupService();
  final _formKey = GlobalKey<FormState>();

  // 섹션 1: 기본 정보
  String? _selectedApplicantType;
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 섹션 2: 계정 정보
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailVerified = false;

  // 섹션 3: 추가 정보
  final TextEditingController _businessNumberController =
      TextEditingController();
  final TextEditingController _serviceAreaController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // 섹션 4: 상세 소개
  final TextEditingController _descriptionController = TextEditingController();

  // 섹션 5: 약관 동의
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _organizationNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessNumberController.dispose();
    _serviceAreaController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 개인사업자가 아닌 경우만 사업자등록번호 표시
  bool get _shouldShowBusinessNumber =>
      _selectedApplicantType != null &&
      _selectedApplicantType != 'individual';

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
      // Supabase Edge Function을 통해 커뮤니티 가입 신청
      final result = await _signupService.submitCommunityApplication(
        applicantType: _selectedApplicantType!,
        organizationName: _organizationNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        agreeTerms: _agreeTerms,
        agreePrivacy: _agreePrivacy,
        agreeMarketing: _agreeMarketing,
        businessNumber: _businessNumberController.text.trim().isNotEmpty
            ? _businessNumberController.text.trim()
            : null,
        serviceArea: _serviceAreaController.text.trim().isNotEmpty
            ? _serviceAreaController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
      );

      if (mounted) {
        if (result.success) {
          Navigator.pushReplacementNamed(
            context,
            '/signup/success',
            arguments: {
              'type': 'community',
              'title': '커뮤니티 이용 신청이 성공적으로 제출되었습니다.',
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
        centerTitle: true,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '커뮤니티 가입',
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
                        'Church Round 커뮤니티 가입',
                        style: figmaStyles.subtitle2.copyWith(
                          color: NewAppColor.skyDeep,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '업체, 사역자, 개인사업자 등으로 커뮤니티에 참여하실 수 있습니다.',
                        style: figmaStyles.body2.copyWith(
                          color: NewAppColor.skyDeep,
                          fontFamily: 'Pretendard Variable',
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
                    _buildDropdownField(
                      label: '신청자 유형',
                      value: _selectedApplicantType,
                      items: _getApplicantTypes(),
                      onChanged: (value) {
                        setState(() {
                          _selectedApplicantType = value;
                        });
                      },
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '단체/회사명',
                      controller: _organizationNameController,
                      hintText: '조직 이름',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '담당자명',
                      controller: _contactPersonController,
                      hintText: '담당자 성함',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '연락처',
                      controller: _phoneController,
                      hintText: '010-0000-0000',
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 섹션 2: 계정 정보
                _buildSection(
                  title: '계정 정보',
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('이메일 (로그인 ID)', true),
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

                // 섹션 3: 추가 정보
                _buildSection(
                  title: '추가 정보',
                  children: [
                    if (_shouldShowBusinessNumber) ...[
                      _buildTextField(
                        label: '사업자등록번호',
                        controller: _businessNumberController,
                        hintText: '000-00-00000',
                        keyboardType: TextInputType.number,
                        isRequired: false,
                      ),
                      SizedBox(height: 16.h),
                    ],
                    _buildTextField(
                      label: '서비스 지역',
                      controller: _serviceAreaController,
                      hintText: '서비스 제공 지역',
                      isRequired: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '주소',
                      controller: _addressController,
                      hintText: '상세 주소',
                      isRequired: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '웹사이트',
                      controller: _websiteController,
                      hintText: '홈페이지 또는 SNS 주소',
                      keyboardType: TextInputType.url,
                      isRequired: false,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 섹션 4: 상세 소개
                _buildSection(
                  title: '상세 소개 및 이용 목적',
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('상세 소개', true),
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
                          decoration: _inputDecoration(
                              '단체/회사 소개 및 커뮤니티 이용 목적을 자세히 작성해주세요'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '상세 소개를 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ],
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
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
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
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    required bool isRequired,
  }) {
    final selectedItem = items.firstWhere(
      (e) => e['value'] == value,
      orElse: () => const {},
    );
    final displayText = selectedItem['label'];
    final hasValue = displayText != null;
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
                    hasValue ? displayText : '선택하세요',
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

  // 1.2.0 선택 시트
  void _showSelectSheet({
    required String title,
    required List<Map<String, String>> items,
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
                      final isSelected = item['value'] == selected;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onSelected(item['value']);
                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 22.w, vertical: 14.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['label']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? NewAppColor.skyPrimary
                                          : NewAppColor.textStrong,
                                      fontSize: 14.5.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
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

  // 신청자 유형 목록
  List<Map<String, String>> _getApplicantTypes() {
    return [
      {'value': 'company', 'label': '업체/회사'},
      {'value': 'individual', 'label': '개인사업자'},
      {'value': 'musician', 'label': '연주자/음악가'},
      {'value': 'minister', 'label': '사역자'},
      {'value': 'organization', 'label': '단체/기관'},
      {'value': 'other', 'label': '기타'},
    ];
  }
}
