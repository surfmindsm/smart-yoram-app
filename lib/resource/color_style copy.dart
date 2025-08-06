import 'package:flutter/material.dart';

class AppColor {
  // Neutral Colors (회색 계열)
  /// #F8F9FC
  static const Color neutral100 = Color(0xffF8F9FC);
  
  /// #F1F3F9
  static const Color neutral200 = Color(0xffF1F3F9);
  
  /// #E1E6EF
  static const Color neutral300 = Color(0xffE1E6EF);
  
  /// #CBD2E1
  static const Color neutral400 = Color(0xffCBD2E1);
  
  /// #94A0B8
  static const Color neutral500 = Color(0xff94A0B8);
  
  /// #5F6C85
  static const Color neutral600 = Color(0xff5F6C85);
  
  /// #3F444D
  static const Color neutral700 = Color(0xff3F444D);
  
  /// #23272F
  static const Color neutral800 = Color(0xff23272F);
  
  /// #1B1F27
  static const Color neutral900 = Color(0xff1B1F27);
  
  /// #0A0D14
  static const Color neutral1000 = Color(0xff0A0D14);

  // Primary Colors (기본 브랜드 색상)
  /// #F0F5FF
  static const Color primary100 = Color(0xffF0F5FF);
  
  /// #DCE7FE
  static const Color primary200 = Color(0xffDCE7FE);
  
  /// #BED3FE
  static const Color primary300 = Color(0xffBED3FE);
  
  /// #91B5FD
  static const Color primary400 = Color(0xff91B5FD);
  
  /// #6194FA
  static const Color primary500 = Color(0xff6194FA);
  
  /// #3D7BF7
  static const Color primary600 = Color(0xff3D7BF7);
  
  /// #2F6FED
  static const Color primary700 = Color(0xff2F6FED);
  
  /// #1D5BD6
  static const Color primary800 = Color(0xff1D5BD6);
  
  /// #1E4EAE
  static const Color primary900 = Color(0xff1E4EAE);
  
  /// #1E428A
  static const Color primary1000 = Color(0xff1E428A);

  // Secondary Colors (보조 색상)
  /// #F8F5FF
  static const Color secondary100 = Color(0xffF8F5FF);
  
  /// #EFE7FE
  static const Color secondary200 = Color(0xffEFE7FE);
  
  /// #E4D7FE
  static const Color secondary300 = Color(0xffE4D7FE);
  
  /// #CCB4FD
  static const Color secondary400 = Color(0xffCCB4FD);
  
  /// #AF89FA
  static const Color secondary500 = Color(0xffAF89FA);
  
  /// #9E70FA
  static const Color secondary600 = Color(0xff9E70FA);
  
  /// #8B54F7
  static const Color secondary700 = Color(0xff8B54F7);
  
  /// #6D35DE
  static const Color secondary800 = Color(0xff6D35DE);
  
  /// #5221B5
  static const Color secondary900 = Color(0xff5221B5);
  
  /// #451D95
  static const Color secondary1000 = Color(0xff451D95);

  // Success Colors (성공 색상)
  /// #EDFDF8
  static const Color success100 = Color(0xffEDFDF8);
  
  /// #D1FAEC
  static const Color success200 = Color(0xffD1FAEC);
  
  /// #A5F3D9
  static const Color success300 = Color(0xffA5F3D9);
  
  /// #6EE7BF
  static const Color success400 = Color(0xff6EE7BF);
  
  /// #36D39F
  static const Color success500 = Color(0xff36D39F);
  
  /// #0EA472
  static const Color success600 = Color(0xff0EA472);
  
  /// #08875D
  static const Color success700 = Color(0xff08875D);
  
  /// #04724D
  static const Color success800 = Color(0xff04724D);
  
  /// #066042
  static const Color success900 = Color(0xff066042);
  
  /// #064C35
  static const Color success1000 = Color(0xff064C35);

  // Warning Colors (경고 색상)
  /// #FFF8EB
  static const Color warning100 = Color(0xffFFF8EB);
  
  /// #FFF1D6
  static const Color warning200 = Color(0xffFFF1D6);
  
  /// #FEE2A9
  static const Color warning300 = Color(0xffFEE2A9);
  
  /// #FDCF72
  static const Color warning400 = Color(0xffFDCF72);
  
  /// #FBBB3C
  static const Color warning500 = Color(0xffFBBB3C);
  
  /// #DB7712
  static const Color warning600 = Color(0xffDB7712);
  
  /// #B25E09
  static const Color warning700 = Color(0xffB25E09);
  
  /// #96530F
  static const Color warning800 = Color(0xff96530F);
  
  /// #80460D
  static const Color warning900 = Color(0xff80460D);
  
  /// #663B0F
  static const Color warning1000 = Color(0xff663B0F);

  // Danger Colors (위험 색상)
  /// #FEF1F2
  static const Color danger100 = Color(0xffFEF1F2);
  
  /// #FEE1E3
  static const Color danger200 = Color(0xffFEE1E3);
  
  /// #FEC8CD
  static const Color danger300 = Color(0xffFEC8CD);
  
  /// #FCA6AD
  static const Color danger400 = Color(0xffFCA6AD);
  
  /// #F8727D
  static const Color danger500 = Color(0xffF8727D);
  
  /// #EF4352
  static const Color danger600 = Color(0xffEF4352);
  
  /// #E02D3C
  static const Color danger700 = Color(0xffE02D3C);
  
  /// #BA2532
  static const Color danger800 = Color(0xffBA2532);
  
  /// #981B25
  static const Color danger900 = Color(0xff981B25);
  
  /// #86131D
  static const Color danger1000 = Color(0xff86131D);

  // Common Colors
  static const Color white = Color(0xffFFFFFF);
  static const Color black = Color(0xff000000);
  static const Color transparent = Color(0x00000000);
  
  // Legacy Colors for backward compatibility
  static const Color background = Color(0xffF2F4F6);
  static const Color border1 = Color(0xffd9e8fb);
  static const Color noselect1 = Color(0xffd0d6dc);
  static const Color error = Color(0xffD7506B);
  
  // Alias for commonly used colors
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textTertiary = neutral500;
  static const Color backgroundPrimary = white;
  static const Color backgroundSecondary = neutral100;
  static const Color borderPrimary = neutral300;
  static const Color borderSecondary = neutral200;
}
