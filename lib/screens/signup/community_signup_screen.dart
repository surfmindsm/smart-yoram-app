import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/components/email_verification_field.dart';
import 'package:smart_yoram_app/services/signup_service.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: NewAppColor.danger600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: NewAppColor.neutral900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '커뮤니티 가입',
          style: figmaStyles.subtitle1.copyWith(
            color: NewAppColor.neutral900,
            fontFamily: 'Pretendard Variable',
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
                    color: NewAppColor.secondary100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Church Round 커뮤니티 가입',
                        style: figmaStyles.subtitle2.copyWith(
                          color: NewAppColor.secondary900,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '업체, 사역자, 개인사업자 등으로 커뮤니티에 참여하실 수 있습니다.',
                        style: figmaStyles.body2.copyWith(
                          color: NewAppColor.secondary700,
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
                        Row(
                          children: [
                            Text(
                              '이메일 (로그인 ID)',
                              style: figmaStyles.bodyText2.copyWith(
                                color: NewAppColor.neutral900,
                                fontFamily: 'Pretendard Variable',
                                letterSpacing: -0.35,
                              ),
                            ),
                            Text(
                              ' *',
                              style: figmaStyles.bodyText2.copyWith(
                                color: NewAppColor.danger600,
                                fontFamily: 'Pretendard Variable',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
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
                        Row(
                          children: [
                            Text(
                              '상세 소개',
                              style: figmaStyles.bodyText2.copyWith(
                                color: NewAppColor.neutral900,
                                fontFamily: 'Pretendard Variable',
                                letterSpacing: -0.35,
                              ),
                            ),
                            Text(
                              ' *',
                              style: figmaStyles.bodyText2.copyWith(
                                color: NewAppColor.danger600,
                                fontFamily: 'Pretendard Variable',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: NewAppColor.primary300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  '단체/회사 소개 및 커뮤니티 이용 목적을 자세히 작성해주세요',
                              hintStyle: figmaStyles.body1.copyWith(
                                color: NewAppColor.neutral200,
                                fontFamily: 'Pretendard Variable',
                                letterSpacing: -0.38,
                              ),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '상세 소개를 입력해주세요';
                              }
                              return null;
                            },
                          ),
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
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? NewAppColor.neutral200
                          : NewAppColor.secondary600,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '가입 신청하기',
                              style: figmaStyles.subtitle2.copyWith(
                                color: Colors.white,
                                fontFamily: 'Pretendard Variable',
                                letterSpacing: -0.40,
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: figmaStyles.headline4.copyWith(
              color: NewAppColor.neutral900,
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
        Row(
          children: [
            Text(
              label,
              style: figmaStyles.bodyText2.copyWith(
                color: NewAppColor.neutral900,
                fontFamily: 'Pretendard Variable',
                letterSpacing: -0.35,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: figmaStyles.bodyText2.copyWith(
                  color: NewAppColor.danger600,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
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
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: figmaStyles.body1.copyWith(
                color: NewAppColor.neutral200,
                fontFamily: 'Pretendard Variable',
                letterSpacing: -0.38,
              ),
              border: InputBorder.none,
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return '$label을(를) 입력해주세요';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // 드롭다운 필드 빌더
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    required bool isRequired,
  }) {
    const figmaStyles = FigmaTextStyles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: figmaStyles.bodyText2.copyWith(
                color: NewAppColor.neutral900,
                fontFamily: 'Pretendard Variable',
                letterSpacing: -0.35,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: figmaStyles.bodyText2.copyWith(
                  color: NewAppColor.danger600,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: NewAppColor.primary300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            hint: Text(
              '선택하세요',
              style: figmaStyles.body1.copyWith(
                color: NewAppColor.neutral200,
                fontFamily: 'Pretendard Variable',
                letterSpacing: -0.38,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item['value'],
                child: Text(
                  item['label']!,
                  style: figmaStyles.body1.copyWith(
                    color: NewAppColor.neutral900,
                    fontFamily: 'Pretendard Variable',
                    letterSpacing: -0.38,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return '$label을(를) 선택해주세요';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // 체크박스 빌더
  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    required bool isRequired,
  }) {
    const figmaStyles = FigmaTextStyles();

    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: value ? NewAppColor.primary100 : Colors.white,
              border: Border.all(
                color: value ? NewAppColor.primary100 : const Color(0xFFE5E5EC),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: value
                ? Icon(
                    Icons.check,
                    size: 14.w,
                    color: NewAppColor.primary600,
                  )
                : null,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Row(
              children: [
                Text(
                  label,
                  style: figmaStyles.body2.copyWith(
                    color: NewAppColor.neutral900,
                    fontFamily: 'Pretendard Variable',
                    letterSpacing: -0.35,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: figmaStyles.body2.copyWith(
                      color: NewAppColor.danger600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 신청자 유형 목록 (API 문서 기준)
  List<Map<String, String>> _getApplicantTypes() {
    return [
      {'value': 'individual', 'label': '개인 사용자'},
      {'value': 'company', 'label': '기업/회사'},
      {'value': 'musician', 'label': '음악사역자'},
      {'value': 'minister', 'label': '목회자/전도사'},
      {'value': 'organization', 'label': '비영리단체'},
      {'value': 'church_admin', 'label': '교회 관계자'},
      {'value': 'other', 'label': '기타'},
    ];
  }
}
