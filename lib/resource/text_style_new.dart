import 'package:flutter/material.dart';

/// Church Round 1.2.0 — C 방향 타이포그래피 토큰
/// 디자인 정책: docs/ver120/DESIGN_OVERVIEW.md §2.2
/// 폰트: Pretendard (pubspec.yaml에 등록되어 있어 fontFamily는 앱 테마에서 일괄 적용).
///
/// 기존 코드와의 호환을 위해 [FigmaTextStyles] 클래스명과 getter 슬롯은
/// 유지하되, 값은 §2.2 역할별 크기/굵기/letter-spacing에 맞춰 재정의했다.
class FigmaTextStyles {
  const FigmaTextStyles();

  // ===========================================================================
  // 정책 §2.2 — 역할별 핵심 스타일 (신규 의미 토큰)
  // ===========================================================================

  /// 화면 타이틀(앱바): 18px / 800, -.01em
  TextStyle get appBarTitle => const TextStyle(
        fontSize: 18,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 24 / 18,
        letterSpacing: -0.18, // -.01em
      );

  /// 큰 제목(온보딩·상세): 22–23px / 800
  TextStyle get pageTitle => const TextStyle(
        fontSize: 22,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 30 / 22,
        letterSpacing: -0.22,
      );

  /// 카드/행 제목: 15–16px / 700
  TextStyle get cardTitle => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 24 / 16,
        letterSpacing: -0.16,
      );

  /// 카드/행 제목 (작은): 15px / 700
  TextStyle get cardTitleSm => const TextStyle(
        fontSize: 15,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 22 / 15,
        letterSpacing: -0.15,
      );

  /// 섹션 헤더: 12px / 700, .03em, 보통 textTertiary
  TextStyle get sectionHeader => const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 16 / 12,
        letterSpacing: 0.36, // .03em
      );

  /// 배지/칩: 11–12px / 700–800
  TextStyle get badge => const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 16 / 12,
        letterSpacing: 0,
      );

  /// 배지/칩 (작은): 11px / 800
  TextStyle get badgeSm => const TextStyle(
        fontSize: 11,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 14 / 11,
        letterSpacing: 0,
      );

  /// 탭바 라벨: 10px
  TextStyle get tabLabel => const TextStyle(
        fontSize: 10,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 14 / 10,
        letterSpacing: 0,
      );

  // ===========================================================================
  // Headers (기존 슬롯 유지 — 값은 정책 기준으로 재정의)
  // ===========================================================================

  TextStyle get header1 => const TextStyle(
        fontSize: 28,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 36 / 28,
        letterSpacing: -0.28,
      );

  TextStyle get header2 => const TextStyle(
        fontSize: 24,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 32 / 24,
        letterSpacing: -0.24,
      );

  // ===========================================================================
  // Subtitles (기존 슬롯 유지)
  //   subtitle1: 앱바/큰 제목 영역, subtitle2~4: 카드/행 제목
  // ===========================================================================

  TextStyle get subtitle1 => const TextStyle(
        fontSize: 18,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 24 / 18,
        letterSpacing: -0.18,
      );

  TextStyle get subtitle2 => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 24 / 16,
        letterSpacing: -0.16,
      );

  TextStyle get subtitle3 => const TextStyle(
        fontSize: 14,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 20 / 14,
        letterSpacing: -0.14,
      );

  TextStyle get subtitle4 => const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 18 / 12,
        letterSpacing: 0,
      );

  // ===========================================================================
  // Body Text (기존 슬롯 유지)
  //   §2.2 본문: 14–15px / 500–600, line-height 1.5–1.7
  // ===========================================================================

  TextStyle get bodyText1 => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 26 / 16,
        letterSpacing: -0.16,
      );

  TextStyle get bodyText2 => const TextStyle(
        fontSize: 14,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 22 / 14,
        letterSpacing: -0.14,
      );

  // ===========================================================================
  // Captions (기존 슬롯 유지)
  //   §2.2 보조/설명: 12–13px / 500
  // ===========================================================================

  TextStyle get captionText1 => const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 18 / 12,
        letterSpacing: 0,
      );

  TextStyle get captionText2 => const TextStyle(
        fontSize: 10,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 14 / 10,
        letterSpacing: 0,
      );

  // ===========================================================================
  // Display Styles (기존 슬롯 유지)
  // ===========================================================================

  TextStyle get display1 => const TextStyle(
        fontSize: 56,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 72 / 56,
        letterSpacing: -0.56,
      );

  TextStyle get display2 => const TextStyle(
        fontSize: 48,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 62 / 48,
        letterSpacing: -0.48,
      );

  TextStyle get display3 => const TextStyle(
        fontSize: 40,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 52 / 40,
        letterSpacing: -0.4,
      );

  TextStyle get display4 => const TextStyle(
        fontSize: 36,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.36,
      );

  TextStyle get display5 => const TextStyle(
        fontSize: 32,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 42 / 32,
        letterSpacing: -0.32,
      );

  TextStyle get display6 => const TextStyle(
        fontSize: 28,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 38 / 28,
        letterSpacing: -0.28,
      );

  // ===========================================================================
  // Headlines (기존 슬롯 유지)
  // ===========================================================================

  TextStyle get headline1 => const TextStyle(
        fontSize: 32,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 42 / 32,
        letterSpacing: -0.32,
      );

  TextStyle get headline2 => const TextStyle(
        fontSize: 28,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 38 / 28,
        letterSpacing: -0.28,
      );

  TextStyle get headline3 => const TextStyle(
        fontSize: 24,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 34 / 24,
        letterSpacing: -0.24,
      );

  TextStyle get headline4 => const TextStyle(
        fontSize: 20,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: -0.2,
      );

  TextStyle get headline5 => const TextStyle(
        fontSize: 18,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w600,
        height: 26 / 18,
        letterSpacing: -0.18,
      );

  TextStyle get headline6 => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        letterSpacing: -0.16,
      );

  // ===========================================================================
  // Titles (기존 슬롯 유지)
  // ===========================================================================

  TextStyle get title1 => const TextStyle(
        fontSize: 24,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 34 / 24,
        letterSpacing: -0.24,
      );

  TextStyle get title2 => const TextStyle(
        fontSize: 20,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        letterSpacing: -0.2,
      );

  TextStyle get title3 => const TextStyle(
        fontSize: 18,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 26 / 18,
        letterSpacing: -0.18,
      );

  TextStyle get title4 => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        letterSpacing: -0.16,
      );

  // ===========================================================================
  // Body Text (Alternative, 기존 슬롯 유지)
  //   body1/body2/body3 — 본문/보조 본문
  // ===========================================================================

  TextStyle get body1 => const TextStyle(
        fontSize: 15,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 24 / 15, // line-height 1.6
        letterSpacing: -0.15,
      );

  TextStyle get body2 => const TextStyle(
        fontSize: 14,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 22 / 14, // line-height 1.57
        letterSpacing: -0.14,
      );

  TextStyle get body3 => const TextStyle(
        fontSize: 13,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 20 / 13,
        letterSpacing: -0.13,
      );

  // ===========================================================================
  // Captions (Alternative, 기존 슬롯 유지)
  // ===========================================================================

  TextStyle get caption1 => const TextStyle(
        fontSize: 13,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 18 / 13,
        letterSpacing: -0.13,
      );

  TextStyle get caption2 => const TextStyle(
        fontSize: 12,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 18 / 12,
        letterSpacing: 0,
      );

  TextStyle get caption3 => const TextStyle(
        fontSize: 11,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        letterSpacing: 0,
      );

  // ===========================================================================
  // Buttons (기존 슬롯 유지)
  //   §3 주 버튼: 15px / 800
  // ===========================================================================

  TextStyle get button1 => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 24 / 16,
        letterSpacing: -0.16,
      );

  TextStyle get button2 => const TextStyle(
        fontSize: 15,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w800,
        height: 22 / 15,
        letterSpacing: -0.15,
      );

  TextStyle get button3 => const TextStyle(
        fontSize: 14,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 20 / 14,
        letterSpacing: -0.14,
      );

  TextStyle get button4 => const TextStyle(
        fontSize: 13,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.w700,
        height: 18 / 13,
        letterSpacing: -0.13,
      );
}
