import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // Edge Function URL 생성
  String get _baseUrl =>
      '${SupabaseConfig.supabaseUrl}/functions/v1${SupabaseConfig.pastoralCareFunction}';

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

  /// 새 심방 신청 생성 (Edge Function 사용)
  Future<ApiResponse<PastoralCareRequest>> createRequest(
    PastoralCareRequestCreate request,
  ) async {
    try {
      print('🙏 PASTORAL_CARE_SERVICE: 심방 신청 생성 시작 (Edge Function)');

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

      final member = memberResponse.data?.id;
      final memberName = memberResponse.data?.name ?? user.fullName;
      final memberPhone = memberResponse.data?.phone ?? '';

      // 요청 데이터 생성
      final requestData = {
        'church_id': user.churchId,
        if (member != null) 'member_id': member,
        'requester_name': request.requesterName ?? memberName,
        'requester_phone': request.requesterPhone ?? memberPhone,
        'request_type': request.requestType,
        'request_content': request.description,
        'priority': request.priority,
        'is_urgent': request.isUrgent,
        if (request.preferredDate != null) 'preferred_date': request.preferredDate,
        if (request.preferredTimeStart != null)
          'preferred_time_start': request.preferredTimeStart,
        if (request.preferredTimeEnd != null)
          'preferred_time_end': request.preferredTimeEnd,
        if (request.contactInfo != null) 'contact_info': request.contactInfo,
        if (request.address != null) 'address': request.address,
        if (request.latitude != null) 'latitude': request.latitude,
        if (request.longitude != null) 'longitude': request.longitude,
      };

      print('🙏 PASTORAL_CARE_SERVICE: 요청 데이터 - $requestData');

      // Edge Function 호출
      final url = Uri.parse('$_baseUrl/admin/requests');
      final headers = _getAuthHeaders();

      print('🙏 PASTORAL_CARE_SERVICE: 요청 URL - $url');
      print('🙏 PASTORAL_CARE_SERVICE: 요청 헤더 - $headers');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      );

      print('🙏 PASTORAL_CARE_SERVICE: 응답 상태 - ${response.statusCode}');
      print('🙏 PASTORAL_CARE_SERVICE: 응답 본문 - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final createdRequest = PastoralCareRequest.fromJson(jsonData);
        return ApiResponse<PastoralCareRequest>(
          success: true,
          message: '심방 신청이 성공적으로 생성되었습니다',
          data: createdRequest,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<PastoralCareRequest>(
          success: false,
          message: errorData['error']?.toString() ?? '심방 신청 생성 실패',
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

  /// 내 심방 신청 목록 조회 (Supabase 직접 조회)
  Future<ApiResponse<List<PastoralCareRequest>>> getMyRequests({
    int page = 1,
    int limit = 100,
    String? status,
  }) async {
    try {
      print('🙏 PASTORAL_CARE_SERVICE: 내 심방 신청 목록 조회 시작 (Supabase 직접)');

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

      // 현재 사용자의 이메일로 신청 조회
      // requester_phone 또는 member 정보의 email이 일치하는 것 조회
      var query = _supabaseService.client
          .from('pastoral_care_requests')
          .select()
          .eq('church_id', user.churchId)
          .or('requester_phone.eq.${user.phone},requester_name.eq.${user.fullName}');

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
        message: '심방 신청 목록 조회 완료',
        data: [],
      );
    }
  }

  /// 심방 신청 수정 (pending 상태만 가능)
  Future<ApiResponse<PastoralCareRequest>> updateRequest(
    String requestId,
    PastoralCareRequestUpdate updateRequest,
  ) async {
    try {
      // Edge Function 호출 (PUT 또는 PATCH를 body로 전달)
      final url = Uri.parse('$_baseUrl/admin/requests/$requestId');
      final response = await http.put(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(updateRequest.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final updatedRequest = PastoralCareRequest.fromJson(jsonData);
        return ApiResponse<PastoralCareRequest>(
          success: true,
          message: '심방 신청 수정 성공',
          data: updatedRequest,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<PastoralCareRequest>(
          success: false,
          message: errorData['error']?.toString() ?? '심방 신청 수정 실패',
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

  /// 심방 신청 취소 (pending 상태만 가능)
  Future<ApiResponse<bool>> cancelRequest(String requestId) async {
    try {
      // 취소는 상태를 'cancelled'로 변경
      final url = Uri.parse('$_baseUrl/admin/requests/$requestId');
      final response = await http.put(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode({'status': 'cancelled'}),
      );

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          message: '심방 신청이 취소되었습니다',
          data: true,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<bool>(
          success: false,
          message: errorData['error']?.toString() ?? '심방 신청 취소 실패',
          data: false,
        );
      }
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
    required String requestId,
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
    required String requestId,
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
