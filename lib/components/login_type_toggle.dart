import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';

class LoginTypeToggle extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const LoginTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const figmaStyles = FigmaTextStyles();

    return Container(
      width: 358.w,
      height: 54.h,
      decoration: BoxDecoration(
        color: NewAppColor.neutral100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Stack(
        children: [
          // 이메일 로그인 버튼
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => onTypeChanged('email'),
              child: Container(
                width: 179.w,
                height: 54.h,
                decoration: BoxDecoration(
                  color: selectedType == 'email'
                      ? NewAppColor.primary600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    '이메일 로그인',
                    style: figmaStyles.body1.copyWith(
                      color: selectedType == 'email'
                          ? NewAppColor.neutral100
                          : NewAppColor.neutral500,
                      fontFamily: 'Pretendard Variable',
                      letterSpacing: -0.38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 전화번호 로그인 버튼
          Positioned(
            left: 179.w,
            top: 0,
            child: GestureDetector(
              onTap: () => onTypeChanged('phone'),
              child: Container(
                width: 179.w,
                height: 54.h,
                decoration: BoxDecoration(
                  color: selectedType == 'phone'
                      ? NewAppColor.primary600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    '전화번호 로그인',
                    style: figmaStyles.body1.copyWith(
                      color: selectedType == 'phone'
                          ? NewAppColor.neutral100
                          : NewAppColor.neutral500,
                      fontFamily: 'Pretendard Variable',
                      letterSpacing: -0.38,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
