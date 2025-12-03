import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// 알림 설정 저장/로드 서비스
class NotificationSettingsService {
  static const String _keyChatNotifications = 'notification_chat';
  static const String _keyLikeNotifications = 'notification_like';
  static const String _keyChurchNewsNotifications = 'notification_church_news';
  static const String _keyNotificationSound = 'notification_sound';

  static NotificationSettingsService? _instance;
  static NotificationSettingsService get instance =>
      _instance ??= NotificationSettingsService._internal();

  NotificationSettingsService._internal();

  /// 채팅 알림 설정 저장
  Future<void> setChatNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyChatNotifications, enabled);
      developer.log('채팅 알림 설정 저장: $enabled', name: 'NOTIFICATION_SETTINGS');
    } catch (e) {
      developer.log('채팅 알림 설정 저장 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
    }
  }

  /// 좋아요 알림 설정 저장
  Future<void> setLikeNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLikeNotifications, enabled);
      developer.log('좋아요 알림 설정 저장: $enabled', name: 'NOTIFICATION_SETTINGS');
    } catch (e) {
      developer.log('좋아요 알림 설정 저장 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
    }
  }

  /// 교회 소식 알림 설정 저장
  Future<void> setChurchNewsNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyChurchNewsNotifications, enabled);
      developer.log('교회 소식 알림 설정 저장: $enabled', name: 'NOTIFICATION_SETTINGS');
    } catch (e) {
      developer.log('교회 소식 알림 설정 저장 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
    }
  }

  /// 알림음 설정 저장
  Future<void> setNotificationSound(String sound) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyNotificationSound, sound);
      developer.log('알림음 설정 저장: $sound', name: 'NOTIFICATION_SETTINGS');
    } catch (e) {
      developer.log('알림음 설정 저장 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
    }
  }

  /// 채팅 알림 설정 로드 (기본값: true)
  Future<bool> getChatNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyChatNotifications) ?? true;
    } catch (e) {
      developer.log('채팅 알림 설정 로드 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
      return true;
    }
  }

  /// 좋아요 알림 설정 로드 (기본값: true)
  Future<bool> getLikeNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyLikeNotifications) ?? true;
    } catch (e) {
      developer.log('좋아요 알림 설정 로드 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
      return true;
    }
  }

  /// 교회 소식 알림 설정 로드 (기본값: true)
  Future<bool> getChurchNewsNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyChurchNewsNotifications) ?? true;
    } catch (e) {
      developer.log('교회 소식 알림 설정 로드 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
      return true;
    }
  }

  /// 알림음 설정 로드 (기본값: '알림음')
  Future<String> getNotificationSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyNotificationSound) ?? '알림음';
    } catch (e) {
      developer.log('알림음 설정 로드 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
      return '알림음';
    }
  }

  /// 알림 타입에 따라 알림 표시 여부 확인
  Future<bool> shouldShowNotification(String? notificationType) async {
    if (notificationType == null) return true;

    try {
      // 알림 타입에 따라 설정 확인
      switch (notificationType) {
        case 'chat_message':
          return await getChatNotifications();
        case 'community_like':
        case 'comment':
          return await getLikeNotifications();
        case 'announcement':
        case 'worship_reminder':
        case 'church_news':
          return await getChurchNewsNotifications();
        default:
          return true; // 알 수 없는 타입은 기본적으로 표시
      }
    } catch (e) {
      developer.log('알림 표시 여부 확인 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
      return true; // 오류 시 기본적으로 표시
    }
  }

  /// 모든 설정 초기화
  Future<void> resetAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyChatNotifications);
      await prefs.remove(_keyLikeNotifications);
      await prefs.remove(_keyChurchNewsNotifications);
      await prefs.remove(_keyNotificationSound);
      developer.log('모든 알림 설정 초기화 완료', name: 'NOTIFICATION_SETTINGS');
    } catch (e) {
      developer.log('알림 설정 초기화 실패: $e', name: 'NOTIFICATION_SETTINGS_ERROR');
    }
  }
}
