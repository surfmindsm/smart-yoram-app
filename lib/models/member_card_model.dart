class MemberCard {
  final MemberCardData member;
  final ChurchCardData church;
  final MemberCardQRCode qrCode;
  final MemberCardStatistics statistics;

  MemberCard({
    required this.member,
    required this.church,
    required this.qrCode,
    required this.statistics,
  });

  factory MemberCard.fromJson(Map<String, dynamic> json) {
    return MemberCard(
      member: MemberCardData.fromJson(json['member']),
      church: ChurchCardData.fromJson(json['church']),
      qrCode: MemberCardQRCode.fromJson(json['qr_code']),
      statistics: MemberCardStatistics.fromJson(json['statistics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member': member.toJson(),
      'church': church.toJson(),
      'qr_code': qrCode.toJson(),
      'statistics': statistics.toJson(),
    };
  }
}

class MemberCardData {
  final int id;
  final String name;
  final String? profilePhotoUrl;
  final String phoneNumber;
  final String position;
  final String district;
  final int age;
  final String memberStatus;

  MemberCardData({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
    required this.phoneNumber,
    required this.position,
    required this.district,
    required this.age,
    required this.memberStatus,
  });

  factory MemberCardData.fromJson(Map<String, dynamic> json) {
    return MemberCardData(
      id: json['id'],
      name: json['name'],
      profilePhotoUrl: json['profile_photo_url'],
      phoneNumber: json['phone_number'],
      position: json['position'],
      district: json['district'],
      age: json['age'],
      memberStatus: json['member_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_photo_url': profilePhotoUrl,
      'phone_number': phoneNumber,
      'position': position,
      'district': district,
      'age': age,
      'member_status': memberStatus,
    };
  }
}

class ChurchCardData {
  final String name;
  final String address;
  final String phone;

  ChurchCardData({
    required this.name,
    required this.address,
    required this.phone,
  });

  factory ChurchCardData.fromJson(Map<String, dynamic> json) {
    return ChurchCardData(
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
    };
  }
}

class MemberCardQRCode {
  final String code;
  final String imageBase64;

  MemberCardQRCode({
    required this.code,
    required this.imageBase64,
  });

  factory MemberCardQRCode.fromJson(Map<String, dynamic> json) {
    return MemberCardQRCode(
      code: json['code'],
      imageBase64: json['image_base64'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'image_base64': imageBase64,
    };
  }
}

class MemberCardStatistics {
  final int recentAttendanceCount;
  final String memberSince;

  MemberCardStatistics({
    required this.recentAttendanceCount,
    required this.memberSince,
  });

  factory MemberCardStatistics.fromJson(Map<String, dynamic> json) {
    return MemberCardStatistics(
      recentAttendanceCount: json['recent_attendance_count'],
      memberSince: json['member_since'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recent_attendance_count': recentAttendanceCount,
      'member_since': memberSince,
    };
  }
}
