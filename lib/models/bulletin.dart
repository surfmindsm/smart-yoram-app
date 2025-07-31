class Bulletin {
  final int id;
  final String title;
  final DateTime date;
  final String? content;  // API에서 content 사용
  final String? fileUrl;
  final int churchId;  // 추가
  final DateTime createdAt;
  final int createdBy;  // API에서 int 사용
  final DateTime? updatedAt;  // 추가

  Bulletin({
    required this.id,
    required this.title,
    required this.date,
    this.content,
    this.fileUrl,
    required this.churchId,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
  });

  factory Bulletin.fromJson(Map<String, dynamic> json) {
    return Bulletin(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      content: json['content'],
      fileUrl: json['file_url'],
      churchId: json['church_id'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      createdBy: json['created_by'] ?? 0,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String().substring(0, 10), // YYYY-MM-DD 형식
      'content': content,
      'file_url': fileUrl,
      'church_id': churchId,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // 호환성을 위한 getter
  String? get description => content;
  String get fileType => fileUrl?.split('.').last ?? 'unknown';
  int? get fileSize => null;
}

class BulletinNotice {
  final String id;
  final String title;
  final String content;
  final bool isImportant;
  final String? attachmentUrl;
  final DateTime createdAt;
  final String createdBy;

  BulletinNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    this.attachmentUrl,
    required this.createdAt,
    required this.createdBy,
  });

  factory BulletinNotice.fromJson(Map<String, dynamic> json) {
    return BulletinNotice(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      isImportant: json['is_important'],
      attachmentUrl: json['attachment_url'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_important': isImportant,
      'attachment_url': attachmentUrl,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
