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
    return PrayerRequest(
      id: json['id']?.toInt(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'personal',
      priority: json['priority'] ?? 'normal',
      isPrivate: json['is_private'] ?? false,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      memberId: json['member_id']?.toInt(),
      memberName: json['member_name'],
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

  const PrayerRequestCreate({
    required this.title,
    required this.content,
    required this.category,
    this.priority = 'normal',
    this.isPrivate = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'is_private': isPrivate,
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
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (category != null) data['category'] = category;
    if (priority != null) data['priority'] = priority;
    if (isPrivate != null) data['is_private'] = isPrivate;
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

  static const Map<String, String> categoryNames = {
    personal: '개인',
    family: '가족',
    church: '교회',
    mission: '선교',
    healing: '치유',
    guidance: '인도',
  };

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
