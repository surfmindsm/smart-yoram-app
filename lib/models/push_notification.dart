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

/// 백엔드 API 요청을 위한 모델들
class DeviceRegistrationRequest {
  final String token;
  final String platform;
  final String? deviceId;
  final String? appVersion;
  
  const DeviceRegistrationRequest({
    required this.token,
    required this.platform,
    this.deviceId,
    this.appVersion,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'platform': platform,
      if (deviceId != null) 'device_id': deviceId,
      if (appVersion != null) 'app_version': appVersion,
    };
  }
}

class SendNotificationRequest {
  final String title;
  final String body;
  final String notificationType;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final List<int>? userIds;
  final int? churchId;
  
  const SendNotificationRequest({
    required this.title,
    required this.body,
    required this.notificationType,
    this.data,
    this.imageUrl,
    this.userIds,
    this.churchId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'notification_type': notificationType,
      if (data != null) 'data': data,
      if (imageUrl != null) 'image_url': imageUrl,
      if (userIds != null) 'user_ids': userIds,
      if (churchId != null) 'church_id': churchId,
    };
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
      announcements: json['announcements'] ?? true,
      worshipReminders: json['worship_reminders'] ?? true,
      attendanceNotifications: json['attendance_notifications'] ?? true,
      birthdayNotifications: json['birthday_notifications'] ?? true,
      prayerRequests: json['prayer_requests'] ?? true,
      systemNotifications: json['system_notifications'] ?? true,
      customNotifications: json['custom_notifications'] ?? true,
      quietHoursStart: json['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] ?? '08:00',
      enableQuietHours: json['enable_quiet_hours'] ?? false,
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
