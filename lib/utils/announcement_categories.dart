class AnnouncementCategories {
  // 카테고리 정의
  static const Map<String, Map<String, dynamic>> categories = {
    'worship': {
      'label': '예배/모임',
      'description': '예배, 각종 모임, 주요 일정',
      'subcategories': {
        'sunday_worship': '주일예배',
        'wednesday_worship': '수요예배',
        'dawn_prayer': '새벽기도',
        'special_worship': '특별예배',
        'group_meeting': '구역/속회 모임',
        'committee_meeting': '위원회 모임',
        'schedule': '주요 일정',
      }
    },
    'member_news': {
      'label': '교우 소식',
      'description': '부고, 결혼, 출산, 이사, 입원 등',
      'subcategories': {
        'obituary': '부고',
        'wedding': '결혼',
        'birth': '출산',
        'relocation': '이사',
        'hospitalization': '입원',
        'celebration': '축하',
        'other': '기타',
      }
    },
    'event': {
      'label': '행사/공지',
      'description': '행사, 봉사, 알림, 일반 공지',
      'subcategories': {
        'church_event': '교회 행사',
        'volunteer': '봉사 활동',
        'education': '교육/세미나',
        'registration': '등록/신청',
        'facility': '시설 관련',
        'notice': '일반 공지',
        'emergency': '긴급 공지',
      }
    },
  };

  // 카테고리 라벨 가져오기
  static String getCategoryLabel(String? category) {
    if (category == null) return '미분류';
    return categories[category]?['label'] ?? '미분류';
  }

  // 서브카테고리 라벨 가져오기
  static String getSubcategoryLabel(String? category, String? subcategory) {
    if (category == null || subcategory == null) return '';
    final categoryData = categories[category];
    if (categoryData == null) return '';
    final subcategories = categoryData['subcategories'] as Map<String, String>?;
    return subcategories?[subcategory] ?? '';
  }

  // 모든 카테고리 키 목록
  static List<String> getCategoryKeys() {
    return categories.keys.toList();
  }

  // 탭용 카테고리 목록 (전체 포함)
  static List<Map<String, String>> getTabCategories() {
    final result = [
      {'key': 'all', 'label': '전체'}
    ];
    
    for (final entry in categories.entries) {
      result.add({
        'key': entry.key,
        'label': entry.value['label'] as String,
      });
    }
    
    return result;
  }
}
