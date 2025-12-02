import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';

/// 회원가입 유형 선택 화면
/// 교회 가입 또는 커뮤니티 가입을 선택
class SignupSelectionScreen extends StatelessWidget {
  const SignupSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: NewAppColor.neutral900),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40.h),

              // 타이틀
              Text(
                '가입 유형 선택',
                style: figmaStyles.display5.copyWith(
                  color: NewAppColor.neutral900,
                  fontFamily: 'Pretendard Variable',
                  letterSpacing: -0.80,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '어떤 유형으로 가입하시겠습니까?',
                style: figmaStyles.headline4.copyWith(
                  color: NewAppColor.neutral600,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.50,
                ),
              ),

              SizedBox(height: 48.h),

              // 교회 가입 카드
              _buildSelectionCard(
                context,
                title: '교회 관리자 가입',
                description: 'Church Round 시스템에\n교회를 등록하고 관리합니다',
                icon: Icons.church,
                color: NewAppColor.primary600,
                onTap: () {
                  Navigator.pushNamed(context, '/signup/church');
                },
              ),

              SizedBox(height: 16.h),

              // 커뮤니티 가입 카드
              _buildSelectionCard(
                context,
                title: '커뮤니티 가입',
                description: '업체, 사역자, 개인사업자 등으로\n커뮤니티에 참여합니다',
                icon: Icons.people,
                color: NewAppColor.secondary600,
                onTap: () {
                  Navigator.pushNamed(context, '/signup/community');
                },
              ),

              const Spacer(),

              // 하단 안내 메시지
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20.w,
                      color: NewAppColor.neutral500,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '가입 신청 후 관리자 검토를 거쳐\n승인 결과를 이메일로 안내드립니다',
                        style: figmaStyles.captionText1.copyWith(
                          color: NewAppColor.neutral600,
                          fontFamily: 'Pretendard Variable',
                          letterSpacing: -0.30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    const figmaStyles = FigmaTextStyles();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: NewAppColor.neutral100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                size: 28.w,
                color: color,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: figmaStyles.subtitle1.copyWith(
                      color: NewAppColor.neutral900,
                      fontFamily: 'Pretendard Variable',
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.40,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: figmaStyles.body2.copyWith(
                      color: NewAppColor.neutral600,
                      fontFamily: 'Pretendard Variable',
                      letterSpacing: -0.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.w,
              color: NewAppColor.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
