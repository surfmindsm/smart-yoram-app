/// 교인 직분(Position) 2단계 계층 구조 관리 상수
///
/// 백엔드 정책:
/// - position_main: 대분류 (CLERGY, ELDER, DEACONESS, DEACON, MEMBER)
/// - position_detail: 세부 직분 (SENIOR_PASTOR, EMERITUS_ELDER, HONORARY_DEACONESS 등)
/// - 주소록 필터링은 position_category 사용
class MemberPosition {
  // ===== 1. 직분 대분류 (position_main) =====
  static const String CLERGY = 'CLERGY';       // 교역자
  static const String ELDER = 'ELDER';         // 장로
  static const String DEACONESS = 'DEACONESS'; // 권사
  static const String DEACON = 'DEACON';       // 집사
  static const String MEMBER = 'MEMBER';       // 성도

  // ===== 2. 직분 세부 (position_detail) =====
  // 교역자 계열
  static const String SENIOR_PASTOR = 'SENIOR_PASTOR';               // 담임목사
  static const String EMERITUS_PASTOR = 'EMERITUS_PASTOR';           // 원로목사
  static const String ASSOCIATE_PASTOR = 'ASSOCIATE_PASTOR';         // 부목사
  static const String COOPERATE_PASTOR = 'COOPERATE_PASTOR';         // 협동목사
  static const String EVANGELIST = 'EVANGELIST';                     // 전도사
  static const String INTERN_EVANGELIST = 'INTERN_EVANGELIST';       // 전임전도사
  static const String EDUCATION_EVANGELIST = 'EDUCATION_EVANGELIST'; // 교육담당전도사

  // 장로 계열
  static const String ACTIVE_ELDER = 'ACTIVE_ELDER';                                 // 시무장로
  static const String EMERITUS_ELDER = 'EMERITUS_ELDER';                             // 원로장로
  static const String TRANSFERRED_EMERITUS_ELDER = 'TRANSFERRED_EMERITUS_ELDER';     // 이명은퇴장로

  // 권사 계열
  static const String HONORARY_DEACONESS = 'HONORARY_DEACONESS';     // 명예권사
  static const String ACTIVE_DEACONESS = 'ACTIVE_DEACONESS';         // 시무권사

  // 집사 계열
  static const String HONORARY_DEACON = 'HONORARY_DEACON';           // 명예집사
  static const String PROBATIONARY_DEACON = 'PROBATIONARY_DEACON';   // 서리집사
  static const String ACTIVE_DEACON = 'ACTIVE_DEACON';               // 집사
  static const String ORDAINED_DEACON = 'ORDAINED_DEACON';           // 안수집사

  // 기타
  static const String TEACHER = 'TEACHER';                           // 교사
  static const String STUDENT = 'STUDENT';                           // 학생

  // ===== 3. 한글 레이블 매핑 =====
  static const Map<String, String> positionMainLabels = {
    CLERGY: '교역자',
    ELDER: '장로',
    DEACONESS: '권사',
    DEACON: '집사',
    MEMBER: '성도',
  };

  static const Map<String, String> positionDetailLabels = {
    // 교역자
    SENIOR_PASTOR: '담임목사',
    EMERITUS_PASTOR: '원로목사',
    ASSOCIATE_PASTOR: '부목사',
    COOPERATE_PASTOR: '협동목사',
    EVANGELIST: '전도사',
    INTERN_EVANGELIST: '전임전도사',
    EDUCATION_EVANGELIST: '교육담당전도사',

    // 장로
    ACTIVE_ELDER: '시무장로',
    EMERITUS_ELDER: '원로장로',
    TRANSFERRED_EMERITUS_ELDER: '이명은퇴장로',

    // 권사
    HONORARY_DEACONESS: '명예권사',
    ACTIVE_DEACONESS: '시무권사',

    // 집사
    HONORARY_DEACON: '명예집사',
    PROBATIONARY_DEACON: '서리집사',
    ACTIVE_DEACON: '집사',
    ORDAINED_DEACON: '안수집사',

    // 기타
    TEACHER: '교사',
    STUDENT: '학생',
  };

  // ===== 4. 카테고리 코드 → 한글 레이블 =====
  static const Map<String, String> categoryLabels = {
    'CLERGY': '교역자',
    'ELDER': '장로',
    'DEACONESS': '권사',
    'DEACON': '집사',
    'YOUTH': '청년',
    'CHILDREN': '교회학교',
    'MEMBER': '성도',
  };

  // ===== 5. 주소록 탭 목록 =====
  static const List<String> addressBookCategories = [
    'CLERGY',
    'ELDER',
    'DEACONESS',
    'DEACON',
    'YOUTH',
    'CHILDREN',
    'MEMBER',
  ];

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

  // ===== 6. 일반 사용자용 드롭다운 옵션 (기본 직분만) =====
  static const List<Map<String, dynamic>> userOptions = [
    {
      'mainValue': MEMBER,
      'mainLabel': '성도',
      'details': []
    },
    {
      'mainValue': CLERGY,
      'mainLabel': '교역자',
      'details': [
        {'value': EVANGELIST, 'label': '전도사'},
      ]
    },
    {
      'mainValue': ELDER,
      'mainLabel': '장로',
      'details': [
        {'value': ACTIVE_ELDER, 'label': '장로'},
      ]
    },
    {
      'mainValue': DEACONESS,
      'mainLabel': '권사',
      'details': [
        {'value': ACTIVE_DEACONESS, 'label': '권사'},
      ]
    },
    {
      'mainValue': DEACON,
      'mainLabel': '집사',
      'details': [
        {'value': ACTIVE_DEACON, 'label': '집사'},
      ]
    },
  ];

  // ===== 7. 관리자/상세화면 드롭다운 옵션 (모든 직분 포함) =====
  static const List<Map<String, dynamic>> detailOptions = [
    {
      'mainValue': MEMBER,
      'mainLabel': '성도',
      'details': []
    },
    {
      'mainValue': CLERGY,
      'mainLabel': '교역자',
      'details': [
        {'value': SENIOR_PASTOR, 'label': '담임목사'},
        {'value': EMERITUS_PASTOR, 'label': '원로목사'},
        {'value': ASSOCIATE_PASTOR, 'label': '부목사'},
        {'value': COOPERATE_PASTOR, 'label': '협동목사'},
        {'value': EVANGELIST, 'label': '전도사'},
        {'value': INTERN_EVANGELIST, 'label': '전임전도사'},
        {'value': EDUCATION_EVANGELIST, 'label': '교육담당전도사'},
      ]
    },
    {
      'mainValue': ELDER,
      'mainLabel': '장로',
      'details': [
        {'value': ACTIVE_ELDER, 'label': '시무장로'},
        {'value': EMERITUS_ELDER, 'label': '원로장로'},
        {'value': TRANSFERRED_EMERITUS_ELDER, 'label': '이명은퇴장로'},
      ]
    },
    {
      'mainValue': DEACONESS,
      'mainLabel': '권사',
      'details': [
        {'value': ACTIVE_DEACONESS, 'label': '시무권사'},
        {'value': HONORARY_DEACONESS, 'label': '명예권사'},
      ]
    },
    {
      'mainValue': DEACON,
      'mainLabel': '집사',
      'details': [
        {'value': ACTIVE_DEACON, 'label': '집사'},
        {'value': ORDAINED_DEACON, 'label': '안수집사'},
        {'value': PROBATIONARY_DEACON, 'label': '서리집사'},
        {'value': HONORARY_DEACON, 'label': '명예집사'},
      ]
    },
  ];

  // ===== 8. 헬퍼 함수 =====

  /// position_main 한글 레이블 반환
  static String getMainLabel(String? main) {
    if (main == null || main.isEmpty) return '성도';
    return positionMainLabels[main] ?? '성도';
  }

  /// position_detail 한글 레이블 반환
  static String getDetailLabel(String? detail) {
    if (detail == null || detail.isEmpty) return '';
    return positionDetailLabels[detail] ?? '';
  }

  /// 전체 직분 표시 (대분류 + 세부)
  static String getFullLabel(String? main, String? detail) {
    final detailLabel = getDetailLabel(detail);
    if (detailLabel.isNotEmpty) {
      return detailLabel; // 세부 직분이 있으면 세부만 표시
    }
    return getMainLabel(main); // 세부가 없으면 대분류만 표시
  }

  /// 카테고리 레이블 반환
  static String getCategoryLabel(String? category) {
    if (category == null || category.isEmpty) return '성도';
    return categoryLabels[category] ?? '성도';
  }

  /// Position → Category 변환 (클라이언트 측 fallback)
  static String getPositionCategory(String? main, DateTime? birthDate) {
    // 1. 직분 우선 확인
    switch (main) {
      case CLERGY:
        return 'CLERGY';
      case ELDER:
        return 'ELDER';
      case DEACONESS:
        return 'DEACONESS';
      case DEACON:
        return 'DEACON';
    }

    // 2. 직분이 없거나 MEMBER인 경우 연령대로 분류
    if (birthDate != null) {
      final age = DateTime.now().year - birthDate.year;
      if (age <= 19) return 'CHILDREN';
      if (age >= 20 && age <= 35) return 'YOUTH';
    }

    // 3. 기본값
    return 'MEMBER';
  }

  /// 레거시: 한글 직분을 영문 코드로 변환 (하위 호환성)
  static Map<String, String?> labelToCode(String? label) {
    if (label == null || label.isEmpty) {
      return {'main': MEMBER, 'detail': null};
    }

    // 세부 직분 매칭
    for (var entry in positionDetailLabels.entries) {
      if (entry.value == label) {
        final detail = entry.key;
        String main = MEMBER;

        // 대분류 결정
        if ([SENIOR_PASTOR, EMERITUS_PASTOR, ASSOCIATE_PASTOR, COOPERATE_PASTOR, EVANGELIST, INTERN_EVANGELIST, EDUCATION_EVANGELIST].contains(detail)) {
          main = CLERGY;
        } else if ([ACTIVE_ELDER, EMERITUS_ELDER, TRANSFERRED_EMERITUS_ELDER].contains(detail)) {
          main = ELDER;
        } else if ([ACTIVE_DEACONESS, HONORARY_DEACONESS].contains(detail)) {
          main = DEACONESS;
        } else if ([ACTIVE_DEACON, ORDAINED_DEACON, PROBATIONARY_DEACON, HONORARY_DEACON].contains(detail)) {
          main = DEACON;
        }

        return {'main': main, 'detail': detail};
      }
    }

    // 대분류만 매칭
    for (var entry in positionMainLabels.entries) {
      if (entry.value == label) {
        return {'main': entry.key, 'detail': null};
      }
    }

    return {'main': MEMBER, 'detail': null};
  }
}
