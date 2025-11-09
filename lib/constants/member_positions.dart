/// 교인 직분(Position) 관련 상수 정의
///
/// 백엔드 정책:
/// - DB에는 영문 코드로 저장 (예: PASTOR, ELDER, DEACON)
/// - 화면에는 한글 레이블로 표시 (예: 목사, 장로, 집사)
/// - 주소록 필터링은 position_category 사용
class MemberPosition {
  // 직분 코드 → 한글 레이블
  static const Map<String, String> positionLabels = {
    // 교역자 계열
    'PASTOR': '목사',
    'EVANGELIST': '전도사',
    'EDUCATION_EVANGELIST': '교육전도사',
    'CLERGY': '교역자',
    // 장로 계열
    'ELDER': '장로',
    'RETIRED_ELDER': '은퇴장로',
    // 권사 계열
    'DEACONESS': '권사',
    'RETIRED_DEACONESS': '은퇴권사',
    // 집사 계열
    'DEACON': '집사',
    'ORDAINED_DEACON': '안수집사',
    // 기타
    'TEACHER': '교사',
    'MEMBER': '성도',
  };

  // 카테고리 코드 → 한글 레이블
  static const Map<String, String> categoryLabels = {
    'CLERGY': '교역자',
    'ELDER': '장로',
    'DEACONESS': '권사',
    'DEACON': '집사',
    'YOUTH': '청년',
    'CHILDREN': '교회학교',
    'MEMBER': '성도',
  };

  // 주소록 탭 목록 (카테고리 코드, 순서 중요)
  static const List<String> addressBookCategories = [
    'CLERGY',
    'ELDER',
    'DEACONESS',
    'DEACON',
    'YOUTH',
    'CHILDREN',
    'MEMBER',
  ];

  // 주소록 탭 한글 레이블 (전체 포함)
  static const List<String> addressBookTabs = [
    '전체',
    '교역자',
    '장로',
    '권사',
    '집사',
    '청년',
    '교회학교',
    '성도',
  ];

  // 일반 사용자용 드롭다운 옵션 (기본 직분만)
  static const List<Map<String, String>> userOptions = [
    {'value': 'MEMBER', 'label': '성도'},
    {'value': 'PASTOR', 'label': '목사'},
    {'value': 'EVANGELIST', 'label': '전도사'},
    {'value': 'ELDER', 'label': '장로'},
    {'value': 'DEACONESS', 'label': '권사'},
    {'value': 'DEACON', 'label': '집사'},
  ];

  // 관리자/상세화면 드롭다운 옵션 (모든 직분 포함)
  static const List<Map<String, String>> detailOptions = [
    {'value': 'MEMBER', 'label': '성도'},
    {'value': 'PASTOR', 'label': '목사'},
    {'value': 'EVANGELIST', 'label': '전도사'},
    {'value': 'EDUCATION_EVANGELIST', 'label': '교육전도사'},
    {'value': 'ELDER', 'label': '장로'},
    {'value': 'RETIRED_ELDER', 'label': '은퇴장로'},
    {'value': 'DEACONESS', 'label': '권사'},
    {'value': 'RETIRED_DEACONESS', 'label': '은퇴권사'},
    {'value': 'DEACON', 'label': '집사'},
    {'value': 'ORDAINED_DEACON', 'label': '안수집사'},
    {'value': 'TEACHER', 'label': '교사'},
  ];

  // 한글 레이블 반환 (직분)
  static String getLabel(String? code) {
    if (code == null || code.isEmpty) return '성도';
    return positionLabels[code] ?? code;
  }

  // 카테고리 레이블 반환
  static String getCategoryLabel(String? category) {
    if (category == null || category.isEmpty) return '성도';
    return categoryLabels[category] ?? category;
  }

  // 레거시 한글 직분을 영문 코드로 변환 (하위 호환성)
  static String labelToCode(String? label) {
    if (label == null || label.isEmpty) return 'MEMBER';

    const reverseMap = {
      '목사': 'PASTOR',
      '전도사': 'EVANGELIST',
      '교육전도사': 'EDUCATION_EVANGELIST',
      '교역자': 'CLERGY',
      '장로': 'ELDER',
      '은퇴장로': 'RETIRED_ELDER',
      '권사': 'DEACONESS',
      '은퇴권사': 'RETIRED_DEACONESS',
      '집사': 'DEACON',
      '안수집사': 'ORDAINED_DEACON',
      '교사': 'TEACHER',
      '성도': 'MEMBER',
    };

    return reverseMap[label] ?? 'MEMBER';
  }

  // Position → Category 변환 (클라이언트 측 fallback)
  static String getPositionCategory(String? position, DateTime? birthDate) {
    // 1. 직분 우선 확인
    switch (position) {
      case 'PASTOR':
      case 'EVANGELIST':
      case 'EDUCATION_EVANGELIST':
      case 'CLERGY':
        return 'CLERGY';

      case 'ELDER':
      case 'RETIRED_ELDER':
        return 'ELDER';

      case 'DEACONESS':
      case 'RETIRED_DEACONESS':
        return 'DEACONESS';

      case 'DEACON':
      case 'ORDAINED_DEACON':
        return 'DEACON';
    }

    // 2. 직분이 없거나 MEMBER/TEACHER인 경우 연령대로 분류
    if (birthDate != null) {
      final age = DateTime.now().year - birthDate.year;
      if (age <= 19) return 'CHILDREN';
      if (age >= 20 && age <= 35) return 'YOUTH';
    }

    // 3. 기본값
    return 'MEMBER';
  }
}
