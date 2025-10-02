import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_yoram_app/config/api_config.dart';
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
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      print('🔍 SIGNUP: 이메일 중복 체크 - 결과: ${response != null}');

      return response != null;
    } catch (e) {
      print('❌ SIGNUP: 이메일 중복 체크 오류 - $e');
      return false;
    }
  }

  /// 교회 가입 신청
  Future<ApiResponse<Map<String, dynamic>>> submitChurchApplication({
    required String churchName,
    required String pastorName,
    required String adminName,
    required String email,
    required String phone,
    required String address,
    required bool agreeTerms,
    required bool agreePrivacy,
    required bool agreeMarketing,
    String? website,
    int? establishedYear,
    String? denomination,
    int? memberCount,
    List<File>? attachments,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/church/applications');

      // FormData 생성
      final request = http.MultipartRequest('POST', url);

      // 필수 필드
      request.fields['church_name'] = churchName;
      request.fields['pastor_name'] = pastorName;
      request.fields['admin_name'] = adminName;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['address'] = address;
      request.fields['description'] = ''; // 빈 문자열
      request.fields['agree_terms'] = agreeTerms.toString();
      request.fields['agree_privacy'] = agreePrivacy.toString();
      request.fields['agree_marketing'] = agreeMarketing.toString();

      // 선택 필드
      if (website != null && website.isNotEmpty) {
        request.fields['website'] = website;
      }
      if (establishedYear != null) {
        request.fields['established_year'] = establishedYear.toString();
      }
      if (denomination != null && denomination.isNotEmpty) {
        request.fields['denomination'] = denomination;
      }
      if (memberCount != null) {
        request.fields['member_count'] = memberCount.toString();
      }

      // 첨부파일
      if (attachments != null && attachments.isNotEmpty) {
        for (var i = 0; i < attachments.length; i++) {
          final file = attachments[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'attachments',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      print('🏛️ SIGNUP: 교회 가입 신청 전송');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🏛️ SIGNUP: 교회 가입 신청 응답 - 상태: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? true,
          message: '교회 가입 신청이 성공적으로 제출되었습니다.',
          data: data['data'],
        );
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: error['message'] ?? '입력 데이터 검증에 실패했습니다.',
          data: null,
        );
      } else if (response.statusCode == 413) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: '첨부파일 크기가 너무 큽니다. 파일 크기를 줄이거나 개수를 줄여주세요.',
          data: null,
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: error['message'] ?? '가입 신청 중 오류가 발생했습니다.',
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

  /// 커뮤니티 가입 신청
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
    List<File>? attachments,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/community/applications');

      // FormData 생성
      final request = http.MultipartRequest('POST', url);

      // 필수 필드
      request.fields['applicant_type'] = applicantType;
      request.fields['organization_name'] = organizationName;
      request.fields['contact_person'] = contactPerson;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['description'] = description;
      request.fields['agree_terms'] = agreeTerms.toString();
      request.fields['agree_privacy'] = agreePrivacy.toString();
      request.fields['agree_marketing'] = agreeMarketing.toString();

      // 임시 비밀번호 (승인 후 실제 비밀번호 발송)
      request.fields['password'] = 'temp_password_will_be_sent_after_approval';

      // 선택 필드
      if (businessNumber != null && businessNumber.isNotEmpty) {
        request.fields['business_number'] = businessNumber;
      }
      if (serviceArea != null && serviceArea.isNotEmpty) {
        request.fields['service_area'] = serviceArea;
      }
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      if (website != null && website.isNotEmpty) {
        request.fields['website'] = website;
      }

      // 첨부파일
      if (attachments != null && attachments.isNotEmpty) {
        for (var i = 0; i < attachments.length; i++) {
          final file = attachments[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'attachments',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      print('🤝 SIGNUP: 커뮤니티 가입 신청 전송');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🤝 SIGNUP: 커뮤니티 가입 신청 응답 - 상태: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: data['success'] ?? true,
          message: '커뮤니티 이용 신청이 성공적으로 제출되었습니다.',
          data: data['data'],
        );
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: error['message'] ?? '입력 데이터 검증에 실패했습니다.',
          data: null,
        );
      } else if (response.statusCode == 413) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: '첨부파일 크기가 너무 큽니다. 파일 크기를 줄이거나 개수를 줄여주세요.',
          data: null,
        );
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: error['message'] ?? '가입 신청 중 오류가 발생했습니다.',
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
