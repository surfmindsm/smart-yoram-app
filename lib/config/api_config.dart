class ApiConfig {
  // 백엔드 API 설정
  static const String baseUrl =
      'https://packs-holds-marc-extended.trycloudflare.com/api/v1';
  static const String swaggerDocsUrl =
      'https://packs-holds-marc-extended.trycloudflare.com/docs#/';

  // API 엔드포인트 경로
  // 인증 및 사용자 관리
  static const String authLogin = '/auth/login/access-token';
  static const String authTestToken = '/auth/test-token';
  
  // 멤버 인증 (새 API)
  static const String authMemberLogin = '/auth/member/login';
  static const String authMemberLoginAccessToken = '/auth/member/login/access-token';
  static const String authMemberPasswordResetRequest = '/auth/member/password-reset-request';
  static const String authMemberChangePassword = '/auth/member/change-password';
  static const String users = '/users/';
  static const String usersMe = '/users/me';
  static const String usersUpdateFirstLogin = '/users/me/update-first-login';

  // 교인 관리
  static const String members = '/members/';
  static const String membersUploadPhoto = '/members/{member_id}/upload-photo';
  static const String membersDeletePhoto = '/members/{member_id}/delete-photo';

  // 출석 관리
  static const String attendances = '/attendances/';

  // 주보 관리
  static const String bulletins = '/bulletins/';

  // 공지사항 관리
  static const String announcements = '/announcements/';
  static const String announcementsTogglePin = '/announcements/{id}/toggle-pin';

  // QR 코드 관리
  static const String qrCodes = '/qr-codes/';
  static const String qrCodesGenerate = '/qr-codes/generate/{member_id}';
  static const String qrCodesImage = '/qr-codes/{code}/image';
  static const String qrCodesVerify = '/qr-codes/verify/{code}';
  static const String qrCodesMember = '/qr-codes/member/{member_id}';

  // SMS 발송
  static const String sms = '/sms/';
  static const String smsSend = '/sms/send';
  static const String smsSendBulk = '/sms/send-bulk';
  static const String smsHistory = '/sms/history';
  static const String smsTemplates = '/sms/templates';

  // 일정 관리
  static const String calendar = '/calendar/';
  static const String calendarBirthdays = '/calendar/birthdays';
  static const String calendarBirthdaysCreate =
      '/calendar/birthdays/create-events';

  // 가족 관계 관리
  static const String family = '/family/';
  static const String familyRelationships = '/family/relationships';
  static const String familyTree = '/family/tree/{member_id}';

  // 모바일 교인증
  static const String memberCard = '/member-card/';
  static const String memberCardData = '/member-card/{member_id}/card';
  static const String memberCardHtml = '/member-card/{member_id}/card/html';
  static const String memberCardRegenerateQr =
      '/member-card/{member_id}/card/regenerate-qr';

  // 엑셀 연동
  static const String excel = '/excel/';
  static const String excelMembersUpload = '/excel/members/upload';
  static const String excelMembersDownload = '/excel/members/download';
  static const String excelMembersTemplate = '/excel/members/template';
  static const String excelAttendanceDownload = '/excel/attendance/download';

  // 통계 및 리포트
  static const String statistics = '/statistics/';
  static const String statisticsAttendanceSummary =
      '/statistics/attendance/summary';
  static const String statisticsAttendanceByMember =
      '/statistics/attendance/by-member';
  static const String statisticsMembersDemographics =
      '/statistics/members/demographics';
  static const String statisticsMembersGrowth = '/statistics/members/growth';

  // HTTP 헤더들
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Map<String, String> formHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json',
  };

  // 토큰 헤더 생성
  static Map<String, String> authHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // 멀티파트 폼 헤더 생성
  static Map<String, String> multipartHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
    };
  }
}

// 레거시 Supabase 설정 (필요시 사용)
class SupabaseConfig {
  static const String supabaseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkemhkc2FqZGFtcmZsdnliaHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NDg5ODEsImV4cCI6MjA2OTQyNDk4MX0.pgn6M5_ihDFt3ojQmCoc3Qf8pc7LzRvQEIDT7g1nW3c';
}
