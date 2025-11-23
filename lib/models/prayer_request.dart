class PrayerRequest {
  final String? id; // UUID
  final String title;
  final String content;
  final String category;
  final String priority;
  final bool isPrivate;
  final bool isAnonymous; // 익명 여부 추가
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? memberId;
  final String? memberName;
  final int prayerCount; // 기도 카운트 추가
  final String? answeredTestimony; // 기도 응답 간증 추가

  const PrayerRequest({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    this.priority = 'normal',
    this.isPrivate = false,
    this.isAnonymous = false,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
    this.memberId,
    this.memberName,
    this.prayerCount = 0,
    this.answeredTestimony,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    // API 응답 필드를 확인하여 올바른 매핑 적용
    return PrayerRequest(
      id: json['id']?.toString(),
      title: json['title'] ?? json['prayer_title'] ?? json['requester_name'] ?? '제목 없음', // 여러 가능한 title 필드 확인
      content: json['prayer_content'] ?? json['content'] ?? '', // API에서 prayer_content 사용
      category: PrayerCategory.fromApiType(json['prayer_type'] ?? 'general'), // API prayer_type을 category로 변환
      priority: json['is_urgent'] == true ? 'urgent' : 'normal', // is_urgent로 우선순위 판단
      isPrivate: !(json['is_public'] ?? true), // is_public의 반대값이 isPrivate
      isAnonymous: json['is_anonymous'] ?? false,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      memberId: json['member_id']?.toInt(),
      memberName: json['requester_name'],
      prayerCount: json['prayer_count'] ?? 0,
      answeredTestimony: json['answered_testimony'],
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
    String? id,
    String? title,
    String? content,
    String? category,
    String? priority,
    bool? isPrivate,
    bool? isAnonymous,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberId,
    String? memberName,
    int? prayerCount,
    String? answeredTestimony,
  }) {
    return PrayerRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isPrivate: isPrivate ?? this.isPrivate,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      prayerCount: prayerCount ?? this.prayerCount,
      answeredTestimony: answeredTestimony ?? this.answeredTestimony,
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
  final bool isAnonymous; // 익명 여부 추가
  final String? requesterName;
  final String? requesterPhone;

  const PrayerRequestCreate({
    required this.title,
    required this.content,
    required this.category,
    this.priority = 'normal',
    this.isPrivate = false,
    this.isAnonymous = false,
    this.requesterName,
    this.requesterPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'prayer_content': content,  // API expects 'prayer_content'
      'prayer_type': PrayerCategory.toApiType(category), // category를 API prayer_type으로 변환
      'is_urgent': priority == 'urgent', // priority -> is_urgent
      'is_public': !isPrivate,    // isPrivate -> is_public (반대)
      'is_anonymous': isAnonymous, // 익명 여부
      'requester_name': requesterName ?? '익명',
      if (requesterPhone != null) 'requester_phone': requesterPhone,
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

// 중보 기도 카테고리 정의 (API 문서: general, healing, family, work, ministry)
class PrayerCategory {
  static const String general = 'general';   // 일반 기도
  static const String healing = 'healing';   // 치유 기도
  static const String family = 'family';     // 가정 기도
  static const String work = 'work';         // 직장/사업 기도
  static const String ministry = 'ministry'; // 사역 기도

  static const Map<String, String> categoryNames = {
    general: '일반',
    healing: '치유',
    family: '가정',
    work: '직장/사업',
    ministry: '사역',
  };

  // API prayer_type을 클라이언트 category로 변환
  static String fromApiType(String apiType) {
    switch (apiType) {
      case 'general':
        return general;
      case 'healing':
        return healing;
      case 'family':
        return family;
      case 'work':
        return work;
      case 'ministry':
        return ministry;
      default:
        return general;
    }
  }

  // 클라이언트 category를 API prayer_type으로 변환
  static String toApiType(String category) {
    return category; // 이제 API와 동일한 값 사용
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
