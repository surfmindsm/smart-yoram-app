class WorshipService {
  final int id;
  final int churchId;
  final String name;
  final String location;
  final int dayOfWeek; // 0=일요일, 1=월요일, ... 6=토요일
  final DateTime startTime;
  final DateTime endTime;
  final String serviceType;
  final String targetGroup;
  final bool isOnline;
  final bool isActive;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorshipService({
    required this.id,
    required this.churchId,
    required this.name,
    required this.location,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.serviceType,
    required this.targetGroup,
    required this.isOnline,
    required this.isActive,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorshipService.fromJson(Map<String, dynamic> json) {
    return WorshipService(
      id: json['id'] ?? 0,
      churchId: json['church_id'] ?? 0,
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 0,
      startTime: _parseTimeField(json['start_time']),
      endTime: _parseTimeField(json['end_time']),
      serviceType: json['service_type'] ?? '',
      targetGroup: json['target_group'] ?? '',
      isOnline: json['is_online'] ?? false,
      isActive: json['is_active'] ?? true,
      orderIndex: json['order_index'] ?? 0,
      createdAt: _parseDateTimeField(json['created_at']),
      updatedAt: _parseDateTimeField(json['updated_at']),
    );
  }

  // 시간 필드 파싱 (HH:mm:ss 또는 ISO 형식 지원)
  static DateTime _parseTimeField(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return DateTime.now();
    }

    try {
      // ISO 형식인지 확인 (YYYY-MM-DDTHH:mm:ss 형식)
      if (timeString.contains('T') || timeString.contains('-')) {
        return DateTime.parse(timeString);
      }

      // HH:mm:ss 형식인 경우 오늘 날짜와 결합
      final today = DateTime.now();
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final second =
            timeParts.length >= 3 ? (int.tryParse(timeParts[2]) ?? 0) : 0;

        return DateTime(
            today.year, today.month, today.day, hour, minute, second);
      }

      // 파싱 실패 시 현재 시간 반환
      return DateTime.now();
    } catch (e) {
      print('⚠️ WORSHIP_SERVICE: 시간 파싱 오류 ($timeString): $e');
      return DateTime.now();
    }
  }

  // 날짜시간 필드 파싱
  static DateTime _parseDateTimeField(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return DateTime.now();
    }

    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      print('⚠️ WORSHIP_SERVICE: 날짜시간 파싱 오류 ($dateTimeString): $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'church_id': churchId,
      'name': name,
      'location': location,
      'day_of_week': dayOfWeek,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'service_type': serviceType,
      'target_group': targetGroup,
      'is_online': isOnline,
      'is_active': isActive,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 편의 메서드들
  String get formattedStartTime {
    final hour = startTime.hour;
    final minute = startTime.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    if (minute == 0) {
      return '$period ${displayHour}시';
    } else {
      return '$period ${displayHour}시 ${minute}분';
    }
  }

  String get formattedTimeRange {
    return '$formattedStartTime - ${_formatTime(endTime)}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    if (minute == 0) {
      return '$period ${displayHour}시';
    } else {
      return '$period ${displayHour}시 ${minute}분';
    }
  }

  String get dayOfWeekName {
    // 백엔드 정의: 0=월요일, 1=화요일, 2=수요일, 3=목요일, 4=금요일, 5=토요일, 6=일요일
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return days[dayOfWeek % 7];
  }

  // 요일 짧은 형식
  String get dayOfWeekShort {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[dayOfWeek % 7];
  }
}
