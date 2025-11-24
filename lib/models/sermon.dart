class Sermon {
  final String id;
  final String title;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String? preacherName;
  final String? description;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int viewCount;
  final int favoriteCount;
  final String? category;
  final DateTime? sermonDate;
  final bool isFeatured;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Sermon({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    this.preacherName,
    this.description,
    this.thumbnailUrl,
    this.durationSeconds,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.category,
    this.sermonDate,
    this.isFeatured = false,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] as String,
      title: json['title'] as String,
      youtubeUrl: json['youtube_url'] as String,
      youtubeVideoId: json['youtube_video_id'] as String,
      preacherName: json['preacher_name'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      viewCount: json['view_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      category: json['category'] as String?,
      sermonDate: json['sermon_date'] != null
          ? DateTime.parse(json['sermon_date'] as String)
          : null,
      isFeatured: json['is_featured'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'youtube_url': youtubeUrl,
      'youtube_video_id': youtubeVideoId,
      'preacher_name': preacherName,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'view_count': viewCount,
      'favorite_count': favoriteCount,
      'category': category,
      'sermon_date': sermonDate?.toIso8601String(),
      'is_featured': isFeatured,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // 유튜브 썸네일 URL 생성 (기본, 중간, 고화질)
  String getThumbnailUrl({String quality = 'default'}) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
    }
    // 유튜브 썸네일 URL 생성
    // quality: default, mqdefault, hqdefault, sddefault, maxresdefault
    return 'https://img.youtube.com/vi/$youtubeVideoId/$quality.jpg';
  }

  // 설교 길이를 시간 형식으로 반환 (예: "1:23:45")
  String getFormattedDuration() {
    if (durationSeconds == null) return '';

    final hours = durationSeconds! ~/ 3600;
    final minutes = (durationSeconds! % 3600) ~/ 60;
    final seconds = durationSeconds! % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // 설교 날짜를 형식화하여 반환 (예: "2024년 1월 7일")
  String getFormattedSermonDate() {
    if (sermonDate == null) return '';

    return '${sermonDate!.year}년 ${sermonDate!.month}월 ${sermonDate!.day}일';
  }

  Sermon copyWith({
    String? id,
    String? title,
    String? youtubeUrl,
    String? youtubeVideoId,
    String? preacherName,
    String? description,
    String? thumbnailUrl,
    int? durationSeconds,
    int? viewCount,
    int? favoriteCount,
    String? category,
    DateTime? sermonDate,
    bool? isFeatured,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sermon(
      id: id ?? this.id,
      title: title ?? this.title,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      preacherName: preacherName ?? this.preacherName,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      category: category ?? this.category,
      sermonDate: sermonDate ?? this.sermonDate,
      isFeatured: isFeatured ?? this.isFeatured,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
