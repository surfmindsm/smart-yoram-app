import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_yoram_app/models/api_response.dart';

/// 회원가입 관련 서비스
class SignupService {
  final _supabase = Supabase.instance.client;

  /// 이메일 인증 코드 발송 (Supabase Edge Function 사용)
  Future<ApiResponse<void>> sendVerificationCode(String email) async {
    try {
      // 먼저 이메일 중복 체크
      final exists = await checkEmailExists(email);
      if (exists) {
        return ApiResponse<void>(
          success: false,
          message: '이미 등록된 이메일입니다. 다른 이메일을 사용해주세요.',
          data: null,
        );
      }

      // Supabase Edge Function 호출
      final response = await _supabase.functions.invoke(
        'email-verification',
        body: {
          'email': email,
          'action': 'send',
        },
      );

      print('📧 SIGNUP: 인증 코드 발송 - 상태: ${response.status}');

      if (response.status == 200) {
        final data = response.data;
        return ApiResponse<void>(
          success: data['success'] ?? true,
          message: data['message'] ?? '인증 코드가 이메일로 전송되었습니다.',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: '인증 코드 발송에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      print('❌ SIGNUP: 인증 코드 발송 오류 - $e');
      return ApiResponse<void>(
        success: false,
        message: '네트워크 오류가 발생했습니다.',
        data: null,
      );
    }
  }

  /// 이메일 인증 코드 확인 (Supabase Edge Function 사용)
  Future<ApiResponse<void>> verifyCode(String email, String code) async {
    try {
      // Supabase Edge Function 호출
      final response = await _supabase.functions.invoke(
        'email-verification',
        body: {
          'email': email,
          'action': 'verify',
          'code': code,
        },
      );

      print('✅ SIGNUP: 인증 코드 확인 - 상태: ${response.status}');

      if (response.status == 200) {
        final data = response.data;
        return ApiResponse<void>(
          success: data['success'] ?? true,
          message: data['message'] ?? '이메일 인증이 완료되었습니다.',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: '인증 코드가 올바르지 않습니다.',
          data: null,
        );
      }
    } catch (e) {
      print('❌ SIGNUP: 인증 코드 확인 오류 - $e');
      return ApiResponse<void>(
        success: false,
        message: '네트워크 오류가 발생했습니다.',
        data: null,
      );
    }
  }

  /// 이메일 중복 체크 (Supabase 직접 쿼리)
  /// users, church_applications, community_applications 테이블 모두 확인
  Future<bool> checkEmailExists(String email) async {
    try {
      // 1. users 테이블 확인
      final userExists = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (userExists != null) {
        print('🔍 SIGNUP: 이메일 중복 체크 - users 테이블에서 발견');
        return true;
      }

      // 2. church_applications 테이블 확인 (pending 또는 approved 상태)
      final churchAppExists = await _supabase
          .from('church_applications')
          .select('email')
          .eq('email', email)
          .inFilter('status', ['pending', 'approved'])
          .maybeSingle();

      if (churchAppExists != null) {
        print('🔍 SIGNUP: 이메일 중복 체크 - church_applications 테이블에서 발견');
        return true;
      }

      // 3. community_applications 테이블 확인 (pending 또는 approved 상태)
      final communityAppExists = await _supabase
          .from('community_applications')
          .select('email')
          .eq('email', email)
          .inFilter('status', ['pending', 'approved'])
          .maybeSingle();

      if (communityAppExists != null) {
        print('🔍 SIGNUP: 이메일 중복 체크 - community_applications 테이블에서 발견');
        return true;
      }

      print('🔍 SIGNUP: 이메일 중복 체크 - 중복 없음');
      return false;
    } catch (e) {
      print('❌ SIGNUP: 이메일 중복 체크 오류 - $e');
      // 오류 발생 시 안전하게 true 반환 (중복으로 간주하여 가입 차단)
      return true;
    }
  }

  /// 교회 가입 신청 (Supabase Edge Function 사용)
  Future<ApiResponse<Map<String, dynamic>>> submitChurchApplication({
    required String churchName,
    required String pastorName,
    required String adminName,
    required String email,
    required String phone,
    required String address,
    required String description,
    required bool agreeTerms,
    required bool agreePrivacy,
    required bool agreeMarketing,
    String? businessNo,
    String? website,
    String? homepageUrl,
    String? youtubeChannel,
    int? establishedYear,
    String? denomination,
    int? memberCount,
  }) async {
    try {
      // 1단계: 신청서 제출
      final response = await _supabase.functions.invoke(
        'church-applications',
        body: {
          // 필수 필드
          'church_name': churchName,
          'pastor_name': pastorName,
          'admin_name': adminName,
          'email': email,
          'phone': phone,
          'address': address,
          'description': description,
          'agree_terms': agreeTerms,
          'agree_privacy': agreePrivacy,

          // 선택 필드 (약관 동의)
          'agree_marketing': agreeMarketing,

          // 선택 필드 (기타)
          if (businessNo != null && businessNo.isNotEmpty)
            'business_no': businessNo,
          if (website != null && website.isNotEmpty)
            'website': website,
          if (homepageUrl != null && homepageUrl.isNotEmpty)
            'homepage_url': homepageUrl,
          if (youtubeChannel != null && youtubeChannel.isNotEmpty)
            'youtube_channel': youtubeChannel,
          if (establishedYear != null)
            'established_year': establishedYear,
          if (denomination != null && denomination.isNotEmpty)
            'denomination': denomination,
          if (memberCount != null)
            'member_count': memberCount,
        },
      );

      print('🏛️ SIGNUP: 교회 가입 신청 - 상태: ${response.status}');

      if (response.status == 201 || response.status == 200) {
        final data = response.data;
        final applicationId = data['data']?['application_id'];

        // 2단계: 관리자에게 알림 이메일 발송
        if (applicationId != null) {
          try {
            print('📧 SIGNUP: 관리자 알림 이메일 발송 중...');

            final notifyResponse = await _supabase.functions.invoke(
              'notify-application',
              body: {
                'type': 'church',
                'applicantEmail': email,
                'applicantName': adminName,
                'organizationName': churchName,
                'applicationId': applicationId,
              },
            );

            if (notifyResponse.status == 200) {
              print('✅ SIGNUP: 관리자 알림 이메일 발송 완료');
            } else {
              print('⚠️ SIGNUP: 관리자 알림 이메일 발송 실패 (신청은 완료됨)');
            }
          } catch (notifyError) {
            print('⚠️ SIGNUP: 알림 발송 오류 (신청은 완료됨) - $notifyError');
            // 알림 발송 실패해도 신청은 성공으로 처리
          }
        }

        return ApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? true,
          message: data['message'] ?? '신청서가 성공적으로 제출되었습니다.',
          data: data['data'],
        );
      } else if (response.status == 400) {
        final data = response.data;
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? '필수 필드가 누락되었거나 약관에 동의하지 않았습니다.',
          data: null,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: '신청서 제출에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      print('❌ SIGNUP: 교회 가입 신청 오류 - $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: '네트워크 오류가 발생했습니다.',
        data: null,
      );
    }
  }

  /// 커뮤니티 가입 신청 (Supabase Edge Function 사용)
  Future<ApiResponse<Map<String, dynamic>>> submitCommunityApplication({
    required String applicantType,
    required String organizationName,
    required String contactPerson,
    required String email,
    required String phone,
    required String description,
    required bool agreeTerms,
    required bool agreePrivacy,
    required bool agreeMarketing,
    String? businessNumber,
    String? serviceArea,
    String? address,
    String? website,
  }) async {
    try {
      // 1단계: 신청서 제출
      final response = await _supabase.functions.invoke(
        'community-applications',
        body: {
          // 필수 필드
          'applicant_type': applicantType,
          'organization_name': organizationName,
          'contact_person': contactPerson,
          'email': email,
          'phone': phone,
          'description': description,
          'agree_terms': agreeTerms,
          'agree_privacy': agreePrivacy,

          // 선택 필드 (약관 동의)
          'agree_marketing': agreeMarketing,

          // 선택 필드 (기타)
          if (businessNumber != null && businessNumber.isNotEmpty)
            'business_number': businessNumber,
          if (serviceArea != null && serviceArea.isNotEmpty)
            'service_area': serviceArea,
          if (address != null && address.isNotEmpty)
            'address': address,
          if (website != null && website.isNotEmpty)
            'website': website,
        },
      );

      print('🤝 SIGNUP: 커뮤니티 가입 신청 - 상태: ${response.status}');

      if (response.status == 201 || response.status == 200) {
        final data = response.data;
        final applicationId = data['data']?['application_id'];

        // 2단계: 관리자에게 알림 이메일 발송
        if (applicationId != null) {
          try {
            print('📧 SIGNUP: 관리자 알림 이메일 발송 중...');

            final notifyResponse = await _supabase.functions.invoke(
              'notify-application',
              body: {
                'type': 'community',
                'applicantEmail': email,
                'applicantName': contactPerson,
                'organizationName': organizationName,
                'applicationId': applicationId,
              },
            );

            if (notifyResponse.status == 200) {
              print('✅ SIGNUP: 관리자 알림 이메일 발송 완료');
            } else {
              print('⚠️ SIGNUP: 관리자 알림 이메일 발송 실패 (신청은 완료됨)');
            }
          } catch (notifyError) {
            print('⚠️ SIGNUP: 알림 발송 오류 (신청은 완료됨) - $notifyError');
            // 알림 발송 실패해도 신청은 성공으로 처리
          }
        }

        return ApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? true,
          message: data['message'] ?? '신청서가 성공적으로 제출되었습니다.',
          data: data['data'],
        );
      } else if (response.status == 400) {
        final data = response.data;
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? '필수 필드가 누락되었거나 약관에 동의하지 않았습니다.',
          data: null,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: '신청서 제출에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      print('❌ SIGNUP: 커뮤니티 가입 신청 오류 - $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: '네트워크 오류가 발생했습니다.',
        data: null,
      );
    }
  }
}
