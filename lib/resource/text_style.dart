import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyle {
  final Color color;
  final TextDecoration deco;
  final FontWeight weight;

  const AppTextStyle({
    required this.color,
    this.deco = TextDecoration.none,
    this.weight = FontWeight.w600,
  });

  // Large Title (34pt / 41pt)
  TextStyle lTitle() => TextStyle(
        color: color,
        fontSize: 34.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.bold,
        decoration: deco,
        height: 41 / 34,
      );

  // Title 1 (28pt / 34pt)
  TextStyle t1() => TextStyle(
        color: color,
        fontSize: 28.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.bold,
        decoration: deco,
        height: 38 / 28,
      );

  // Title 2 (22pt / 28pt)
  TextStyle t2() => TextStyle(
        color: color,
        fontSize: 22.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        decoration: deco,
        height: 28 / 22,
      );

  // Title 3 (20pt / 25pt)
  TextStyle t3() => TextStyle(
        color: color,
        fontSize: 20.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        decoration: deco,
        height: 25 / 20,
      );

  // Headline (17pt / 22pt)
  TextStyle headline() => TextStyle(
        color: color,
        fontSize: 17.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        decoration: deco,
        height: 22 / 17,
      );

  // Body (17pt / 22pt)
  TextStyle body() => TextStyle(
        color: color,
        fontSize: 17.sp,
        fontFamily: 'Pretendard',
        fontWeight: weight,
        decoration: deco,
        height: 22 / 17,
      );

  // Callout (16pt / 21pt)
  TextStyle callout() => TextStyle(
        color: color,
        fontSize: 16.sp,
        fontFamily: 'Pretendard',
        fontWeight: weight,
        decoration: deco,
        height: 21 / 16,
      );

  // Subhead (15pt / 20pt)
  TextStyle sub() => TextStyle(
        color: color,
        fontSize: 15.sp,
        fontFamily: 'Pretendard',
        fontWeight: weight,
        decoration: deco,
        height: 20 / 15,
      );

  // Footnote (13pt / 18pt)
  TextStyle foot() => TextStyle(
        color: color,
        fontSize: 13.sp,
        fontFamily: 'Pretendard',
        fontWeight: weight,
        decoration: deco,
        height: 18 / 13,
      );

  // Caption 1 (12pt / 16pt)
  TextStyle c1() => TextStyle(
        color: color,
        fontSize: 12.sp,
        fontFamily: 'Pretendard',
        fontWeight: weight,
        decoration: deco,
        height: 16 / 12,
      );

  // Caption 2 (11pt / 13pt)
  TextStyle c2() => TextStyle(
        color: color,
        fontSize: 11.sp,
        fontFamily: 'Pretendard',
        fontWeight: weight,
        decoration: deco,
        height: 13 / 11,
      );
  //트윅추가
  /// Display
  TextStyle display() => TextStyle(
        color: color,
        fontSize: 60.sp,
        fontFamily: 'pretendard',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        decoration: deco,
        height: (82 / 60).h,
      );

  /// Display
  TextStyle display2() => TextStyle(
        color: color,
        fontSize: 32.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w800,
        letterSpacing: -0.85,
        decoration: deco,
        height: (44 / 32).h,
      );

  /// Title1
  TextStyle title1() => TextStyle(
        color: color,
        fontSize: 32.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: (44 / 32).h,
      );

  /// Title1
  TextStyle title1_1() => TextStyle(
        color: color,
        fontSize: 32.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: (40 / 32).h,
      );

  /// Title2
  TextStyle title2() => TextStyle(
        color: color,
        fontSize: 28.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        decoration: deco,
        height: (38 / 28).h,
      );

  /// Title3
  TextStyle title3() => TextStyle(
        color: color,
        fontSize: 24.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        decoration: deco,
        height: (36 / 24).h,
      );

  /// Title3
  TextStyle title3_1() => TextStyle(
        color: color,
        fontSize: 24.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        decoration: deco,
        height: (30 / 24).h,
      );

  /// Title4
  TextStyle title4() => TextStyle(
        color: color,
        fontSize: 18.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        decoration: deco,
        height: (24 / 18).h,
      );

  /// H1
  TextStyle h1() => TextStyle(
        color: color,
        fontSize: 20.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        decoration: deco,
        height: (30 / 20).h,
      );

  /// H2
  TextStyle h2() => TextStyle(
        color: color,
        fontSize: 16.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        decoration: deco,
        height: (24 / 16).h,
      );

  /// H3
  TextStyle h3() => TextStyle(
        color: color,
        fontSize: 14.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        decoration: deco,
        height: (18 / 14).h,
      );

  /// Bodytext
  /// B1
  TextStyle b1() => TextStyle(
        color: color,
        fontSize: 18.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        decoration: deco,
        height: (26 / 18).h,
      );

  /// B2
  TextStyle b2() => TextStyle(
        color: color,
        fontSize: 16.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        decoration: deco,
        height: (24 / 16).h,
      );

  /// B3
  TextStyle b3() => TextStyle(
        color: color,
        fontSize: 14.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        decoration: deco,
        height: (18 / 14).h,
      );

  /// B4
  TextStyle b4() => TextStyle(
        color: color,
        fontSize: 12.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        decoration: deco,
        height: (16 / 12).h,
      );

  /// B5
  TextStyle b5() => TextStyle(
        color: color,
        fontSize: 10.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        decoration: deco,
        height: (14 / 10).h,
      );

  /// Caption
  /// caption1
  TextStyle caption1() => TextStyle(
        color: color,
        fontSize: 12.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        decoration: deco,
        height: (16 / 12).h,
      );

  /// caption2
  TextStyle caption2() => TextStyle(
        color: color,
        fontSize: 8.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        decoration: deco,
        height: (12 / 8).h,
      );

  /// Button
  /// Button Large
  TextStyle buttonLarge() => TextStyle(
        color: color,
        fontSize: 16.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        decoration: deco,
        height: (24 / 16).h,
      );

  /// Button Small
  TextStyle buttonSmall() => TextStyle(
        color: color,
        fontSize: 12.sp,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        decoration: deco,
        height: (16 / 12).h,
      );
}
