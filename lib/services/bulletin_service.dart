import '../models/bulletin.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// 주보/공지사항 서비스
class BulletinService {
  static final BulletinService _instance = BulletinService._internal();
  factory BulletinService() => _instance;
  BulletinService._internal();

  final ApiService _apiService = ApiService();

  /// 주보 목록 조회
  Future<ApiResponse<List<Bulletin>>> getBulletins({
    int skip = 0,
    int limit = 100,
    String? search,
    String? category,
  }) async {
    try {
      String endpoint = '${ApiConfig.baseUrl}bulletins?skip=$skip&limit=$limit';
      
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      
      if (category != null && category.isNotEmpty) {
        endpoint += '&category=${Uri.encodeComponent(category)}';
      }

      final response = await _apiService.get<List<dynamic>>(endpoint);

      if (response.success && response.data != null) {
        final List<Bulletin> bulletins = (response.data as List)
            .map((bulletinJson) => Bulletin.fromJson(bulletinJson))
            .toList();

        return ApiResponse<List<Bulletin>>(
          success: true,
          message: '주보 목록 조회 성공',
          data: bulletins,
        );
      }

      return ApiResponse<List<Bulletin>>(
        success: false,
        message: response.message,
        data: [],
      );
    } catch (e) {
      print('🔍 BULLETIN_SERVICE: 목록 조회 실패 - $e');
      // API가 구현되지 않은 경우 샘플 데이터 반환
      return ApiResponse<List<Bulletin>>(
        success: true,
        message: '임시 주보 데이터',
        data: _generateSampleBulletins(),
      );
    }
  }

  /// 특정 주보 조회
  Future<ApiResponse<Bulletin>> getBulletin(String bulletinId) async {
    try {
      final response = await _apiService.get<Bulletin>(
        '${ApiConfig.baseUrl}bulletins/$bulletinId',
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
        '${ApiConfig.baseUrl}bulletins',
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
        '${ApiConfig.baseUrl}bulletins/$bulletinId',
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
        '${ApiConfig.baseUrl}bulletins/$bulletinId',
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
        '${ApiConfig.baseUrl}bulletins/$bulletinId/download',
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
        id: '1',
        title: '2024년 1월 마지막 주일 주보',
        date: now.subtract(const Duration(days: 1)),
        description: '주일예배 및 각종 행사 안내',
        fileType: 'pdf',
        fileSize: 1024 * 500, // 500KB
        createdAt: now.subtract(const Duration(days: 1)),
        createdBy: '관리자',
      ),
      Bulletin(
        id: '2',
        title: '2024년 1월 넷째주 주보',
        date: now.subtract(const Duration(days: 8)),
        description: '신년예배 및 새해계획 안내',
        fileType: 'pdf',
        fileSize: 1024 * 450, // 450KB
        createdAt: now.subtract(const Duration(days: 8)),
        createdBy: '관리자',
      ),
      Bulletin(
        id: '3',
        title: '2024년 1월 셋째주 주보',
        date: now.subtract(const Duration(days: 15)),
        description: '새해 첫 성찬식 안내',
        fileType: 'pdf',
        fileSize: 1024 * 600, // 600KB
        createdAt: now.subtract(const Duration(days: 15)),
        createdBy: '관리자',
      ),
      Bulletin(
        id: '4',
        title: '2024년 1월 둘째주 주보',
        date: now.subtract(const Duration(days: 22)),
        description: '신년 감사예배 및 떡국 나눔',
        fileType: 'pdf',
        fileSize: 1024 * 700, // 700KB
        createdAt: now.subtract(const Duration(days: 22)),
        createdBy: '관리자',
      ),
      Bulletin(
        id: '5',
        title: '2024년 1월 첫째주 주보',
        date: now.subtract(const Duration(days: 29)),
        description: '새해 첫 주일예배',
        fileType: 'pdf',
        fileSize: 1024 * 400, // 400KB
        createdAt: now.subtract(const Duration(days: 29)),
        createdBy: '관리자',
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
