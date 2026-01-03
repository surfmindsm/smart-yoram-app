class Member {
  final int id;
  final String name;
  final String? nameEng; // 영문명
  final String? email;
  final String gender;
  final DateTime? birthdate;
  final String phone;
  final String? address;
  final String? position; // 직분 코드 (영문): PASTOR, ELDER, DEACON 등
  final String? positionMain; // 주 직분 (position_main 컬럼)
  final String? positionDetail; // 상세 직분 (position_detail 컬럼)
  final String? positionCategory; // 주소록 카테고리: CLERGY, ELDER, DEACONESS, DEACON, YOUTH, CHILDREN, MEMBER
  final String? department; // 부서: WORSHIP, EDUCATION, MISSION, YOUTH, CHILDREN
  final String? district; // 구역: 텍스트 입력 (예: "1구역")
  final String? organizationId; // 조직 ID (UUID)
  final DateTime? appointedOn; // 임명일
  final String? ordinationChurch; // 안수교회
  final String? memberType; // 교인구분: 정교인, 학습교인, 세례교인, 방문자
  final DateTime? confirmationDate; // 입교일
  final DateTime? baptismDate; // 세례일
  final String? baptismChurch; // 세례교회
  final String? ageGroup; // 나이그룹: 어린이, 학생, 청년, 성인, 시니어
  final String? spiritualGrade; // 신급: 초신자, B급, A급, 리더
  final DateTime? lastContactDate; // 마지막 연락일
  final String? maritalStatus; // 결혼 상태: 미혼, 기혼, 이혼, 사별
  final String? spouseName; // 배우자 이름
  final DateTime? marriedOn; // 결혼일
  final String? postalCode; // 우편번호
  final String? region1; // 지역 1
  final String? region2; // 지역 2
  final String? region3; // 지역 3
  final String? jobCategory; // 직업분류: 사무직, 교육직, 의료진, 서비스업, 자영업, 학생, 주부, 기타
  final String? jobDetail; // 구체적 업무
  final String? jobPosition; // 직책/직위
  final String? jobTitle; // 직업명
  final String? workplace; // 직장명
  final String? workplacePhone; // 직장 전화번호
  final DateTime? ministryStartDate; // 사역 시작일
  final String? neighboringChurch; // 이웃교회
  final String? positionDecision; // 직분 결정
  final int? inviter3MemberId; // 인도자 (member_id)
  final String? dailyActivity; // 일상 활동
  final String? customField1; // 자유필드 1
  final String? customField2; // 자유필드 2
  final String? customField3; // 자유필드 3
  final String? customField4; // 자유필드 4
  final String? customField5; // 자유필드 5
  final String? customField6; // 자유필드 6
  final String? customField7; // 자유필드 7
  final String? customField8; // 자유필드 8
  final String? customField9; // 자유필드 9
  final String? customField10; // 자유필드 10
  final String? customField11; // 자유필드 11
  final String? customField12; // 자유필드 12
  final String? specialNotes; // 개인 특별사항
  final int churchId;
  final String? profilePhotoUrl;
  final String? mobileProfileImageUrl; // 커뮤니티용 프로필 이미지
  final String memberStatus; // 상태 (status 컬럼)
  final DateTime? registrationDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? transferChurch;
  final DateTime? transferDate;
  final String? memo;
  final bool invitationSent;
  final DateTime? invitationSentAt;
  final int? userId; // user_id 매핑 필드 추가

  Member({
    required this.id,
    required this.name,
    this.nameEng,
    this.email,
    required this.gender,
    this.birthdate,
    required this.phone,
    this.address,
    this.position,
    this.positionMain,
    this.positionDetail,
    this.positionCategory,
    this.department,
    this.district,
    this.organizationId,
    this.appointedOn,
    this.ordinationChurch,
    this.memberType,
    this.confirmationDate,
    this.baptismDate,
    this.baptismChurch,
    this.ageGroup,
    this.spiritualGrade,
    this.lastContactDate,
    this.maritalStatus,
    this.spouseName,
    this.marriedOn,
    this.postalCode,
    this.region1,
    this.region2,
    this.region3,
    this.jobCategory,
    this.jobDetail,
    this.jobPosition,
    this.jobTitle,
    this.workplace,
    this.workplacePhone,
    this.ministryStartDate,
    this.neighboringChurch,
    this.positionDecision,
    this.inviter3MemberId,
    this.dailyActivity,
    this.customField1,
    this.customField2,
    this.customField3,
    this.customField4,
    this.customField5,
    this.customField6,
    this.customField7,
    this.customField8,
    this.customField9,
    this.customField10,
    this.customField11,
    this.customField12,
    this.specialNotes,
    required this.churchId,
    this.profilePhotoUrl,
    this.mobileProfileImageUrl,
    required this.memberStatus,
    this.registrationDate,
    this.createdAt,
    this.updatedAt,
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
      nameEng: json['name_eng'],
      email: json['email'],
      gender: json['gender'] ?? '',
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      phone: json['phone'] ?? '',
      address: json['address'],
      position: json['position'],
      positionMain: json['position_main'],
      positionDetail: json['position_detail'],
      positionCategory: json['position_category'],
      department: json['department'],
      district: json['district'],
      organizationId: json['organization_id'],
      appointedOn: json['appointed_on'] != null
          ? DateTime.parse(json['appointed_on'])
          : null,
      ordinationChurch: json['ordination_church'],
      memberType: json['member_type'],
      confirmationDate: json['confirmation_date'] != null
          ? DateTime.parse(json['confirmation_date'])
          : null,
      baptismDate: json['baptism_date'] != null
          ? DateTime.parse(json['baptism_date'])
          : null,
      baptismChurch: json['baptism_church'],
      ageGroup: json['age_group'],
      spiritualGrade: json['spiritual_grade'],
      lastContactDate: json['last_contact_date'] != null
          ? DateTime.parse(json['last_contact_date'])
          : null,
      maritalStatus: json['marital_status'],
      spouseName: json['spouse_name'],
      marriedOn: json['married_on'] != null
          ? DateTime.parse(json['married_on'])
          : null,
      postalCode: json['postal_code'],
      region1: json['region_1'],
      region2: json['region_2'],
      region3: json['region_3'],
      jobCategory: json['job_category'],
      jobDetail: json['job_detail'],
      jobPosition: json['job_position'],
      jobTitle: json['job_title'],
      workplace: json['workplace'],
      workplacePhone: json['workplace_phone'],
      ministryStartDate: json['ministry_start_date'] != null
          ? DateTime.parse(json['ministry_start_date'])
          : null,
      neighboringChurch: json['neighboring_church'],
      positionDecision: json['position_decision'],
      inviter3MemberId: json['inviter3_member_id'],
      dailyActivity: json['daily_activity'],
      customField1: json['custom_field_1'],
      customField2: json['custom_field_2'],
      customField3: json['custom_field_3'],
      customField4: json['custom_field_4'],
      customField5: json['custom_field_5'],
      customField6: json['custom_field_6'],
      customField7: json['custom_field_7'],
      customField8: json['custom_field_8'],
      customField9: json['custom_field_9'],
      customField10: json['custom_field_10'],
      customField11: json['custom_field_11'],
      customField12: json['custom_field_12'],
      specialNotes: json['special_notes'],
      churchId: json['church_id'] ?? 0,
      profilePhotoUrl: json['profile_photo_url'],
      mobileProfileImageUrl: json['mobile_profile_image_url'],
      memberStatus: json['member_status'] ?? json['status'] ?? 'active',
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
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
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_eng': nameEng,
      'email': email,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String().split('T')[0],
      'phone': phone,
      'address': address,
      'position': position,
      'position_main': positionMain,
      'position_detail': positionDetail,
      'position_category': positionCategory,
      'department': department,
      'district': district,
      'organization_id': organizationId,
      'appointed_on': appointedOn?.toIso8601String().split('T')[0],
      'ordination_church': ordinationChurch,
      'member_type': memberType,
      'confirmation_date': confirmationDate?.toIso8601String().split('T')[0],
      'baptism_date': baptismDate?.toIso8601String().split('T')[0],
      'baptism_church': baptismChurch,
      'age_group': ageGroup,
      'spiritual_grade': spiritualGrade,
      'last_contact_date': lastContactDate?.toIso8601String().split('T')[0],
      'marital_status': maritalStatus,
      'spouse_name': spouseName,
      'married_on': marriedOn?.toIso8601String().split('T')[0],
      'postal_code': postalCode,
      'region_1': region1,
      'region_2': region2,
      'region_3': region3,
      'job_category': jobCategory,
      'job_detail': jobDetail,
      'job_position': jobPosition,
      'job_title': jobTitle,
      'workplace': workplace,
      'workplace_phone': workplacePhone,
      'ministry_start_date': ministryStartDate?.toIso8601String().split('T')[0],
      'neighboring_church': neighboringChurch,
      'position_decision': positionDecision,
      'inviter3_member_id': inviter3MemberId,
      'daily_activity': dailyActivity,
      'custom_field_1': customField1,
      'custom_field_2': customField2,
      'custom_field_3': customField3,
      'custom_field_4': customField4,
      'custom_field_5': customField5,
      'custom_field_6': customField6,
      'custom_field_7': customField7,
      'custom_field_8': customField8,
      'custom_field_9': customField9,
      'custom_field_10': customField10,
      'custom_field_11': customField11,
      'custom_field_12': customField12,
      'special_notes': specialNotes,
      'church_id': churchId,
      'profile_photo_url': profilePhotoUrl,
      'mobile_profile_image_url': mobileProfileImageUrl,
      'member_status': memberStatus,
      'registration_date': registrationDate?.toIso8601String().split('T')[0],
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'transfer_church': transferChurch,
      'transfer_date': transferDate?.toIso8601String().split('T')[0],
      'memo': memo,
      'invitation_sent': invitationSent,
      'invitation_sent_at': invitationSentAt?.toIso8601String(),
      'user_id': userId,
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
    // 상세 직분 한글 변환 맵 (영문 코드인 경우 대비)
    const detailLabels = {
      // 교역자(CLERGY) 계열
      'SENIOR_PASTOR': '담임목사',
      'EMERITUS_PASTOR': '원로목사',
      'ASSOCIATE_PASTOR': '부목사',
      'COOPERATE_PASTOR': '협동목사',
      'EVANGELIST': '전도사',
      'INTERN_EVANGELIST': '전임전도사',
      'EDUCATION_EVANGELIST': '교육담당전도사',

      // 장로(ELDER) 계열
      'ACTIVE_ELDER': '시무장로',
      'EMERITUS_ELDER': '원로장로',
      'TRANSFERRED_EMERITUS_ELDER': '이명은퇴장로',

      // 권사(DEACONESS) 계열
      'HONORARY_DEACONESS': '명예권사',
      'ACTIVE_DEACONESS': '시무권사',

      // 집사(DEACON) 계열
      'HONORARY_DEACON': '명예집사',
      'PROBATIONARY_DEACON': '서리집사',
      'ACTIVE_DEACON': '집사',
      'ORDAINED_DEACON': '안수집사',

      // 교회학교(CHURCH_SCHOOL) 계열
      'INFANT': '영아부',
      'KINDERGARTEN': '유치부',
      'YOUNG_CHILDREN': '유년부',
      'ELEMENTARY': '초등부',
      'JUNIOR': '소년부',
      'MIDDLE_SCHOOL': '중등부',
      'HIGH_SCHOOL': '고등부',
      'YOUTH': '청년부',

      // 기타(MEMBER) 계열
      'TEACHER': '교사',
      'STUDENT': '학생',
    };

    // position_detail 값이 있으면 우선 표시 (영문 코드면 한글로 변환)
    if (positionDetail != null && positionDetail!.isNotEmpty) {
      return detailLabels[positionDetail] ?? positionDetail!;
    }

    // position_main을 한글로 변환
    const mainLabels = {
      'CLERGY': '교역자',
      'ELDER': '장로',
      'DEACONESS': '권사',
      'DEACON': '집사',
      'CHURCH_SCHOOL': '교회학교',
      'MEMBER': '성도',
    };
    if (positionMain == null || positionMain!.isEmpty) return '성도';
    return mainLabels[positionMain] ?? positionMain!;
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
