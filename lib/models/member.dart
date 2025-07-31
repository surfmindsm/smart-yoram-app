class Member {
  final int id;
  final String name;
  final String gender;
  final DateTime? birthdate;
  final String phone;
  final String? address;
  final String? position;
  final String? district;
  final int churchId;
  final String? profilePhotoUrl;
  final String memberStatus;
  final DateTime? registrationDate;
  final DateTime? createdAt;
  final String? transferChurch;
  final DateTime? transferDate;
  final String? memo;
  final bool invitationSent;
  final DateTime? invitationSentAt;

  Member({
    required this.id,
    required this.name,
    required this.gender,
    this.birthdate,
    required this.phone,
    this.address,
    this.position,
    this.district,
    required this.churchId,
    this.profilePhotoUrl,
    required this.memberStatus,
    this.registrationDate,
    this.createdAt,
    this.transferChurch,
    this.transferDate,
    this.memo,
    this.invitationSent = false,
    this.invitationSentAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      birthdate: json['birthdate'] != null 
          ? DateTime.parse(json['birthdate']) 
          : null,
      phone: json['phone'] ?? '',
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
      transferChurch: json['transfer_church'],
      transferDate: json['transfer_date'] != null 
          ? DateTime.parse(json['transfer_date']) 
          : null,
      memo: json['memo'],
      invitationSent: json['invitation_sent'] ?? false,
      invitationSentAt: json['invitation_sent_at'] != null 
          ? DateTime.parse(json['invitation_sent_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String().split('T')[0],
      'phone': phone,
      'address': address,
      'position': position,
      'district': district,
      'church_id': churchId,
      'profile_photo_url': profilePhotoUrl,
      'member_status': memberStatus,
      'registration_date': registrationDate?.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
      'transfer_church': transferChurch,
      'transfer_date': transferDate?.toIso8601String().split('T')[0],
      'memo': memo,
      'invitation_sent': invitationSent,
      'invitation_sent_at': invitationSentAt?.toIso8601String(),
    };
  }

  // 나이 계산
  int? get age {
    if (birthdate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthdate!.year;
    if (now.month < birthdate!.month || 
        (now.month == birthdate!.month && now.day < birthdate!.day)) {
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
    return 'Member(id: $id, name: $name, phone: $phone, memberStatus: $memberStatus)';
  }
}

// 교인 생성/수정을 위한 DTO
class MemberCreateRequest {
  final String name;
  final String gender;
  final DateTime? birthdate;
  final String phone;
  final String? address;
  final String? position;
  final String? district;
  final int churchId;
  final String? transferChurch;
  final DateTime? transferDate;
  final String? memo;

  MemberCreateRequest({
    required this.name,
    required this.gender,
    this.birthdate,
    required this.phone,
    this.address,
    this.position,
    this.district,
    required this.churchId,
    this.transferChurch,
    this.transferDate,
    this.memo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String().split('T')[0],
      'phone': phone,
      'address': address,
      'position': position,
      'district': district,
      'church_id': churchId,
      'transfer_church': transferChurch,
      'transfer_date': transferDate?.toIso8601String().split('T')[0],
      'memo': memo,
    };
  }
}

// 교인 업데이트를 위한 DTO
class MemberUpdateRequest {
  final String? name;
  final String? phone;
  final String? memberStatus;
  final String? address;
  final String? position;
  final String? district;
  final String? transferChurch;
  final DateTime? transferDate;
  final String? memo;

  MemberUpdateRequest({
    this.name,
    this.phone,
    this.memberStatus,
    this.address,
    this.position,
    this.district,
    this.transferChurch,
    this.transferDate,
    this.memo,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (memberStatus != null) data['member_status'] = memberStatus;
    if (address != null) data['address'] = address;
    if (position != null) data['position'] = position;
    if (district != null) data['district'] = district;
    if (transferChurch != null) data['transfer_church'] = transferChurch;
    if (transferDate != null) data['transfer_date'] = transferDate?.toIso8601String().split('T')[0];
    if (memo != null) data['memo'] = memo;
    return data;
  }
}
