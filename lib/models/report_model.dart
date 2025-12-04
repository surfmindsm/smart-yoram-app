/// 신고 모델
class Report {
  final int id;
  final int reporterId;
  final String reportedType; // 'post', 'chat', 'user'
  final int reportedId;
  final String? reportedTable;
  final String reason; // 'spam', 'inappropriate', 'fraud', 'harassment', 'etc'
  final String? description;
  final String status; // 'pending', 'reviewing', 'resolved', 'rejected'
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final int? resolvedBy;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedType,
    required this.reportedId,
    this.reportedTable,
    required this.reason,
    this.description,
    required this.status,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reporterId: json['reporter_id'],
      reportedType: json['reported_type'],
      reportedId: json['reported_id'],
      reportedTable: json['reported_table'],
      reason: json['reason'],
      description: json['description'],
      status: json['status'],
      adminNote: json['admin_note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolvedBy: json['resolved_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_type': reportedType,
      'reported_id': reportedId,
      'reported_table': reportedTable,
      'reason': reason,
      'description': description,
      'status': status,
      'admin_note': adminNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
    };
  }
}

/// 신고 사유 열거형
enum ReportReason {
  spam('spam', '스팸/광고'),
  inappropriate('inappropriate', '부적절한 콘텐츠'),
  fraud('fraud', '사기/거짓 정보'),
  harassment('harassment', '욕설/비방/혐오'),
  etc('etc', '기타');

  final String value;
  final String label;

  const ReportReason(this.value, this.label);

  static ReportReason fromValue(String value) {
    return ReportReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => ReportReason.etc,
    );
  }
}

/// 신고 타입 열거형
enum ReportType {
  post('post', '게시글'),
  chat('chat', '채팅'),
  user('user', '사용자');

  final String value;
  final String label;

  const ReportType(this.value, this.label);

  static ReportType fromValue(String value) {
    return ReportType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReportType.post,
    );
  }
}
