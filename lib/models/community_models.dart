/// 커뮤니티 공통 타입 및 모델
/// 웹 명세서(community-spec.md) 기반

import 'dart:convert';

// ============================================================================
// 공통 타입 정의
// ============================================================================

/// 표준 상태
enum CommunityStatus {
  active('active', '진행중'),
  completed('completed', '완료'),
  cancelled('cancelled', '취소'),
  paused('paused', '일시중지'),
  available('available', '나눔가능'),
  reserved('reserved', '예약중'),
  requesting('requesting', '요청중'),
  open('open', '모집중'),
  closed('closed', '마감');

  final String value;
  final String displayName;
  const CommunityStatus(this.value, this.displayName);

  static CommunityStatus fromValue(String value) {
    return CommunityStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CommunityStatus.active,
    );
  }
}

/// 긴급도
enum UrgencyLevel {
  low('low', '여유', '초록색'),
  normal('normal', '보통', '파란색'),
  medium('medium', '보통', '주황색'),
  high('high', '긴급', '빨간색');

  final String value;
  final String displayName;
  final String color;
  const UrgencyLevel(this.value, this.displayName, this.color);

  static UrgencyLevel fromValue(String value) {
    return UrgencyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => UrgencyLevel.normal,
    );
  }
}

// ============================================================================
// 기본 게시글 모델
// ============================================================================

/// 커뮤니티 기본 게시글
abstract class CommunityBasePost {
  final int id;
  final String title;
  final String? description;
  final String status;
  final int authorId;
  final String? authorName;
  final String? authorProfilePhotoUrl;
  final int? churchId;
  final String? churchName;
  final int viewCount;
  final int likes;
  final int? comments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityBasePost({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.authorId,
    this.authorName,
    this.authorProfilePhotoUrl,
    this.churchId,
    this.churchName,
    this.viewCount = 0,
    this.likes = 0,
    this.comments,
    required this.createdAt,
    this.updatedAt,
  });

  /// 상태 표시명
  String get statusDisplayName {
    final statusEnum = CommunityStatus.fromValue(status);
    return statusEnum.displayName;
  }

  /// 교회명 표시 (9998은 협력사/무소속)
  String get displayChurchName {
    if (churchId == 9998) return '협력사';
    return churchName ?? '교회 정보 없음';
  }

  /// 날짜 포맷 (상대 시간)
  String get formattedDate {
    // UTC 기준으로 계산 (시간대 혼동 방지)
    final nowUtc = DateTime.now().toUtc();
    final createdAtUtc = createdAt.toUtc();
    final difference = nowUtc.difference(createdAtUtc);

    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';

    // 날짜 표시는 로컬 시간으로
    final localCreatedAt = createdAt.toLocal();
    return '${localCreatedAt.year}.${localCreatedAt.month.toString().padLeft(2, '0')}.${localCreatedAt.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// 1. 무료 나눔 / 물품 판매 (community_sharing)
// ============================================================================

/// 무료 나눔/물품 판매 아이템
class SharingItem extends CommunityBasePost {
  final String category; // 가구, 전자제품, 도서, 악기, 기타
  final String condition; // 양호, 보통, 사용감있음, 새상품
  final List<String> images;
  final String? province; // 도/시 (예: 서울특별시, 경기도)
  final String? district; // 시/군/구 (예: 강남구, 수원시)
  final bool deliveryAvailable; // 택배 가능 여부
  final String? location; // 레거시 필드 (하위 호환성)
  final String? churchLocation; // 교회 지역 (도시 + 구/동)
  final String contactPhone;
  final String? contactEmail;
  final bool isFree; // true: 무료나눔, false: 물품판매
  final int? price; // 판매가격 (isFree=false일 때)
  final DateTime? purchaseDate; // 구매 날짜 (물품 구입 시기)

  SharingItem({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.authorId,
    super.authorName,
    super.authorProfilePhotoUrl,
    super.churchId,
    super.churchName,
    super.viewCount,
    super.likes,
    super.comments,
    required super.createdAt,
    super.updatedAt,
    required this.category,
    required this.condition,
    this.images = const [],
    this.province,
    this.district,
    this.deliveryAvailable = false,
    this.location,
    this.churchLocation,
    required this.contactPhone,
    this.contactEmail,
    this.isFree = true,
    this.price,
    this.purchaseDate,
  });

  factory SharingItem.fromJson(Map<String, dynamic> json) {
    // 조인된 author/church 데이터 파싱
    String? authorName;
    String? authorProfilePhotoUrl;
    if (json['author'] != null && json['author'] is Map) {
      authorName = json['author']['name'];
      authorProfilePhotoUrl = json['author']['profile_photo_url'];
    } else {
      authorName = json['author_name'] ?? json['userName'];
      authorProfilePhotoUrl = json['author_profile_photo_url'];
    }

    String? churchName;
    if (json['church'] != null && json['church'] is Map) {
      churchName = json['church']['name'];
    } else {
      churchName = json['church_name'] ?? json['church'];
    }

    // images 파싱: JSON 문자열인 경우 처리
    List<String> imageList = [];
    if (json['images'] != null) {
      if (json['images'] is String) {
        try {
          final parsed = jsonDecode(json['images']);
          if (parsed is List) {
            imageList = List<String>.from(parsed);
          }
        } catch (e) {
          print('⚠️ COMMUNITY_MODELS: images 파싱 실패 - $e');
        }
      } else if (json['images'] is List) {
        imageList = List<String>.from(json['images']);
      }
    }

    return SharingItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'available',
      authorId: json['author_id'] ?? 0,
      authorName: authorName,
      authorProfilePhotoUrl: authorProfilePhotoUrl,
      churchId: json['church_id'],
      churchName: churchName,
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at']).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at']).toUtc()
          : null,
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      images: imageList,
      province: json['province'],
      district: json['district'],
      deliveryAvailable: json['delivery_available'] ?? false,
      location: json['location'],
      churchLocation: json['church_location'],
      contactPhone: json['contactPhone'] ?? json['contact_phone'] ?? json['contact_info'] ?? '',
      contactEmail: json['contactEmail'] ?? json['contact_email'],
      isFree: json['is_free'] ?? true,
      price: json['price'] != null
          ? (json['price'] is int ? json['price'] : (json['price'] is String ? int.tryParse(json['price'].replaceAll('.00', '')) : (json['price'] as double).toInt()))
          : null,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'images': images,
      'province': province,
      'district': district,
      'delivery_available': deliveryAvailable,
      'location': location,
      'is_free': isFree,
      'price': price,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
    };
  }

  /// 주소 표시 (province + district)
  String get displayLocation {
    if (province != null && district != null) {
      return '$province $district';
    } else if (province != null) {
      return province!;
    } else if (district != null) {
      return district!;
    } else if (location != null && location!.isNotEmpty) {
      return location!; // 레거시 필드 사용
    }
    return '주소 정보 없음';
  }

  @override
  String get statusDisplayName {
    final statusLower = status.toLowerCase();

    // 무료나눔
    if (isFree) {
      switch (statusLower) {
        case 'active':
          return '나눔 가능';
        case 'ing':
          return '예약중';
        case 'completed':
          return '나눔 완료';
        default:
          return status;
      }
    }

    // 물품판매
    switch (statusLower) {
      case 'active':
        return '판매중';
      case 'ing':
        return '예약중';
      case 'completed':
      case 'sold':
        return '판매 완료';
      default:
        return status;
    }
  }

  String get formattedPrice {
    if (isFree) return '무료';
    if (price == null || price == 0) return '가격 협의';
    return '${price!.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  /// 구매 날짜 포맷 (예: 2024년 1월)
  String get formattedPurchaseDate {
    if (purchaseDate == null) return '정보 없음';
    return '${purchaseDate!.year}년 ${purchaseDate!.month}월';
  }
}

// ============================================================================
// 2. 물품 요청 (community_requests)
// ============================================================================

/// 물품 요청
class RequestItem extends CommunityBasePost {
  final String category;
  final String urgency; // low, normal, medium, high
  final String? location; // 레거시 필드 (하위 호환성)
  final String? province; // 도/시 (예: 서울특별시, 경기도)
  final String? district; // 시/군/구 (예: 강남구, 수원시)
  final bool deliveryAvailable; // 택배 가능 여부
  final String contactPhone;
  final String? contactEmail;
  final List<String>? images; // 참고 이미지
  final String? rewardType; // none, exchange, payment 등
  final double? rewardAmount; // 보상 금액

  RequestItem({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.authorId,
    super.authorName,
    super.authorProfilePhotoUrl,
    super.churchId,
    super.churchName,
    super.viewCount,
    super.likes,
    super.comments,
    required super.createdAt,
    super.updatedAt,
    required this.category,
    this.urgency = 'normal',
    this.location,
    this.province,
    this.district,
    this.deliveryAvailable = false,
    required this.contactPhone,
    this.contactEmail,
    this.images,
    this.rewardType,
    this.rewardAmount,
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    // 조인된 author/church 데이터 파싱
    String? authorName;
    String? authorProfilePhotoUrl;
    if (json['author'] != null && json['author'] is Map) {
      authorName = json['author']['name'];
      authorProfilePhotoUrl = json['author']['profile_photo_url'];
    } else {
      authorName = json['author_name'] ?? json['userName'];
      authorProfilePhotoUrl = json['author_profile_photo_url'];
    }

    String? churchName;
    if (json['church'] != null && json['church'] is Map) {
      churchName = json['church']['name'];
    } else {
      churchName = json['church_name'] ?? json['church'];
    }

    // images 파싱: JSON 문자열인 경우 처리
    List<String>? imageList;
    if (json['images'] != null) {
      if (json['images'] is String) {
        try {
          final parsed = jsonDecode(json['images']);
          if (parsed is List) {
            imageList = List<String>.from(parsed);
          }
        } catch (e) {
          print('⚠️ REQUEST_ITEM: images 파싱 실패 - $e');
        }
      } else if (json['images'] is List) {
        imageList = List<String>.from(json['images']);
      }
    }

    return RequestItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'active',
      authorId: json['author_id'] ?? 0,
      authorName: authorName,
      authorProfilePhotoUrl: authorProfilePhotoUrl,
      churchId: json['church_id'],
      churchName: churchName,
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at']).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at']).toUtc()
          : null,
      category: json['category'] ?? '',
      urgency: json['urgency'] ?? 'normal',
      location: json['location'],
      province: json['province'],
      district: json['district'],
      deliveryAvailable: json['delivery_available'] ?? false,
      contactPhone: json['contact_phone'] ?? json['contactInfo'] ?? '',
      contactEmail: json['contact_email'],
      images: imageList,
      rewardType: json['reward_type'],
      rewardAmount: json['reward_amount'] != null
          ? (json['reward_amount'] is num
              ? (json['reward_amount'] as num).toDouble()
              : double.tryParse(json['reward_amount'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'urgency': urgency,
      'location': location,
      'province': province,
      'district': district,
      'delivery_available': deliveryAvailable,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'images': images,
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
    };
  }

  UrgencyLevel get urgencyLevel => UrgencyLevel.fromValue(urgency);

  /// 주소 표시 (province + district)
  String get displayLocation {
    if (province != null && district != null) {
      return '$province $district';
    } else if (province != null) {
      return province!;
    } else if (district != null) {
      return district!;
    } else if (location != null && location!.isNotEmpty) {
      return location!; // 레거시 필드 사용
    }
    return '주소 정보 없음';
  }

  @override
  String get statusDisplayName {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'active':
      case 'requesting':
        return '요청중';
      case 'ing':
        return '예약중';
      case 'completed':
        return '완료';
      case 'closed':
        return '마감';
      default:
        return status;
    }
  }
}

// ============================================================================
// 3. 구인 공고 (job_posts)
// ============================================================================

/// 구인 공고
class JobPost extends CommunityBasePost {
  final String? company; // 회사명
  final String churchIntro; // 교회/회사 소개
  final String position; // 직책
  final String jobType; // 직종
  final String employmentType; // full-time, part-time, volunteer
  final String salary; // 급여
  final List<String>? benefits; // 복리후생
  final List<String>? qualifications; // 지원 자격
  final List<String>? requiredDocuments; // 제출 서류
  final String? location;
  final String? province;
  final String? district;
  final bool? deliveryAvailable;
  final String? deadline; // 마감일
  final String? contactPhone;
  final String? contactEmail;
  final int? applications; // 지원 건수

  JobPost({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.authorId,
    super.authorName,
    super.churchId,
    super.churchName,
    super.viewCount,
    super.likes,
    super.comments,
    required super.createdAt,
    super.updatedAt,
    this.company,
    required this.churchIntro,
    required this.position,
    required this.jobType,
    required this.employmentType,
    required this.salary,
    this.benefits,
    this.qualifications,
    this.requiredDocuments,
    this.location,
    this.province,
    this.district,
    this.deliveryAvailable,
    this.deadline,
    this.contactPhone,
    this.contactEmail,
    this.applications,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    return JobPost(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'open',
      authorId: json['author_id'] ?? 0,
      authorName: json['userName'] ?? json['author_name'],
      churchId: json['church_id'],
      churchName: json['churchName'] ?? json['church_name'],
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at']).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at']).toUtc()
          : null,
      company: json['company'],
      churchIntro: json['churchIntro'] ?? json['church_intro'] ?? '',
      position: json['position'] ?? '',
      jobType: json['jobType'] ?? json['job_type'] ?? '',
      employmentType: json['employment_type'] ?? 'full-time',
      salary: json['salary'] ?? '',
      benefits: json['benefits'] != null ? List<String>.from(json['benefits']) : null,
      qualifications: json['qualifications'] != null ? List<String>.from(json['qualifications']) : null,
      requiredDocuments: json['requiredDocuments'] != null ? List<String>.from(json['requiredDocuments']) : null,
      location: json['location'] ?? '',
      province: json['province'],
      district: json['district'],
      deliveryAvailable: json['delivery_available'] ?? false,
      deadline: json['deadline'] ?? json['application_deadline'],
      contactPhone: json['contactPhone'] ?? json['contact_phone'],
      contactEmail: json['contactEmail'] ?? json['contact_email'],
      applications: json['applications'],
    );
  }
}

// ============================================================================
// 4. 음악팀 모집 (community_music_teams)
// ============================================================================

/// 음악팀 모집
class MusicTeamRecruitment extends CommunityBasePost {
  final String recruitmentType; // new_member, substitute, project, permanent
  final String? worshipType; // 예배 형태
  final List<String> teamTypes; // 팀 형태
  final List<String> instrumentsNeeded; // 필요 악기/파트
  final String? schedule; // 연습 일정
  final String location;
  final String? requirements; // 지원 자격
  final String? benefits; // 보상/사례 (스키마: benefits)
  final String contactPhone;
  final String? contactEmail;
  final int? applications;

  MusicTeamRecruitment({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.authorId,
    super.authorName,
    super.churchId,
    super.churchName,
    super.viewCount,
    super.likes,
    super.comments,
    required super.createdAt,
    super.updatedAt,
    required this.recruitmentType,
    this.worshipType,
    this.teamTypes = const [],
    this.instrumentsNeeded = const [],
    this.schedule,
    required this.location,
    this.requirements,
    this.benefits, // compensation → benefits로 변경
    required this.contactPhone,
    this.contactEmail,
    this.applications,
  });

  factory MusicTeamRecruitment.fromJson(Map<String, dynamic> json) {
    return MusicTeamRecruitment(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'open',
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'],
      churchId: json['church_id'],
      churchName: json['church_name'],
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']).toUtc()
          : null,
      recruitmentType: json['recruitment_type'] ?? '',
      worshipType: json['worship_type'],
      teamTypes: json['team_types'] != null ? List<String>.from(json['team_types']) : [],
      instrumentsNeeded: json['instruments_needed'] != null ? List<String>.from(json['instruments_needed']) : [],
      schedule: json['practice_schedule'] ?? json['schedule'], // practice_schedule 우선
      location: json['practice_location'] ?? json['location'] ?? '', // practice_location 우선
      requirements: json['requirements'],
      benefits: json['benefits'], // ⭐ compensation → benefits로 변경
      contactPhone: json['contact_info'] ?? json['contact_phone'] ?? '', // contact_info 우선
      contactEmail: json['contact_email'],
      applications: json['applicants_count'] ?? json['applications'], // applicants_count 우선
    );
  }
}

// ============================================================================
// 5. 음악팀 참여 신청 (music_team_seekers)
// ============================================================================

/// 음악팀 참여 신청
class MusicTeamSeeker extends CommunityBasePost {
  final String name;
  final String? teamName;
  final String instrument; // 전공 파트
  final List<String>? instruments; // 호환성
  final String experience; // 경력
  final String portfolio; // 포트폴리오
  final String? portfolioFile;
  final List<String> preferredLocation;
  final List<String> availableDays;
  final String? availableTime;
  final String contactPhone;
  final String? contactEmail;
  final String? introduction;
  final int? matches;

  MusicTeamSeeker({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.authorId,
    super.authorName,
    super.churchId,
    super.churchName,
    super.viewCount,
    super.likes,
    super.comments,
    required super.createdAt,
    super.updatedAt,
    required this.name,
    this.teamName,
    required this.instrument,
    this.instruments,
    required this.experience,
    required this.portfolio,
    this.portfolioFile,
    this.preferredLocation = const [],
    this.availableDays = const [],
    this.availableTime,
    required this.contactPhone,
    this.contactEmail,
    this.introduction,
    this.matches,
  });

  factory MusicTeamSeeker.fromJson(Map<String, dynamic> json) {
    return MusicTeamSeeker(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'available',
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'],
      churchId: json['church_id'],
      churchName: json['church_name'],
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']).toUtc()
          : null,
      name: json['name'] ?? '',
      teamName: json['team_name'],
      instrument: json['instrument'] ?? '',
      instruments: json['instruments'] != null ? List<String>.from(json['instruments']) : null,
      experience: json['experience'] ?? '',
      portfolio: json['portfolio'] ?? '',
      portfolioFile: json['portfolio_file'],
      preferredLocation: json['preferred_location'] != null ? List<String>.from(json['preferred_location']) : [],
      availableDays: json['available_days'] != null ? List<String>.from(json['available_days']) : [],
      availableTime: json['available_time'],
      contactPhone: json['contact_phone'] ?? '',
      contactEmail: json['contact_email'],
      introduction: json['introduction'],
      matches: json['matches'],
    );
  }
}

// ============================================================================
// 6. 교회 소식 (church_news)
// ============================================================================

/// 교회 소식
class ChurchNews extends CommunityBasePost {
  final String category;
  final String? content; // 본문 내용 (description과 별도)
  final String? priority; // urgent, important, normal
  final bool? isUrgent;
  final String? eventDate;
  final String? eventTime;
  final String? location;
  final String? organizer;
  final String? targetAudience;
  final String? participationFee;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final List<String>? images;
  final List<String>? tags;

  ChurchNews({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.authorId,
    super.authorName,
    super.churchId,
    super.churchName,
    super.viewCount,
    super.likes,
    super.comments,
    required super.createdAt,
    super.updatedAt,
    required this.category,
    this.content,
    this.priority,
    this.isUrgent,
    this.eventDate,
    this.eventTime,
    this.location,
    this.organizer,
    this.targetAudience,
    this.participationFee,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.images,
    this.tags,
  });

  factory ChurchNews.fromJson(Map<String, dynamic> json) {
    return ChurchNews(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'active',
      authorId: json['authorId'] ?? json['author_id'] ?? 0,
      authorName: json['authorName'] ?? json['author_name'],
      churchId: json['churchId'] ?? json['church_id'],
      churchName: json['churchName'] ?? json['church_name'],
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at']).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at']).toUtc()
          : null,
      category: json['category'] ?? '',
      content: json['content'],
      priority: json['priority'],
      isUrgent: json['isUrgent'] ?? json['is_urgent'],
      eventDate: json['eventDate'] ?? json['event_date'],
      eventTime: json['eventTime'] ?? json['event_time'],
      location: json['location'],
      organizer: json['organizer'],
      targetAudience: json['targetAudience'] ?? json['target_audience'],
      participationFee: json['participationFee'] ?? json['participation_fee'],
      contactPerson: json['contactPerson'] ?? json['contact_person'],
      contactPhone: json['contactPhone'] ?? json['contact_phone'],
      contactEmail: json['contactEmail'] ?? json['contact_email'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }
}
