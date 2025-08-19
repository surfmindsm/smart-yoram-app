import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_request.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PrayerRequestService {
  static const String baseUrl = '${ApiConfig.baseUrl}/prayer-requests';
  static final ApiService _apiService = ApiService();

  /// 새 중보 기도 신청 생성
  static Future<ApiResponse<PrayerRequest>> createRequest(
    PrayerRequestCreate request,
  ) async {
    try {
      final token = _apiService.token;
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        final prayerRequest = PrayerRequest.fromJson(data);
        return ApiResponse.success(prayerRequest);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '중보 기도 신청 생성에 실패했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 내 중보 기도 신청 목록 조회
  static Future<ApiResponse<List<PrayerRequest>>> getMyRequests({
    int skip = 0,
    int limit = 100,
    String? status,
    String? category,
  }) async {
    try {
      final token = _apiService.token;
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse('$baseUrl/my').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as List;
        final requests = data
            .map((item) => PrayerRequest.fromJson(item))
            .toList();
        return ApiResponse.success(requests);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '중보 기도 목록을 불러오지 못했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 공동 중보 기도 목록 조회 (공개된 것만)
  static Future<ApiResponse<List<PrayerRequest>>> getPublicRequests({
    int skip = 0,
    int limit = 100,
    String? status,
    String? category,
  }) async {
    try {
      final token = _apiService.token;
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
        'is_private': 'false', // 공개된 것만
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as List;
        final requests = data
            .map((item) => PrayerRequest.fromJson(item))
            .toList();
        return ApiResponse.success(requests);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '공동 기도 목록을 불러오지 못했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 중보 기도 신청 수정
  static Future<ApiResponse<PrayerRequest>> updateRequest(
    int requestId,
    PrayerRequestUpdate updateRequest,
  ) async {
    try {
      final token = _apiService.token;
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateRequest.toJson()),
      );

      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final prayerRequest = PrayerRequest.fromJson(data);
        return ApiResponse.success(prayerRequest);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '중보 기도 수정에 실패했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 중보 기도 신청 삭제
  static Future<ApiResponse<bool>> deleteRequest(int requestId) async {
    try {
      final token = _apiService.token;
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(true);
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '중보 기도 삭제에 실패했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 중보 기도를 응답됨으로 표시
  static Future<ApiResponse<PrayerRequest>> markAsAnswered(int requestId) async {
    final updateData = PrayerRequestUpdate(status: PrayerStatus.answered);
    return updateRequest(requestId, updateData);
  }

  /// 중보 기도를 종료됨으로 표시
  static Future<ApiResponse<PrayerRequest>> markAsClosed(int requestId) async {
    final updateData = PrayerRequestUpdate(status: PrayerStatus.closed);
    return updateRequest(requestId, updateData);
  }

  /// 중보 기도를 일시정지로 표시
  static Future<ApiResponse<PrayerRequest>> markAsPaused(int requestId) async {
    final updateData = PrayerRequestUpdate(status: PrayerStatus.paused);
    return updateRequest(requestId, updateData);
  }

  /// 중보 기도를 다시 활성화
  static Future<ApiResponse<PrayerRequest>> markAsActive(int requestId) async {
    final updateData = PrayerRequestUpdate(status: PrayerStatus.active);
    return updateRequest(requestId, updateData);
  }

  /// 상태별 목록 조회 헬퍼 메서드들
  static Future<ApiResponse<List<PrayerRequest>>> getActiveRequests() {
    return getMyRequests(status: PrayerStatus.active);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getAnsweredRequests() {
    return getMyRequests(status: PrayerStatus.answered);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getClosedRequests() {
    return getMyRequests(status: PrayerStatus.closed);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getPausedRequests() {
    return getMyRequests(status: PrayerStatus.paused);
  }

  /// 카테고리별 목록 조회 헬퍼 메서드들
  static Future<ApiResponse<List<PrayerRequest>>> getPersonalRequests() {
    return getMyRequests(category: PrayerCategory.personal);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getFamilyRequests() {
    return getMyRequests(category: PrayerCategory.family);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getChurchRequests() {
    return getMyRequests(category: PrayerCategory.church);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getMissionRequests() {
    return getMyRequests(category: PrayerCategory.mission);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getHealingRequests() {
    return getMyRequests(category: PrayerCategory.healing);
  }

  static Future<ApiResponse<List<PrayerRequest>>> getGuidanceRequests() {
    return getMyRequests(category: PrayerCategory.guidance);
  }

  /// 공동 기도 카테고리별 목록 조회
  static Future<ApiResponse<List<PrayerRequest>>> getPublicRequestsByCategory(String category) {
    return getPublicRequests(category: category);
  }

  /// 긴급 기도 요청 조회
  static Future<ApiResponse<List<PrayerRequest>>> getUrgentRequests() {
    return getPublicRequests(status: PrayerStatus.active);
  }
}
