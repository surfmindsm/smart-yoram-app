import '../config/api_config.dart';
import '../models/worship_service.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class WorshipServiceApi {
  final ApiService _apiService = ApiService();

  // 예배 서비스 목록 조회
  Future<List<WorshipService>> getWorshipServices({
    bool? isActive,
    int? dayOfWeek,
    String? serviceType,
  }) async {
    try {
      print('🛐 WORSHIP_SERVICE: 예배 서비스 목록 조회 시작');
      
      // 쿼리 파라미터 구성
      String endpoint = ApiConfig.worshipServices;
      final queryParams = <String, String>{};
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      if (dayOfWeek != null) queryParams['day_of_week'] = dayOfWeek.toString();
      if (serviceType != null) queryParams['service_type'] = serviceType;

      if (queryParams.isNotEmpty) {
        final query = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
        endpoint += '?$query';
      }

      print('🛐 WORSHIP_SERVICE: API 호출 - $endpoint');
      print('🛐 WORSHIP_SERVICE: 쿼리 파라미터: $queryParams');

      final response = await _apiService.get(endpoint);
      
      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        final services = data.map((json) => WorshipService.fromJson(json)).toList();
        
        // 정렬: order_index 기준, 그 다음 day_of_week, start_time 기준
        services.sort((a, b) {
          if (a.orderIndex != b.orderIndex) {
            return a.orderIndex.compareTo(b.orderIndex);
          }
          if (a.dayOfWeek != b.dayOfWeek) {
            return a.dayOfWeek.compareTo(b.dayOfWeek);
          }
          return a.startTime.compareTo(b.startTime);
        });
        
        print('🛐 WORSHIP_SERVICE: 예배 서비스 ${services.length}개 조회 성공');
        return services;
      } else {
        throw Exception('예배 서비스 조회 실패: ${response.message}');
      }
    } catch (e) {
      print('🛐 WORSHIP_SERVICE: 예배 서비스 조회 오류: $e');
      
      // 네트워크 오류 또는 API 실패 시 샘플 데이터 반환
      return _getSampleWorshipServices();
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

  // 주일 예배 서비스만 조회 (홈화면용)
  Future<List<WorshipService>> getSundayServices() async {
    return await getWorshipServices(
      isActive: true,
      dayOfWeek: 0, // 일요일
    );
  }

  // 주간 예배 서비스 조회
  Future<List<WorshipService>> getWeekdayServices() async {
    final allServices = await getWorshipServices(isActive: true);
    return allServices.where((service) => service.dayOfWeek != 0).toList();
  }

  // 샘플 데이터 (API 실패 시 사용)
  List<WorshipService> _getSampleWorshipServices() {
    print('🛐 WORSHIP_SERVICE: 샘플 데이터 사용');
    
    final now = DateTime.now();
    return [
      WorshipService(
        id: 1,
        churchId: 6,
        name: '주일예배 1부',
        location: '예배실(본성전)',
        dayOfWeek: 0,
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 30),
        serviceType: 'sunday_worship',
        targetGroup: 'all',
        isOnline: false,
        isActive: true,
        orderIndex: 1,
        createdAt: now,
        updatedAt: now,
      ),
      WorshipService(
        id: 2,
        churchId: 6,
        name: '주일예배 2부',
        location: '예배실(본성전)',
        dayOfWeek: 0,
        startTime: DateTime(now.year, now.month, now.day, 11, 0),
        endTime: DateTime(now.year, now.month, now.day, 12, 30),
        serviceType: 'sunday_worship',
        targetGroup: 'all',
        isOnline: false,
        isActive: true,
        orderIndex: 2,
        createdAt: now,
        updatedAt: now,
      ),
      WorshipService(
        id: 3,
        churchId: 6,
        name: '주일예배 3부',
        location: '예배실(본성전)',
        dayOfWeek: 0,
        startTime: DateTime(now.year, now.month, now.day, 13, 30),
        endTime: DateTime(now.year, now.month, now.day, 15, 0),
        serviceType: 'sunday_worship',
        targetGroup: 'all',
        isOnline: false,
        isActive: true,
        orderIndex: 3,
        createdAt: now,
        updatedAt: now,
      ),
      WorshipService(
        id: 4,
        churchId: 6,
        name: '새벽부',
        location: '새벽부실',
        dayOfWeek: 0,
        startTime: DateTime(now.year, now.month, now.day, 11, 0),
        endTime: DateTime(now.year, now.month, now.day, 12, 0),
        serviceType: 'children',
        targetGroup: 'children',
        isOnline: false,
        isActive: true,
        orderIndex: 4,
        createdAt: now,
        updatedAt: now,
      ),
      WorshipService(
        id: 5,
        churchId: 6,
        name: '수요예배',
        location: '예배실(본성전)',
        dayOfWeek: 3,
        startTime: DateTime(now.year, now.month, now.day, 20, 0),
        endTime: DateTime(now.year, now.month, now.day, 21, 0),
        serviceType: 'wednesday_worship',
        targetGroup: 'all',
        isOnline: false,
        isActive: true,
        orderIndex: 5,
        createdAt: now,
        updatedAt: now,
      ),
      WorshipService(
        id: 6,
        churchId: 6,
        name: '새벽기도회',
        location: '온라인',
        dayOfWeek: 1, // 월-금 대표로 월요일
        startTime: DateTime(now.year, now.month, now.day, 5, 30),
        endTime: DateTime(now.year, now.month, now.day, 6, 30),
        serviceType: 'dawn_prayer',
        targetGroup: 'all',
        isOnline: true,
        isActive: true,
        orderIndex: 6,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
