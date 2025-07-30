class Member {
  final int id;
  final String name;
  final String gender;
  final DateTime? dateOfBirth;
  final String phoneNumber;
  final String? address;
  final String? position;
  final String? district;
  final int churchId;
  final String? profilePhotoUrl;
  final String memberStatus;
  final DateTime? registrationDate;
  final DateTime? createdAt;

  Member({
    required this.id,
    required this.name,
    required this.gender,
    this.dateOfBirth,
    required this.phoneNumber,
    this.address,
    this.position,
    this.district,
    required this.churchId,
    this.profilePhotoUrl,
    required this.memberStatus,
    this.registrationDate,
    this.createdAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      phoneNumber: json['phone_number'] ?? '',
      address: json['address'],
      position: json['position'],
      district: json['district'],
      churchId: json['church_id'] ?? 0,
      profilePhotoUrl: json['profile_photo_url'],
      memberStatus: json['member_status'] ?? 'active',
      registrationDate: json['registration_date'] != null 
          ? DateTime.parse(json['registration_date']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'phone_number': phoneNumber,
      'address': address,
      'position': position,
      'district': district,
      'church_id': churchId,
      'profile_photo_url': profilePhotoUrl,
      'member_status': memberStatus,
      'registration_date': registrationDate?.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // 나이 계산
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // 프로필 사진 전체 URL
  String? get fullProfilePhotoUrl {
    if (profilePhotoUrl == null || profilePhotoUrl!.isEmpty) return null;
    if (profilePhotoUrl!.startsWith('http')) return profilePhotoUrl;
    return 'https://packs-holds-marc-extended.trycloudflare.com$profilePhotoUrl';
  }

  @override
  String toString() {
    return 'Member(id: $id, name: $name, phoneNumber: $phoneNumber, memberStatus: $memberStatus)';
  }
}

// 교인 생성/수정을 위한 DTO
class MemberCreateRequest {
  final String name;
  final String gender;
  final DateTime? dateOfBirth;
  final String phoneNumber;
  final String? address;
  final String? position;
  final String? district;
  final int churchId;

  MemberCreateRequest({
    required this.name,
    required this.gender,
    this.dateOfBirth,
    required this.phoneNumber,
    this.address,
    this.position,
    this.district,
    required this.churchId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'phone_number': phoneNumber,
      'address': address,
      'position': position,
      'district': district,
      'church_id': churchId,
    };
  }
}

// 교인 업데이트를 위한 DTO
class MemberUpdateRequest {
  final String? name;
  final String? phoneNumber;
  final String? memberStatus;
  final String? address;
  final String? position;
  final String? district;

  MemberUpdateRequest({
    this.name,
    this.phoneNumber,
    this.memberStatus,
    this.address,
    this.position,
    this.district,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (memberStatus != null) data['member_status'] = memberStatus;
    if (address != null) data['address'] = address;
    if (position != null) data['position'] = position;
    if (district != null) data['district'] = district;
    return data;
  }
}
