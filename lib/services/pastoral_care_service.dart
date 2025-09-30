import '../models/pastoral_care_request.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'member_service.dart';

/// 심방 신청 서비스 (Supabase Edge Function 사용)
class PastoralCareService {
  static final PastoralCareService _instance = PastoralCareService._internal();
  factory PastoralCareService() => _instance;
  PastoralCareService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();
  final MemberService _memberService = MemberService();

  /// 새 심방 신청 생성 (Supabase 직접 삽입)
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

      // user_id로 member_id 조회
      var memberResponse = await _memberService.getMemberByUserId(user.id);

      // user_id로 찾지 못하면 이메일로 조회
      if (!memberResponse.success || memberResponse.data == null) {
        print('🙏 PASTORAL_CARE_SERVICE: user_id로 Member 조회 실패, 이메일로 재시도 - ${user.email}');
        final allMembersResponse = await _memberService.getMembers(limit: 1000);
        if (allMembersResponse.success) {
          final memberByEmail = allMembersResponse.data!
              .where((m) => m.email == user.email)
              .firstOrNull;
          if (memberByEmail != null) {
            memberResponse = ApiResponse(
              success: true,
              message: '이메일로 Member 조회 성공',
              data: memberByEmail,
            );
          }
        }
      }

      if (!memberResponse.success || memberResponse.data == null) {
        print('🙏 PASTORAL_CARE_SERVICE: Member 정보 조회 실패 - ${memberResponse.message}');
        return ApiResponse<PastoralCareRequest>(
          success: false,
          message: 'Member 정보 조회 실패: ${memberResponse.message}',
          data: null,
        );
      }

      final member = memberResponse.data!;
      print('🙏 PASTORAL_CARE_SERVICE: Member 정보 - ID: ${member.id}');

      // pastoral_care_requests 테이블에 직접 삽입
      // 주의: member_id는 users.id를 참조함 (members.id가 아님)
      final requestData = {
        'church_id': user.churchId,
        'member_id': user.id, // users.id 사용
        'requester_name': request.requesterName ?? member.name,
        'requester_phone': request.requesterPhone ?? member.phone ?? '',
        'request_type': request.requestType,
        'request_content': '${request.title}\n\n${request.description}', // title + description 합침
        'preferred_date': request.preferredDate,
        'preferred_time_start': request.preferredTime,
        'priority': request.priority,
        'contact_info': request.contactInfo,
        'is_urgent': request.isUrgent,
        'address': request.address != null && request.detailAddress != null
            ? '${request.address} ${request.detailAddress}'
            : request.address,
        'latitude': request.latitude,
        'longitude': request.longitude,
        'status': 'pending',
      };

      print('🙏 PASTORAL_CARE_SERVICE: 삽입 데이터 - $requestData');

      final response = await _supabaseService.client
          .from('pastoral_care_requests')
          .insert(requestData)
          .select()
          .single();

      print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 생성 완료 - $response');

      final createdRequest = PastoralCareRequest.fromJson(response);
      return ApiResponse<PastoralCareRequest>(
        success: true,
        message: '심방 신청이 성공적으로 생성되었습니다',
        data: createdRequest,
      );
    } catch (e) {
      print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 생성 예외 발생 - $e');
      return ApiResponse<PastoralCareRequest>(
        success: false,
        message: '심방 신청 생성 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 내 심방 신청 목록 조회 (Supabase 직접 조회)
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

      // user_id로 member_id 조회
      var memberResponse = await _memberService.getMemberByUserId(user.id);

      // user_id로 찾지 못하면 이메일로 조회
      if (!memberResponse.success || memberResponse.data == null) {
        print('🙏 PASTORAL_CARE_SERVICE: user_id로 Member 조회 실패, 이메일로 재시도 - ${user.email}');
        final allMembersResponse = await _memberService.getMembers(limit: 1000);
        if (allMembersResponse.success) {
          final memberByEmail = allMembersResponse.data!
              .where((m) => m.email == user.email)
              .firstOrNull;
          if (memberByEmail != null) {
            memberResponse = ApiResponse(
              success: true,
              message: '이메일로 Member 조회 성공',
              data: memberByEmail,
            );
          }
        }
      }

      if (!memberResponse.success || memberResponse.data == null) {
        print('🙏 PASTORAL_CARE_SERVICE: Member 정보 조회 실패 - ${memberResponse.message}');
        return ApiResponse<List<PastoralCareRequest>>(
          success: true,
          message: 'Member 정보를 찾을 수 없습니다',
          data: [],
        );
      }

      final member = memberResponse.data!;

      // pastoral_care_requests 테이블에서 직접 조회
      // 주의: member_id는 users.id를 참조함
      var query = _supabaseService.client
          .from('pastoral_care_requests')
          .select()
          .eq('church_id', user.churchId)
          .eq('member_id', user.id); // users.id 사용

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final requests = (response as List)
          .map((item) => PastoralCareRequest.fromJson(item as Map<String, dynamic>))
          .toList();

      print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 ${requests.length}개 조회 완료');

      return ApiResponse<List<PastoralCareRequest>>(
        success: true,
        message: '심방 신청 목록 조회 성공',
        data: requests,
      );
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

  /// 관리자용: 전체 심방 신청 목록 조회 (모든 교인의 신청)
  Future<ApiResponse<List<PastoralCareRequest>>> getAllRequests({
    int page = 1,
    int limit = 100,
    String? status,
  }) async {
    try {
      print('🙏 PASTORAL_CARE_SERVICE: 전체 심방 신청 목록 조회 시작 (관리자)');

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

      // pastoral_care_requests 테이블에서 교회의 모든 신청 조회
      var query = _supabaseService.client
          .from('pastoral_care_requests')
          .select()
          .eq('church_id', user.churchId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final requests = (response as List)
          .map((item) => PastoralCareRequest.fromJson(item as Map<String, dynamic>))
          .toList();

      print('🙏 PASTORAL_CARE_SERVICE: 전체 심방 신청 ${requests.length}개 조회 완료');

      return ApiResponse<List<PastoralCareRequest>>(
        success: true,
        message: '전체 심방 신청 목록 조회 성공',
        data: requests,
      );
    } catch (e) {
      print('🙏 PASTORAL_CARE_SERVICE: 전체 목록 조회 예외 발생 - $e');
      return ApiResponse<List<PastoralCareRequest>>(
        success: true,
        message: '심방 신청 목록을 찾을 수 없습니다',
        data: [],
      );
    }
  }

  /// 관리자용: 심방 신청 상태 변경
  Future<ApiResponse<PastoralCareRequest>> updateRequestStatus({
    required int requestId,
    required String status,
    String? adminNote,
  }) async {
    try {
      print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 상태 변경 시작 - requestId: $requestId, status: $status');

      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminNote != null) {
        updateData['admin_note'] = adminNote;
      }

      final response = await _supabaseService.client
          .from('pastoral_care_requests')
          .update(updateData)
          .eq('id', requestId)
          .select()
          .single();

      final updatedRequest = PastoralCareRequest.fromJson(response);

      print('✅ PASTORAL_CARE_SERVICE: 심방 신청 상태 변경 성공');

      return ApiResponse<PastoralCareRequest>(
        success: true,
        message: '심방 신청 상태가 변경되었습니다',
        data: updatedRequest,
      );
    } catch (e) {
      print('❌ PASTORAL_CARE_SERVICE: 심방 신청 상태 변경 실패 - $e');
      return ApiResponse<PastoralCareRequest>(
        success: false,
        message: '심방 신청 상태 변경 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 관리자용: 담당자 지정 및 일정 설정
  Future<ApiResponse<PastoralCareRequest>> assignPastor({
    required int requestId,
    required int pastorId,
    String? scheduledDate,
    String? scheduledTime,
  }) async {
    try {
      print('🙏 PASTORAL_CARE_SERVICE: 담당자 지정 시작 - requestId: $requestId, pastorId: $pastorId');

      final updateData = <String, dynamic>{
        'assigned_pastor_id': pastorId,
        'status': 'approved',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (scheduledDate != null) {
        updateData['scheduled_date'] = scheduledDate;
      }

      if (scheduledTime != null) {
        updateData['scheduled_time'] = scheduledTime;
      }

      final response = await _supabaseService.client
          .from('pastoral_care_requests')
          .update(updateData)
          .eq('id', requestId)
          .select()
          .single();

      final updatedRequest = PastoralCareRequest.fromJson(response);

      print('✅ PASTORAL_CARE_SERVICE: 담당자 지정 성공');

      return ApiResponse<PastoralCareRequest>(
        success: true,
        message: '담당자가 지정되었습니다',
        data: updatedRequest,
      );
    } catch (e) {
      print('❌ PASTORAL_CARE_SERVICE: 담당자 지정 실패 - $e');
      return ApiResponse<PastoralCareRequest>(
        success: false,
        message: '담당자 지정 실패: ${e.toString()}',
        data: null,
      );
    }
  }
}
