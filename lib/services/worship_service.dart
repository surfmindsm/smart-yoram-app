import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/worship_service.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WorshipServiceApi {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // 예배 서비스 목록 조회 (Supabase 직접 연동)
  Future<List<WorshipService>> getWorshipServices({
    bool? isActive,
    int? dayOfWeek,
    String? serviceType,
  }) async {
    try {
      print('🛐 WORSHIP_SERVICE: 예배 서비스 목록 조회 시작 (Supabase)');

      // 현재 사용자의 교회 ID 가져오기
      final userResponse = await _authService.getCurrentUser();
      final churchId = userResponse.data?.churchId;

      if (churchId == null) {
        print('❌ WORSHIP_SERVICE: 교회 ID를 찾을 수 없습니다');
        return [];
      }

      print('🛐 WORSHIP_SERVICE: 교회 ID: $churchId');

      // Supabase 쿼리 빌드
      var query = _supabase
          .from('worship_services')
          .select()
          .eq('church_id', churchId);

      // 필터 적용
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (dayOfWeek != null) {
        query = query.eq('day_of_week', dayOfWeek);
      }
      if (serviceType != null) {
        query = query.eq('service_type', serviceType);
      }

      print('🛐 WORSHIP_SERVICE: Supabase 쿼리 실행 중...');

      // 기본 정렬로 실행 (시간순)
      final response = await query.order('start_time', ascending: true);

      print('🛐 WORSHIP_SERVICE: 응답 데이터: $response');

      if (response == null || response.isEmpty) {
        print('🛐 WORSHIP_SERVICE: 예배 서비스 데이터 없음');
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      final services = data.map((json) => WorshipService.fromJson(json)).toList();

      // 커스텀 정렬: 예배 종류별 그룹화 → 요일순 → 시간순
      services.sort((a, b) {
        // 1. 예배 종류별 우선순위 (주일예배 → 주중예배 → 새벽예배)
        final aTypePriority = _getServiceTypePriority(a.serviceType, a.dayOfWeek);
        final bTypePriority = _getServiceTypePriority(b.serviceType, b.dayOfWeek);

        if (aTypePriority != bTypePriority) {
          return aTypePriority.compareTo(bTypePriority);
        }

        // 2. 같은 종류 내에서 요일순 (일요일=6이 먼저, 그 다음 월~토=0~5)
        if (a.dayOfWeek != b.dayOfWeek) {
          // 일요일(6)을 최우선으로
          if (a.dayOfWeek == 6) return -1;
          if (b.dayOfWeek == 6) return 1;
          // 나머지는 월~토 순서
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        }

        // 3. 같은 요일 내에서 시간순
        return a.startTime.compareTo(b.startTime);
      });

      print('🛐 WORSHIP_SERVICE: 예배 서비스 ${services.length}개 조회 성공 (정렬 완료)');

      return services;
    } catch (e, stackTrace) {
      print('🛐 WORSHIP_SERVICE: 예배 서비스 조회 오류: $e');
      print('🛐 WORSHIP_SERVICE: 스택트레이스: $stackTrace');

      // 오류 발생 시 빈 리스트 반환
      return [];
    }
  }

  // 특정 예배 서비스 조회
  Future<ApiResponse<WorshipService?>> getWorshipService(int serviceId) async {
    try {
      print('🛐 WORSHIP_SERVICE: 예배 서비스 상세 조회 시작 - ID: $serviceId');
      
      final response = await _apiService.get('${ApiConfig.worshipServices}/$serviceId');

      if (response.success && response.data != null) {
        final service = WorshipService.fromJson(response.data);
        print('🛐 WORSHIP_SERVICE: 예배 서비스 상세 조회 성공');
        return ApiResponse(
          success: true,
          message: '조회 성공',
          data: service,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      print('🛐 WORSHIP_SERVICE: 예배 서비스 상세 조회 오류: $e');
      return ApiResponse(
        success: false,
        message: '예배 서비스 조회 중 오류가 발생했습니다: $e',
        data: null,
      );
    }
  }

  // 예배 종류별 우선순위 결정 (숫자가 작을수록 위에 표시)
  int _getServiceTypePriority(String serviceType, int dayOfWeek) {
    // 일요일(6)에 하는 모든 예배 = 주일예배 그룹
    if (dayOfWeek == 6) {
      return 1; // 주일예배
    }

    // 평일 예배는 service_type으로 구분
    switch (serviceType) {
      case 'dawn_prayer': // 새벽기도회
        return 3; // 새벽예배 그룹 (가장 마지막)

      case 'wednesday_worship': // 수요예배
      case 'friday_worship': // 금요예배
      case 'special_worship': // 특별예배
        return 2; // 주중예배 그룹

      default:
        // 기타 예배는 주중예배로 분류
        return 2;
    }
  }

  // 주일 예배 서비스만 조회 (홈화면용)
  Future<List<WorshipService>> getSundayServices() async {
    return await getWorshipServices(
      isActive: true,
      dayOfWeek: 6, // 일요일 (0=월요일, 6=일요일)
    );
  }

  // 주간 예배 서비스 조회
  Future<List<WorshipService>> getWeekdayServices() async {
    final allServices = await getWorshipServices(isActive: true);
    return allServices.where((service) => service.dayOfWeek != 6).toList();
  }
}
