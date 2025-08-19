import 'member.dart';

class PastoralCareRequest {
  final int id;
  final int memberId;
  final String requestType;
  final String priority;
  final String title;
  final String description;
  final String? preferredDate;
  final String? preferredTime;
  final String? contactInfo;
  final bool isUrgent;
  final String status;
  final String? adminNotes;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final Member? member; // 요청자 정보

  const PastoralCareRequest({
    required this.id,
    required this.memberId,
    required this.requestType,
    required this.priority,
    required this.title,
    required this.description,
    this.preferredDate,
    this.preferredTime,
    this.contactInfo,
    required this.isUrgent,
    required this.status,
    this.adminNotes,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.member,
  });

  factory PastoralCareRequest.fromJson(Map<String, dynamic> json) {
    return PastoralCareRequest(
      id: json['id'] as int,
      memberId: json['member_id'] as int,
      requestType: json['request_type'] as String,
      priority: json['priority'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      preferredDate: json['preferred_date'] as String?,
      preferredTime: json['preferred_time'] as String?,
      contactInfo: json['contact_info'] as String?,
      isUrgent: json['is_urgent'] as bool,
      status: json['status'] as String,
      adminNotes: json['admin_notes'] as String?,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      member: json['member'] != null 
          ? Member.fromJson(json['member'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'request_type': requestType,
      'priority': priority,
      'title': title,
      'description': description,
      'preferred_date': preferredDate,
      'preferred_time': preferredTime,
      'contact_info': contactInfo,
      'is_urgent': isUrgent,
      'status': status,
      'admin_notes': adminNotes,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'member': member?.toJson(),
    };
  }

  /// 상태별 색상 반환
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // 주황색
      case 'approved':
        return '#4CAF50'; // 녹색
      case 'in_progress':
        return '#2196F3'; // 파란색
      case 'completed':
        return '#9E9E9E'; // 회색
      case 'cancelled':
        return '#F44336'; // 빨간색
      default:
        return '#757575'; // 기본 회색
    }
  }

  /// 상태별 한글명 반환
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return '대기중';
      case 'approved':
        return '승인됨';
      case 'in_progress':
        return '진행중';
      case 'completed':
        return '완료됨';
      case 'cancelled':
        return '취소됨';
      default:
        return '알 수 없음';
    }
  }

  /// 우선순위별 한글명 반환
  String get priorityDisplayName {
    switch (priority.toLowerCase()) {
      case 'high':
        return '높음';
      case 'medium':
        return '보통';
      case 'low':
        return '낮음';
      default:
        return '보통';
    }
  }

  /// 신청 유형별 한글명 반환
  String get requestTypeDisplayName {
    switch (requestType.toLowerCase()) {
      case 'visit':
        return '심방';
      case 'counseling':
        return '상담';
      case 'prayer':
        return '기도';
      case 'emergency':
        return '응급상황';
      case 'other':
        return '기타';
      default:
        return requestType;
    }
  }

  /// 수정 가능 여부 확인
  bool get canEdit => status.toLowerCase() == 'pending';

  /// 취소 가능 여부 확인
  bool get canCancel => status.toLowerCase() == 'pending';
}

/// 심방 신청 생성 요청 모델
class PastoralCareRequestCreate {
  final String requestType;
  final String priority;
  final String title;
  final String description;
  final String? preferredDate;
  final String? preferredTime;
  final String? contactInfo;
  final bool isUrgent;

  const PastoralCareRequestCreate({
    required this.requestType,
    required this.priority,
    required this.title,
    required this.description,
    this.preferredDate,
    this.preferredTime,
    this.contactInfo,
    this.isUrgent = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_type': requestType,
      'priority': priority,
      'title': title,
      'description': description,
      'preferred_date': preferredDate,
      'preferred_time': preferredTime,
      'contact_info': contactInfo,
      'is_urgent': isUrgent,
    };
  }
}

/// 심방 신청 수정 요청 모델
class PastoralCareRequestUpdate {
  final String? requestType;
  final String? priority;
  final String? title;
  final String? description;
  final String? preferredDate;
  final String? preferredTime;
  final String? contactInfo;
  final bool? isUrgent;

  const PastoralCareRequestUpdate({
    this.requestType,
    this.priority,
    this.title,
    this.description,
    this.preferredDate,
    this.preferredTime,
    this.contactInfo,
    this.isUrgent,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    
    if (requestType != null) json['request_type'] = requestType;
    if (priority != null) json['priority'] = priority;
    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (preferredDate != null) json['preferred_date'] = preferredDate;
    if (preferredTime != null) json['preferred_time'] = preferredTime;
    if (contactInfo != null) json['contact_info'] = contactInfo;
    if (isUrgent != null) json['is_urgent'] = isUrgent;
    
    return json;
  }
}

/// 심방 신청 유형 상수
class PastoralCareRequestType {
  static const String visit = 'visit';
  static const String counseling = 'counseling';
  static const String prayer = 'prayer';
  static const String emergency = 'emergency';
  static const String other = 'other';

  static const List<String> all = [visit, counseling, prayer, emergency, other];
  
  static const Map<String, String> displayNames = {
    visit: '심방',
    counseling: '상담',
    prayer: '기도',
    emergency: '응급상황',
    other: '기타',
  };
}

/// 우선순위 상수
class PastoralCarePriority {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';

  static const List<String> all = [high, medium, low];
  
  static const Map<String, String> displayNames = {
    high: '높음',
    medium: '보통',
    low: '낮음',
  };
}
