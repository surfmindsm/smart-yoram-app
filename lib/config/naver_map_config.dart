class NaverMapConfig {
  // 네이버 지도 SDK용 Client ID
  static const String clientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: 'l1xephxcbw', // 개발용 기본값
  );

  // Naver Open API 게이트웨이 키 (지오코딩/역지오코딩용)
  // 지도 SDK와 동일한 키 사용
  static const String apiKeyId = String.fromEnvironment(
    'NAVER_MAP_API_KEY_ID',
    defaultValue: 'l1xephxcbw', // Client ID와 동일
  );

  static const String apiKey = String.fromEnvironment(
    'NAVER_MAP_API_KEY',
    defaultValue: 'CRgYzEOXbNFKYliOaulz67H58ZRhNEjdN9d6gVlp', // Client Secret
  );

  // Naver Cloud Platform Maps API 엔드포인트
  static const String geocodeUrl =
      'https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode';
  static const String reverseGeocodeUrl =
      'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc';
}
