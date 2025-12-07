import 'dart:developer' as developer;
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'chat_service.dart';

/// 앱 아이콘 배지 관리 서비스
/// 읽지 않은 채팅 메시지와 알림의 총 개수를 배지로 표시
class BadgeService {
  static BadgeService? _instance;
  static BadgeService get instance => _instance ??= BadgeService._internal();

  BadgeService._internal();

  final _supabase = Supabase.instance.client;
  bool _isSupported = false;

  /// 배지 기능 초기화 및 지원 여부 확인
  Future<void> initialize() async {
    try {
      _isSupported = await FlutterAppBadger.isAppBadgeSupported();
      developer.log('📛 앱 배지 지원: ${_isSupported ? "O" : "X"}', name: 'BadgeService');

      if (_isSupported) {
        // 초기화 시 배지 업데이트
        await updateBadge();
      }
    } catch (e) {
      developer.log('❌ 배지 초기화 실패: $e', name: 'BadgeService');
      _isSupported = false;
    }
  }

  /// 배지 업데이트 (읽지 않은 채팅 + 알림)
  Future<void> updateBadge() async {
    if (!_isSupported) return;

    try {
      final unreadCount = await getTotalUnreadCount();
      developer.log('📛 배지 업데이트: $unreadCount개', name: 'BadgeService');

      if (unreadCount > 0) {
        await FlutterAppBadger.updateBadgeCount(unreadCount);
      } else {
        await FlutterAppBadger.removeBadge();
      }
    } catch (e) {
      developer.log('❌ 배지 업데이트 실패: $e', name: 'BadgeService');
    }
  }

  /// 전체 읽지 않은 개수 가져오기 (채팅 + 알림)
  Future<int> getTotalUnreadCount() async {
    try {
      final authService = AuthService();
      final userResponse = await authService.getCurrentUser();

      if (userResponse.data == null) {
        developer.log('⚠️ 로그인되지 않아 배지 카운트 0', name: 'BadgeService');
        return 0;
      }

      final userId = userResponse.data!.id;

      // 병렬로 읽지 않은 채팅과 알림 개수 가져오기
      final results = await Future.wait([
        _getUnreadChatCount(userId),
        _getUnreadNotificationCount(userId),
      ]);

      final unreadChatCount = results[0];
      final unreadNotificationCount = results[1];
      final total = unreadChatCount + unreadNotificationCount;

      developer.log(
        '📛 읽지 않음: 채팅 $unreadChatCount개 + 알림 $unreadNotificationCount개 = 총 $total개',
        name: 'BadgeService',
      );

      return total;
    } catch (e) {
      developer.log('❌ 읽지 않은 개수 조회 실패: $e', name: 'BadgeService');
      return 0;
    }
  }

  /// 읽지 않은 채팅 메시지 개수 조회
  Future<int> _getUnreadChatCount(int userId) async {
    try {
      // ChatService를 사용하여 읽지 않은 메시지 개수 조회
      final chatService = ChatService();
      final chatRooms = await chatService.getChatRooms();

      int totalUnread = 0;
      for (final room in chatRooms) {
        totalUnread += room.unreadCount;
      }

      developer.log('📛 읽지 않은 채팅: $totalUnread개', name: 'BadgeService');
      return totalUnread;
    } catch (e) {
      developer.log('❌ 읽지 않은 채팅 조회 실패: $e', name: 'BadgeService');
      return 0;
    }
  }

  /// 읽지 않은 알림 개수 조회
  Future<int> _getUnreadNotificationCount(int userId) async {
    try {
      // notifications 테이블에서 읽지 않은 알림 개수 조회
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      final count = response.count ?? 0;
      developer.log('📛 읽지 않은 알림: $count개', name: 'BadgeService');
      return count;
    } catch (e) {
      developer.log('❌ 읽지 않은 알림 조회 실패: $e', name: 'BadgeService');
      return 0;
    }
  }

  /// 배지 제거
  Future<void> removeBadge() async {
    if (!_isSupported) return;

    try {
      await FlutterAppBadger.removeBadge();
      developer.log('📛 배지 제거 완료', name: 'BadgeService');
    } catch (e) {
      developer.log('❌ 배지 제거 실패: $e', name: 'BadgeService');
    }
  }

  /// 배지 숫자 직접 설정 (디버깅용)
  Future<void> setBadgeCount(int count) async {
    if (!_isSupported) return;

    try {
      if (count > 0) {
        await FlutterAppBadger.updateBadgeCount(count);
        developer.log('📛 배지 설정: $count개', name: 'BadgeService');
      } else {
        await FlutterAppBadger.removeBadge();
        developer.log('📛 배지 제거 (count=0)', name: 'BadgeService');
      }
    } catch (e) {
      developer.log('❌ 배지 설정 실패: $e', name: 'BadgeService');
    }
  }

  /// 배지 지원 여부
  bool get isSupported => _isSupported;
}
