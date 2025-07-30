class QRCodeInfo {
  final int id;
  final String code;
  final int memberId;
  final String memberName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  QRCodeInfo({
    required this.id,
    required this.code,
    required this.memberId,
    required this.memberName,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
  });

  factory QRCodeInfo.fromJson(Map<String, dynamic> json) {
    return QRCodeInfo(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      memberId: json['member_id'] ?? 0,
      memberName: json['member_name'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'member_id': memberId,
      'member_name': memberName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

class QRScanResult {
  final String status;
  final String message;
  final Member? member;
  final AttendanceRecord? attendance;

  QRScanResult({
    required this.status,
    required this.message,
    this.member,
    this.attendance,
  });

  factory QRScanResult.fromJson(Map<String, dynamic> json) {
    return QRScanResult(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      member: json['member'] != null 
          ? Member.fromJson(json['member']) 
          : null,
      attendance: json['attendance'] != null 
          ? AttendanceRecord.fromJson(json['attendance']) 
          : null,
    );
  }

  bool get isSuccess => status == 'success';
}

class AttendanceRecord {
  final int id;
  final int memberId;
  final String attendanceType;
  final DateTime attendanceDate;
  final DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.attendanceType,
    required this.attendanceDate,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      memberId: json['member_id'] ?? 0,
      attendanceType: json['attendance_type'] ?? '',
      attendanceDate: json['attendance_date'] != null 
          ? DateTime.parse(json['attendance_date']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'attendance_type': attendanceType,
      'attendance_date': attendanceDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Member 클래스 import가 필요하므로 따로 import 해야 함
class Member {
  final int id;
  final String name;
  final String? profilePhotoUrl;

  Member({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
}
