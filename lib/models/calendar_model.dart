class CalendarEvent {
  final int id;
  final String title;
  final String? description;
  final String eventType;
  final DateTime eventDate;
  final String? eventTime;
  final bool isRecurring;
  final int churchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.eventDate,
    this.eventTime,
    required this.isRecurring,
    required this.churchId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      eventType: json['event_type'],
      eventDate: DateTime.parse(json['event_date']),
      eventTime: json['event_time'],
      isRecurring: json['is_recurring'] ?? false,
      churchId: json['church_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'event_time': eventTime,
      'is_recurring': isRecurring,
      'church_id': churchId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class BirthdayEvent {
  final int memberId;
  final String memberName;
  final DateTime birthday;
  final int age;
  final int daysUntil;
  final String? profilePhotoUrl;

  BirthdayEvent({
    required this.memberId,
    required this.memberName,
    required this.birthday,
    required this.age,
    required this.daysUntil,
    this.profilePhotoUrl,
  });

  factory BirthdayEvent.fromJson(Map<String, dynamic> json) {
    return BirthdayEvent(
      memberId: json['member_id'],
      memberName: json['member_name'],
      birthday: DateTime.parse(json['birthday']),
      age: json['age'],
      daysUntil: json['days_until'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  bool get isToday => daysUntil == 0;
  bool get isTomorrow => daysUntil == 1;
  bool get isThisWeek => daysUntil <= 7;
}

// 이벤트 타입 상수
class EventType {
  static const String service = 'service';          // 예배
  static const String prayer = 'prayer';            // 기도회
  static const String bible_study = 'bible_study';  // 성경공부
  static const String meeting = 'meeting';          // 모임
  static const String birthday = 'birthday';        // 생일
  static const String special = 'special';          // 특별행사
  static const String conference = 'conference';    // 컨퍼런스
  static const String retreat = 'retreat';          // 수련회
  
  static List<String> get all => [
    service,
    prayer,
    bible_study,
    meeting,
    birthday,
    special,
    conference,
    retreat,
  ];
  
  static String getDisplayName(String type) {
    switch (type) {
      case service:
        return '예배';
      case prayer:
        return '기도회';
      case bible_study:
        return '성경공부';
      case meeting:
        return '모임';
      case birthday:
        return '생일';
      case special:
        return '특별행사';
      case conference:
        return '컨퍼런스';
      case retreat:
        return '수련회';
      default:
        return type;
    }
  }
  
  static String getIcon(String type) {
    switch (type) {
      case service:
        return '🙏';
      case prayer:
        return '🤲';
      case bible_study:
        return '📖';
      case meeting:
        return '👥';
      case birthday:
        return '🎂';
      case special:
        return '🎉';
      case conference:
        return '🎤';
      case retreat:
        return '🏕️';
      default:
        return '📅';
    }
  }
}
