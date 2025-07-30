class ApiConfig {
  // Supabase 기본 설정
  static const String baseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co/rest/v1';
  static const String functionsUrl = 'https://adzhdsajdamrflvybhxq.supabase.co/functions/v1';
  
  // API 엔드포인트 경로
  static const String auth = '/auth';
  static const String members = '/members';
  static const String attendance = '/attendance';
  static const String qrCodes = '/qr-codes/';
  static const String sms = '/sms';
  static const String calendar = '/calendar';
  static const String family = '/family';
  static const String excel = '/excel';
  static const String statistics = '/statistics';
  static const String users = '/users';
  static const String memberCard = '/member-card';
  
  // 헤더 설정
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // 타임아웃 설정 (초)
  static const int timeoutSeconds = 30;
}
