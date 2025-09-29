class ApiConfig {
  // 백엔드 API 설정
  static const String baseUrl =
      'https://api.surfmind-team.com/api/v1';
  static const String swaggerDocsUrl =
      'https://api.surfmind-team.com/docs';

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

  // 심방 관리 (새 추가)
  static const String pastoralCareRequests = '/pastoral-care/requests';
  static const String pastoralCareRequestsMy = '/pastoral-care/requests/my';

  // 중보 기도 관리
  static const String prayerRequests = '/prayer-requests/';
  static const String prayerRequestsMy = '/prayer-requests/my';

  // 교회 관리
  static const String churches = '/churches/';
  static const String churchesMy = '/churches/my';

  // 출석 관리
  static const String attendances = '/attendances/';

  // 주보 관리
  static const String bulletins = '/bulletins/';

  // 공지사항 관리
  static const String announcements = '/announcements/';
  static const String announcementsCategories = '/announcements/categories';
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

  // 오늘의 말씀
  static const String dailyVerses = '/daily-verses/';
  static const String dailyVersesRandom = '/daily-verses/random';

  // 예배 서비스
  static const String worshipServices = '/worship/services';

  // 푸시 알림 관리 (API v1.0)
  static const String notifications = '/notifications/';
  static const String notificationsDevices = '/notifications/devices'; // POST: 기기 등록, GET: 기기 목록
  static const String notificationsDevicesRegister = '/notifications/devices/register'; // POST: 기기 등록
  static const String notificationsDevicesUnregister = '/notifications/devices/unregister'; // DELETE
  static const String notificationsSend = '/notifications/send'; // POST: 개별 발송
  static const String notificationsSendBatch = '/notifications/send-batch'; // POST: 다중 발송
  static const String notificationsSendChurch = '/notifications/send-church'; // POST: 교회 전체 발송
  static const String notificationsSendToChurch = '/notifications/send-church'; // POST: 교회 전체 발송 (별명)
  static const String notificationsHistory = '/notifications/history'; // GET: 발송 이력
  static const String notificationsMy = '/notifications/my'; // GET: 내 알림 목록
  static const String notificationsMyNotifications = '/notifications/my'; // GET: 내 알림 목록 (별명)
  static const String notificationsRead = '/notifications/{id}/read'; // PUT: 읽음 처리
  static const String notificationsMarkAsRead = '/notifications'; // PUT: 읽음 처리 (별명)
  static const String notificationsPreferences = '/notifications/preferences'; // GET/PUT: 알림 설정
  static const String notificationsTemplates = '/notifications/templates'; // GET: 알림 템플릿
  static const String notificationsStats = '/notifications/stats'; // GET: 알림 통계

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

// Supabase 설정 (마이그레이션 후 메인 백엔드)
class SupabaseConfig {
  static const String supabaseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkemhkc2FqZGFtcmZsdnliaHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NDg5ODEsImV4cCI6MjA2OTQyNDk4MX0.pgn6M5_ihDFt3ojQmCoc3Qf8pc7LzRvQEIDT7g1nW3c';

  // Edge Functions 기본 URL
  static String get functionsUrl => '$supabaseUrl/functions/v1';

  // Edge Function 엔드포인트들
  static const String membersFunction = '/members';
  static const String announcementsFunction = '/announcements';
  static const String bulletinsFunction = '/bulletins';
  static const String offeringsFunction = '/offerings';
  static const String communityFunction = '/community-sharing';
  static const String requestsFunction = '/community-requests';
  static const String wishlistsFunction = '/wishlists';
  static const String musicSeekersFunction = '/music-seekers';
  static const String worshipServicesFunction = '/worship-services';
  static const String statisticsFunction = '/statistics';
  static const String sendSmsFunction = '/send-sms';
  static const String emailVerificationFunction = '/email-verification';
  static const String dailyVersesFunction = '/daily-verses';
  static const String pastoralCareFunction = '/pastoral-care-requests';
}
