import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/member.dart';
import 'api_service.dart';

class MemberService {
  static final MemberService _instance = MemberService._internal();
  factory MemberService() => _instance;
  MemberService._internal();

  final ApiService _apiService = ApiService();

  // 교인 목록 조회
  Future<ApiResponse<List<Member>>> getMembers({
    int skip = 0,
    int limit = 100,
    String? search,
    String? memberStatus,
  }) async {
    print('👥 MEMBER_SERVICE: getMembers 시작');
    print('👥 MEMBER_SERVICE: 파라미터 - skip: $skip, limit: $limit');
    print('👥 MEMBER_SERVICE: search: $search, memberStatus: $memberStatus');
    
    try {
      String endpoint = '${ApiConfig.members}?skip=$skip&limit=$limit';
      
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      
      if (memberStatus != null && memberStatus.isNotEmpty) {
        endpoint += '&member_status=${Uri.encodeComponent(memberStatus)}';
      }
      
      print('👥 MEMBER_SERVICE: API 엔드포인트: $endpoint');
      print('👥 MEMBER_SERVICE: 전체 URL: ${ApiConfig.baseUrl}$endpoint');

      final response = await _apiService.get<List<dynamic>>(endpoint);
      
      print('👥 MEMBER_SERVICE: API 응답 - success: ${response.success}');
      print('👥 MEMBER_SERVICE: API 응답 - message: "${response.message}"');
      print('👥 MEMBER_SERVICE: API 응답 - data null 여부: ${response.data == null}');

      if (response.success && response.data != null) {
        print('👥 MEMBER_SERVICE: 원본 데이터 타입: ${response.data.runtimeType}');
        print('👥 MEMBER_SERVICE: 원본 데이터 길이: ${(response.data as List).length}');
        
        final List<Member> members = (response.data as List)
            .map((memberJson) {
              // 처음 3개 데이터만 상세 로그
              if ((response.data as List).indexOf(memberJson) < 3) {
                print('👥 MEMBER_SERVICE: member 데이터 파싱: $memberJson');
              }
              return Member.fromJson(memberJson);
            })
            .toList();
        
        print('👥 MEMBER_SERVICE: 파싱된 교인 수: ${members.length}');
        for (int i = 0; i < members.length && i < 3; i++) {
          final member = members[i];
          print('👥 MEMBER_SERVICE: [$i] ID: ${member.id}, 이름: ${member.name}, 교회ID: ${member.churchId}');
        }

        return ApiResponse<List<Member>>(
          success: true,
          message: '교인 목록 조회 성공',
          data: members,
        );
      }

      print('👥 MEMBER_SERVICE: API 응답 실패 또는 데이터 없음');
      return ApiResponse<List<Member>>(
        success: false,
        message: response.message,
        data: null,
      );
    } catch (e) {
      print('👥 MEMBER_SERVICE: getMembers 예외 - $e');
      return ApiResponse<List<Member>>(
        success: false,
        message: '교인 목록 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 특정 교인 상세 조회 (member_id로)
  Future<ApiResponse<Member>> getMember(int memberId) async {
    try {
      final response = await _apiService.get<Member>(
        '${ApiConfig.members}$memberId',
        fromJson: (json) => Member.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<Member>(
        success: false,
        message: '교인 정보 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // user_id로 교인 조회 (users-members 매핑)
  Future<ApiResponse<Member>> getMemberByUserId(int userId) async {
    print('🔍 MEMBER_SERVICE: user_id $userId로 member 조회 시작');
    try {
      // 전체 members 목록에서 user_id로 필터링하는 방식
      // API에 /by-user 엔드포인트가 없어서 대안 방식 사용
      print('🔍 MEMBER_SERVICE: 전체 members 목록에서 user_id $userId 검색');
      
      final response = await getMembers(limit: 1000); // 충분히 큰 limit
      
      if (response.success && response.data != null) {
        // user_id가 일치하는 member 찾기
        final members = response.data!;
        print('🔍 MEMBER_SERVICE: 총 ${members.length}개 member 조회됨');
        
        final matchedMember = members.firstWhere(
          (member) => member.userId == userId,
          orElse: () => throw Exception('Member not found'),
        );
        
        print('🔍 MEMBER_SERVICE: 성공! user_id $userId → member_id ${matchedMember.id}');
        return ApiResponse<Member>(
          success: true,
          message: '매핑 성공',
          data: matchedMember,
        );
      } else {
        print('🔍 MEMBER_SERVICE: members 목록 조회 실패 - ${response.message}');
        return ApiResponse<Member>(
          success: false,
          message: 'Members 목록 조회 실패: ${response.message}',
          data: null,
        );
      }
    } catch (e) {
      print('🔍 MEMBER_SERVICE: 예외 발생 - $e');
      return ApiResponse<Member>(
        success: false,
        message: 'user_id로 교인 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 새 교인 등록
  Future<ApiResponse<Member>> createMember(MemberCreateRequest request) async {
    try {
      final response = await _apiService.post<Member>(
        ApiConfig.members,
        body: request.toJson(),
        fromJson: (json) => Member.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<Member>(
        success: false,
        message: '교인 등록 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 교인 정보 수정
  Future<ApiResponse<Member>> updateMember(
    int memberId, 
    MemberUpdateRequest request,
  ) async {
    try {
      final response = await _apiService.put<Member>(
        '${ApiConfig.members}$memberId',
        body: request.toJson(),
        fromJson: (json) => Member.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<Member>(
        success: false,
        message: '교인 정보 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 교인 삭제
  Future<ApiResponse<void>> deleteMember(int memberId) async {
    try {
      final response = await _apiService.delete<void>(
        '${ApiConfig.members}$memberId',
      );

      return response;
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: '교인 삭제 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 프로필 사진 업로드
  Future<ApiResponse<Member>> uploadProfilePhoto(
    int memberId, 
    File imageFile,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.members}$memberId/upload-photo'
      );

      final request = http.MultipartRequest('POST', url);
      
      // 인증 헤더 추가
      if (_apiService.token != null) {
        request.headers.addAll(ApiConfig.multipartHeaders(_apiService.token!));
      }

      // 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        final member = Member.fromJson(responseData);
        
        return ApiResponse<Member>(
          success: true,
          message: '프로필 사진 업로드 성공',
          data: member,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse<Member>(
          success: false,
          message: errorData['detail']?.toString() ?? '프로필 사진 업로드 실패',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Member>(
        success: false,
        message: '프로필 사진 업로드 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 프로필 사진 삭제
  Future<ApiResponse<Member>> deleteProfilePhoto(int memberId) async {
    try {
      final response = await _apiService.delete<Member>(
        '${ApiConfig.members}$memberId/delete-photo',
        fromJson: (json) => Member.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<Member>(
        success: false,
        message: '프로필 사진 삭제 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 한글 초성 검색
  Future<ApiResponse<List<Member>>> searchMembersByInitials(String initials) async {
    return getMembers(search: initials);
  }

  // 상태별 교인 조회
  Future<ApiResponse<List<Member>>> getMembersByStatus(String status) async {
    return getMembers(memberStatus: status);
  }

  // 활성 교인만 조회
  Future<ApiResponse<List<Member>>> getActiveMembers() async {
    return getMembersByStatus('active');
  }

  // 비활성 교인 조회
  Future<ApiResponse<List<Member>>> getInactiveMembers() async {
    return getMembersByStatus('inactive');
  }

  // 이명 교인 조회
  Future<ApiResponse<List<Member>>> getTransferredMembers() async {
    return getMembersByStatus('transferred');
  }
}
