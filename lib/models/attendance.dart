class Attendance {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime date;
  final String serviceType; // 주일예배, 수요예배, 새벽예배 등
  final bool isPresent;
  final String? notes;

  Attendance({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.date,
    required this.serviceType,
    required this.isPresent,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      memberId: json['member_id'],
      memberName: json['member_name'],
      date: DateTime.parse(json['date']),
      serviceType: json['service_type'],
      isPresent: json['is_present'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'member_name': memberName,
      'date': date.toIso8601String(),
      'service_type': serviceType,
      'is_present': isPresent,
      'notes': notes,
    };
  }
}

class AttendanceStats {
  final int totalMembers;
  final int presentMembers;
  final double attendanceRate;
  final Map<String, int> byDistrict; // 구역별 출석
  final Map<String, int> byPosition; // 직분별 출석

  AttendanceStats({
    required this.totalMembers,
    required this.presentMembers,
    required this.attendanceRate,
    required this.byDistrict,
    required this.byPosition,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalMembers: json['total_members'],
      presentMembers: json['present_members'],
      attendanceRate: json['attendance_rate'].toDouble(),
      byDistrict: Map<String, int>.from(json['by_district']),
      byPosition: Map<String, int>.from(json['by_position']),
    );
  }
}
