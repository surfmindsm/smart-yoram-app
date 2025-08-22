class NaverMapConfig {
  // 네이버 지도 SDK용 Client ID
  static const String clientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: 'l1xephxcbw', // 개발용 기본값
  );

  // Application 방식 인증키 (지오코딩/역지오코딩용)
  // 기존 Application 사용 (Geocoding 서비스 추가 필요)
  static const String apiKeyId = String.fromEnvironment(
    'NAVER_MAP_API_KEY_ID',
    defaultValue: 'l1xephxcbw', // Application Client ID
  );

  static const String apiKey = String.fromEnvironment(
    'NAVER_MAP_API_KEY',
    defaultValue: 'CRgYzEOXbNFKYliOaulz67H58ZRhNEjdN9d6gVlp', // Application Client Secret
  );

  // Naver Cloud Platform Maps API 엔드포인트
  static const String geocodeUrl =
      'https://maps.apigw.ntruss.com/map-geocode/v2/geocode';
  static const String reverseGeocodeUrl =
      'https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc';
}
