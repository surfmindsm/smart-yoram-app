/// 찜하기 모델

/// 찜한 글 아이템
class WishlistItem {
  final int id;
  final String postType;
  final int postId;
  final String postTitle;
  final String postDescription;
  final String? postImageUrl;
  final DateTime createdAt;

  WishlistItem({
    required this.id,
    required this.postType,
    required this.postId,
    required this.postTitle,
    required this.postDescription,
    this.postImageUrl,
    required this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] ?? 0,
      postType: json['post_type'] ?? '',
      postId: json['post_id'] ?? 0,
      postTitle: json['post_title'] ?? '',
      postDescription: json['post_description'] ?? '',
      postImageUrl: json['post_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_type': postType,
      'post_id': postId,
      'post_title': postTitle,
      'post_description': postDescription,
      'post_image_url': postImageUrl,
    };
  }

  /// 게시물 타입을 한글명으로 변환
  String get postTypeName {
    const typeMap = {
      'community-sharing': '무료나눔',
      'sharing-offer': '물품판매',
      'item-request': '물품요청',
      'job-posting': '사역자모집',
      'music-team-recruit': '행사팀모집',
      'music-team-seeking': '행사팀지원',
      'church-events': '행사소식',
    };
    return typeMap[postType] ?? postType;
  }

  /// 상대 시간 표시
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';

    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// 이미지가 필요없는 타입인지 확인
  bool get needsImage {
    const noImageTypes = [
      'item-request',
      'job-posting',
      'music-team-recruit',
    ];
    return !noImageTypes.contains(postType);
  }
}

/// 페이지네이션 정보
class WishlistPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  WishlistPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory WishlistPagination.fromJson(Map<String, dynamic> json) {
    return WishlistPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

/// 찜한 글 데이터
class WishlistData {
  final List<WishlistItem> items;
  final WishlistPagination pagination;

  WishlistData({
    required this.items,
    required this.pagination,
  });

  factory WishlistData.fromJson(Map<String, dynamic> json) {
    return WishlistData(
      items: (json['items'] as List?)
              ?.map((item) => WishlistItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: WishlistPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
