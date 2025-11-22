import 'member.dart';

class PastoralCareRequest {
  final String id; // UUID
  final int churchId;
  final int? memberId;
  final String requesterName;
  final String requesterPhone;
  final String requestType;
  final String? requestContent;
  final String priority;
  final DateTime? preferredDate;
  final String? preferredTimeStart;
  final String? preferredTimeEnd;
  final String? contactInfo;
  final bool isUrgent;
  final String status;
  final String? adminNotes;
  final int? assignedPastorId;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String? completionNotes;
  // 방문지 주소/좌표
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final Member? member; // 요청자 정보
  // 추가 필드 (Edge Function 응답)
  final String? organizationName;
  final String? department;
  final String? profilePhotoUrl;

  const PastoralCareRequest({
    required this.id,
    required this.churchId,
    this.memberId,
    required this.requesterName,
    required this.requesterPhone,
    required this.requestType,
    this.requestContent,
    required this.priority,
    this.preferredDate,
    this.preferredTimeStart,
    this.preferredTimeEnd,
    this.contactInfo,
    required this.isUrgent,
    required this.status,
    this.adminNotes,
    this.assignedPastorId,
    this.scheduledDate,
    this.scheduledTime,
    this.completionNotes,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.member,
    this.organizationName,
    this.department,
    this.profilePhotoUrl,
  });

  // 하위 호환성을 위한 getter
  String get title => requestContent?.split('\n').first ?? '';
  String get description => requestContent ?? '';
  String? get assignedTo => assignedPastorId?.toString();
  String? get preferredTime => preferredTimeStart;

  factory PastoralCareRequest.fromJson(Map<String, dynamic> json) {
    return PastoralCareRequest(
      id: json['id']?.toString() ?? '',
      churchId: json['church_id'] ?? 0,
      memberId: json['member_id'],
      requesterName: json['requester_name'] ?? '',
      requesterPhone: json['requester_phone'] ?? '',
      requestType: json['request_type'] ?? 'general',
      requestContent: json['request_content'] ?? json['description'],
      priority: json['priority'] ?? 'normal',
      preferredDate: json['preferred_date'] != null
          ? DateTime.parse(json['preferred_date'])
          : null,
      preferredTimeStart: json['preferred_time_start']?.toString(),
      preferredTimeEnd: json['preferred_time_end']?.toString(),
      contactInfo: json['contact_info'],
      isUrgent: json['is_urgent'] ?? false,
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      assignedPastorId: json['assigned_pastor_id'],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      scheduledTime: json['scheduled_time']?.toString(),
      completionNotes: json['completion_notes'],
      address: json['address'],
      latitude: (() {
        final v = json['latitude'] ?? json['lat'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      })(),
      longitude: (() {
        final v = json['longitude'] ?? json['lng'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      })(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      member: json['member'] != null
          ? Member.fromJson(json['member'] as Map<String, dynamic>)
          : null,
      organizationName: json['organization_name'],
      department: json['department'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'church_id': churchId,
      'member_id': memberId,
      'requester_name': requesterName,
      'requester_phone': requesterPhone,
      'request_type': requestType,
      'request_content': requestContent,
      'priority': priority,
      'preferred_date': preferredDate?.toIso8601String().split('T')[0],
      'preferred_time_start': preferredTimeStart,
      'preferred_time_end': preferredTimeEnd,
      'contact_info': contactInfo,
      'is_urgent': isUrgent,
      'status': status,
      'admin_notes': adminNotes,
      'assigned_pastor_id': assignedPastorId,
      'scheduled_date': scheduledDate?.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'completion_notes': completionNotes,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
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
      case 'scheduled':
        return '예정됨';
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
      case 'urgent':
        return '긴급';
      case 'high':
        return '높음';
      case 'normal':
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
      case 'general':
        return '일반 심방';
      case 'urgent':
        return '긴급 심방';
      case 'hospital':
        return '병원 심방';
      case 'counseling':
        return '상담';
      // 하위 호환성
      case 'visit':
        return '심방';
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
  final String? preferredTimeStart;
  final String? preferredTimeEnd;
  final String? contactInfo;
  final bool isUrgent;
  final String? requesterName;
  final String? requesterPhone;
  // 방문지 주소/좌표 (옵션)
  final String? address;
  final String? detailAddress;
  final double? latitude;
  final double? longitude;

  const PastoralCareRequestCreate({
    required this.requestType,
    required this.priority,
    required this.title,
    required this.description,
    this.preferredDate,
    this.preferredTimeStart,
    this.preferredTimeEnd,
    this.contactInfo,
    this.isUrgent = false,
    this.requesterName,
    this.requesterPhone,
    this.address,
    this.detailAddress,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'request_type': requestType,
      'priority': priority,
      'request_content': description,  // API에서 요구하는 필드
      'is_urgent': isUrgent,
      'requester_name': requesterName ?? '',
      'requester_phone': requesterPhone ?? '',
    };

    // null이 아닌 경우만 추가
    if (preferredDate != null && preferredDate!.isNotEmpty) {
      json['preferred_date'] = preferredDate;
    }
    if (preferredTimeStart != null && preferredTimeStart!.isNotEmpty) {
      json['preferred_time_start'] = preferredTimeStart;
    }
    if (preferredTimeEnd != null && preferredTimeEnd!.isNotEmpty) {
      json['preferred_time_end'] = preferredTimeEnd;
    }
    if (contactInfo != null && contactInfo!.isNotEmpty) {
      json['contact_info'] = contactInfo;
    }
    if (address != null && address!.isNotEmpty) {
      // 주소와 상세주소를 합쳐서 전송
      String fullAddress = address!;
      if (detailAddress != null && detailAddress!.isNotEmpty) {
        fullAddress += ' ${detailAddress!}';
      }
      json['address'] = fullAddress;
    }
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    if (longitude != null) {
      json['longitude'] = longitude;
    }

    return json;
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
  // 방문지 주소/좌표 (옵션)
  final String? address;
  final double? latitude;
  final double? longitude;

  const PastoralCareRequestUpdate({
    this.requestType,
    this.priority,
    this.title,
    this.description,
    this.preferredDate,
    this.preferredTime,
    this.contactInfo,
    this.isUrgent,
    this.address,
    this.latitude,
    this.longitude,
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
    if (address != null) json['address'] = address;
    if (latitude != null) json['latitude'] = latitude;
    if (longitude != null) json['longitude'] = longitude;
    
    return json;
  }
}

/// 심방 신청 유형 상수
class PastoralCareRequestType {
  static const String general = 'general';
  static const String urgent = 'urgent';
  static const String hospital = 'hospital';
  static const String counseling = 'counseling';

  static const List<String> all = [general, urgent, hospital, counseling];

  static const Map<String, String> displayNames = {
    general: '일반 심방',
    urgent: '긴급 심방',
    hospital: '병원 심방',
    counseling: '상담',
  };
}

/// 우선순위 상수
class PastoralCarePriority {
  static const String urgent = 'urgent';
  static const String high = 'high';
  static const String normal = 'normal';
  static const String low = 'low';

  static const List<String> all = [urgent, high, normal, low];

  static const Map<String, String> displayNames = {
    urgent: '긴급',
    high: '높음',
    normal: '보통',
    low: '낮음',
  };
}
