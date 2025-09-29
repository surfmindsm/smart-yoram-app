import '../models/pastoral_care_request.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// 심방 신청 서비스 (Supabase Edge Function 사용)
class PastoralCareService {
  static final PastoralCareService _instance = PastoralCareService._internal();
  factory PastoralCareService() => _instance;
  PastoralCareService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  /// 새 심방 신청 생성 (Supabase Edge Function)
  Future<ApiResponse<PastoralCareRequest>> createRequest(
    PastoralCareRequestCreate request,
  ) async {
    try {
      print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 생성 시작 (Supabase)');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        print('🙏 PASTORAL_CARE_SERVICE: 사용자 정보 조회 실패 - ${userResponse.message}');
        return ApiResponse<PastoralCareRequest>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: null,
        );
      }

      final user = userResponse.data!;
      print('🙏 PASTORAL_CARE_SERVICE: 사용자 정보 - ID: ${user.id}, Church ID: ${user.churchId}');

      // Edge Function 호출
      final response = await _supabaseService.invokeFunction<PastoralCareRequest>(
        SupabaseConfig.pastoralCareFunction,
        body: {
          'action': 'create_request',
          'church_id': user.churchId,
          'request_data': request.toJson(),
        },
        fromJson: (json) => PastoralCareRequest.fromJson(json),
      );

      if (response.success && response.data != null) {
        print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 생성 완료');
        return ApiResponse<PastoralCareRequest>(
          success: true,
          message: '심방 신청이 성공적으로 생성되었습니다',
          data: response.data!,
        );
      } else {
        print('🙏 PASTORAL_CARE_SERVICE: Edge Function 응답 실패 - ${response.message}');
        return ApiResponse<PastoralCareRequest>(
          success: false,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 생성 예외 발생 - $e');
      return ApiResponse<PastoralCareRequest>(
        success: false,
        message: '심방 신청 생성 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 내 심방 신청 목록 조회 (Supabase Edge Function)
  Future<ApiResponse<List<PastoralCareRequest>>> getMyRequests({
    int page = 1,
    int limit = 100,
    String? status,
  }) async {
    try {
      print('🙏 PASTORAL_CARE_SERVICE: 내 심방 신청 목록 조회 시작 (Supabase)');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        print('🙏 PASTORAL_CARE_SERVICE: 사용자 정보 조회 실패 - ${userResponse.message}');
        return ApiResponse<List<PastoralCareRequest>>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: [],
        );
      }

      final user = userResponse.data!;
      print('🙏 PASTORAL_CARE_SERVICE: 사용자 정보 - ID: ${user.id}, Church ID: ${user.churchId}');

      // Edge Function 호출
      final response = await _supabaseService.invokeFunction<List<PastoralCareRequest>>(
        SupabaseConfig.pastoralCareFunction,
        body: {
          'action': 'get_my_requests',
          'church_id': user.churchId,
          'user_id': user.id,
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
        fromJsonList: (dataList) => dataList
            .map((item) => PastoralCareRequest.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      if (response.success && response.data != null) {
        print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 ${response.data!.length}개 조회 완료');
        return ApiResponse<List<PastoralCareRequest>>(
          success: true,
          message: '심방 신청 목록 조회 성공',
          data: response.data!,
        );
      } else {
        print('🙏 PASTORAL_CARE_SERVICE: Edge Function 응답 실패 - ${response.message}');
        // API 실패 시 빈 목록 반환
        return ApiResponse<List<PastoralCareRequest>>(
          success: true,
          message: '심방 신청 목록을 찾을 수 없습니다',
          data: [],
        );
      }
    } catch (e) {
      print('🙏 PASTORAL_CARE_SERVICE: 목록 조회 예외 발생 - $e');
      return ApiResponse<List<PastoralCareRequest>>(
        success: true,
        message: '심방 신청 목록을 찾을 수 없습니다',
        data: [],
      );
    }
  }

  /// 심방 신청 수정 (pending 상태만 가능) (Supabase Edge Function)
  Future<ApiResponse<PastoralCareRequest>> updateRequest(
    int requestId,
    PastoralCareRequestUpdate updateRequest,
  ) async {
    try {
      final response = await _supabaseService.invokeFunction<PastoralCareRequest>(
        SupabaseConfig.pastoralCareFunction,
        body: {
          'action': 'update_request',
          'request_id': requestId,
          'request_data': updateRequest.toJson(),
        },
        fromJson: (json) => PastoralCareRequest.fromJson(json),
      );

      if (response.success && response.data != null) {
        return ApiResponse<PastoralCareRequest>(
          success: true,
          message: '심방 신청 수정 성공',
          data: response.data!,
        );
      } else {
        return ApiResponse<PastoralCareRequest>(
          success: false,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<PastoralCareRequest>(
        success: false,
        message: '심방 신청 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 심방 신청 취소 (pending 상태만 가능) (Supabase Edge Function)
  Future<ApiResponse<bool>> cancelRequest(int requestId) async {
    try {
      final response = await _supabaseService.invokeFunction<Map<String, dynamic>>(
        SupabaseConfig.pastoralCareFunction,
        body: {
          'action': 'cancel_request',
          'request_id': requestId,
        },
        fromJson: (json) => json,
      );

      return ApiResponse<bool>(
        success: response.success,
        message: response.message,
        data: response.success,
      );
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: '심방 신청 취소 실패: ${e.toString()}',
        data: false,
      );
    }
  }

  /// 심방 신청 상태별 목록 조회 헬퍼
  Future<ApiResponse<List<PastoralCareRequest>>> getPendingRequests() {
    return getMyRequests(status: 'pending');
  }

  Future<ApiResponse<List<PastoralCareRequest>>> getApprovedRequests() {
    return getMyRequests(status: 'approved');
  }

  Future<ApiResponse<List<PastoralCareRequest>>> getInProgressRequests() {
    return getMyRequests(status: 'in_progress');
  }

  Future<ApiResponse<List<PastoralCareRequest>>> getCompletedRequests() {
    return getMyRequests(status: 'completed');
  }

  Future<ApiResponse<List<PastoralCareRequest>>> getCancelledRequests() {
    return getMyRequests(status: 'cancelled');
  }
}
