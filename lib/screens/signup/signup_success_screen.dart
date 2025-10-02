import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';

/// 가입 신청 완료 화면
class SignupSuccessScreen extends StatelessWidget {
  const SignupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    // 라우트 인자 받기
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String type = args?['type'] ?? 'church';
    final String title = args?['title'] ??
        '가입 신청이 성공적으로 제출되었습니다.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 체크 아이콘
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: NewAppColor.success00,
                  borderRadius: BorderRadius.circular(40.r),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 48.w,
                  color: NewAppColor.success600,
                ),
              ),

              SizedBox(height: 24.h),

              // 타이틀
              Text(
                '신청 완료!',
                style: figmaStyles.display5.copyWith(
                  color: NewAppColor.neutral900,
                  fontFamily: 'Pretendard Variable',
                  letterSpacing: -0.80,
                ),
              ),

              SizedBox(height: 12.h),

              // 설명
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  title,
                  style: figmaStyles.body1.copyWith(
                    color: NewAppColor.neutral600,
                    fontFamily: 'Pretendard Variable',
                    letterSpacing: -0.38,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 8.h),

              // 추가 안내
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  '관리자 검토 후 승인 결과를\n이메일로 안내드리겠습니다.',
                  style: figmaStyles.body2.copyWith(
                    color: NewAppColor.neutral500,
                    fontFamily: 'Pretendard Variable',
                    letterSpacing: -0.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // 안내 카드
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
                        '승인까지 1-2 영업일이 소요될 수 있습니다.\n궁금한 사항은 고객센터로 문의해주세요.',
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

              SizedBox(height: 24.h),

              // 로그인 페이지로 이동 버튼
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: type == 'church'
                        ? NewAppColor.primary600
                        : NewAppColor.secondary600,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      '로그인 페이지로 이동',
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
    );
  }
}
