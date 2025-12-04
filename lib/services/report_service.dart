import 'package:smart_yoram_app/models/api_response.dart';
import 'package:smart_yoram_app/models/report_model.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';

/// 신고 서비스
class ReportService {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  /// 신고 생성
  /// Edge Function을 통해 신고를 생성합니다
  Future<ApiResponse<Report>> createReport({
    required ReportType reportedType,
    required int reportedId,
    String? reportedTable,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📝 REPORT_SERVICE: 신고 생성 시도 - ${reportedType.value}/$reportedId');

      // Edge Function 호출
      final response = await _supabaseService.client.functions.invoke(
        'create-report',
        body: {
          'reported_type': reportedType.value,
          'reported_id': reportedId,
          'reported_table': reportedTable,
          'reason': reason.value,
          'description': description,
        },
      );

      print('📝 REPORT_SERVICE: Edge Function 응답 - ${response.data}');

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? '신고가 접수되었습니다',
            data: Report.fromJson(data['data']),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? '신고 접수에 실패했습니다',
            data: null,
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: '신고 접수에 실패했습니다',
          data: null,
        );
      }
    } catch (e) {
      print('❌ REPORT_SERVICE: 신고 생성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '신고 접수 중 오류가 발생했습니다: $e',
        data: null,
      );
    }
  }

  /// 내 신고 목록 조회
  Future<List<Report>> getMyReports() async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ REPORT_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      final response = await _supabaseService.client
          .from('reports')
          .select()
          .eq('reporter_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Report.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ REPORT_SERVICE: 내 신고 목록 조회 실패 - $e');
      return [];
    }
  }

  /// 특정 신고 상세 조회
  Future<Report?> getReport(int reportId) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ REPORT_SERVICE: 로그인된 사용자 없음');
        return null;
      }

      final response = await _supabaseService.client
          .from('reports')
          .select()
          .eq('id', reportId)
          .eq('reporter_id', currentUser.id) // 본인 신고만 조회 가능
          .single();

      return Report.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ REPORT_SERVICE: 신고 상세 조회 실패 - $e');
      return null;
    }
  }

  /// 특정 대상에 대한 중복 신고 확인
  Future<bool> hasReported({
    required ReportType reportedType,
    required int reportedId,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return false;
      }

      final response = await _supabaseService.client
          .from('reports')
          .select('id')
          .eq('reporter_id', currentUser.id)
          .eq('reported_type', reportedType.value)
          .eq('reported_id', reportedId)
          .eq('status', 'pending')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ REPORT_SERVICE: 중복 신고 확인 실패 - $e');
      return false;
    }
  }
}
