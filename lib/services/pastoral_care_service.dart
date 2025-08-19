import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pastoral_care_request.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PastoralCareService {
  static const String baseUrl = '${ApiConfig.baseUrl}/pastoral-care/requests';
  static final ApiService _apiService = ApiService();

  /// 새 심방 신청 생성
  static Future<ApiResponse<PastoralCareRequest>> createRequest(
    PastoralCareRequestCreate request,
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

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final pastoralCareRequest = PastoralCareRequest.fromJson(data);
        return ApiResponse.success(pastoralCareRequest);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '심방 신청 생성에 실패했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 내 심방 신청 목록 조회
  static Future<ApiResponse<List<PastoralCareRequest>>> getMyRequests({
    int skip = 0,
    int limit = 100,
    String? status,
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
            .map((item) => PastoralCareRequest.fromJson(item))
            .toList();
        return ApiResponse.success(requests);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '심방 신청 목록을 불러오지 못했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 심방 신청 수정 (pending 상태만 가능)
  static Future<ApiResponse<PastoralCareRequest>> updateRequest(
    int requestId,
    PastoralCareRequestUpdate updateRequest,
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
        final pastoralCareRequest = PastoralCareRequest.fromJson(data);
        return ApiResponse.success(pastoralCareRequest);
      } else {
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '심방 신청 수정에 실패했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 심방 신청 취소 (pending 상태만 가능)
  static Future<ApiResponse<bool>> cancelRequest(int requestId) async {
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

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        final error = jsonDecode(responseBody);
        return ApiResponse.error(
          error['detail']?.toString() ?? '심방 신청 취소에 실패했습니다.',
        );
      }
    } catch (e) {
      return ApiResponse.error('네트워크 오류가 발생했습니다: $e');
    }
  }

  /// 심방 신청 상태별 목록 조회 헬퍼
  static Future<ApiResponse<List<PastoralCareRequest>>> getPendingRequests() {
    return getMyRequests(status: 'pending');
  }

  static Future<ApiResponse<List<PastoralCareRequest>>> getApprovedRequests() {
    return getMyRequests(status: 'approved');
  }

  static Future<ApiResponse<List<PastoralCareRequest>>> getInProgressRequests() {
    return getMyRequests(status: 'in_progress');
  }

  static Future<ApiResponse<List<PastoralCareRequest>>> getCompletedRequests() {
    return getMyRequests(status: 'completed');
  }

  static Future<ApiResponse<List<PastoralCareRequest>>> getCancelledRequests() {
    return getMyRequests(status: 'cancelled');
  }
}
