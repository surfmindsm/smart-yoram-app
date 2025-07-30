class SmsRecord {
  final int id;
  final String recipientPhone;
  final int? recipientMemberId;
  final String message;
  final String smsType;
  final String status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? errorMessage;

  SmsRecord({
    required this.id,
    required this.recipientPhone,
    this.recipientMemberId,
    required this.message,
    required this.smsType,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.errorMessage,
  });

  factory SmsRecord.fromJson(Map<String, dynamic> json) {
    return SmsRecord(
      id: json['id'],
      recipientPhone: json['recipient_phone'],
      recipientMemberId: json['recipient_member_id'],
      message: json['message'],
      smsType: json['sms_type'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_phone': recipientPhone,
      'recipient_member_id': recipientMemberId,
      'message': message,
      'sms_type': smsType,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'error_message': errorMessage,
    };
  }
}

class BulkSmsResult {
  final String message;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  BulkSmsResult({
    required this.message,
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });

  factory BulkSmsResult.fromJson(Map<String, dynamic> json) {
    return BulkSmsResult(
      message: json['message'],
      successCount: json['success_count'] ?? 0,
      failureCount: json['failure_count'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}

class SmsTemplate {
  final int id;
  final String name;
  final String message;
  final String smsType;
  final bool isActive;

  SmsTemplate({
    required this.id,
    required this.name,
    required this.message,
    required this.smsType,
    required this.isActive,
  });

  factory SmsTemplate.fromJson(Map<String, dynamic> json) {
    return SmsTemplate(
      id: json['id'],
      name: json['name'],
      message: json['message'],
      smsType: json['sms_type'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'message': message,
      'sms_type': smsType,
      'is_active': isActive,
    };
  }
}

// SMS 타입 상수
class SmsType {
  static const String invitation = 'invitation';
  static const String notice = 'notice';
  static const String reminder = 'reminder';
  static const String birthday = 'birthday';
  static const String emergency = 'emergency';
  
  static List<String> get all => [
    invitation,
    notice,
    reminder,
    birthday,
    emergency,
  ];
  
  static String getDisplayName(String type) {
    switch (type) {
      case invitation:
        return '초대';
      case notice:
        return '공지';
      case reminder:
        return '알림';
      case birthday:
        return '생일축하';
      case emergency:
        return '긴급';
      default:
        return type;
    }
  }
}
