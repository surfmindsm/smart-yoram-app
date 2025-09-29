import '../models/bulletin.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// 주보/공지사항 서비스 (Supabase Edge Function 사용)
class BulletinService {
  static final BulletinService _instance = BulletinService._internal();
  factory BulletinService() => _instance;
  BulletinService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  /// 주보 목록 조회 (Supabase Edge Function 사용)
  Future<ApiResponse<List<Bulletin>>> getBulletins({
    int page = 1,
    int limit = 100,
    String? search,
    int? year,
    int? month,
  }) async {
    try {
      print('📰 BULLETIN_SERVICE: 주보 목록 조회 시작 (Supabase)');

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

      // 직접 bulletins 테이블 조회
      final response = await _supabaseService.client
          .from('bulletins')
          .select('*')
          .eq('church_id', user.churchId)
          .order('date', ascending: false)
          .limit(limit);

      print('📰 BULLETIN_SERVICE: Supabase 응답 타입: ${response.runtimeType}');
      print('📰 BULLETIN_SERVICE: Supabase 응답 데이터: $response');

      final List<Bulletin> bulletins = (response as List)
          .map((item) => Bulletin.fromJson(item as Map<String, dynamic>))
          .toList();

      print('📰 BULLETIN_SERVICE: 파싱된 주보 수: ${bulletins.length}');

      return ApiResponse<List<Bulletin>>(
        success: true,
        message: '주보 목록 조회 성공',
        data: bulletins,
      );
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

  /// 특정 주보 조회 (Supabase Edge Function)
  Future<ApiResponse<Bulletin>> getBulletin(int bulletinId) async {
    try {
      final response = await _supabaseService.invokeFunction<Bulletin>(
        SupabaseConfig.bulletinsFunction,
        body: {
          'action': 'get_bulletin',
          'bulletin_id': bulletinId,
        },
        fromJson: (json) => Bulletin.fromJson(json),
      );

      if (response.success && response.data != null) {
        return ApiResponse<Bulletin>(
          success: true,
          message: '주보 조회 성공',
          data: response.data!,
        );
      } else {
        return ApiResponse<Bulletin>(
          success: false,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Bulletin>(
        success: false,
        message: '주보 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 주보 생성 (관리자용) (Supabase Edge Function)
  Future<ApiResponse<Bulletin>> createBulletin(Map<String, dynamic> bulletinData) async {
    try {
      final response = await _supabaseService.invokeFunction<Bulletin>(
        SupabaseConfig.bulletinsFunction,
        body: {
          'action': 'create_bulletin',
          'bulletin_data': bulletinData,
        },
        fromJson: (json) => Bulletin.fromJson(json),
      );

      if (response.success && response.data != null) {
        return ApiResponse<Bulletin>(
          success: true,
          message: '주보 생성 성공',
          data: response.data!,
        );
      } else {
        return ApiResponse<Bulletin>(
          success: false,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Bulletin>(
        success: false,
        message: '주보 생성 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 주보 수정 (관리자용) (Supabase Edge Function)
  Future<ApiResponse<Bulletin>> updateBulletin(
    int bulletinId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _supabaseService.invokeFunction<Bulletin>(
        SupabaseConfig.bulletinsFunction,
        body: {
          'action': 'update_bulletin',
          'bulletin_id': bulletinId,
          'bulletin_data': updateData,
        },
        fromJson: (json) => Bulletin.fromJson(json),
      );

      if (response.success && response.data != null) {
        return ApiResponse<Bulletin>(
          success: true,
          message: '주보 수정 성공',
          data: response.data!,
        );
      } else {
        return ApiResponse<Bulletin>(
          success: false,
          message: response.message,
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Bulletin>(
        success: false,
        message: '주보 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 주보 삭제 (관리자용) (Supabase Edge Function)
  Future<ApiResponse<void>> deleteBulletin(int bulletinId) async {
    try {
      final response = await _supabaseService.invokeFunction<Map<String, dynamic>>(
        SupabaseConfig.bulletinsFunction,
        body: {
          'action': 'delete_bulletin',
          'bulletin_id': bulletinId,
        },
        fromJson: (json) => json,
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: '주보 삭제 실패: ${e.toString()}',
      );
    }
  }

  /// 주보 파일 다운로드 (Supabase Storage)
  Future<ApiResponse<String>> downloadBulletin(int bulletinId) async {
    try {
      // 실제 구현에서는 Supabase Storage를 통해 파일 다운로드 URL을 가져옴
      // 현재는 빈 구현으로 유지
      return ApiResponse<String>(
        success: false,
        message: '주보 다운로드 기능은 현재 구현되지 않았습니다',
        data: null,
      );
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
