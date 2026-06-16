import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart' hide IconButton;
import '../resource/color_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChurchRegistrationScreen extends StatefulWidget {
  const ChurchRegistrationScreen({super.key});

  @override
  State<ChurchRegistrationScreen> createState() => _ChurchRegistrationScreenState();
}

class _ChurchRegistrationScreenState extends State<ChurchRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _churchNameController = TextEditingController();
  final _representativeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;

  @override
  void dispose() {
    _churchNameController.dispose();
    _representativeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _agreeToTerms && _agreeToPrivacy;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '교회 등록',
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: NewAppColor.textStrong,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, size: 26.sp, color: NewAppColor.textStrong),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: NewAppColor.borderHair),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '교회 정보를 입력해주세요',
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '관리자 승인 후 이용 가능합니다.',
                style: TextStyle(
                  color: NewAppColor.textTertiary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 22.h),

              AppInput(
                label: '교회명',
                placeholder: '○○교회',
                controller: _churchNameController,
                required: true,
                prefixIcon: LucideIcons.church,
              ),
              SizedBox(height: 14.h),
              AppInput(
                label: '대표자명',
                placeholder: '담임목사님 성함',
                controller: _representativeController,
                required: true,
                prefixIcon: LucideIcons.user,
              ),
              SizedBox(height: 14.h),
              AppInput(
                label: '교회 주소',
                placeholder: '주소를 입력해주세요',
                controller: _addressController,
                required: true,
                prefixIcon: LucideIcons.mapPin,
                suffixIcon: LucideIcons.search,
                readOnly: true,
                onTap: () {
                  AppToast.show(context, '주소 검색 기능은 추후 구현 예정입니다');
                },
              ),
              SizedBox(height: 14.h),
              AppInput(
                label: '대표 연락처',
                placeholder: '010-0000-0000',
                controller: _phoneController,
                required: true,
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 14.h),
              AppInput(
                label: '대표 이메일',
                placeholder: 'church@example.com',
                controller: _emailController,
                required: true,
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 24.h),

              // 약관 동의 카드
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: NewAppColor.borderHair),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '약관 동의',
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildAgreementRow(
                      label: '서비스 이용약관 동의 (필수)',
                      value: _agreeToTerms,
                      onChanged: (v) => setState(() => _agreeToTerms = v),
                    ),
                    SizedBox(height: 10.h),
                    _buildAgreementRow(
                      label: '개인정보 처리방침 동의 (필수)',
                      value: _agreeToPrivacy,
                      onChanged: (v) => setState(() => _agreeToPrivacy = v),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28.h),

              // 등록 버튼
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: canSubmit ? _registerChurch : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NewAppColor.skyPrimary,
                    disabledBackgroundColor: NewAppColor.borderSoft,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: NewAppColor.textTertiary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    '교회 등록하기',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: value ? NewAppColor.skyPrimary : Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: value ? NewAppColor.skyPrimary : NewAppColor.borderStrong,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(LucideIcons.check, size: 14.sp, color: Colors.white)
                : null,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: NewAppColor.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerChurch() async {
    if (_formKey.currentState!.validate()) {
      await AppConfirmSheet.show(
        context: context,
        title: '교회 등록이 완료되었어요',
        description: '관리자 승인 후 이용 가능합니다.',
        confirmLabel: '확인',
        cancelLabel: '닫기',
        tone: AppSheetTone.success,
        icon: LucideIcons.circleCheck,
      );
      if (mounted) Navigator.of(context).pop();
    }
  }
}
