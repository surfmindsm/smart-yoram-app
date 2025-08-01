import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/push_notification.dart';
import '../models/api_response.dart';
import 'auth_service.dart';

/// 백엔드 알림 API 서비스
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._internal();
  
  NotificationService._internal();
  
  /// API 헤더 생성 (Bearer 토큰 포함)
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getStoredToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  /// 디바이스 토큰 등록
  Future<ApiResponse<bool>> registerDevice({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      developer.log('디바이스 토큰 등록 시작: $platform', name: 'NOTIFICATION_API');
      
      final request = DeviceRegistrationRequest(
        token: token,
        platform: platform,
        deviceId: deviceId,
        appVersion: appVersion,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsDevicesRegister}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '디바이스 토큰 등록 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '디바이스 등록 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('디바이스 토큰 등록 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('디바이스 등록 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 디바이스 토큰 해제
  Future<ApiResponse<bool>> unregisterDevice({required String token}) async {
    try {
      developer.log('디바이스 토큰 해제 시작', name: 'NOTIFICATION_API');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsDevicesUnregister}'),
        headers: await _getHeaders(),
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '디바이스 토큰 해제 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '디바이스 해제 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('디바이스 토큰 해제 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('디바이스 해제 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 내 디바이스 목록 조회
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyDevices() async {
    try {
      developer.log('내 디바이스 목록 조회 시작', name: 'NOTIFICATION_API');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsDevices}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '내 디바이스 목록 조회 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return ApiResponse.success(
          data.map((device) => device as Map<String, dynamic>).toList(),
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '디바이스 목록 조회 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('내 디바이스 목록 조회 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('디바이스 목록 조회 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 개별 알림 발송
  Future<ApiResponse<bool>> sendNotification({
    required int userId,
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      developer.log('개별 알림 발송 시작: $userId', name: 'NOTIFICATION_API');
      
      final request = SendNotificationRequest(
        title: title,
        body: body,
        notificationType: notificationType,
        data: data,
        imageUrl: imageUrl,
        userIds: [userId],
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsSend}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '개별 알림 발송 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '알림 발송 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('개별 알림 발송 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('알림 발송 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 그룹 알림 발송
  Future<ApiResponse<bool>> sendBatchNotification({
    required List<int> userIds,
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      developer.log('그룹 알림 발송 시작: ${userIds.length}명', name: 'NOTIFICATION_API');
      
      final request = SendNotificationRequest(
        title: title,
        body: body,
        notificationType: notificationType,
        data: data,
        imageUrl: imageUrl,
        userIds: userIds,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsSendBatch}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '그룹 알림 발송 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '그룹 알림 발송 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('그룹 알림 발송 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('그룹 알림 발송 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 교회 전체 알림 발송
  Future<ApiResponse<bool>> sendChurchNotification({
    required int churchId,
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      developer.log('교회 전체 알림 발송 시작: churchId=$churchId', name: 'NOTIFICATION_API');
      
      final request = SendNotificationRequest(
        title: title,
        body: body,
        notificationType: notificationType,
        data: data,
        imageUrl: imageUrl,
        churchId: churchId,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsSendToChurch}'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '교회 전체 알림 발송 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '교회 알림 발송 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('교회 전체 알림 발송 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('교회 알림 발송 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 발송 이력 조회
  Future<ApiResponse<List<NotificationHistory>>> getNotificationHistory() async {
    try {
      developer.log('발송 이력 조회 시작', name: 'NOTIFICATION_API');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsHistory}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '발송 이력 조회 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final history = data
            .map((item) => NotificationHistory.fromJson(item))
            .toList();
        
        return ApiResponse.success(history);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '발송 이력 조회 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('발송 이력 조회 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('발송 이력 조회 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 내 알림 목록 조회
  Future<ApiResponse<List<PushNotificationModel>>> getMyNotifications() async {
    try {
      developer.log('내 알림 목록 조회 시작', name: 'NOTIFICATION_API');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsMyNotifications}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '내 알림 목록 조회 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final notifications = data
            .map((item) => PushNotificationModel.fromJson(item))
            .toList();
        
        return ApiResponse.success(notifications);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '내 알림 목록 조회 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('내 알림 목록 조회 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('내 알림 목록 조회 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 알림 읽음 처리
  Future<ApiResponse<bool>> markAsRead(int notificationId) async {
    try {
      developer.log('알림 읽음 처리 시작: $notificationId', name: 'NOTIFICATION_API');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsMarkAsRead}/$notificationId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '알림 읽음 처리 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '알림 읽음 처리 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('알림 읽음 처리 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('알림 읽음 처리 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 알림 설정 조회
  Future<ApiResponse<NotificationPreferences>> getNotificationPreferences() async {
    try {
      developer.log('알림 설정 조회 시작', name: 'NOTIFICATION_API');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsPreferences}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '알림 설정 조회 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(NotificationPreferences.fromJson(data));
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '알림 설정 조회 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('알림 설정 조회 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('알림 설정 조회 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 알림 설정 변경
  Future<ApiResponse<bool>> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      developer.log('알림 설정 변경 시작', name: 'NOTIFICATION_API');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notificationsPreferences}'),
        headers: await _getHeaders(),
        body: jsonEncode(preferences.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log(
        '알림 설정 변경 응답: ${response.statusCode}',
        name: 'NOTIFICATION_API',
      );
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          '알림 설정 변경 실패: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      developer.log('알림 설정 변경 실패: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('알림 설정 변경 중 오류가 발생했습니다: $e');
    }
  }
}
