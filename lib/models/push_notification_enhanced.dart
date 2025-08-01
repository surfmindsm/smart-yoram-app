

/// 푸시 알림 유형
enum NotificationType {
  announcement('ANNOUNCEMENT', '공지사항'),
  worship('WORSHIP_REMINDER', '예배 알림'),
  attendance('ATTENDANCE', '출석 관련'),
  birthday('BIRTHDAY', '생일 축하'),
  prayer('PRAYER_REQUEST', '기도 요청'),
  system('SYSTEM', '시스템 알림'),
  custom('CUSTOM', '커스텀 알림');

  const NotificationType(this.value, this.displayName);
  final String value;
  final String displayName;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.custom,
    );
  }
}

/// 디바이스 플랫폼 유형
enum DevicePlatform {
  ios('ios'),
  android('android'),
  web('web');

  const DevicePlatform(this.value);
  final String value;

  static DevicePlatform fromValue(String value) {
    return DevicePlatform.values.firstWhere(
      (platform) => platform.value == value,
      orElse: () => DevicePlatform.android,
    );
  }
}

/// 디바이스 등록 요청 모델
class DeviceRegistrationRequest {
  final String token;
  final String platform;
  final String? deviceId;
  final String? appVersion;
  final Map<String, dynamic>? metadata;

  DeviceRegistrationRequest({
    required this.token,
    required this.platform,
    this.deviceId,
    this.appVersion,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'platform': platform,
    if (deviceId != null) 'device_id': deviceId,
    if (appVersion != null) 'app_version': appVersion,
    if (metadata != null) 'metadata': metadata,
  };
}

/// 사용자 디바이스 모델
class UserDevice {
  final String id;
  final int userId;
  final String token;
  final DevicePlatform platform;
  final String? deviceId;
  final String? appVersion;
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDevice({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    this.deviceId,
    this.appVersion,
    this.metadata,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDevice.fromJson(Map<String, dynamic> json) => UserDevice(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? 0,
    token: json['token'] ?? '',
    platform: DevicePlatform.fromValue(json['platform'] ?? 'android'),
    deviceId: json['device_id'],
    appVersion: json['app_version'],
    metadata: json['metadata'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
  );
}

/// 알림 템플릿 모델
class NotificationTemplate {
  final String id;
  final String name;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isActive;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isActive,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) => NotificationTemplate(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: NotificationType.fromValue(json['type'] ?? 'CUSTOM'),
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    data: json['data'],
    isActive: json['is_active'] ?? true,
  );
}

/// 푸시 알림 모델
class PushNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final int? senderId;
  final int? churchId;
  final String status; // pending, sent, failed
  final DateTime createdAt;
  final DateTime? sentAt;
  final int totalRecipients;
  final int successCount;
  final int failureCount;

  PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.senderId,
    this.churchId,
    required this.status,
    required this.createdAt,
    this.sentAt,
    required this.totalRecipients,
    required this.successCount,
    required this.failureCount,
  });

  factory PushNotification.fromJson(Map<String, dynamic> json) => PushNotification(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    type: NotificationType.fromValue(json['notification_type'] ?? 'CUSTOM'),
    data: json['data'],
    senderId: json['sender_id'],
    churchId: json['church_id'],
    status: json['status'] ?? 'pending',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
    totalRecipients: json['total_recipients'] ?? 0,
    successCount: json['success_count'] ?? 0,
    failureCount: json['failure_count'] ?? 0,
  );

  String get formattedDate => 
    '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')} '
    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}

/// 알림 수신자 모델
class NotificationRecipient {
  final String id;
  final String notificationId;
  final int userId;
  final String status; // sent, delivered, read, failed
  final String? errorMessage;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  NotificationRecipient({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.status,
    this.errorMessage,
    this.deliveredAt,
    this.readAt,
  });

  factory NotificationRecipient.fromJson(Map<String, dynamic> json) => NotificationRecipient(
    id: json['id'] ?? '',
    notificationId: json['notification_id'] ?? '',
    userId: json['user_id'] ?? 0,
    status: json['status'] ?? 'sent',
    errorMessage: json['error_message'],
    deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
    readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
  );

  bool get isRead => status == 'read';
  bool get isDelivered => deliveredAt != null;
}

/// 내 알림 모델
class MyNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  MyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory MyNotification.fromJson(Map<String, dynamic> json) => MyNotification(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    type: NotificationType.fromValue(json['notification_type'] ?? 'CUSTOM'),
    data: json['data'],
    isRead: json['is_read'] ?? false,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
  );

  String get formattedDate => 
    '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';

  String get formattedTime =>
    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}

/// 알림 설정 모델
class NotificationPreference {
  final int userId;
  final Map<NotificationType, bool> preferences;
  final bool allowSound;
  final bool allowVibration;
  final bool allowBadge;
  final String quietHoursStart;
  final String quietHoursEnd;
  final DateTime updatedAt;

  NotificationPreference({
    required this.userId,
    required this.preferences,
    required this.allowSound,
    required this.allowVibration,
    required this.allowBadge,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.updatedAt,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final prefMap = <NotificationType, bool>{};
    if (json['preferences'] != null) {
      (json['preferences'] as Map<String, dynamic>).forEach((key, value) {
        final type = NotificationType.fromValue(key);
        prefMap[type] = value ?? true;
      });
    }

    return NotificationPreference(
      userId: json['user_id'] ?? 0,
      preferences: prefMap,
      allowSound: json['allow_sound'] ?? true,
      allowVibration: json['allow_vibration'] ?? true,
      allowBadge: json['allow_badge'] ?? true,
      quietHoursStart: json['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] ?? '07:00',
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'preferences': preferences.map((key, value) => MapEntry(key.value, value)),
    'allow_sound': allowSound,
    'allow_vibration': allowVibration,
    'allow_badge': allowBadge,
    'quiet_hours_start': quietHoursStart,
    'quiet_hours_end': quietHoursEnd,
  };
}

/// 알림 발송 요청 모델
class SendNotificationRequest {
  final int? userId;
  final List<int>? userIds;
  final int? churchId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final String? templateId;
  final DateTime? scheduledAt;

  SendNotificationRequest({
    this.userId,
    this.userIds,
    this.churchId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.templateId,
    this.scheduledAt,
  });

  Map<String, dynamic> toJson() => {
    if (userId != null) 'user_id': userId,
    if (userIds != null && userIds!.isNotEmpty) 'user_ids': userIds,
    if (churchId != null) 'church_id': churchId,
    'title': title,
    'body': body,
    'notification_type': type.value,
    if (data != null) 'data': data,
    if (templateId != null) 'template_id': templateId,
    if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
  };
}

/// 알림 발송 결과 모델
class SendNotificationResult {
  final String notificationId;
  final int totalRecipients;
  final int successCount;
  final int failureCount;
  final String status;
  final String? message;

  SendNotificationResult({
    required this.notificationId,
    required this.totalRecipients,
    required this.successCount,
    required this.failureCount,
    required this.status,
    this.message,
  });

  factory SendNotificationResult.fromJson(Map<String, dynamic> json) => SendNotificationResult(
    notificationId: json['notification_id'] ?? '',
    totalRecipients: json['total_recipients'] ?? 0,
    successCount: json['success_count'] ?? 0,
    failureCount: json['failure_count'] ?? 0,
    status: json['status'] ?? 'unknown',
    message: json['message'],
  );

  bool get isSuccess => status == 'success' || status == 'sent';
  double get successRate => totalRecipients > 0 ? successCount / totalRecipients : 0.0;
}
