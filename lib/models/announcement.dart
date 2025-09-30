class Announcement {
  final int id;
  final int churchId;
  final String title;
  final String content;
  final int authorId;
  final String? authorName;
  final bool isPinned;
  final bool isActive;
  final String? targetAudience; // 대상 (전체, 임원진 등)
  final String category; // 카테고리 (worship, member_news, event)
  final String? subcategory; // 서브카테고리
  final DateTime createdAt;
  final DateTime updatedAt;

  const Announcement({
    required this.id,
    required this.churchId,
    required this.title,
    required this.content,
    required this.authorId,
    this.authorName,
    required this.isPinned,
    required this.isActive,
    this.targetAudience,
    required this.category,
    this.subcategory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      churchId: json['church_id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'],
      isPinned: json['is_pinned'] ?? false,
      isActive: json['is_active'] ?? true,
      targetAudience: json['target_audience'],
      category: json['category'] ?? 'general',
      subcategory: json['subcategory'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'church_id': churchId,
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'is_pinned': isPinned,
      'is_active': isActive,
      'target_audience': targetAudience,
      'category': category,
      'subcategory': subcategory,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Announcement copyWith({
    int? id,
    int? churchId,
    String? title,
    String? content,
    int? authorId,
    String? authorName,
    bool? isPinned,
    bool? isActive,
    String? targetAudience,
    String? category,
    String? subcategory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      churchId: churchId ?? this.churchId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      targetAudience: targetAudience ?? this.targetAudience,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // UI에서 사용할 편의 메서드들
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  String get truncatedContent {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}

// 공지사항 생성/수정용 DTO
class AnnouncementCreateRequest {
  final String title;
  final String content;
  final bool isPinned;
  final String? targetAudience;

  const AnnouncementCreateRequest({
    required this.title,
    required this.content,
    this.isPinned = false,
    this.targetAudience,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'is_pinned': isPinned,
      'target_audience': targetAudience,
    };
  }
}

class AnnouncementUpdateRequest {
  final String? title;
  final String? content;
  final bool? isPinned;
  final String? targetAudience;

  const AnnouncementUpdateRequest({
    this.title,
    this.content,
    this.isPinned,
    this.targetAudience,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (title != null) json['title'] = title;
    if (content != null) json['content'] = content;
    if (isPinned != null) json['is_pinned'] = isPinned;
    if (targetAudience != null) json['target_audience'] = targetAudience;
    return json;
  }
}
