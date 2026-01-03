import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/member.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// 교인 서비스 (Supabase Edge Function 사용)
class MemberService {
  static final MemberService _instance = MemberService._internal();
  factory MemberService() => _instance;
  MemberService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  // 교인 목록 캐시
  List<Member>? _cachedMembers;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 10);

  // 조직 계층 구조 캐시 (organizationId -> 계층 경로)
  final Map<String, String> _organizationPathCache = {};

  /// 캐시 무효화
  void invalidateCache() {
    _cachedMembers = null;
    _cacheTimestamp = null;
    print('🗑️ MEMBER_SERVICE: 캐시 무효화됨');
  }

  /// 조직 경로 캐시 무효화
  void invalidateOrganizationCache() {
    _organizationPathCache.clear();
    print('🗑️ MEMBER_SERVICE: 조직 경로 캐시 무효화됨');
  }

  /// 조직 계층 구조 경로 조회 (캐싱 포함)
  Future<String?> getOrganizationPath(String organizationId) async {
    // 캐시 확인
    if (_organizationPathCache.containsKey(organizationId)) {
      print('✨ MEMBER_SERVICE: 캐시된 조직 경로 반환 - $organizationId');
      return _organizationPathCache[organizationId];
    }

    try {
      final supabase = _supabaseService.client;

      // 현재 조직 정보 조회
      final response = await supabase
          .from('church_organizations')
          .select('*')
          .eq('id', organizationId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      // 계층 구조 경로 생성
      final path = await _buildOrganizationPath(response);

      // 캐시에 저장
      _organizationPathCache[organizationId] = path;
      print('💾 MEMBER_SERVICE: 조직 경로 캐시에 저장 - $organizationId: $path');

      return path;
    } catch (e) {
      print('❌ MEMBER_SERVICE: 조직 경로 조회 실패 - $e');
      return null;
    }
  }

  /// 조직 계층 구조를 따라 올라가며 경로 생성 (예: 1교구 > 2구역 > 4셀)
  Future<String> _buildOrganizationPath(Map<String, dynamic> organization) async {
    final supabase = _supabaseService.client;
    final List<String> pathParts = [];

    // 현재 조직명 추가
    final currentName = organization['name'] ?? organization['organization_name'] ?? organization['org_name'];
    if (currentName != null) {
      pathParts.insert(0, currentName as String);
    }

    // parent_id를 따라 상위 조직 탐색
    var parentId = organization['parent_id'];
    while (parentId != null) {
      try {
        final parentResponse = await supabase
            .from('church_organizations')
            .select('*')
            .eq('id', parentId)
            .maybeSingle();

        if (parentResponse != null) {
          final parentName = parentResponse['name'] ?? parentResponse['organization_name'] ?? parentResponse['org_name'];
          if (parentName != null) {
            pathParts.insert(0, parentName as String);
          }
          parentId = parentResponse['parent_id'];
        } else {
          break;
        }
      } catch (e) {
        print('❌ MEMBER_SERVICE: 상위 조직 조회 실패 (parent_id: $parentId): $e');
        break;
      }
    }

    // ' > ' 구분자로 연결
    return pathParts.join(' > ');
  }

  /// 교인 목록 조회 (Supabase Edge Function)
  Future<ApiResponse<List<Member>>> getMembers({
    int page = 1,
    int limit = 100,
    String? search,
    String? memberStatus,
  }) async {
    try {
      // 캐시 확인 (검색/필터가 없고 첫 페이지일 때만)
      if (page == 1 && search == null && memberStatus == null) {
        if (_cachedMembers != null && _cacheTimestamp != null) {
          final now = DateTime.now();
          if (now.difference(_cacheTimestamp!) < _cacheDuration) {
            print('✨ MEMBER_SERVICE: 캐시된 교인 목록 반환 (${_cachedMembers!.length}명)');
            return ApiResponse<List<Member>>(
              success: true,
              message: '교인 목록 조회 성공 (캐시)',
              data: _cachedMembers!,
            );
          } else {
            print('⏰ MEMBER_SERVICE: 캐시 만료됨');
          }
        }
      }

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse<List<Member>>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: [],
        );
      }

      final user = userResponse.data!;
      print('📁 MEMBER_SERVICE: 사용자 정보 - ID: ${user.id}, Church ID: ${user.churchId}');

      // 직접 members 테이블 조회
      var query = _supabaseService.client
          .from('members')
          .select('*')
          .eq('church_id', user.churchId);

      print('📁 MEMBER_SERVICE: members 테이블 조회 시작 - church_id: ${user.churchId}');

      // 검색 필터 적용
      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,phone.ilike.%$search%');
      }

      // 상태 필터 적용
      if (memberStatus != null && memberStatus != 'all') {
        query = query.eq('member_status', memberStatus);
      }

      // 페이징 적용
      final offset = (page - 1) * limit;
      print('📁 MEMBER_SERVICE: 페이징 - offset: $offset, limit: $limit');

      final response = await query.range(offset, offset + limit - 1);

      print('📁 MEMBER_SERVICE: Supabase 응답 타입: ${response.runtimeType}');
      print('📁 MEMBER_SERVICE: Supabase 응답 길이: ${response is List ? response.length : 'null'}');
      if (response is List && response.isNotEmpty) {
        print('📁 MEMBER_SERVICE: 첫 번째 항목: ${response.first}');
      }

      final List<Member> members = (response as List)
          .map((item) => Member.fromJson(item as Map<String, dynamic>))
          .toList();

      print('📁 MEMBER_SERVICE: 파싱된 교인 수: ${members.length}');
      if (members.isNotEmpty) {
        print('📁 MEMBER_SERVICE: 첫 번째 교인 - 이름: ${members.first.name}, position_main: ${members.first.positionMain}, position_detail: ${members.first.positionDetail}');

        // 교회학교 교인 수 확인 (position_main = 'CHURCH_SCHOOL')
        final churchSchoolMembers = members.where((m) => m.positionMain == 'CHURCH_SCHOOL').toList();
        print('📁 MEMBER_SERVICE: 교회학교(CHURCH_SCHOOL) 교인 수: ${churchSchoolMembers.length}');

        // position_main 분포 출력
        final positionMainCount = <String, int>{};
        for (var member in members) {
          final posMain = member.positionMain ?? 'MEMBER';
          positionMainCount[posMain] = (positionMainCount[posMain] ?? 0) + 1;
        }
        print('📁 MEMBER_SERVICE: position_main 분포: $positionMainCount');

        // 교회학교 세부 분포 (position_detail)
        if (churchSchoolMembers.isNotEmpty) {
          final detailCount = <String, int>{};
          for (var member in churchSchoolMembers) {
            final detail = member.positionDetail ?? 'null';
            detailCount[detail] = (detailCount[detail] ?? 0) + 1;
          }
          print('📁 MEMBER_SERVICE: 교회학교 세부 분포 (position_detail): $detailCount');
        }
      }

      // 캐시에 저장 (검색/필터가 없고 첫 페이지일 때만)
      if (page == 1 && search == null && memberStatus == null) {
        _cachedMembers = members;
        _cacheTimestamp = DateTime.now();
        print('💾 MEMBER_SERVICE: 교인 목록 캐시에 저장 (${members.length}명)');
      }

      return ApiResponse<List<Member>>(
        success: true,
        message: '교인 목록 조회 성공',
        data: members,
      );
    } catch (e, stackTrace) {
      print('❌ MEMBER_SERVICE: 교인 목록 조회 실패');
      print('❌ 에러: $e');
      print('❌ 스택 트레이스: $stackTrace');
      return ApiResponse<List<Member>>(
        success: false,
        message: '교인 목록 조회 실패: ${e.toString()}',
        data: [],
      );
    }
  }

  /// 특정 교인 상세 조회 (직접 테이블 조회)
  Future<ApiResponse<Member>> getMember(int memberId) async {
    try {
      final response = await _supabaseService.client
          .from('members')
          .select('*')
          .eq('id', memberId)
          .single();

      final member = Member.fromJson(response);

      return ApiResponse<Member>(
        success: true,
        message: '교인 정보 조회 성공',
        data: member,
      );
    } catch (e) {
      return ApiResponse<Member>(
        success: false,
        message: '교인 정보 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// user_id로 교인 조회 (직접 DB 조회)
  Future<ApiResponse<Member>> getMemberByUserId(int userId) async {
    try {
      print('👤 MEMBER_SERVICE: user_id로 교인 조회 시작 - userId: $userId');

      // members 테이블에서 user_id로 직접 조회
      final response = await _supabaseService.client
          .from('members')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      print('👤 MEMBER_SERVICE: DB 응답: $response');

      if (response != null) {
        final member = Member.fromJson(response as Map<String, dynamic>);

        print('✅ MEMBER_SERVICE: 교인 정보 조회 성공');
        print('  - ID: ${member.id}');
        print('  - 이름: ${member.name}');
        print('  - 이메일: ${member.email}');
        print('  - 프로필 이미지: ${member.profilePhotoUrl}');

        return ApiResponse<Member>(
          success: true,
          message: '교인 정보 조회 성공',
          data: member,
        );
      } else {
        print('❌ MEMBER_SERVICE: user_id에 해당하는 교인 정보 없음');
        return ApiResponse<Member>(
          success: false,
          message: 'user_id에 해당하는 교인 정보를 찾을 수 없습니다',
          data: null,
        );
      }
    } catch (e) {
      print('❌ MEMBER_SERVICE: user_id로 교인 조회 실패 - $e');
      return ApiResponse<Member>(
        success: false,
        message: 'user_id로 교인 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 교인 정보 수정 (직접 테이블 수정)
  Future<ApiResponse<Member>> updateMember(
    int memberId,
    Map<String, dynamic> memberData,
  ) async {
    try {
      print('📝 MEMBER_SERVICE: 교인 정보 수정 시작 - memberId: $memberId');

      final response = await _supabaseService.client
          .from('members')
          .update(memberData)
          .eq('id', memberId)
          .select()
          .single();

      final member = Member.fromJson(response);

      print('✅ MEMBER_SERVICE: 교인 정보 수정 성공');

      // 캐시 무효화
      invalidateCache();

      return ApiResponse<Member>(
        success: true,
        message: '교인 정보 수정 성공',
        data: member,
      );
    } catch (e) {
      print('❌ MEMBER_SERVICE: 교인 정보 수정 실패 - $e');
      return ApiResponse<Member>(
        success: false,
        message: '교인 정보 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 교인 추가 (직접 테이블 삽입)
  Future<ApiResponse<Member>> createMember(
    Map<String, dynamic> memberData,
  ) async {
    try {
      print('➕ MEMBER_SERVICE: 교인 추가 시작 - 데이터: $memberData');

      final response = await _supabaseService.client
          .from('members')
          .insert(memberData)
          .select()
          .single();

      final member = Member.fromJson(response);

      print('✅ MEMBER_SERVICE: 교인 추가 성공');

      // 캐시 무효화
      invalidateCache();

      return ApiResponse<Member>(
        success: true,
        message: '교인이 추가되었습니다',
        data: member,
      );
    } catch (e) {
      print('❌ MEMBER_SERVICE: 교인 추가 실패 - $e');
      return ApiResponse<Member>(
        success: false,
        message: '교인 추가 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 교인 상태 변경 (직접 테이블 수정)
  Future<ApiResponse<Member>> updateMemberStatus({
    required int memberId,
    required String status,
  }) async {
    try {
      print('📝 MEMBER_SERVICE: 교인 상태 변경 시작 - memberId: $memberId, status: $status');

      final response = await _supabaseService.client
          .from('members')
          .update({'member_status': status})
          .eq('id', memberId)
          .select()
          .single();

      final member = Member.fromJson(response);

      print('✅ MEMBER_SERVICE: 교인 상태 변경 성공');

      // 캐시 무효화
      invalidateCache();

      return ApiResponse<Member>(
        success: true,
        message: '교인 상태가 변경되었습니다',
        data: member,
      );
    } catch (e) {
      print('❌ MEMBER_SERVICE: 교인 상태 변경 실패 - $e');
      return ApiResponse<Member>(
        success: false,
        message: '교인 상태 변경 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 교인 삭제 (Supabase Edge Function 사용)
  /// 웹 admin-dashboard와 동일한 방식으로 처리:
  /// - inviter 참조 제거 (다른 교인이 이 교인을 인도자로 참조하는 경우)
  /// - 연관 테이블 데이터 삭제 (member_contacts, sacraments, transfers, member_vehicles)
  /// - 인증 계정 삭제 (auth.users, users)
  /// - 최종 교인 레코드 삭제 (Hard Delete)
  Future<ApiResponse<bool>> deleteMember(int memberId) async {
    try {
      print('🗑️ MEMBER_SERVICE: 교인 삭제 시작 - memberId: $memberId');

      // 1. 먼저 이 교인을 인도자로 참조하는 다른 교인들의 참조를 NULL로 설정
      print('🔗 MEMBER_SERVICE: inviter 참조 제거 중...');
      await _supabaseService.client
          .from('members')
          .update({'inviter1_member_id': null})
          .eq('inviter1_member_id', memberId);

      await _supabaseService.client
          .from('members')
          .update({'inviter2_member_id': null})
          .eq('inviter2_member_id', memberId);

      await _supabaseService.client
          .from('members')
          .update({'inviter3_member_id': null})
          .eq('inviter3_member_id', memberId);

      print('✅ MEMBER_SERVICE: inviter 참조 제거 완료');

      // 2. 현재 사용자 정보 가져오기 (인증 토큰 생성용)
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse<bool>(
          success: false,
          message: '사용자 인증 실패: ${userResponse.message}',
          data: false,
        );
      }

      final userId = userResponse.data!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 3. Supabase Edge Function URL 구성
      final url = Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/members?id=$memberId');

      print('🌐 MEMBER_SERVICE: Edge Function 호출 - URL: $url');

      // HTTP DELETE 요청 (웹과 동일한 방식)
      final response = await http.delete(
        url,
        headers: {
          'X-Custom-Auth': 'temp_token_${userId}_$timestamp',
          'Authorization': 'Bearer ${_supabaseService.client.auth.currentSession?.accessToken ?? ''}',
          'Content-Type': 'application/json',
        },
      );

      print('📡 MEMBER_SERVICE: 응답 상태 코드 - ${response.statusCode}');
      print('📡 MEMBER_SERVICE: 응답 본문 - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          print('✅ MEMBER_SERVICE: 교인 삭제 성공 (완전 삭제)');
          print('   - ${responseData['message']}');

          // 캐시 무효화
          invalidateCache();

          return ApiResponse<bool>(
            success: true,
            message: responseData['message'] ?? '교인이 완전히 삭제되었습니다',
            data: true,
          );
        } else {
          print('❌ MEMBER_SERVICE: 교인 삭제 실패 - ${responseData['message']}');
          return ApiResponse<bool>(
            success: false,
            message: responseData['message'] ?? '교인 삭제에 실패했습니다',
            data: false,
          );
        }
      } else {
        print('❌ MEMBER_SERVICE: HTTP 오류 - 상태 코드: ${response.statusCode}');
        return ApiResponse<bool>(
          success: false,
          message: '교인 삭제 요청 실패 (HTTP ${response.statusCode})',
          data: false,
        );
      }
    } catch (e, stackTrace) {
      print('❌ MEMBER_SERVICE: 교인 삭제 중 오류 발생 - $e');
      print('❌ 스택 트레이스: $stackTrace');
      return ApiResponse<bool>(
        success: false,
        message: '교인 삭제 중 오류가 발생했습니다: ${e.toString()}',
        data: false,
      );
    }
  }

  /// 교인 초대 (Supabase Edge Function)
  Future<ApiResponse<Map<String, dynamic>>> inviteMember({
    required String email,
    required int churchId,
    String? role,
    String? fullName,
  }) async {
    try {
      final response = await _supabaseService.invokeFunction<Map<String, dynamic>>(
        SupabaseConfig.membersFunction,
        body: {
          'action': 'invite_member',
          'email': email,
          'church_id': churchId,
          if (role != null) 'role': role,
          if (fullName != null) 'full_name': fullName,
        },
        fromJson: (json) => json,
      );

      return ApiResponse<Map<String, dynamic>>(
        success: response.success,
        message: response.message,
        data: response.data,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: '교인 초대 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 모바일 프로필 이미지 업로드 (Supabase Storage 사용)
  Future<ApiResponse<Member>> uploadMobileProfileImage({
    required int memberId,
    required File imageFile,
  }) async {
    try {
      print('📸 MEMBER_SERVICE: 모바일 프로필 이미지 업로드 시작 - memberId: $memberId');

      // 파일 확장자 추출
      final extension = imageFile.path.split('.').last;
      final fileName = 'mobile-profiles/$memberId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Supabase Storage에 이미지 업로드 (member-photos 버킷의 mobile-profiles 폴더에 저장)
      final uploadPath = await _supabaseService.client.storage
          .from('member-photos')
          .upload(fileName, imageFile);

      print('✅ MEMBER_SERVICE: 이미지 업로드 성공 - 경로: $uploadPath');

      // Public URL 생성
      final publicUrl = _supabaseService.client.storage
          .from('member-photos')
          .getPublicUrl(fileName);

      print('🔗 MEMBER_SERVICE: Public URL 생성 - $publicUrl');

      // Member 테이블의 mobile_profile_image_url 업데이트
      final response = await _supabaseService.client
          .from('members')
          .update({'mobile_profile_image_url': fileName})
          .eq('id', memberId)
          .select()
          .single();

      final member = Member.fromJson(response);

      print('✅ MEMBER_SERVICE: 모바일 프로필 이미지 업데이트 성공');

      return ApiResponse<Member>(
        success: true,
        message: '프로필 이미지가 업데이트되었습니다',
        data: member,
      );
    } catch (e) {
      print('❌ MEMBER_SERVICE: 모바일 프로필 이미지 업로드 실패 - $e');
      return ApiResponse<Member>(
        success: false,
        message: '프로필 이미지 업로드 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 기존 프로필 이미지를 모바일 프로필 이미지로 설정
  Future<ApiResponse<Member>> setMobileProfileImageToExisting(int memberId) async {
    try {
      print('🔄 MEMBER_SERVICE: 기존 프로필 이미지를 모바일 프로필로 설정 - memberId: $memberId');

      // 기존 프로필 이미지 URL을 가져오기
      final memberResponse = await getMember(memberId);
      if (!memberResponse.success || memberResponse.data == null) {
        return ApiResponse<Member>(
          success: false,
          message: '교인 정보를 찾을 수 없습니다',
          data: null,
        );
      }

      final member = memberResponse.data!;
      if (member.profilePhotoUrl == null || member.profilePhotoUrl!.isEmpty) {
        return ApiResponse<Member>(
          success: false,
          message: '기존 프로필 이미지가 없습니다',
          data: null,
        );
      }

      // mobile_profile_image_url을 null로 설정 (기존 이미지 사용을 의미)
      final response = await _supabaseService.client
          .from('members')
          .update({'mobile_profile_image_url': null})
          .eq('id', memberId)
          .select()
          .single();

      final updatedMember = Member.fromJson(response);

      print('✅ MEMBER_SERVICE: 기존 프로필 이미지로 설정 완료');

      return ApiResponse<Member>(
        success: true,
        message: '기존 프로필 이미지를 사용합니다',
        data: updatedMember,
      );
    } catch (e) {
      print('❌ MEMBER_SERVICE: 기존 프로필 이미지 설정 실패 - $e');
      return ApiResponse<Member>(
        success: false,
        message: '프로필 이미지 설정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 자기 자신의 교인 정보 수정 (본인만 수정 가능한 필드만)
  /// 수정 불가 필드: name, email, position_main, position_detail
  Future<ApiResponse<Member>> updateMyMemberInfo(Map<String, dynamic> memberData) async {
    try {
      print('📝 MEMBER_SERVICE: 자기 교인 정보 수정 시작');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse<Member>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: null,
        );
      }

      final userId = userResponse.data!.id;

      // user_id로 교인 정보 조회
      final memberResponse = await getMemberByUserId(userId);
      if (!memberResponse.success || memberResponse.data == null) {
        return ApiResponse<Member>(
          success: false,
          message: '교인 정보를 찾을 수 없습니다',
          data: null,
        );
      }

      final memberId = memberResponse.data!.id;

      // 수정 불가 필드 제거 (보안상 중요)
      memberData.remove('name');
      memberData.remove('email');
      memberData.remove('position_main');
      memberData.remove('position_detail');
      memberData.remove('id');
      memberData.remove('church_id');
      memberData.remove('user_id');
      memberData.remove('created_at');
      memberData.remove('updated_at');
      memberData.remove('member_status');
      memberData.remove('status');

      // 교인 정보 업데이트
      final response = await _supabaseService.client
          .from('members')
          .update(memberData)
          .eq('id', memberId)
          .select()
          .single();

      final member = Member.fromJson(response);

      print('✅ MEMBER_SERVICE: 자기 교인 정보 수정 성공');

      // 캐시 무효화
      invalidateCache();

      return ApiResponse<Member>(
        success: true,
        message: '개인정보가 성공적으로 수정되었습니다',
        data: member,
      );
    } catch (e) {
      print('❌ MEMBER_SERVICE: 자기 교인 정보 수정 실패 - $e');
      return ApiResponse<Member>(
        success: false,
        message: '개인정보 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }
}