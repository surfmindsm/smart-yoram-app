import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 가입 신청 완료 화면 — 1.2.0 C 방향
class SignupSuccessScreen extends StatelessWidget {
  const SignupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String title =
        args?['title'] ?? '가입 신청이 성공적으로 제출되었습니다.';

    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 24.h, 18.w, 18.h),
          child: Column(
            children: [
              const Spacer(),
              // 체크 아이콘
              Container(
                width: 84.w,
                height: 84.w,
                decoration: BoxDecoration(
                  color: NewAppColor.successBg,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.circleCheck,
                    size: 44.sp, color: NewAppColor.success700),
              ),
              SizedBox(height: 24.h),
              Text(
                '신청이 완료되었어요',
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NewAppColor.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    height: 1.55,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  '관리자 검토 후 승인 결과를\n이메일로 안내드릴게요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NewAppColor.textTertiary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    height: 1.55,
                  ),
                ),
              ),
              const Spacer(),
              // 안내 카드
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
                        '승인까지 1~2 영업일이 소요될 수 있어요.\n궁금한 사항은 고객센터로 문의해주세요.',
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
              SizedBox(height: 14.h),
              // 로그인 페이지로 이동 버튼
              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                ),
                behavior: HitTestBehavior.opaque,
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
                  child: Text(
                    '로그인 페이지로 이동',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
            ],
          ),
        ),
      ),
    );
  }
}
