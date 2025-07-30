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
    try {
      String endpoint = '${ApiConfig.members}?skip=$skip&limit=$limit';
      
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      
      if (memberStatus != null && memberStatus.isNotEmpty) {
        endpoint += '&member_status=${Uri.encodeComponent(memberStatus)}';
      }

      final response = await _apiService.get<List<dynamic>>(endpoint);

      if (response.success && response.data != null) {
        final List<Member> members = (response.data as List)
            .map((memberJson) => Member.fromJson(memberJson))
            .toList();

        return ApiResponse<List<Member>>(
          success: true,
          message: '교인 목록 조회 성공',
          data: members,
        );
      }

      return ApiResponse<List<Member>>(
        success: false,
        message: response.message,
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<Member>>(
        success: false,
        message: '교인 목록 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 특정 교인 상세 조회
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
