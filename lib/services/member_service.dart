import 'dart:io';
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

  /// 교인 목록 조회 (Supabase Edge Function)
  Future<ApiResponse<List<Member>>> getMembers({
    int page = 1,
    int limit = 100,
    String? search,
    String? memberStatus,
  }) async {
    try {
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
        query = query.or('full_name.ilike.%$search%,email.ilike.%$search%');
      }

      // 상태 필터 적용
      if (memberStatus != null && memberStatus != 'all') {
        query = query.eq('status', memberStatus);
      }

      // 페이징 적용
      final offset = (page - 1) * limit;
      final response = await query.range(offset, offset + limit - 1);

      print('📁 MEMBER_SERVICE: Supabase 응답 타입: ${response.runtimeType}');
      print('📁 MEMBER_SERVICE: Supabase 응답 데이터: $response');

      final List<Member> members = (response as List)
          .map((item) => Member.fromJson(item as Map<String, dynamic>))
          .toList();

      print('📁 MEMBER_SERVICE: 파싱된 교인 수: ${members.length}');

      return ApiResponse<List<Member>>(
        success: true,
        message: '교인 목록 조회 성공',
        data: members,
      );
    } catch (e) {
      return ApiResponse<List<Member>>(
        success: true,
        message: '교인 목록을 찾을 수 없습니다',
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

  /// 교인 삭제 (직접 테이블 삭제)
  Future<ApiResponse<bool>> deleteMember(int memberId) async {
    try {
      print('🗑️ MEMBER_SERVICE: 교인 삭제 시작 - memberId: $memberId');

      await _supabaseService.client
          .from('members')
          .delete()
          .eq('id', memberId);

      print('✅ MEMBER_SERVICE: 교인 삭제 성공');

      return ApiResponse<bool>(
        success: true,
        message: '교인이 삭제되었습니다',
        data: true,
      );
    } catch (e) {
      print('❌ MEMBER_SERVICE: 교인 삭제 실패 - $e');
      return ApiResponse<bool>(
        success: false,
        message: '교인 삭제 실패: ${e.toString()}',
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
}