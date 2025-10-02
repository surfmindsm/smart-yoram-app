import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/components/email_verification_field.dart';
import 'package:smart_yoram_app/components/file_upload_field.dart';
import 'package:smart_yoram_app/services/signup_service.dart';

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
  final TextEditingController _memberCountController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // 섹션 4: 첨부파일
  List<File> _attachments = [];

  // 섹션 5: 약관 동의
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
    _memberCountController.dispose();
    _websiteController.dispose();
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
      // 레거시 API를 통해 교회 가입 신청
      final result = await _signupService.submitChurchApplication(
        churchName: _churchNameController.text.trim(),
        pastorName: _pastorNameController.text.trim(),
        adminName: _adminNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _churchPhoneController.text.trim(),
        address: _churchAddressController.text.trim(),
        agreeTerms: _agreeTerms,
        agreePrivacy: _agreePrivacy,
        agreeMarketing: _agreeMarketing,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        establishedYear: _establishedYearController.text.trim().isNotEmpty
            ? int.tryParse(_establishedYearController.text.trim())
            : null,
        denomination: _selectedDenomination,
        memberCount: _memberCountController.text.trim().isNotEmpty
            ? int.tryParse(_memberCountController.text.trim())
            : null,
        attachments: _attachments.isNotEmpty ? _attachments : null,
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
          '교회 관리자 가입',
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
                    color: NewAppColor.primary100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Church Round 교회 관리자 가입',
                        style: figmaStyles.subtitle2.copyWith(
                          color: NewAppColor.primary900,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '교회 정보를 등록하고 Church Round 시스템을 이용하실 수 있습니다.',
                        style: figmaStyles.body2.copyWith(
                          color: NewAppColor.primary700,
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
                        Row(
                          children: [
                            Text(
                              '계정 사용자 이메일 (로그인 ID)',
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
                    _buildTextField(
                      label: '교인 수 (교적부 등록 예정)',
                      controller: _memberCountController,
                      hintText: '대략적인 교인 수',
                      keyboardType: TextInputType.number,
                      isRequired: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      label: '홈페이지',
                      controller: _websiteController,
                      hintText: '홈페이지 또는 유튜브 주소',
                      keyboardType: TextInputType.url,
                      isRequired: false,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // 섹션 4: 첨부파일
                _buildSection(
                  title: '첨부파일',
                  children: [
                    FileUploadField(
                      onFilesChanged: (files) {
                        setState(() {
                          _attachments = files;
                        });
                      },
                      maxFiles: 5,
                      maxFileSizeMB: 5,
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
                          : NewAppColor.primary600,
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
    required List<String> items,
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
                value: item,
                child: Text(
                  item,
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
