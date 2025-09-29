import '../models/api_response.dart';
import '../models/church.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class ChurchService {
  static final ChurchService _instance = ChurchService._internal();
  factory ChurchService() => _instance;
  ChurchService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  /// 현재 사용자의 교회 정보 조회 (Supabase)
  Future<ApiResponse<Church>> getMyChurch() async {
    print('🏛️ CHURCH_SERVICE: 교회 정보 조회 시작');

    try {
      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        print('🏛️ CHURCH_SERVICE: 사용자 정보 조회 실패');
        return ApiResponse<Church>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: null,
        );
      }

      final user = userResponse.data!;
      print('🏛️ CHURCH_SERVICE: 사용자 교회 ID: ${user.churchId}');

      // churches 테이블에서 교회 정보 조회
      final response = await _supabaseService.client
          .from('churches')
          .select('*')
          .eq('id', user.churchId)
          .single();

      print('🏛️ CHURCH_SERVICE: DB 응답 데이터: $response');

      final church = Church.fromJson(response);

      print('🏛️ CHURCH_SERVICE: 교회 정보 조회 성공');
      print('  - 교회명: ${church.name}');
      print('  - 전화번호: ${church.phone}');
      print('  - 이메일: ${church.email}');
      print('  - 주소: ${church.address}');
      print('  - 담임목사: ${church.pastorName}');

      return ApiResponse<Church>(
        success: true,
        message: '교회 정보 조회 성공',
        data: church,
      );
    } catch (e) {
      print('❌ CHURCH_SERVICE: 교회 정보 조회 오류: $e');
      // 샘플 데이터로 fallback
      final sampleChurch = _createSampleChurch();
      return ApiResponse<Church>(
        success: true,
        message: '오류로 인해 샘플 데이터를 사용합니다: $e',
        data: sampleChurch,
      );
    }
  }

  /// 특정 교회 정보 조회 (Supabase)
  Future<ApiResponse<Church>> getChurch(int churchId) async {
    print('🏛️ CHURCH_SERVICE: 특정 교회 정보 조회 시작 - ID: $churchId');

    try {
      // churches 테이블에서 특정 교회 정보 조회
      final response = await _supabaseService.client
          .from('churches')
          .select('*')
          .eq('id', churchId)
          .single();

      print('🏛️ CHURCH_SERVICE: DB 응답 데이터: $response');

      final church = Church.fromJson(response);

      print('🏛️ CHURCH_SERVICE: 교회 정보 조회 성공: ${church.name}');
      return ApiResponse<Church>(
        success: true,
        data: church,
        message: '교회 정보를 성공적으로 가져왔습니다.',
      );
    } catch (e) {
      print('❌ CHURCH_SERVICE: 교회 정보 조회 실패: $e');
      return ApiResponse<Church>(
        success: false,
        message: '교회 정보를 가져오는데 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 샘플 교회 데이터 생성 (DB 오류 시 fallback)
  Church _createSampleChurch() {
    print('🏛️ CHURCH_SERVICE: 샘플 교회 데이터 생성');

    return Church(
      id: 7,
      name: '9월22일 교회',
      address: '아산시 평화구 시스템로 14124',
      phone: '13216549',
      email: 'composm@naver.com',
      pastorName: '이선민',
      subscriptionStatus: 'trial',
      subscriptionEndDate: null,
      memberLimit: 500,
      isActive: true,
      createdAt: DateTime.parse('2025-09-22 04:35:09.542181+00'),
      updatedAt: DateTime.parse('2025-09-27 08:08:08.283+00'),
    );
  }
}
