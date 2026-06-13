import 'package:flutter/material.dart';

/// Church Round 1.2.0 — C 방향 컬러 토큰
/// 디자인 정책: docs/ver120/DESIGN_OVERVIEW.md §2.1
///
/// 기존 코드와의 호환을 위해 [NewAppColor] 클래스명과 primary*/neutral*/
/// success*/warning*/danger* 슬롯명은 유지하되, 값을 스카이(Sky) 액센트 +
/// 슬레이트(Slate) 중립 + 상태색 팔레트로 재정의했다.
class NewAppColor {
  // =========================================================================
  // Primary — Sky (스카이 액센트)
  //   주 버튼, 활성 아이콘/탭, 토글 ON, 포커스 링
  // =========================================================================
  static const Color primary100 = Color(0xfff0f9ff); // skyWash — 인포 박스 배경
  static const Color primary200 = Color(0xffe0f2fe); // skyTint — 아이콘 타일/칩 배경
  static const Color primary300 = Color(0xffbae6fd); // 보조 버튼 테두리
  static const Color primary400 = Color(0xff7dd3fc);
  static const Color primary500 = Color(0xff38bdf8);
  static const Color primary600 = Color(0xff0ea5e0); // skyPrimary — 메인 액센트
  static const Color primary700 = Color(0xff0284c7); // skyDeep — 강조 텍스트/아이콘
  static const Color primary800 = Color(0xff0369a1);
  static const Color primary900 = Color(0xff075985);
  static const Color primary1000 = Color(0xff0c4a6e);

  // =========================================================================
  // Secondary — Sky 보조 (단일 액센트 정책. 기존 슬롯 호환을 위해 sky 톤 유지)
  // =========================================================================
  static const Color secondary100 = Color(0xfff0f9ff);
  static const Color secondary200 = Color(0xffe0f2fe);
  static const Color secondary300 = Color(0xffbae6fd);
  static const Color secondary400 = Color(0xff7dd3fc);
  static const Color secondary500 = Color(0xff38bdf8);
  static const Color secondary600 = Color(0xff0ea5e0);
  static const Color secondary700 = Color(0xff0284c7);
  static const Color secondary800 = Color(0xff0369a1);
  static const Color secondary900 = Color(0xff075985);
  static const Color secondary1000 = Color(0xff0c4a6e);

  // =========================================================================
  // Neutral — Slate (슬레이트 중립)
  //   텍스트/아이콘/테두리/배경
  // =========================================================================
  static const Color neutral100 = Color(0xfff1f5f9); // borderSoft / canvas
  static const Color neutral200 = Color(0xffe2e8f0); // borderStrong — 입력 테두리
  static const Color neutral300 = Color(0xffcbd5e1); // iconFaint — chevron, 비활성
  static const Color neutral400 = Color(0xff94a3b8); // textTertiary — 플레이스홀더
  static const Color neutral500 = Color(0xff64748b); // textMuted — 설명문
  static const Color neutral600 = Color(0xff475569); // textSecondary — 보조 텍스트
  static const Color neutral700 = Color(0xff334155);
  static const Color neutral800 = Color(0xff1e293b); // textBody — 본문
  static const Color neutral900 = Color(0xff0f172a); // textStrong — 제목 강조
  static const Color neutral1000 = Color(0xff020617);

  // =========================================================================
  // Success — Emerald (거래확정 등)
  // =========================================================================
  static const Color success00 = Color(0xffecfdf5);
  static const Color success200 = Color(0xffd1fae5); // 배지 배경
  static const Color success300 = Color(0xffa7f3d0);
  static const Color success400 = Color(0xff6ee7b7);
  static const Color success500 = Color(0xff34d399);
  static const Color success600 = Color(0xff10b981);
  static const Color success700 = Color(0xff059669); // 메인 성공
  static const Color success800 = Color(0xff047857);
  static const Color success900 = Color(0xff065f46);
  static const Color success000 = Color(0xff064e3b);

  // =========================================================================
  // Warning — Amber (예약중 등)
  // =========================================================================
  static const Color warning100 = Color(0xfffffbeb);
  static const Color warning200 = Color(0xfffef3c7); // 배지 배경
  static const Color warning300 = Color(0xfffde68a);
  static const Color warning400 = Color(0xfffcd34d);
  static const Color warning500 = Color(0xfffbbf24);
  static const Color warning600 = Color(0xfff59e0b);
  static const Color warning700 = Color(0xffd97706); // 메인 경고
  static const Color warning800 = Color(0xffb45309);
  static const Color warning900 = Color(0xff92400e);
  static const Color warning1000 = Color(0xff78350f);

  // =========================================================================
  // Danger — Rose (로그아웃, 신고)
  // =========================================================================
  static const Color danger100 = Color(0xfffff1f2);
  static const Color danger200 = Color(0xffffe4e6); // 배경
  static const Color danger300 = Color(0xfffecdd3); // 테두리
  static const Color danger400 = Color(0xfffda4af);
  static const Color danger500 = Color(0xfffb7185);
  static const Color danger600 = Color(0xfff43f5e);
  static const Color danger700 = Color(0xffe11d48); // 메인 위험
  static const Color danger800 = Color(0xffbe123c);
  static const Color danger900 = Color(0xff9f1239);
  static const Color danger1000 = Color(0xff881337);

  // =========================================================================
  // Semantic Aliases — C 방향 정책 토큰 직접 노출 (신규)
  //   §2.1 정책 문서의 명명을 그대로 코드에서 사용 가능하도록 추가
  // =========================================================================

  // Sky
  static const Color skyPrimary = primary600; // #0EA5E0
  static const Color skyDeep = primary700; // #0284C7
  static const Color skyTint = primary200; // #E0F2FE
  static const Color skyWash = primary100; // #F0F9FF

  // Text
  static const Color textStrong = neutral900; // #0F172A
  static const Color textBody = neutral800; // #1E293B
  static const Color textSecondary = neutral600; // #475569
  static const Color textMuted = neutral500; // #64748B
  static const Color textTertiary = neutral400; // #94A3B8

  // Icon / Border
  static const Color iconFaint = neutral300; // #CBD5E1
  static const Color borderStrong = neutral200; // #E2E8F0
  static const Color borderSoft = neutral100; // #F1F5F9
  static const Color borderHair = Color(0xfff4f7fa); // 리스트 행 구분

  // Surface / Canvas
  static const Color surface = Color(0xffffffff);
  static const Color canvas = Color(0xffeef2f6); // 화면 배경 1
  static const Color canvasAlt = Color(0xfff1f5f9); // 화면 배경 2

  // Status (semantic shortcuts)
  static const Color dangerBg = danger200; // #FFE4E6
  static const Color dangerBorder = danger300; // #FECDD3
  static const Color warningBg = warning200; // #FEF3C7
  static const Color successBg = success200; // #D1FAE5

  // Focus ring / Shadow tints (with opacity은 사용처에서 적용)
  static const Color focusRing = skyPrimary; // rgba(14,165,224,.12) 사용
  static const Color buttonShadowTint = skyPrimary; // rgba(14,165,224,.32)
  static const Color floatingShadowTint = skyPrimary; // rgba(14,165,224,.42)
  static const Color sheetShadowTint = Color(0xff020817); // rgba(2,8,23,.25)

  // 기본
  static const Color transparent = Color.fromARGB(0, 0, 0, 0);
  static const Color white = Color(0xffffffff);
  static const Color black = Color.fromARGB(255, 0, 0, 0);
}
