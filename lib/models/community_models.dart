/// 커뮤니티 공통 타입 및 모델
/// 웹 명세서(community-spec.md) 기반

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
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';

    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// 1. 무료 나눔 / 물품 판매 (community_sharing)
// ============================================================================

/// 무료 나눔/물품 판매 아이템
class SharingItem extends CommunityBasePost {
  final String category; // 가구, 전자제품, 도서, 악기, 기타
  final String condition; // 양호, 보통, 사용감있음, 새상품
  final int quantity;
  final List<String> images;
  final String location;
  final String contactPhone;
  final String? contactEmail;
  final bool isFree; // true: 무료나눔, false: 물품판매
  final int? price; // 판매가격 (isFree=false일 때)
  final String? deliveryMethod; // 직거래, 택배발송, 픽업, 협의
  final String? purchaseDate; // 구매 시기

  SharingItem({
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
    required this.condition,
    required this.quantity,
    this.images = const [],
    required this.location,
    required this.contactPhone,
    this.contactEmail,
    this.isFree = true,
    this.price,
    this.deliveryMethod,
    this.purchaseDate,
  });

  factory SharingItem.fromJson(Map<String, dynamic> json) {
    return SharingItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'available',
      authorId: json['author_id'] ?? 0,
      authorName: json['userName'] ?? json['author_name'],
      churchId: json['church_id'],
      churchName: json['church'],
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
          : null,
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      quantity: json['quantity'] ?? 1,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      location: json['location'] ?? '',
      contactPhone: json['contactPhone'] ?? json['contact_phone'] ?? '',
      contactEmail: json['contactEmail'] ?? json['contact_email'],
      isFree: json['is_free'] ?? true,
      price: json['price'] != null
          ? (json['price'] is int ? json['price'] : (json['price'] as double).toInt())
          : null,
      deliveryMethod: json['deliveryMethod'] ?? json['delivery_method'],
      purchaseDate: json['purchaseDate'] ?? json['purchase_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'quantity': quantity,
      'images': images,
      'location': location,
      'is_free': isFree,
      'price': price,
      'delivery_method': deliveryMethod,
      'purchase_date': purchaseDate,
    };
  }

  String get formattedPrice {
    if (isFree) return '무료';
    if (price == null || price == 0) return '가격 협의';
    return '${price!.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }
}

// ============================================================================
// 2. 물품 요청 (community_requests)
// ============================================================================

/// 물품 요청
class RequestItem extends CommunityBasePost {
  final String category;
  final String? requestedItem; // 요청 물품명
  final int? quantity;
  final String? reason; // 요청 사유
  final String? neededDate; // 필요일
  final String location;
  final String? priceRange; // 희망 가격대
  final String contactPhone;
  final String? contactEmail;
  final String urgency; // low, normal, medium, high
  final List<String>? images; // 참고 이미지

  RequestItem({
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
    this.requestedItem,
    this.quantity,
    this.reason,
    this.neededDate,
    required this.location,
    this.priceRange,
    required this.contactPhone,
    this.contactEmail,
    this.urgency = 'normal',
    this.images,
  });

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'requesting',
      authorId: json['author_id'] ?? 0,
      authorName: json['userName'] ?? json['author_name'],
      churchId: json['church_id'],
      churchName: json['church'],
      viewCount: json['view_count'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'],
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
          : null,
      category: json['category'] ?? '',
      requestedItem: json['requestedItem'] ?? json['requested_item'],
      quantity: json['quantity'],
      reason: json['reason'],
      neededDate: json['neededDate'] ?? json['needed_date'],
      location: json['location'] ?? '',
      priceRange: json['priceRange'] ?? json['price_range'],
      contactPhone: json['contactPhone'] ?? json['contact_phone'] ?? '',
      contactEmail: json['contactEmail'] ?? json['contact_email'],
      urgency: json['urgency'] ?? 'normal',
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'requested_item': requestedItem,
      'quantity': quantity,
      'reason': reason,
      'needed_date': neededDate,
      'location': location,
      'price_range': priceRange,
      'urgency': urgency,
      'images': images,
    };
  }

  UrgencyLevel get urgencyLevel => UrgencyLevel.fromValue(urgency);
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
  final String location;
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
    required this.location,
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
          ? DateTime.parse(json['createdAt'] ?? json['created_at'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
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
  final String? compensation; // 보상/사례
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
    this.compensation,
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
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      recruitmentType: json['recruitment_type'] ?? '',
      worshipType: json['worship_type'],
      teamTypes: json['team_types'] != null ? List<String>.from(json['team_types']) : [],
      instrumentsNeeded: json['instruments_needed'] != null ? List<String>.from(json['instruments_needed']) : [],
      schedule: json['schedule'],
      location: json['location'] ?? '',
      requirements: json['requirements'],
      compensation: json['compensation'],
      contactPhone: json['contact_phone'] ?? '',
      contactEmail: json['contact_email'],
      applications: json['applications'],
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
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
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
          ? DateTime.parse(json['createdAt'] ?? json['created_at'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
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
