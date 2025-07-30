class ApiConfig {
  // 백엔드 API 설정
  static const String baseUrl = 'https://packs-holds-marc-extended.trycloudflare.com/api/v1';
  static const String swaggerDocsUrl = 'https://packs-holds-marc-extended.trycloudflare.com/docs#/';
  
  // API 엔드포인트들
  static const String authLogin = '/auth/login';
  static const String usersMe = '/users/me';
  static const String members = '/members/';
  static const String attendance = '/attendance/';
  static const String qrCodes = '/qr-codes/';
  static const String sms = '/sms/';
  static const String calendar = '/calendar/';
  static const String family = '/family/';
  static const String memberCard = '/member-card/';
  static const String excel = '/excel/';
  static const String statistics = '/statistics/';
  
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
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkemhkc2FqZGFtcmZsdnliaHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NDg5ODEsImV4cCI6MjA2OTQyNDk4MX0.pgn6M5_ihDFt3ojQmCoc3Qf8pc7LzRvQEIDT7g1nW3c';
}
