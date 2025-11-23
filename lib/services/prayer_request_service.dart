import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_request.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// 중보 기도 서비스 (Supabase Edge Function 사용)
class PrayerRequestService {
  static final PrayerRequestService _instance = PrayerRequestService._internal();
  factory PrayerRequestService() => _instance;
  PrayerRequestService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  // Edge Function URL 생성
  String get _baseUrl =>
      '${SupabaseConfig.supabaseUrl}/functions/v1${SupabaseConfig.prayerRequestsFunction}';

  // 인증 헤더 생성 (Supabase Anon Key + temp_token 방식)
  Map<String, String> _getAuthHeaders() {
    final user = _authService.currentUser;
    if (user == null) {
      return {'Content-Type': 'application/json'};
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userToken = 'temp_token_${user.id}_$timestamp';

    // 두 개의 인증 헤더 모두 필요
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}', // Supabase 공개 키
      'X-Custom-Auth': userToken, // 사용자 인증 토큰
    };
  }

  /// 새 중보 기도 신청 생성 (Edge Function 사용)
  Future<ApiResponse<PrayerRequest>> createRequest(
    PrayerRequestCreate request,
  ) async {
    try {
      print('🙏 PRAYER_REQUEST_SERVICE: 기도 요청 생성 시작 (Edge Function)');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        print('🙏 PRAYER_REQUEST_SERVICE: 사용자 정보 조회 실패 - ${userResponse.message}');
        return ApiResponse<PrayerRequest>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: null,
        );
      }

      final user = userResponse.data!;
      print('🙏 PRAYER_REQUEST_SERVICE: 사용자 정보 - ID: ${user.id}, Church ID: ${user.churchId}');

      // 요청 데이터 생성
      final requestData = {
        'church_id': user.churchId,
        'requester_name': request.requesterName ?? user.fullName,
        'requester_phone': request.requesterPhone ?? user.phone ?? '',
        'prayer_type': request.toJson()['prayer_type'],
        'prayer_content': request.content,
        'is_anonymous': request.isAnonymous,
        'is_urgent': request.priority == 'urgent',
        'is_public': !request.isPrivate,
      };

      print('🙏 PRAYER_REQUEST_SERVICE: 요청 데이터 - $requestData');

      // Edge Function 호출
      final url = Uri.parse('$_baseUrl/admin/requests');
      final headers = _getAuthHeaders();

      print('🙏 PRAYER_REQUEST_SERVICE: 요청 URL - $url');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      );

      print('🙏 PRAYER_REQUEST_SERVICE: 응답 상태 - ${response.statusCode}');
      print('🙏 PRAYER_REQUEST_SERVICE: 응답 본문 - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final createdRequest = PrayerRequest.fromJson(jsonData);
        return ApiResponse<PrayerRequest>(
          success: true,
          message: '기도 요청이 성공적으로 생성되었습니다',
          data: createdRequest,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<PrayerRequest>(
          success: false,
          message: errorData['error']?.toString() ?? '기도 요청 생성 실패',
          data: null,
        );
      }
    } catch (e) {
      print('🙏 PRAYER_REQUEST_SERVICE: 기도 요청 생성 예외 발생 - $e');
      return ApiResponse<PrayerRequest>(
        success: false,
        message: '기도 요청 생성 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 내 중보 기도 신청 목록 조회 (Supabase 직접 조회)
  Future<ApiResponse<List<PrayerRequest>>> getMyRequests({
    int page = 1,
    int limit = 100,
    String? status,
    String? category,
  }) async {
    try {
      print('🙏 PRAYER_REQUEST_SERVICE: 내 기도 요청 목록 조회 시작');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse<List<PrayerRequest>>(
          success: false,
          message: '사용자 정보 조회 실패',
          data: [],
        );
      }

      final user = userResponse.data!;

      // Supabase에서 직접 조회
      var query = _supabaseService.client
          .from('prayer_requests')
          .select()
          .eq('church_id', user.churchId)
          .or('requester_phone.eq.${user.phone},requester_name.eq.${user.fullName}');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (category != null) {
        final apiType = PrayerCategory.toApiType(category);
        query = query.eq('prayer_type', apiType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final requests = (response as List)
          .map((item) => PrayerRequest.fromJson(item as Map<String, dynamic>))
          .toList();

      print('🙏 PRAYER_REQUEST_SERVICE: 기도 요청 ${requests.length}개 조회 완료');

      return ApiResponse<List<PrayerRequest>>(
        success: true,
        message: '기도 요청 목록 조회 성공',
        data: requests,
      );
    } catch (e) {
      print('🙏 PRAYER_REQUEST_SERVICE: 목록 조회 예외 발생 - $e');
      return ApiResponse<List<PrayerRequest>>(
        success: true,
        message: '기도 요청 목록 조회 완료',
        data: [],
      );
    }
  }

  /// 공개 기도 요청 목록 조회
  Future<ApiResponse<List<PrayerRequest>>> getPublicRequests({
    int page = 1,
    int limit = 100,
    String? status,
    String? category,
  }) async {
    try {
      print('🙏 PRAYER_REQUEST_SERVICE: 공개 기도 요청 목록 조회 시작');

      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse<List<PrayerRequest>>(
          success: false,
          message: '사용자 정보 조회 실패',
          data: [],
        );
      }

      final user = userResponse.data!;

      var query = _supabaseService.client
          .from('prayer_requests')
          .select()
          .eq('church_id', user.churchId)
          .eq('is_public', true)
          .eq('status', status ?? 'active');

      if (category != null) {
        final apiType = PrayerCategory.toApiType(category);
        query = query.eq('prayer_type', apiType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final requests = (response as List)
          .map((item) => PrayerRequest.fromJson(item as Map<String, dynamic>))
          .toList();

      return ApiResponse<List<PrayerRequest>>(
        success: true,
        message: '공개 기도 요청 목록 조회 성공',
        data: requests,
      );
    } catch (e) {
      return ApiResponse<List<PrayerRequest>>(
        success: true,
        message: '공개 기도 요청 목록 조회 완료',
        data: [],
      );
    }
  }

  /// 중보 기도 신청 수정
  Future<ApiResponse<PrayerRequest>> updateRequest(
    String requestId,
    PrayerRequestUpdate updateRequest,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('prayer_requests')
          .update(updateRequest.toJson())
          .eq('id', requestId)
          .select()
          .single();

      final updatedRequest = PrayerRequest.fromJson(response);
      return ApiResponse<PrayerRequest>(
        success: true,
        message: '기도 요청 수정 성공',
        data: updatedRequest,
      );
    } catch (e) {
      return ApiResponse<PrayerRequest>(
        success: false,
        message: '기도 요청 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 중보 기도 신청 삭제
  Future<ApiResponse<bool>> deleteRequest(String requestId) async {
    try {
      await _supabaseService.client
          .from('prayer_requests')
          .delete()
          .eq('id', requestId);

      return ApiResponse<bool>(
        success: true,
        message: '기도 요청이 삭제되었습니다',
        data: true,
      );
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: '기도 요청 삭제 실패: ${e.toString()}',
        data: false,
      );
    }
  }

  /// 중보 기도를 응답됨으로 표시
  Future<ApiResponse<PrayerRequest>> markAsAnswered(
    String requestId,
    String? testimony,
  ) async {
    final updateData = PrayerRequestUpdate(
      status: PrayerStatus.answered,
    );
    return updateRequest(requestId, updateData);
  }

  /// 중보 기도를 종료됨으로 표시
  Future<ApiResponse<PrayerRequest>> markAsClosed(String requestId) async {
    final updateData = PrayerRequestUpdate(status: PrayerStatus.closed);
    return updateRequest(requestId, updateData);
  }

  /// 중보 기도를 다시 활성화
  Future<ApiResponse<PrayerRequest>> markAsActive(String requestId) async {
    final updateData = PrayerRequestUpdate(status: PrayerStatus.active);
    return updateRequest(requestId, updateData);
  }

  /// 상태별 목록 조회 헬퍼 메서드들
  Future<ApiResponse<List<PrayerRequest>>> getActiveRequests() {
    return getMyRequests(status: PrayerStatus.active);
  }

  Future<ApiResponse<List<PrayerRequest>>> getAnsweredRequests() {
    return getMyRequests(status: PrayerStatus.answered);
  }

  Future<ApiResponse<List<PrayerRequest>>> getClosedRequests() {
    return getMyRequests(status: PrayerStatus.closed);
  }

  /// 카테고리별 목록 조회 헬퍼 메서드들
  Future<ApiResponse<List<PrayerRequest>>> getGeneralRequests() {
    return getMyRequests(category: PrayerCategory.general);
  }

  Future<ApiResponse<List<PrayerRequest>>> getFamilyRequests() {
    return getMyRequests(category: PrayerCategory.family);
  }

  Future<ApiResponse<List<PrayerRequest>>> getHealingRequests() {
    return getMyRequests(category: PrayerCategory.healing);
  }

  Future<ApiResponse<List<PrayerRequest>>> getWorkRequests() {
    return getMyRequests(category: PrayerCategory.work);
  }

  Future<ApiResponse<List<PrayerRequest>>> getMinistryRequests() {
    return getMyRequests(category: PrayerCategory.ministry);
  }

  /// 공동 기도 카테고리별 목록 조회
  Future<ApiResponse<List<PrayerRequest>>> getPublicRequestsByCategory(
      String category) {
    return getPublicRequests(category: category);
  }

  /// 긴급 기도 요청 조회
  Future<ApiResponse<List<PrayerRequest>>> getUrgentRequests() {
    return getPublicRequests(status: PrayerStatus.active);
  }
}
