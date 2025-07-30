class Bulletin {
  final String id;
  final String title;
  final DateTime date;
  final String? description;
  final String? fileUrl; // PDF 또는 이미지 URL
  final String fileType; // 'pdf' 또는 'image'
  final int? fileSize;
  final DateTime createdAt;
  final String createdBy;

  Bulletin({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    this.fileUrl,
    required this.fileType,
    this.fileSize,
    required this.createdAt,
    required this.createdBy,
  });

  factory Bulletin.fromJson(Map<String, dynamic> json) {
    return Bulletin(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
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
