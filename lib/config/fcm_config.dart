import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM 설정 및 상수 관리
class FCMConfig {
  // 알림 채널 설정
  static const String defaultChannelId = 'smart_yoram_notifications';
  static const String defaultChannelName = 'Smart Yoram 알림';
  static const String defaultChannelDescription = 'Smart Yoram 앱의 일반 알림';
  
  // 알림 타입별 채널 설정
  static const Map<String, NotificationChannelConfig> channels = {
    'announcement': NotificationChannelConfig(
      id: 'announcements',
      name: '공지사항',
      description: '교회 공지사항 알림',
      importance: Importance.high,
    ),
    'worship': NotificationChannelConfig(
      id: 'worship_reminders',
      name: '예배 알림',
      description: '예배 시간 및 일정 알림',
      importance: Importance.high,
    ),
    'attendance': NotificationChannelConfig(
      id: 'attendance',
      name: '출석 관련',
      description: '출석 확인 및 관련 알림',
      importance: Importance.defaultImportance,
    ),
    'birthday': NotificationChannelConfig(
      id: 'birthdays',
      name: '생일 축하',
      description: '생일 축하 메시지',
      importance: Importance.defaultImportance,
    ),
    'prayer': NotificationChannelConfig(
      id: 'prayer_requests',
      name: '기도 요청',
      description: '기도 요청 및 응답 알림',
      importance: Importance.defaultImportance,
    ),
    'system': NotificationChannelConfig(
      id: 'system_notifications',
      name: '시스템 알림',
      description: '앱 업데이트 및 시스템 메시지',
      importance: Importance.low,
    ),
    'custom': NotificationChannelConfig(
      id: 'custom_notifications',
      name: '사용자 정의',
      description: '사용자 정의 알림',
      importance: Importance.defaultImportance,
    ),
  };
  
  // 기본 알림 설정
  static const AndroidNotificationDetails defaultAndroidNotificationDetails = 
    AndroidNotificationDetails(
      defaultChannelId,
      defaultChannelName,
      channelDescription: defaultChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: Color(0xFF1976D2), // Blue color
      enableVibration: true,
      playSound: true,
    );
    
  static const DarwinNotificationDetails defaultIOSNotificationDetails = 
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );
    
  static const NotificationDetails defaultNotificationDetails = 
    NotificationDetails(
      android: defaultAndroidNotificationDetails,
      iOS: defaultIOSNotificationDetails,
    );
}

/// 알림 채널 설정 클래스
class NotificationChannelConfig {
  final String id;
  final String name;
  final String description;
  final Importance importance;
  
  const NotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
  });
  
  AndroidNotificationChannel toAndroidChannel() {
    return AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: importance,
      enableVibration: true,
      playSound: true,
    );
  }
}

/// 알림 타입 enum
enum NotificationType {
  announcement('공지사항'),
  worship('예배 알림'),
  attendance('출석 관련'),
  birthday('생일 축하'),
  prayer('기도 요청'),
  system('시스템 알림'),
  custom('사용자 정의');
  
  const NotificationType(this.displayName);
  final String displayName;
  
  String get channelId {
    switch (this) {
      case NotificationType.announcement:
        return 'announcements';
      case NotificationType.worship:
        return 'worship_reminders';
      case NotificationType.attendance:
        return 'attendance';
      case NotificationType.birthday:
        return 'birthdays';
      case NotificationType.prayer:
        return 'prayer_requests';
      case NotificationType.system:
        return 'system_notifications';
      case NotificationType.custom:
        return 'custom_notifications';
    }
  }
}
