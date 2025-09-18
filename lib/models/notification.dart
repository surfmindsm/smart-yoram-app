class NotificationModel {
  final int id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final bool isImportant;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.isImportant = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      category: NotificationCategory.fromString(json['category'] ?? 'notice'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      isImportant: json['is_important'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category.value,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_important': isImportant,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
    bool? isImportant,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  String get timeAgo {
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
      return '${difference.inDays ~/ 7}주 전';
    }
  }
}

enum NotificationCategory {
  all('all', '전체'),
  important('important', '중요'),
  notice('notice', '공지'),
  schedule('schedule', '일정'),
  attendance('attendance', '출석');

  const NotificationCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static NotificationCategory fromString(String value) {
    return NotificationCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => NotificationCategory.notice,
    );
  }

  // 카테고리별 색상 정의
  NotificationCategoryStyle get style {
    switch (this) {
      case NotificationCategory.important:
        return const NotificationCategoryStyle(
          backgroundColor: 0xFFFEE1E3, // #fee1e3
          borderColor: 0xFFEF4352, // #ef4352
          textColor: 0xFFEF4352, // #ef4352
        );
      case NotificationCategory.notice:
        return const NotificationCategoryStyle(
          backgroundColor: 0xFFD6EBFF, // #d6ebff
          borderColor: 0xFF0078FF, // #0078ff
          textColor: 0xFF0078FF, // #0078ff
        );
      case NotificationCategory.schedule:
        return const NotificationCategoryStyle(
          backgroundColor: 0xFFD1FAEC, // #d1faec
          borderColor: 0xFF0EA472, // #0ea472
          textColor: 0xFF0EA472, // #0ea472
        );
      case NotificationCategory.attendance:
        return const NotificationCategoryStyle(
          backgroundColor: 0xFFFFF1D6, // #fff1d6
          borderColor: 0xFFDB7712, // #db7712
          textColor: 0xFFDB7712, // #db7712
        );
      default:
        return const NotificationCategoryStyle(
          backgroundColor: 0xFFF2F3F8, // #f2f3f8
          borderColor: 0xFF99A1B1, // #99a1b1
          textColor: 0xFF354153, // #354153
        );
    }
  }
}

class NotificationCategoryStyle {
  final int backgroundColor;
  final int borderColor;
  final int textColor;

  const NotificationCategoryStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}