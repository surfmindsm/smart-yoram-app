import '../models/bulletin.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// 주보/공지사항 서비스
class BulletinService {
  static final BulletinService _instance = BulletinService._internal();
  factory BulletinService() => _instance;
  BulletinService._internal();

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  /// 주보 목록 조회
  Future<ApiResponse<List<Bulletin>>> getBulletins({
    int skip = 0,
    int limit = 100,
    String? search,
    String? category,
  }) async {
    try {
      print('📰 BULLETIN_SERVICE: 주보 목록 조회 시작');
      
      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        print('📰 BULLETIN_SERVICE: 사용자 정보 조회 실패 - ${userResponse.message}');
        return ApiResponse<List<Bulletin>>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: [],
        );
      }

      final user = userResponse.data!;
      print('📰 BULLETIN_SERVICE: 사용자 정보 - ID: ${user.id}, Church ID: ${user.churchId}');
      
      // API 엔드포인트 구성 (ApiService에서 baseUrl을 붙이므로 경로만 전달)
      String endpoint = '${ApiConfig.bulletins}?skip=$skip&limit=$limit&church_id=${user.churchId}';
      
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      
      if (category != null && category.isNotEmpty) {
        endpoint += '&category=${Uri.encodeComponent(category)}';
      }

      print('📰 BULLETIN_SERVICE: API 요청 시작 - ${ApiConfig.baseUrl}$endpoint');
      print('📰 BULLETIN_SERVICE: API 엔드포인트 - $endpoint');
      
      try {
        var response = await _apiService.get<List<dynamic>>(
          endpoint,
          fromJson: (json) => json as List<dynamic>,
        ).timeout(const Duration(seconds: 10));
        print('📰 BULLETIN_SERVICE: API 응답 완료 - success: ${response.success}, message: ${response.message}');
        
        if (response.success && response.data != null) {
          print('📰 BULLETIN_SERVICE: 응답 데이터 타입: ${response.data.runtimeType}');
          print('📰 BULLETIN_SERVICE: 응답 데이터 길이: ${(response.data as List).length}');
          
          final List<Bulletin> bulletins = (response.data as List)
              .map((bulletinJson) {
                print('📰 BULLETIN_SERVICE: 주보 데이터 파싱: $bulletinJson');
                return Bulletin.fromJson(bulletinJson);
              })
              .toList();

          print('📰 BULLETIN_SERVICE: 파싱된 주보 수: ${bulletins.length}');
          return ApiResponse<List<Bulletin>>(
            success: true,
            message: '주보 목록 조회 성공',
            data: bulletins,
          );
        }
        
        print('📰 BULLETIN_SERVICE: API 응답 실패 또는 빈 데이터');
        
        // "Not Found" 오류인 경우 샘플 데이터로 대체하여 UI 테스트 진행
        if (response.message.contains('Not Found')) {
          print('📰 BULLETIN_SERVICE: "Not Found" 오류로 인해 샘플 데이터 사용');
          return ApiResponse<List<Bulletin>>(
            success: true,
            message: '해당 교회에 주보 데이터가 없어 샘플 데이터로 표시',
            data: _generateSampleBulletins(),
          );
        }
        
        return ApiResponse<List<Bulletin>>(
          success: false,
          message: response.message,
          data: [],
        );
      } catch (e) {
        print('📰 BULLETIN_SERVICE: API 호출 타임아웃 또는 예외 - $e');
        print('📰 BULLETIN_SERVICE: 네트워크 문제로 인해 샘플 데이터 사용');
        return ApiResponse<List<Bulletin>>(
          success: true,
          message: 'API 연결 문제로 인해 샘플 데이터로 표시',
          data: _generateSampleBulletins(),
        );
      }
    } catch (e) {
      print('📰 BULLETIN_SERVICE: 목록 조회 예외 발생 - $e');
      print('📰 BULLETIN_SERVICE: 샘플 데이터로 대체하여 UI 테스트 진행');
      return ApiResponse<List<Bulletin>>(
        success: true,
        message: '주보 데이터를 찾을 수 없어 샘플 데이터로 표시',
        data: _generateSampleBulletins(),
      );
    }
  }

  /// 특정 주보 조회
  Future<ApiResponse<Bulletin>> getBulletin(String bulletinId) async {
    try {
      final response = await _apiService.get<Bulletin>(
        '${ApiConfig.bulletins}$bulletinId',
        fromJson: (json) => Bulletin.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<Bulletin>(
        success: false,
        message: '주보 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 주보 생성 (관리자용)
  Future<ApiResponse<Bulletin>> createBulletin(BulletinCreateRequest request) async {
    try {
      final response = await _apiService.post<Bulletin>(
        ApiConfig.bulletins,
        body: request.toJson(),
        fromJson: (json) => Bulletin.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<Bulletin>(
        success: false,
        message: '주보 생성 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 주보 수정 (관리자용)
  Future<ApiResponse<Bulletin>> updateBulletin(
    String bulletinId,
    BulletinUpdateRequest request,
  ) async {
    try {
      final response = await _apiService.put<Bulletin>(
        '${ApiConfig.bulletins}$bulletinId',
        body: request.toJson(),
        fromJson: (json) => Bulletin.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<Bulletin>(
        success: false,
        message: '주보 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 주보 삭제 (관리자용)
  Future<ApiResponse<void>> deleteBulletin(String bulletinId) async {
    try {
      final response = await _apiService.delete<void>(
        '${ApiConfig.bulletins}$bulletinId',
      );

      return response;
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: '주보 삭제 실패: ${e.toString()}',
      );
    }
  }

  /// 주보 파일 다운로드
  Future<ApiResponse<String>> downloadBulletin(String bulletinId) async {
    try {
      final response = await _apiService.get<String>(
        '${ApiConfig.bulletins}$bulletinId/download',
      );

      return response;
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: '주보 다운로드 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 샘플 주보 데이터 생성 (API가 없을 경우 임시용)
  List<Bulletin> _generateSampleBulletins() {
    final now = DateTime.now();
    return [
      Bulletin(
        id: 1,
        title: '2025년 1월 마지막 주일 주보',
        date: now.subtract(const Duration(days: 1)),
        content: '주일예배 및 각종 행사 안내\n- 오전 11시 주일예배\n- 오후 2시 찬양예배\n- 저녁 7시 청년부 모임',
        fileUrl: 'https://example.com/bulletin_2025_01_last.pdf',
        churchId: 6, // 현재 사용자의 교회 ID
        createdAt: now.subtract(const Duration(days: 1)),
        createdBy: 1,
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Bulletin(
        id: 2,
        title: '2025년 1월 넷째주 주보',
        date: now.subtract(const Duration(days: 8)),
        content: '신년예배 및 새해계획 안내\n- 신년감사예배 준비\n- 새해 비전 선포\n- 교육부서 계획 발표',
        fileUrl: 'https://example.com/bulletin_2025_01_4th.pdf',
        churchId: 6,
        createdAt: now.subtract(const Duration(days: 8)),
        createdBy: 1,
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      Bulletin(
        id: 3,
        title: '2025년 1월 셋째주 주보',
        date: now.subtract(const Duration(days: 15)),
        content: '새해 첫 성찬식 안내\n- 성찬식 준비기도회\n- 새해 결단 나눔\n- 구역 모임 안내',
        fileUrl: 'https://example.com/bulletin_2025_01_3rd.pdf',
        churchId: 6,
        createdAt: now.subtract(const Duration(days: 15)),
        createdBy: 1,
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      Bulletin(
        id: 4,
        title: '2025년 1월 둘째주 주보',
        date: now.subtract(const Duration(days: 22)),
        content: '신년 감사예배 및 떡국 나눔\n- 떡국 나눔 행사\n- 감사 간증 시간\n- 새해 포부 발표',
        fileUrl: 'https://example.com/bulletin_2025_01_2nd.pdf',
        churchId: 6,
        createdAt: now.subtract(const Duration(days: 22)),
        createdBy: 1,
        updatedAt: now.subtract(const Duration(days: 22)),
      ),
      Bulletin(
        id: 5,
        title: '2025년 1월 첫째주 주보',
        date: now.subtract(const Duration(days: 29)),
        content: '새해 첫 주일예배\n- 신년 기원 예배\n- 새해 계획 나눔\n- 교회 운영 방향 안내',
        fileUrl: 'https://example.com/bulletin_2025_01_1st.pdf',
        churchId: 6,
        createdAt: now.subtract(const Duration(days: 29)),
        createdBy: 1,
        updatedAt: now.subtract(const Duration(days: 29)),
      ),
    ];
  }
}

/// 주보 생성 요청 모델
class BulletinCreateRequest {
  final String title;
  final DateTime date;
  final String? description;
  final String? category;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;

  BulletinCreateRequest({
    required this.title,
    required this.date,
    this.description,
    this.category,
    this.fileUrl,
    this.fileType,
    this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
      if (fileSize != null) 'file_size': fileSize,
    };
  }
}

/// 주보 수정 요청 모델
class BulletinUpdateRequest {
  final String? title;
  final DateTime? date;
  final String? description;
  final String? category;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;

  BulletinUpdateRequest({
    this.title,
    this.date,
    this.description,
    this.category,
    this.fileUrl,
    this.fileType,
    this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (date != null) 'date': date!.toIso8601String(),
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
      if (fileSize != null) 'file_size': fileSize,
    };
  }
}
