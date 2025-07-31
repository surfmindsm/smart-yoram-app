class Attendance {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime serviceDate;
  final String serviceType; // 주일예배, 수요예배, 새벽예배 등
  final bool present;
  final String? notes;

  Attendance({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.serviceDate,
    required this.serviceType,
    required this.present,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      memberId: json['member_id'],
      memberName: json['member_name'],
      serviceDate: DateTime.parse(json['service_date']),
      serviceType: json['service_type'],
      present: json['present'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'member_name': memberName,
      'service_date': serviceDate.toIso8601String(),
      'service_type': serviceType,
      'present': present,
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
