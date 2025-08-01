import '../config/api_config.dart';
import '../models/church.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class ChurchService {
  static final ChurchService _instance = ChurchService._internal();
  factory ChurchService() => _instance;
  ChurchService._internal();

  final ApiService _apiService = ApiService();

  /// 내 교회 정보 조회
  Future<ApiResponse<Church>> getMyChurch() async {
    print('🏦 CHURCH_SERVICE: getMyChurch 시작');
    
    try {
      final response = await _apiService.get('${ApiConfig.churches}my');
      
      if (response.data != null) {
        final church = Church.fromJson(response.data);
        print('🏦 CHURCH_SERVICE: 내 교회 정보 조회 성공: ${church.name}');
        return ApiResponse(
          success: true,
          data: church,
          message: '교회 정보를 성공적으로 가져왔습니다.',
        );
      } else {
        print('🏦 CHURCH_SERVICE: 내 교회 정보가 없음');
        // 샘플 데이터 사용
        final sampleChurch = _createSampleChurch();
        return ApiResponse(
          success: true,
          data: sampleChurch,
          message: '샘플 교회 정보를 사용합니다.',
        );
      }
    } catch (e) {
      print('🏦 CHURCH_SERVICE: 내 교회 정보 조회 실패: $e');
      // 샘플 데이터 사용
      final sampleChurch = _createSampleChurch();
      return ApiResponse(
        success: true,
        data: sampleChurch,
        message: '네트워크 오류로 샘플 교회 정보를 사용합니다.',
      );
    }
  }

  /// 특정 교회 정보 조회
  Future<ApiResponse<Church>> getChurch(int churchId) async {
    print('🏦 CHURCH_SERVICE: getChurch 시작 - ID: $churchId');
    
    try {
      final response = await _apiService.get('${ApiConfig.churches}$churchId');
      
      if (response.data != null) {
        final church = Church.fromJson(response.data);
        print('🏦 CHURCH_SERVICE: 교회 정보 조회 성공: ${church.name}');
        return ApiResponse(
          success: true,
          data: church,
          message: '교회 정보를 성공적으로 가져왔습니다.',
        );
      } else {
        print('🏦 CHURCH_SERVICE: 교회 정보가 없음 - ID: $churchId');
        return ApiResponse(
          success: false,
          message: '교회 정보를 찾을 수 없습니다.',
        );
      }
    } catch (e) {
      print('🏦 CHURCH_SERVICE: 교회 정보 조회 실패: $e');
      return ApiResponse(
        success: false,
        message: '교회 정보를 가져오는데 실패했습니다: $e',
      );
    }
  }

  /// 샘플 교회 데이터 생성 (API 실패 시 fallback)
  Church _createSampleChurch() {
    print('🏦 CHURCH_SERVICE: 샘플 교회 데이터 생성');
    
    return Church(
      id: 6,
      name: '스마트 요람교회',
      address: '서울시 강남구 요람로 123',
      phone: '02-1234-5678',
      email: 'info@smartyoram.com',
      pastorName: '김요람 목사',
      subscriptionStatus: 'active',
      subscriptionEndDate: DateTime.now().add(const Duration(days: 365)),
      memberLimit: 500,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
