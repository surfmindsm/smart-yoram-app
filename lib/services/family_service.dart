import '../models/api_response.dart';
import '../models/family_model.dart';
import 'api_service.dart';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  final ApiService _apiService = ApiService();

  /// 가족 관계 생성
  Future<ApiResponse<FamilyRelationship>> createRelationship({
    required int memberId,
    required int relatedMemberId,
    required String relationshipType,
  }) async {
    final body = {
      'member_id': memberId,
      'related_member_id': relatedMemberId,
      'relationship_type': relationshipType,
    };

    return await _apiService.post<FamilyRelationship>(
      '/family/relationships',
      body: body,
      fromJson: (json) => FamilyRelationship.fromJson(json),
    );
  }

  /// 교인의 가족 관계 조회
  Future<ApiResponse<List<FamilyRelationship>>> getMemberRelationships(
      int memberId) async {
    final response = await _apiService.get<List<dynamic>>(
      '/family/relationships/$memberId',
    );

    if (response.success && response.data != null) {
      final relationships = response.data!
          .map((json) => FamilyRelationship.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<FamilyRelationship>>(
        success: true,
        message: response.message,
        data: relationships,
      );
    }

    return ApiResponse<List<FamilyRelationship>>(
      success: false,
      message: response.message,
      data: null,
    );
  }

  /// 가족 트리 조회
  Future<ApiResponse<FamilyTree>> getFamilyTree(int memberId) async {
    return await _apiService.get<FamilyTree>(
      '/family/tree/$memberId',
      fromJson: (json) => FamilyTree.fromJson(json),
    );
  }

  /// 가족 관계 삭제
  Future<ApiResponse<void>> deleteRelationship(int relationshipId) async {
    return await _apiService.delete<void>('/family/relationships/$relationshipId');
  }

  /// 가능한 관계 유형 목록
  static List<String> get relationshipTypes => [
    '부모',
    '자녀',
    '배우자',
    '형제',
    '자매',
    '조부모',
    '손자녀',
    '삼촌',
    '이모',
    '고모',
    '조카',
  ];
}
