class PrayerRequest {
  final int? id;
  final String title;
  final String content;
  final String category;
  final String priority;
  final bool isPrivate;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? memberId;
  final String? memberName;

  const PrayerRequest({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    this.priority = 'normal',
    this.isPrivate = false,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
    this.memberId,
    this.memberName,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    // API 응답 필드를 확인하여 올바른 매핑 적용
    return PrayerRequest(
      id: json['id']?.toInt(),
      title: json['title'] ?? json['prayer_title'] ?? json['requester_name'] ?? '제목 없음', // 여러 가능한 title 필드 확인
      content: json['prayer_content'] ?? json['content'] ?? '', // API에서 prayer_content 사용
      category: PrayerCategory.fromApiType(json['prayer_type'] ?? 'general'), // API prayer_type을 category로 변환
      priority: json['is_urgent'] == true ? 'urgent' : 'normal', // is_urgent로 우선순위 판단
      isPrivate: !(json['is_public'] ?? true), // is_public의 반대값이 isPrivate
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      memberId: json['member_id']?.toInt(),
      memberName: json['requester_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'is_private': isPrivate,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (memberId != null) 'member_id': memberId,
      if (memberName != null) 'member_name': memberName,
    };
  }

  PrayerRequest copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? priority,
    bool? isPrivate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberId,
    String? memberName,
  }) {
    return PrayerRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isPrivate: isPrivate ?? this.isPrivate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
    );
  }

  @override
  String toString() {
    return 'PrayerRequest(id: $id, title: $title, category: $category, status: $status, isPrivate: $isPrivate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PrayerRequestCreate {
  final String title;
  final String content;
  final String category;
  final String priority;
  final bool isPrivate;
  final String? requesterName;

  const PrayerRequestCreate({
    required this.title,
    required this.content,
    required this.category,
    this.priority = 'normal',
    this.isPrivate = false,
    this.requesterName,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,  // 기도 제목은 title 필드로 전송
      'requester_name': isPrivate ? '익명' : (requesterName ?? '익명'), // 비공개일 때만 익명, 공개일 때는 실제 이름
      'prayer_content': content,  // API expects 'prayer_content'
      'prayer_type': PrayerCategory.toApiType(category), // category를 API prayer_type으로 변환
      'is_urgent': priority == 'urgent', // priority -> is_urgent
      'is_public': !isPrivate,    // isPrivate -> is_public (반대)
    };
  }
}

class PrayerRequestUpdate {
  final String? title;
  final String? content;
  final String? category;
  final String? priority;
  final bool? isPrivate;
  final String? status;

  const PrayerRequestUpdate({
    this.title,
    this.content,
    this.category,
    this.priority,
    this.isPrivate,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title; // 기도 제목은 title 필드로 전송
    if (content != null) data['prayer_content'] = content; // content -> prayer_content  
    if (category != null) data['prayer_type'] = PrayerCategory.toApiType(category!); // category를 API prayer_type으로 변환
    if (priority != null) data['is_urgent'] = (priority == 'urgent'); // priority -> is_urgent
    if (isPrivate != null) data['is_public'] = !isPrivate!; // isPrivate -> is_public (반대)
    if (status != null) data['status'] = status;
    return data;
  }
}

// 중보 기도 카테고리 정의
class PrayerCategory {
  static const String personal = 'personal';
  static const String family = 'family';
  static const String church = 'church';
  static const String mission = 'mission';
  static const String healing = 'healing';
  static const String guidance = 'guidance';
  static const String general = 'general'; // API에서 사용하는 일반 카테고리

  static const Map<String, String> categoryNames = {
    personal: '개인',
    family: '가족',
    church: '교회',
    mission: '선교',
    healing: '치유',
    guidance: '인도',
    general: '일반', // API general 카테고리 추가
  };
  
  // API prayer_type을 클라이언트 category로 변환
  static String fromApiType(String apiType) {
    switch (apiType) {
      case 'general':
        return personal; // general을 personal로 매핑
      case 'family':
        return family;
      case 'church':
        return church;
      case 'mission':
        return mission;
      case 'healing':
        return healing;
      case 'guidance':
        return guidance;
      default:
        return personal;
    }
  }
  
  // 클라이언트 category를 API prayer_type으로 변환
  static String toApiType(String category) {
    switch (category) {
      case personal:
        return 'general'; // personal을 general로 매핑
      case family:
        return 'family';
      case church:
        return 'church';
      case mission:
        return 'mission';
      case healing:
        return 'healing';
      case guidance:
        return 'guidance';
      default:
        return 'general';
    }
  }

  static List<String> get allCategories => categoryNames.keys.toList();
  
  static String getCategoryName(String category) {
    return categoryNames[category] ?? '기타';
  }
}

// 중보 기도 우선순위 정의
class PrayerPriority {
  static const String urgent = 'urgent';
  static const String high = 'high';
  static const String normal = 'normal';
  static const String low = 'low';

  static const Map<String, String> priorityNames = {
    urgent: '긴급',
    high: '높음',
    normal: '보통',
    low: '낮음',
  };

  static List<String> get allPriorities => priorityNames.keys.toList();
  
  static String getPriorityName(String priority) {
    return priorityNames[priority] ?? '보통';
  }
}

// 중보 기도 상태 정의
class PrayerStatus {
  static const String active = 'active';
  static const String answered = 'answered';
  static const String closed = 'closed';
  static const String paused = 'paused';

  static const Map<String, String> statusNames = {
    active: '진행중',
    answered: '응답됨',
    closed: '종료됨',
    paused: '일시정지',
  };

  static List<String> get allStatuses => statusNames.keys.toList();
  
  static String getStatusName(String status) {
    return statusNames[status] ?? '진행중';
  }
}
