class Notice {
  final String id;
  final String title;
  final String content;
  final String type; // 'general', 'important', 'urgent', 'event'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final bool isPublished;
  final String? imageUrl;
  final List<String>? attachments;
  final DateTime? expiryDate;
  final bool isRead;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.isPublished = true,
    this.imageUrl,
    this.attachments,
    this.expiryDate,
    this.isRead = false,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
      isPublished: json['is_published'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  // Announcement 테이블 데이터에서 Notice 객체 생성
  factory Notice.fromAnnouncement(Map<String, dynamic> json) {
    return Notice(
      id: json['id'].toString(),
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['category'] as String? ?? 'general',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['author_name'] as String? ?? '관리자',
      isPublished: json['is_active'] as bool? ?? true,
      imageUrl: null, // announcements 테이블에 없는 경우
      attachments: null,
      expiryDate: null,
      isRead: false, // 기본값
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'is_published': isPublished,
      'image_url': imageUrl,
      'attachments': attachments,
      'expiry_date': expiryDate?.toIso8601String(),
      'is_read': isRead,
    };
  }

  Notice copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isPublished,
    String? imageUrl,
    List<String>? attachments,
    DateTime? expiryDate,
    bool? isRead,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isPublished: isPublished ?? this.isPublished,
      imageUrl: imageUrl ?? this.imageUrl,
      attachments: attachments ?? this.attachments,
      expiryDate: expiryDate ?? this.expiryDate,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isImportant {
    return type == 'important' || type == 'urgent';
  }

  @override
  String toString() {
    return 'Notice(id: $id, title: $title, type: $type, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Notice &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        type.hashCode ^
        createdAt.hashCode ^
        createdBy.hashCode;
  }
}
