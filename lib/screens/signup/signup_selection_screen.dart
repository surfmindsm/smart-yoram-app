import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 회원가입 유형 선택 화면 — 1.2.0 C 방향
class SignupSelectionScreen extends StatelessWidget {
  const SignupSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          '회원가입',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 24.h, 18.w, 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어떤 회원으로\n가입할까요?',
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                  height: 1.35,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '가입 유형에 따라 입력할 정보가 달라져요.',
                style: TextStyle(
                  color: NewAppColor.textTertiary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 24.h),
              _buildSelectionCard(
                context,
                title: '교회 관리자 가입',
                description: 'Church Round 시스템에\n교회를 등록하고 관리합니다',
                icon: LucideIcons.church,
                onTap: () => Navigator.pushNamed(context, '/signup/church'),
              ),
              SizedBox(height: 10.h),
              _buildSelectionCard(
                context,
                title: '커뮤니티 가입',
                description: '업체, 사역자, 개인사업자 등으로\n커뮤니티에 참여합니다',
                icon: LucideIcons.users,
                onTap: () => Navigator.pushNamed(context, '/signup/community'),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: NewAppColor.skyTint,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info,
                        size: 16.sp, color: NewAppColor.skyDeep),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Text(
                        '가입 신청 후 관리자 검토를 거쳐\n승인 결과를 이메일로 안내드려요.',
                        style: TextStyle(
                          color: NewAppColor.skyDeep,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: NewAppColor.borderHair, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24.sp, color: NewAppColor.skyDeep),
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: NewAppColor.textTertiary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 20.sp, color: NewAppColor.iconFaint),
          ],
        ),
      ),
    );
  }
}
