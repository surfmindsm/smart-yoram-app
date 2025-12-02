import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/push_notification.dart';
import '../models/api_response.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// 푸시 알림 백엔드 API 서비스
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  NotificationService._internal();
  
  /// API 헤더 생성 (Bearer 토큰 포함)
  Future<Map<String, String>> _getHeaders() async {
    print('🔑 NOTIFICATION_API: 토큰 조회 시작...');
    final token = await AuthService().getStoredToken();

    if (token != null) {
      print('✅ NOTIFICATION_API: 토큰 존재 (길이: ${token.length})');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      print('❌ NOTIFICATION_API: 토큰 없음!');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
  }
  
  /// 디바이스 정보 가져오기
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String platform = Platform.isAndroid ? 'android' : 'ios';
      String deviceModel = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = '${iosInfo.name} ${iosInfo.model}';
      }
      
      return {
        'platform': platform,
        'device_model': deviceModel,
        'app_version': packageInfo.version,
      };
    } catch (e) {
      developer.log('디바이스 정보 가져오기 실패: $e', name: 'NOTIFICATION_API');
      return {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'device_model': 'Unknown',
        'app_version': '1.0.0',
      };
    }
  }
  
  /// 1. 기기 등록 (POST /devices)
  Future<ApiResponse<DeviceRegistrationResponse>> registerDevice(String fcmToken) async {
    try {
      developer.log('기기 등록 시작', name: 'NOTIFICATION_API');
      
      final deviceInfo = await _getDeviceInfo();
      final request = DeviceRegistrationRequest(
        deviceToken: fcmToken,
        platform: deviceInfo['platform']!,
        deviceModel: deviceInfo['device_model'],
        appVersion: deviceInfo['app_version'],
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/devices'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('기기 등록 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final deviceResponse = DeviceRegistrationResponse.fromJson(responseData);
        return ApiResponse.success(deviceResponse);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('기기 등록 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('기기 등록 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('기기 등록 중 오류가 발생했습니다');
    }
  }
  
  /// 기기 등록 해제 (DELETE /devices)
  Future<ApiResponse<bool>> unregisterDevice() async {
    try {
      developer.log('기기 등록 해제 시작', name: 'NOTIFICATION_API');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notifications/devices'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('기기 등록 해제 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('기기 등록 해제 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('기기 등록 해제 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('기기 등록 해제 중 오류가 발생했습니다');
    }
  }
  
  /// 2. 개별 알림 발송 (POST /send)
  Future<ApiResponse<SendNotificationResponse>> sendNotificationToUser({
    required int userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      developer.log('개별 알림 발송 시작: 사용자 $userId', name: 'NOTIFICATION_API');
      
      final request = SendNotificationRequest(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/send'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('개별 알림 발송 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final sendResponse = SendNotificationResponse.fromJson(responseData);
        return ApiResponse.success(sendResponse);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('알림 발송 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('개별 알림 발송 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('알림 발송 중 오류가 발생했습니다');
    }
  }
  
  /// 3. 다중 사용자 알림 발송 (POST /send-batch)
  Future<ApiResponse<SendNotificationResponse>> sendBatchNotification({
    required List<int> userIds,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      developer.log('다중 사용자 알림 발송 시작: ${userIds.length}명', name: 'NOTIFICATION_API');
      
      final request = SendBatchNotificationRequest(
        userIds: userIds,
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/send-batch'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('다중 사용자 알림 발송 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final sendResponse = SendNotificationResponse.fromJson(responseData);
        return ApiResponse.success(sendResponse);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('다중 알림 발송 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('다중 사용자 알림 발송 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('다중 알림 발송 중 오류가 발생했습니다');
    }
  }
  
  /// 4. 교회 전체 알림 발송 (POST /send-to-church)
  Future<ApiResponse<SendNotificationResponse>> sendChurchNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      developer.log('교회 전체 알림 발송 시작', name: 'NOTIFICATION_API');
      
      final request = SendChurchNotificationRequest(
        title: title,
        body: body,
        type: type,
        data: data,
        imageUrl: imageUrl,
      );
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/send-to-church'),
        headers: await _getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('교회 전체 알림 발송 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final sendResponse = SendNotificationResponse.fromJson(responseData);
        return ApiResponse.success(sendResponse);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('교회 전체 알림 발송 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('교회 전체 알림 발송 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('교회 전체 알림 발송 중 오류가 발생했습니다');
    }
  }
  
  /// 5. 발송 이력 조회 (GET /history)
  Future<ApiResponse<List<NotificationHistory>>> getNotificationHistory({
    int limit = 50,
    int offset = 0,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      developer.log('알림 발송 이력 조회 시작', name: 'NOTIFICATION_API');
      
      final queryParameters = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (type != null) 'type': type,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/history')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('알림 발송 이력 조회 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> historyList = responseData['data'] ?? [];
        final notifications = historyList
            .map((item) => NotificationHistory.fromJson(item))
            .toList();
        return ApiResponse.success(notifications);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('이력 조회 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('알림 발송 이력 조회 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('이력 조회 중 오류가 발생했습니다');
    }
  }
  
  /// 6. 내가 받은 알림 조회 (Supabase)
  Future<ApiResponse<List<MyNotification>>> getMyNotifications({
    int limit = 50,
    int offset = 0,
    bool? isRead,
  }) async {
    try {
      print('🔔 NOTIFICATION_SUPABASE: 내 알림 조회 시작 (Supabase)');

      // 현재 사용자 정보 가져오기
      final currentUser = await AuthService().getCurrentUser();
      if (!currentUser.success || currentUser.data == null) {
        print('❌ NOTIFICATION_SUPABASE: 로그인 필요');
        return ApiResponse.error('로그인이 필요합니다');
      }

      final userId = currentUser.data!.id;
      print('🔔 NOTIFICATION_SUPABASE: User ID = $userId, limit = $limit, offset = $offset');

      // Supabase 쿼리 구성 (필터링 → 정렬 → limit 순서)
      print('🔔 NOTIFICATION_SUPABASE: Supabase 쿼리 실행...');
      final startTime = DateTime.now();

      // 쿼리 빌더 시작
      var query = _supabaseService.client
          .from('notifications')
          .select('*')
          .eq('user_id', userId);

      // isRead 필터 추가 (order 전에 필터링 완료)
      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      // 정렬 및 limit 적용하여 최종 실행
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final duration = DateTime.now().difference(startTime);
      print('🔔 NOTIFICATION_SUPABASE: 응답 받음 (${duration.inMilliseconds}ms)');

      if (response == null) {
        print('🔔 NOTIFICATION_SUPABASE: 알림 없음');
        return ApiResponse.success([]);
      }

      print('🔔 NOTIFICATION_SUPABASE: 응답 타입 = ${response.runtimeType}');

      // 응답을 List로 변환
      final List<dynamic> notificationList = response is List
          ? response
          : [response];

      print('✅ NOTIFICATION_SUPABASE: 알림 ${notificationList.length}개 조회 완료');

      // MyNotification 객체로 변환
      final notifications = notificationList.map((item) {
        final createdAt = DateTime.parse(item['created_at'] as String);
        return MyNotification(
          id: item['id'] as int,
          notificationId: item['id'] as int, // Using same as id since notifications table doesn't have separate notificationId
          userId: item['user_id'] as int,
          title: item['title'] as String,
          body: item['body'] as String,
          type: item['type'] as String? ?? 'notice',
          isRead: item['is_read'] as bool? ?? false,
          receivedAt: createdAt, // Use created_at as receivedAt
          createdAt: createdAt,
          data: item['data'] as Map<String, dynamic>?,
        );
      }).toList();

      return ApiResponse<List<MyNotification>>.success(notifications);
    } catch (e, stackTrace) {
      print('❌ NOTIFICATION_SUPABASE: 예외 발생 - $e');
      print('❌ NOTIFICATION_SUPABASE: 스택 트레이스 - $stackTrace');
      developer.log('내 알림 조회 오류: $e', name: 'NOTIFICATION_ERROR', stackTrace: stackTrace);
      return ApiResponse.error('내 알림 조회 중 오류가 발생했습니다: $e');
    }
  }
  
  /// 7. 알림 읽음 처리 (Supabase)
  Future<ApiResponse<bool>> markNotificationAsRead(int notificationId) async {
    try {
      print('🔔 NOTIFICATION_SUPABASE: 알림 읽음 처리 시작 - ID: $notificationId');

      // Supabase에서 is_read 업데이트
      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

      print('✅ NOTIFICATION_SUPABASE: 알림 읽음 처리 완료');
      return ApiResponse.success(true);
    } catch (e) {
      print('❌ NOTIFICATION_SUPABASE: 알림 읽음 처리 실패 - $e');
      developer.log('알림 읽음 처리 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('읽음 처리 중 오류가 발생했습니다');
    }
  }
  
  /// 8. 알림 설정 조회 (GET /preferences)
  Future<ApiResponse<NotificationPreferences>> getNotificationPreferences() async {
    try {
      developer.log('알림 설정 조회 시작', name: 'NOTIFICATION_API');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/preferences'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('알림 설정 조회 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final preferences = NotificationPreferences.fromJson(responseData);
        return ApiResponse.success(preferences);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('설정 조회 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('알림 설정 조회 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('설정 조회 중 오류가 발생했습니다');
    }
  }
  
  /// 9. 알림 설정 변경 (PUT /preferences)
  Future<ApiResponse<bool>> updateNotificationPreferences(NotificationPreferences preferences) async {
    try {
      developer.log('알림 설정 변경 시작', name: 'NOTIFICATION_API');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/notifications/preferences'),
        headers: await _getHeaders(),
        body: jsonEncode(preferences.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('알림 설정 변경 응답: ${response.statusCode}', name: 'NOTIFICATION_API');
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error('설정 변경 실패: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('알림 설정 변경 오류: $e', name: 'NOTIFICATION_ERROR');
      return ApiResponse.error('설정 변경 중 오류가 발생했습니다');
    }
  }
}
