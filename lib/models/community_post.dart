// 커뮤니티 게시글 모델
class CommunityPost {
  final int id;
  final int churchId;
  final int authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String category; // 'free_sharing', 'sale', 'request', 'general'
  final String title;
  final String content;
  final List<String> imageUrls;
  final String status; // 'active', 'completed', 'deleted'
  final int? price; // 판매 가격 (판매 카테고리용)
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isLiked; // 현재 사용자의 좋아요 여부
  final bool isFavorited; // 현재 사용자의 찜 여부
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityPost({
    required this.id,
    required this.churchId,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.category,
    required this.title,
    required this.content,
    this.imageUrls = const [],
    this.status = 'active',
    this.price,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isFavorited = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? 0,
      churchId: json['church_id'] ?? 0,
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'] ?? '',
      authorProfileUrl: json['author_profile_url'],
      category: json['category'] ?? 'general',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      status: json['status'] ?? 'active',
      price: json['price'],
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isFavorited: json['is_favorited'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'church_id': churchId,
      'author_id': authorId,
      'author_name': authorName,
      'author_profile_url': authorProfileUrl,
      'category': category,
      'title': title,
      'content': content,
      'image_urls': imageUrls,
      'status': status,
      'price': price,
      'view_count': viewCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_liked': isLiked,
      'is_favorited': isFavorited,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // 카테고리 한글명
  String get categoryName {
    switch (category) {
      case 'free_sharing':
        return '무료나눔';
      case 'sale':
        return '물품 판매';
      case 'request':
        return '물품 요청';
      case 'general':
        return '일반';
      default:
        return '기타';
    }
  }

  // 가격 포맷
  String get formattedPrice {
    if (price == null) return '';
    if (price == 0) return '무료';
    return '${price!.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  // 날짜 포맷
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
    }
  }

  // 복사 메서드
  CommunityPost copyWith({
    int? id,
    int? churchId,
    int? authorId,
    String? authorName,
    String? authorProfileUrl,
    String? category,
    String? title,
    String? content,
    List<String>? imageUrls,
    String? status,
    int? price,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isFavorited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      churchId: churchId ?? this.churchId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfileUrl: authorProfileUrl ?? this.authorProfileUrl,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      price: price ?? this.price,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 커뮤니티 댓글 모델
class CommunityComment {
  final int id;
  final int postId;
  final int authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] ?? 0,
      postId: json['post_id'] ?? 0,
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'] ?? '',
      authorProfileUrl: json['author_profile_url'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_profile_url': authorProfileUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
    }
  }
}

// 커뮤니티 카테고리 열거형
enum CommunityCategory {
  freeSharing('free_sharing', '무료나눔', '나눔하고 싶은 물품을 공유하세요'),
  sale('sale', '물품 판매', '판매하고 싶은 물품을 등록하세요'),
  request('request', '물품 요청', '필요한 물품을 요청하세요'),
  general('general', '일반', '자유롭게 이야기를 나누세요');

  final String value;
  final String displayName;
  final String description;

  const CommunityCategory(this.value, this.displayName, this.description);

  static CommunityCategory fromValue(String value) {
    return CommunityCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => CommunityCategory.general,
    );
  }
}
