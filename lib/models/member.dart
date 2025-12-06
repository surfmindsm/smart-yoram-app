class Member {
  final int id;
  final String name;
  final String? email;
  final String gender;
  final DateTime? birthdate;
  final String phone;
  final String? address;
  final String? position; // 직분 코드 (영문): PASTOR, ELDER, DEACON 등
  final String? positionCategory; // 주소록 카테고리: CLERGY, ELDER, DEACONESS, DEACON, YOUTH, CHILDREN, MEMBER
  final String? department; // 부서: WORSHIP, EDUCATION, MISSION, YOUTH, CHILDREN
  final String? district; // 구역: 텍스트 입력 (예: "1구역")
  final String? organizationId; // 조직 ID (UUID)
  final int churchId;
  final String? profilePhotoUrl;
  final String? mobileProfileImageUrl; // 커뮤니티용 프로필 이미지
  final String memberStatus;
  final DateTime? registrationDate;
  final DateTime? createdAt;
  final String? transferChurch;
  final DateTime? transferDate;
  final String? memo;
  final bool invitationSent;
  final DateTime? invitationSentAt;
  final int? userId; // user_id 매핑 필드 추가

  Member({
    required this.id,
    required this.name,
    this.email,
    required this.gender,
    this.birthdate,
    required this.phone,
    this.address,
    this.position,
    this.positionCategory,
    this.department,
    this.district,
    this.organizationId,
    required this.churchId,
    this.profilePhotoUrl,
    this.mobileProfileImageUrl,
    required this.memberStatus,
    this.registrationDate,
    this.createdAt,
    this.transferChurch,
    this.transferDate,
    this.memo,
    this.invitationSent = false,
    this.invitationSentAt,
    this.userId, // user_id 매핑 필드 추가
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      gender: json['gender'] ?? '',
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      phone: json['phone'] ?? '',
      address: json['address'],
      position: json['position'],
      positionCategory: json['position_category'], // 주소록 카테고리
      department: json['department'],
      district: json['district'],
      organizationId: json['organization_id'],
      churchId: json['church_id'] ?? 0,
      profilePhotoUrl: json['profile_photo_url'],
      mobileProfileImageUrl: json['mobile_profile_image_url'],
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
      userId: json['user_id'], // user_id 매핑 필드 추가
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String().split('T')[0],
      'phone': phone,
      'address': address,
      'position': position,
      'position_category': positionCategory,
      'department': department,
      'district': district,
      'organization_id': organizationId,
      'church_id': churchId,
      'profile_photo_url': profilePhotoUrl,
      'mobile_profile_image_url': mobileProfileImageUrl,
      'member_status': memberStatus,
      'registration_date': registrationDate?.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
      'transfer_church': transferChurch,
      'transfer_date': transferDate?.toIso8601String().split('T')[0],
      'memo': memo,
      'invitation_sent': invitationSent,
      'invitation_sent_at': invitationSentAt?.toIso8601String(),
      'user_id': userId, // user_id 매핑 필드 추가
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

  // 직분 한글 레이블 (화면 표시용)
  String get positionLabel {
    // MemberPosition import 필요
    // return MemberPosition.getLabel(position);
    // 임시로 하위 호환성 유지
    const labels = {
      'PASTOR': '목사',
      'EVANGELIST': '전도사',
      'EDUCATION_EVANGELIST': '교육전도사',
      'CLERGY': '교역자',
      'ELDER': '장로',
      'RETIRED_ELDER': '은퇴장로',
      'DEACONESS': '권사',
      'RETIRED_DEACONESS': '은퇴권사',
      'DEACON': '집사',
      'ORDAINED_DEACON': '안수집사',
      'TEACHER': '교사',
      'MEMBER': '성도',
    };
    if (position == null || position!.isEmpty) return '성도';
    return labels[position] ?? position!;
  }

  // 카테고리 한글 레이블 (주소록 탭)
  String get categoryLabel {
    const labels = {
      'CLERGY': '교역자',
      'ELDER': '장로',
      'DEACONESS': '권사',
      'DEACON': '집사',
      'YOUTH': '청년',
      'CHILDREN': '교회학교',
      'MEMBER': '성도',
    };
    if (positionCategory == null || positionCategory!.isEmpty) return '성도';
    return labels[positionCategory] ?? positionCategory!;
  }

  // 프로필 사진 전체 URL (Supabase Storage)
  String? get fullProfilePhotoUrl {
    if (profilePhotoUrl == null || profilePhotoUrl!.isEmpty) return null;

    // 이미 전체 URL이면 그대로 반환
    if (profilePhotoUrl!.startsWith('http')) return profilePhotoUrl;

    // Supabase Storage public URL 생성
    const supabaseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co';

    // profilePhotoUrl이 상대경로일 경우 (/uploads/... 또는 uploads/...)
    final cleanPath = profilePhotoUrl!.startsWith('/')
        ? profilePhotoUrl!.substring(1)
        : profilePhotoUrl!;

    // Supabase Storage public URL 형식: {supabase_url}/storage/v1/object/public/{bucket}/{path}
    // 실제 버킷 이름은 member-photos
    return '$supabaseUrl/storage/v1/object/public/member-photos/$cleanPath';
  }

  // 프로필 사진 별칭 (기존 코드 호환성을 위해)
  String? get photo => fullProfilePhotoUrl;

  // 커뮤니티용 모바일 프로필 이미지 전체 URL
  String? get fullMobileProfileImageUrl {
    // 모바일 프로필 이미지가 설정되어 있으면 우선 사용
    final imageUrl = mobileProfileImageUrl ?? profilePhotoUrl;
    if (imageUrl == null || imageUrl.isEmpty) return null;

    // 이미 전체 URL이면 그대로 반환
    if (imageUrl.startsWith('http')) return imageUrl;

    // Supabase Storage public URL 생성
    const supabaseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co';

    // imageUrl이 상대경로일 경우 (/uploads/... 또는 uploads/...)
    final cleanPath = imageUrl.startsWith('/')
        ? imageUrl.substring(1)
        : imageUrl;

    // Supabase Storage public URL 형식
    // 모바일 프로필과 기존 프로필 모두 member-photos 버킷 사용
    return '$supabaseUrl/storage/v1/object/public/member-photos/$cleanPath';
  }

  @override
  String toString() {
    return 'Member(id: $id, name: $name, phone: $phone, memberStatus: $memberStatus, userId: $userId)';
  }
}

// 교인 생성/수정을 위한 DTO
class MemberCreateRequest {
  final String name;
  final String gender;
  final DateTime? birthdate;
  final String phone;
  final String? address;
  final String? position; // 직분: 목사, 장로, 집사, 권사, 전도사, 교사, 부장, 회장
  final String? department; // 부서: WORSHIP, EDUCATION, MISSION, YOUTH, CHILDREN
  final String? district; // 구역
  final String? organizationId; // 조직 ID (UUID)
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
    this.department,
    this.district,
    this.organizationId,
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
      'position': position, // null이면 null로 전송 (빈 문자열 ❌)
      'department': department,
      'district': district,
      'organization_id': organizationId,
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
  final String? position; // 직분: 목사, 장로, 집사, 권사, 전도사, 교사, 부장, 회장
  final String? department; // 부서: WORSHIP, EDUCATION, MISSION, YOUTH, CHILDREN
  final String? district; // 구역
  final String? organizationId; // 조직 ID (UUID)
  final String? transferChurch;
  final DateTime? transferDate;
  final String? memo;

  MemberUpdateRequest({
    this.name,
    this.phone,
    this.memberStatus,
    this.address,
    this.position,
    this.department,
    this.district,
    this.organizationId,
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
    if (position != null) data['position'] = position; // null이면 null로 전송
    if (department != null) data['department'] = department;
    if (district != null) data['district'] = district;
    if (organizationId != null) data['organization_id'] = organizationId;
    if (transferChurch != null) data['transfer_church'] = transferChurch;
    if (transferDate != null) data['transfer_date'] = transferDate?.toIso8601String().split('T')[0];
    if (memo != null) data['memo'] = memo;
    return data;
  }
}

// MemberPositionOptions 클래스는 제거되었습니다.
// 대신 lib/constants/member_positions.dart의 MemberPosition 클래스를 사용하세요.

// 부서 옵션 (웹과 동일)
class MemberDepartmentOptions {
  static const Map<String, String> departments = {
    'WORSHIP': '예배부',
    'EDUCATION': '교육부',
    'MISSION': '선교부',
    'YOUTH': '청년부',
    'CHILDREN': '아동부',
  };

  static String? getLabel(String? value) {
    return value != null ? departments[value] : null;
  }

  static String? getValue(String? label) {
    return departments.entries
        .firstWhere((entry) => entry.value == label, orElse: () => const MapEntry('', ''))
        .key;
  }
}
