class MemberCard {
  final MemberCardData? member;
  final ChurchCardData? church;
  final MemberCardQRCode? qrCode;
  final MemberCardStatistics? statistics;

  MemberCard({
    this.member,
    this.church,
    this.qrCode,
    this.statistics,
  });

  factory MemberCard.fromJson(Map<String, dynamic> json) {
    return MemberCard(
      member: json['member'] != null ? MemberCardData.fromJson(json['member']) : null,
      church: json['church'] != null ? ChurchCardData.fromJson(json['church']) : null,
      qrCode: json['qr_code'] != null ? MemberCardQRCode.fromJson(json['qr_code']) : null,
      statistics: json['statistics'] != null ? MemberCardStatistics.fromJson(json['statistics']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member': member?.toJson(),
      'church': church?.toJson(),
      'qr_code': qrCode?.toJson(),
      'statistics': statistics?.toJson(),
    };
  }
}

class MemberCardData {
  final int? id;
  final String? name;
  final String? profilePhotoUrl;
  final String? phone;
  final String? position;
  final String? district;
  final int? age;
  final String? memberStatus;

  MemberCardData({
    this.id,
    this.name,
    this.profilePhotoUrl,
    this.phone,
    this.position,
    this.district,
    this.age,
    this.memberStatus,
  });

  factory MemberCardData.fromJson(Map<String, dynamic> json) {
    return MemberCardData(
      id: json['id'],
      name: json['name'],
      profilePhotoUrl: json['profile_photo_url'],
      phone: json['phone'],
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
      'phone': phone,
      'position': position,
      'district': district,
      'age': age,
      'member_status': memberStatus,
    };
  }
}

class ChurchCardData {
  final String? name;
  final String? address;
  final String? phone;

  ChurchCardData({
    this.name,
    this.address,
    this.phone,
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
  final String? code;
  final String? imageBase64;

  MemberCardQRCode({
    this.code,
    this.imageBase64,
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
  final int? recentAttendanceCount;
  final String? memberSince;

  MemberCardStatistics({
    this.recentAttendanceCount,
    this.memberSince,
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
