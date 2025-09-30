class NaverMapConfig {
  // 네이버 지도 SDK용 Client ID
  static const String clientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: 'l1xephxcbw', // 개발용 기본값
  );

  // Naver Cloud Platform - Maps API (지오코딩/역지오코딩용)
  static const String apiKeyId = String.fromEnvironment(
    'NAVER_MAP_API_KEY_ID',
    defaultValue: 'l1xephxcbw', // Application Client ID
  );

  static const String apiKey = String.fromEnvironment(
    'NAVER_MAP_API_KEY',
    defaultValue: 'CRgYzEOXbNFKYliOaulz67H58ZRhNEjdN9d6gVlp', // Application Client Secret
  );

  // Naver Search API (Local Search용)
  // 주소/장소 검색에 사용 - 정확하지 않은 검색어도 처리 가능
  static const String searchClientId = String.fromEnvironment(
    'NAVER_SEARCH_CLIENT_ID',
    defaultValue: 'XhQe4Qqod7ELUMhv0Es6', // Search API Client ID
  );

  static const String searchClientSecret = String.fromEnvironment(
    'NAVER_SEARCH_CLIENT_SECRET',
    defaultValue: '1TBE08_iug', // Search API Client Secret
  );

  // Naver Cloud Platform Maps API 엔드포인트
  static const String geocodeUrl =
      'https://maps.apigw.ntruss.com/map-geocode/v2/geocode';
  static const String reverseGeocodeUrl =
      'https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc';

  // Naver Open API 엔드포인트
  static const String searchLocalUrl =
      'https://openapi.naver.com/v1/search/local.json';
}
