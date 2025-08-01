import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/push_notification_enhanced.dart';
import '../models/api_response.dart';
import 'auth_service.dart';

/// 향상된 푸시 알림 서비스 (새로운 백엔드 API 연동)
class NotificationServiceEnhanced {
  static NotificationServiceEnhanced? _instance;
  static NotificationServiceEnhanced get instance => 
    _instance ??= NotificationServiceEnhanced._internal();
  
  NotificationServiceEnhanced._internal();
  
  /// API 헤더 생성 (Bearer 토큰 포함)
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getStoredToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 1. 디바이스 토큰 등록
  Future<ApiResponse<bool>> registerDevice({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      developer.log('📱 디바이스 토큰 등록 시작: $platform', name: 'PUSH_NOTIFICATION');
      
      final request = DeviceRegistrationRequest(
        token: token,
        platform: platform,
        deviceId: deviceId ?? (Platform.isIOS ? 'ios_device' : 'android_device'),
        appVersion: appVersion ?? '1.0.0',
        metadata: {
          'registered_at': DateTime.now().toIso8601String(),
          'platform_version': Platform.operatingSystemVersion,
        },
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsDevicesRegister}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('📱 등록 응답: ${response.statusCode} - ${response.body}', name: 'PUSH_NOTIFICATION');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('디바이스 등록 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 디바이스 등록 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('디바이스 등록 중 오류가 발생했습니다: $e');
    }
  }

  /// 2. 디바이스 토큰 해제
  Future<ApiResponse<bool>> unregisterDevice({required String token}) async {
    try {
      developer.log('📱 디바이스 토큰 해제 시작', name: 'PUSH_NOTIFICATION');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsDevicesUnregister}'),
        headers: await _getHeaders(),
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('📱 해제 응답: ${response.statusCode}', name: 'PUSH_NOTIFICATION');
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('디바이스 해제 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 디바이스 해제 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('디바이스 해제 중 오류가 발생했습니다: $e');
    }
  }

  /// 3. 내 디바이스 목록 조회
  Future<ApiResponse<List<UserDevice>>> getMyDevices() async {
    try {
      developer.log('📱 내 디바이스 목록 조회', name: 'PUSH_NOTIFICATION');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsDevices}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final devices = data.map((json) => UserDevice.fromJson(json)).toList();
        return ApiResponse.success(devices);
      } else {
        return ApiResponse.error('디바이스 목록 조회 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 디바이스 목록 조회 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('디바이스 목록 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 4. 개별 알림 발송
  Future<ApiResponse<SendNotificationResult>> sendToUser({
    required int userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      developer.log('📤 개별 알림 발송: $userId', name: 'PUSH_NOTIFICATION');
      
      final request = SendNotificationRequest(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsSend}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = SendNotificationResult.fromJson(jsonDecode(response.body));
        return ApiResponse.success(result);
      } else {
        return ApiResponse.error('개별 알림 발송 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 개별 알림 발송 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('개별 알림 발송 중 오류가 발생했습니다: $e');
    }
  }

  /// 5. 그룹 알림 발송 (배치)
  Future<ApiResponse<SendNotificationResult>> sendBatch({
    required List<int> userIds,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      developer.log('📤 그룹 알림 발송: ${userIds.length}명', name: 'PUSH_NOTIFICATION');
      
      final request = SendNotificationRequest(
        userIds: userIds,
        title: title,
        body: body,
        type: type,
        data: data,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsSendBatch}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = SendNotificationResult.fromJson(jsonDecode(response.body));
        return ApiResponse.success(result);
      } else {
        return ApiResponse.error('그룹 알림 발송 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 그룹 알림 발송 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('그룹 알림 발송 중 오류가 발생했습니다: $e');
    }
  }

  /// 6. 교회 전체 알림 발송
  Future<ApiResponse<SendNotificationResult>> sendToChurch({
    required int churchId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      developer.log('📤 교회 전체 알림 발송: church_id=$churchId', name: 'PUSH_NOTIFICATION');
      
      final request = SendNotificationRequest(
        churchId: churchId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsSendToChurch}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = SendNotificationResult.fromJson(jsonDecode(response.body));
        return ApiResponse.success(result);
      } else {
        return ApiResponse.error('교회 전체 알림 발송 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 교회 전체 알림 발송 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('교회 전체 알림 발송 중 오류가 발생했습니다: $e');
    }
  }

  /// 7. 발송 이력 조회
  Future<ApiResponse<List<PushNotification>>> getNotificationHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      developer.log('📋 발송 이력 조회: page=$page, limit=$limit', name: 'PUSH_NOTIFICATION');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsHistory}?page=$page&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final notifications = data.map((json) => PushNotification.fromJson(json)).toList();
        return ApiResponse.success(notifications);
      } else {
        return ApiResponse.error('발송 이력 조회 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 발송 이력 조회 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('발송 이력 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 8. 내 알림 목록 조회
  Future<ApiResponse<List<MyNotification>>> getMyNotifications({
    int page = 1,
    int limit = 50,
    bool? unreadOnly,
  }) async {
    try {
      developer.log('📨 내 알림 조회: page=$page, unreadOnly=$unreadOnly', name: 'PUSH_NOTIFICATION');
      
      String url = '${ApiConfig.baseUrl}${ApiConfig.notificationsMyNotifications}?page=$page&limit=$limit';
      if (unreadOnly == true) {
        url += '&unread_only=true';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final notifications = data.map((json) => MyNotification.fromJson(json)).toList();
        return ApiResponse.success(notifications);
      } else {
        return ApiResponse.error('내 알림 조회 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 내 알림 조회 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('내 알림 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 9. 알림 읽음 처리
  Future<ApiResponse<bool>> markAsRead(String notificationId) async {
    try {
      developer.log('✅ 알림 읽음 처리: $notificationId', name: 'PUSH_NOTIFICATION');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsMarkAsRead}/$notificationId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('알림 읽음 처리 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 알림 읽음 처리 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('알림 읽음 처리 중 오류가 발생했습니다: $e');
    }
  }

  /// 10. 알림 설정 조회
  Future<ApiResponse<NotificationPreference>> getPreferences() async {
    try {
      developer.log('⚙️ 알림 설정 조회', name: 'PUSH_NOTIFICATION');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsPreferences}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final preference = NotificationPreference.fromJson(jsonDecode(response.body));
        return ApiResponse.success(preference);
      } else {
        return ApiResponse.error('알림 설정 조회 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 알림 설정 조회 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('알림 설정 조회 중 오류가 발생했습니다: $e');
    }
  }

  /// 11. 알림 설정 변경
  Future<ApiResponse<bool>> updatePreferences(NotificationPreference preference) async {
    try {
      developer.log('⚙️ 알림 설정 변경', name: 'PUSH_NOTIFICATION');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsPreferences}'),
        headers: await _getHeaders(),
        body: jsonEncode(preference.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('알림 설정 변경 실패: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      developer.log('❌ 알림 설정 변경 오류: $e', name: 'PUSH_NOTIFICATION');
      return ApiResponse.error('알림 설정 변경 중 오류가 발생했습니다: $e');
    }
  }

  // === 편의 메서드들 ===

  /// 공지사항 알림 발송 (교회 전체)
  Future<ApiResponse<SendNotificationResult>> sendAnnouncementToChurch({
    required int churchId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return sendToChurch(
      churchId: churchId,
      title: title,
      body: body,
      type: NotificationType.announcement,
      data: data,
    );
  }

  /// 예배 알림 발송 (교회 전체)
  Future<ApiResponse<SendNotificationResult>> sendWorshipReminderToChurch({
    required int churchId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return sendToChurch(
      churchId: churchId,
      title: title,
      body: body,
      type: NotificationType.worship,
      data: data,
    );
  }

  /// 생일 축하 알림 발송 (개별)
  Future<ApiResponse<SendNotificationResult>> sendBirthdayGreeting({
    required int userId,
    required String name,
    Map<String, dynamic>? data,
  }) async {
    return sendToUser(
      userId: userId,
      title: '생일 축하합니다! 🎉',
      body: '$name님의 생일을 축하합니다. 하나님의 은혜가 함께하시길 바랍니다.',
      type: NotificationType.birthday,
      data: data,
    );
  }

  /// 기도 요청 알림 발송 (그룹)
  Future<ApiResponse<SendNotificationResult>> sendPrayerRequest({
    required List<int> userIds,
    required String requesterName,
    required String prayerRequest,
    Map<String, dynamic>? data,
  }) async {
    return sendBatch(
      userIds: userIds,
      title: '새로운 기도 요청',
      body: '$requesterName님이 기도 요청을 올렸습니다: ${prayerRequest.length > 50 ? '${prayerRequest.substring(0, 50)}...' : prayerRequest}',
      type: NotificationType.prayer,
      data: data,
    );
  }

  /// 출석 알림 발송 (개별)
  Future<ApiResponse<SendNotificationResult>> sendAttendanceReminder({
    required int userId,
    required String eventName,
    required DateTime eventTime,
    Map<String, dynamic>? data,
  }) async {
    return sendToUser(
      userId: userId,
      title: '출석 확인 요청',
      body: '$eventName 출석을 확인해 주세요. (${eventTime.hour}:${eventTime.minute.toString().padLeft(2, '0')})',
      type: NotificationType.attendance,
      data: data,
    );
  }
}
