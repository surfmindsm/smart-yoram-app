class DailyVerse {
  final int id;
  final String verse;
  final String reference;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyVerse({
    required this.id,
    required this.verse,
    required this.reference,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyVerse.fromJson(Map<String, dynamic> json) {
    return DailyVerse(
      id: json['id'] ?? 0,
      verse: json['verse'] ?? '',
      reference: json['reference'] ?? '',
      isActive: json['is_active'] ?? true,
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
      'verse': verse,
      'reference': reference,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 편의 메서드들
  String get content => verse; // verse 필드가 실제 말씀 내용
  String get shortContent => verse.length > 50 ? '${verse.substring(0, 50)}...' : verse;
}
