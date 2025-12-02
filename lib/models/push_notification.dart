import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/fcm_config.dart';

/// 푸시 알림 모델
class PushNotificationModel {
  final int? id;
  final String? title;
  final String? body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final NotificationType? type;
  final DateTime? receivedAt;
  final bool isRead;
  
  const PushNotificationModel({
    this.id,
    this.title,
    this.body,
    this.imageUrl,
    this.data,
    this.type,
    this.receivedAt,
    this.isRead = false,
  });
  
  /// Firebase RemoteMessage에서 변환
  factory PushNotificationModel.fromFirebaseMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    // 알림 타입 결정
    NotificationType? notificationType;
    if (data.containsKey('notification_type')) {
      try {
        notificationType = NotificationType.values.firstWhere(
          (type) => type.name == data['notification_type'],
        );
      } catch (e) {
        notificationType = NotificationType.custom;
      }
    }
    
    return PushNotificationModel(
      id: data.containsKey('id') ? int.tryParse(data['id'].toString()) : null,
      title: notification?.title ?? data['title'],
      body: notification?.body ?? data['body'],
      imageUrl: notification?.android?.imageUrl ?? data['image_url'],
      data: data,
      type: notificationType,
      receivedAt: DateTime.now(),
      isRead: false,
    );
  }
  
  /// JSON에서 변환
  factory PushNotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType? notificationType;
    if (json['notification_type'] != null) {
      try {
        notificationType = NotificationType.values.firstWhere(
          (type) => type.name == json['notification_type'],
        );
      } catch (e) {
        notificationType = NotificationType.custom;
      }
    }
    
    return PushNotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['image_url'],
      data: json['data'],
      type: notificationType,
      receivedAt: json['received_at'] != null 
          ? DateTime.parse(json['received_at'])
          : null,
      isRead: json['is_read'] ?? false,
    );
  }
  
  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'data': data,
      'notification_type': type?.name,
      'received_at': receivedAt?.toIso8601String(),
      'is_read': isRead,
    };
  }
  
  /// 복사본 생성
  PushNotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationType? type,
    DateTime? receivedAt,
    bool? isRead,
  }) {
    return PushNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      type: type ?? this.type,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }
  
  @override
  String toString() {
    return 'PushNotificationModel(id: $id, title: $title, body: $body, type: $type, isRead: $isRead)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PushNotificationModel &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.imageUrl == imageUrl &&
      other.type == type &&
      other.receivedAt == receivedAt &&
      other.isRead == isRead;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      body.hashCode ^
      imageUrl.hashCode ^
      type.hashCode ^
      receivedAt.hashCode ^
      isRead.hashCode;
  }
}

/// 백엔드 API 요청/응답을 위한 모델들

/// 기기 등록 요청
class DeviceRegistrationRequest {
  final String deviceToken;
  final String platform;
  final String? deviceModel;
  final String? appVersion;
  
  const DeviceRegistrationRequest({
    required this.deviceToken,
    required this.platform,
    this.deviceModel,
    this.appVersion,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'device_token': deviceToken,
      'platform': platform,
      if (deviceModel != null) 'device_model': deviceModel,
      if (appVersion != null) 'app_version': appVersion,
    };
  }
}

/// 기기 등록 응답
class DeviceRegistrationResponse {
  final int id;
  final int userId;
  final String deviceToken;
  final String platform;
  final String? deviceModel;
  final String? appVersion;
  final bool isActive;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  
  const DeviceRegistrationResponse({
    required this.id,
    required this.userId,
    required this.deviceToken,
    required this.platform,
    this.deviceModel,
    this.appVersion,
    required this.isActive,
    this.lastUsedAt,
    required this.createdAt,
  });
  
  factory DeviceRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResponse(
      id: json['id'],
      userId: json['user_id'],
      deviceToken: json['device_token'],
      platform: json['platform'],
      deviceModel: json['device_model'],
      appVersion: json['app_version'],
      isActive: json['is_active'] ?? true,
      lastUsedAt: json['last_used_at'] != null 
          ? DateTime.parse(json['last_used_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// 개별 알림 발송 요청
class SendNotificationRequest {
  final int userId;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  
  const SendNotificationRequest({
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.imageUrl,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      if (type != null) 'type': type,
      if (data != null) 'data': data,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

/// 다중 사용자 알림 발송 요청
class SendBatchNotificationRequest {
  final List<int> userIds;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  
  const SendBatchNotificationRequest({
    required this.userIds,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.imageUrl,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'user_ids': userIds,
      'title': title,
      'body': body,
      if (type != null) 'type': type,
      if (data != null) 'data': data,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

/// 교회 전체 알림 발송 요청
class SendChurchNotificationRequest {
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  
  const SendChurchNotificationRequest({
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.imageUrl,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      if (type != null) 'type': type,
      if (data != null) 'data': data,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

/// 알림 발송 응답
class SendNotificationResponse {
  final bool success;
  final String message;
  final int? notificationId;
  final int? sentCount;
  final int? failedCount;
  final int? noDeviceCount;
  final int? totalUsers;
  final List<int>? noDeviceUsers;
  
  const SendNotificationResponse({
    required this.success,
    required this.message,
    this.notificationId,
    this.sentCount,
    this.failedCount,
    this.noDeviceCount,
    this.totalUsers,
    this.noDeviceUsers,
  });
  
  factory SendNotificationResponse.fromJson(Map<String, dynamic> json) {
    return SendNotificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      notificationId: json['notification_id'],
      sentCount: json['sent_count'],
      failedCount: json['failed_count'],
      noDeviceCount: json['no_device_count'],
      totalUsers: json['total_users'],
      noDeviceUsers: json['no_device_users'] != null
          ? List<int>.from(json['no_device_users'])
          : null,
    );
  }
}

class NotificationHistory {
  final int id;
  final String title;
  final String body;
  final String notificationType;
  final int sentCount;
  final int deliveredCount;
  final int readCount;
  final DateTime createdAt;
  final bool isSuccess;
  
  const NotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.sentCount,
    required this.deliveredCount,
    required this.readCount,
    required this.createdAt,
    required this.isSuccess,
  });
  
  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      notificationType: json['notification_type'],
      sentCount: json['sent_count'] ?? 0,
      deliveredCount: json['delivered_count'] ?? 0,
      readCount: json['read_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      isSuccess: json['is_success'] ?? false,
    );
  }
}

class NotificationPreferences {
  final bool announcements;
  final bool worshipReminders;
  final bool attendanceNotifications;
  final bool birthdayNotifications;
  final bool prayerRequests;
  final bool systemNotifications;
  final bool customNotifications;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool enableQuietHours;
  
  const NotificationPreferences({
    this.announcements = true,
    this.worshipReminders = true,
    this.attendanceNotifications = true,
    this.birthdayNotifications = true,
    this.prayerRequests = true,
    this.systemNotifications = true,
    this.customNotifications = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.enableQuietHours = false,
  });
  
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      announcements: json['announcements'] as bool? ?? true,
      worshipReminders: json['worship_reminders'] as bool? ?? true,
      attendanceNotifications: json['attendance_notifications'] as bool? ?? true,
      birthdayNotifications: json['birthday_notifications'] as bool? ?? true,
      prayerRequests: json['prayer_requests'] as bool? ?? true,
      systemNotifications: json['system_notifications'] as bool? ?? true,
      customNotifications: json['custom_notifications'] as bool? ?? true,
      quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '08:00',
      enableQuietHours: json['enable_quiet_hours'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'announcements': announcements,
      'worship_reminders': worshipReminders,
      'attendance_notifications': attendanceNotifications,
      'birthday_notifications': birthdayNotifications,
      'prayer_requests': prayerRequests,
      'system_notifications': systemNotifications,
      'custom_notifications': customNotifications,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'enable_quiet_hours': enableQuietHours,
    };
  }
  
  NotificationPreferences copyWith({
    bool? announcements,
    bool? worshipReminders,
    bool? attendanceNotifications,
    bool? birthdayNotifications,
    bool? prayerRequests,
    bool? systemNotifications,
    bool? customNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? enableQuietHours,
  }) {
    return NotificationPreferences(
      announcements: announcements ?? this.announcements,
      worshipReminders: worshipReminders ?? this.worshipReminders,
      attendanceNotifications: attendanceNotifications ?? this.attendanceNotifications,
      birthdayNotifications: birthdayNotifications ?? this.birthdayNotifications,
      prayerRequests: prayerRequests ?? this.prayerRequests,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      customNotifications: customNotifications ?? this.customNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
    );
  }
}

/// 내가 받은 알림 모델
class MyNotification {
  final int id;
  final int notificationId;
  final int userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime receivedAt;
  final DateTime createdAt;
  final int? relatedId;
  final String? relatedType;

  const MyNotification({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.imageUrl,
    required this.isRead,
    this.readAt,
    required this.receivedAt,
    required this.createdAt,
    this.relatedId,
    this.relatedType,
  });
  
  factory MyNotification.fromJson(Map<String, dynamic> json) {
    return MyNotification(
      id: json['id'],
      notificationId: json['notification_id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      type: json['type'] ?? 'custom',
      data: json['data'],
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
      receivedAt: DateTime.parse(json['received_at']),
      createdAt: DateTime.parse(json['created_at']),
      relatedId: json['related_id'],
      relatedType: json['related_type'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_id': notificationId,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'image_url': imageUrl,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'received_at': receivedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'related_id': relatedId,
      'related_type': relatedType,
    };
  }
  
  MyNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return MyNotification(
      id: id,
      notificationId: notificationId,
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      imageUrl: imageUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      receivedAt: receivedAt,
      createdAt: createdAt,
      relatedId: relatedId,
      relatedType: relatedType,
    );
  }
}
