import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/naver_map_config.dart';
import '../models/api_response.dart';

class GeoAddress {
  final String address;
  final double latitude;
  final double longitude;

  GeoAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'GeoAddress(address: $address, lat: $latitude, lng: $longitude)';
}

class GeocodingService {
  static Map<String, String> _headers() {
    // 네이버 클라우드 플랫폼 API 게이트웨이 헤더
    return {
      'X-NCP-APIGW-API-KEY-ID': NaverMapConfig.apiKeyId,
      'X-NCP-APIGW-API-KEY': NaverMapConfig.apiKey,
      'User-Agent': 'SmartYoramApp/1.0 (com.surfmind.yoram)', // 앱 식별용
    };
  }

  static bool _hasValidKeys() {
    return NaverMapConfig.apiKeyId.isNotEmpty && NaverMapConfig.apiKey.isNotEmpty;
  }

  /// 주소 문자열을 좌표로 변환 (Forward Geocoding)
  /// 1차: Geocoding API 시도 (정확한 주소용)
  /// 2차 fallback: Local Search API 시도 (부정확한 검색어용)
  static Future<ApiResponse<GeoAddress>> geocode(String query) async {
    try {
      print('🔍 GEOCODING_SERVICE: 지오코딩 요청 - "$query"');

      if (!_hasValidKeys()) {
        return ApiResponse.error('Naver Open API 키가 설정되지 않았습니다.');
      }

      // 1차 시도: Geocoding API (정확한 주소)
      final geocodingResult = await _tryGeocoding(query);
      if (geocodingResult.success) {
        return geocodingResult;
      }

      print('🔄 GEOCODING_SERVICE: Geocoding 실패, Local Search 시도');

      // 2차 시도: Local Search API (부정확한 검색어)
      final searchResult = await _tryLocalSearch(query);
      if (searchResult.success) {
        return searchResult;
      }

      // 모두 실패
      return ApiResponse.error('주소를 찾을 수 없습니다: "$query"\n\n구체적인 장소명, 건물명 또는 완전한 도로명 주소를 입력해주세요.\n\n예시:\n• 장소: 강남역, 롯데타워, 강남구청\n• 주소: 서울특별시 강남구 테헤란로 152');
    } catch (e) {
      return ApiResponse.error('지오코딩 중 오류 발생: $e');
    }
  }

  /// Geocoding API 시도 (정확한 주소)
  static Future<ApiResponse<GeoAddress>> _tryGeocoding(String query) async {
    try {
      final uri = Uri.parse(
        '${NaverMapConfig.geocodeUrl}?query=${Uri.encodeQueryComponent(query)}',
      );

      print('🔍 GEOCODING_SERVICE: Geocoding API 호출 - $uri');
      final res = await http.get(uri, headers: _headers());
      final body = utf8.decode(res.bodyBytes);
      print('🔍 GEOCODING_SERVICE: Geocoding 응답 - ${res.statusCode}');

      if (res.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        print('🔍 GEOCODING_SERVICE: Geocoding 응답 JSON - $json');
        final addresses = (json['addresses'] as List?) ?? [];
        if (addresses.isEmpty) {
          print('⚠️ GEOCODING_SERVICE: Geocoding addresses가 비어있음');
          return ApiResponse.error('Geocoding: 주소를 찾을 수 없습니다');
        }
        final first = addresses.first as Map<String, dynamic>;
        final addr = (first['roadAddress'] as String?)?.trim();
        final jibun = (first['jibunAddress'] as String?)?.trim();
        final x = double.tryParse((first['x'] ?? '').toString()); // lng
        final y = double.tryParse((first['y'] ?? '').toString()); // lat

        if (x == null || y == null) {
          return ApiResponse.error('좌표 정보를 파싱할 수 없습니다.');
        }

        final result = GeoAddress(
          address: (addr?.isNotEmpty == true ? addr : jibun) ?? '${y.toStringAsFixed(6)}, ${x.toStringAsFixed(6)}',
          latitude: y,
          longitude: x,
        );
        print('✅ GEOCODING_SERVICE: Geocoding 성공');
        return ApiResponse.success(result);
      } else {
        return ApiResponse.error('Geocoding 실패: HTTP ${res.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Geocoding 오류: $e');
    }
  }

  /// Naver Local Search API 시도 (부정확한 검색어)
  static Future<ApiResponse<GeoAddress>> _tryLocalSearch(String query) async {
    try {
      final uri = Uri.parse(
        '${NaverMapConfig.searchLocalUrl}?query=${Uri.encodeQueryComponent(query)}&display=5',
      );

      // Naver Search API 전용 헤더 사용
      final headers = {
        'X-Naver-Client-Id': NaverMapConfig.searchClientId,
        'X-Naver-Client-Secret': NaverMapConfig.searchClientSecret,
      };

      print('🔍 GEOCODING_SERVICE: Local Search API 호출 - $uri');
      print('🔍 GEOCODING_SERVICE: Client ID: ${NaverMapConfig.searchClientId}');
      final res = await http.get(uri, headers: headers);
      final body = utf8.decode(res.bodyBytes);
      print('🔍 GEOCODING_SERVICE: Local Search 응답 - ${res.statusCode}');
      print('🔍 GEOCODING_SERVICE: Local Search 응답 본문 - ${body.length > 500 ? body.substring(0, 500) : body}');

      if (res.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final items = (json['items'] as List?) ?? [];
        print('🔍 GEOCODING_SERVICE: Local Search items 개수 - ${items.length}');

        if (items.isEmpty) {
          print('⚠️ GEOCODING_SERVICE: Local Search 결과가 비어있음. 장소명이나 건물명이 필요합니다.');
          return ApiResponse.error('Local Search: 검색 결과가 없습니다.\n\n도로명보다는 구체적인 장소명이나 건물명을 입력해주세요.\n예: 강남역, 롯데타워, 스타벅스 강남점, 강남구청');
        }

        // 첫 번째 결과 사용
        final first = items.first as Map<String, dynamic>;
        final title = (first['title'] as String?)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? ''; // HTML 태그 제거
        final roadAddress = (first['roadAddress'] as String?)?.trim() ?? '';
        final address = (first['address'] as String?)?.trim() ?? '';

        // 위도/경도는 mapx, mapy로 제공됨 (카텍좌표 x 10^7)
        final mapx = first['mapx'];
        final mapy = first['mapy'];

        if (mapx == null || mapy == null) {
          return ApiResponse.error('Local Search: 좌표 정보가 없습니다');
        }

        // 카텍 좌표를 WGS84로 변환 (간단히 10^7로 나누기)
        final longitude = (mapx is int ? mapx : int.tryParse(mapx.toString()) ?? 0) / 10000000.0;
        final latitude = (mapy is int ? mapy : int.tryParse(mapy.toString()) ?? 0) / 10000000.0;

        final displayAddress = roadAddress.isNotEmpty ? roadAddress : address;

        final result = GeoAddress(
          address: '$title ($displayAddress)',
          latitude: latitude,
          longitude: longitude,
        );

        print('✅ GEOCODING_SERVICE: Local Search 성공 - $title');
        return ApiResponse.success(result);
      } else {
        return ApiResponse.error('Local Search 실패: HTTP ${res.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Local Search 오류: $e');
    }
  }

  /// 좌표를 주소로 변환 (Reverse Geocoding)
  static Future<ApiResponse<GeoAddress>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🔍 GEOCODING_SERVICE: 역지오코딩 요청 - lat: $latitude, lng: $longitude');
      
      if (!_hasValidKeys()) {
        return ApiResponse.error('Naver Open API 키가 설정되지 않았습니다.');
      }

      // Naver reverse geocode는 coords 순서가 "lng,lat"
      final coords = '${longitude.toStringAsFixed(7)},${latitude.toStringAsFixed(7)}';
      final uri = Uri.parse(
        '${NaverMapConfig.reverseGeocodeUrl}?coords=$coords&orders=roadaddr,addr&output=json',
      );

      print('🔍 GEOCODING_SERVICE: API 호출 시작 - $uri');
      print('🔍 GEOCODING_SERVICE: 요청 헤더 - ${_headers()}');
      final res = await http.get(uri, headers: _headers());
      final body = utf8.decode(res.bodyBytes);
      print('🔍 GEOCODING_SERVICE: HTTP 응답 - ${res.statusCode}');
      print('🔍 GEOCODING_SERVICE: 응답 헤더 - ${res.headers}');
      print('🔍 GEOCODING_SERVICE: 응답 본문 - ${body.length > 200 ? body.substring(0, 200) + '...' : body}');

      if (res.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final results = (json['results'] as List?) ?? [];
        if (results.isEmpty) {
          return ApiResponse.error('역지오코딩 결과가 없습니다.');
        }

        // roadaddr 우선, 없으면 addr 사용
        String? address;
        for (final item in results.cast<Map<String, dynamic>>()) {
          final name = item['name']?.toString();
          if (name == 'roadaddr' || name == 'addr') {
            address = _composeAddressFromReverse(item);
            if (address != null && address.trim().isNotEmpty) break;
          }
        }
        address ??= _composeAddressFromReverse(results.first as Map<String, dynamic>) ??
            '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

        final result = GeoAddress(
          address: address,
          latitude: latitude,
          longitude: longitude,
        );
        print('✅ GEOCODING_SERVICE: 역지오코딩 성공');
        return ApiResponse.success(result);
      } else if (res.statusCode == 401) {
        // API 구독 필요 - 좌표만으로 주소 표시
        print('⚠️ GEOCODING_SERVICE: 역지오코딩 API 구독이 필요합니다.');
        final result = GeoAddress(
          address: '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          latitude: latitude,
          longitude: longitude,
        );
        return ApiResponse.success(result);
      } else {
        return ApiResponse.error('역지오코딩 실패: HTTP ${res.statusCode}\n${body.length < 800 ? body : body.substring(0, 800)}');
      }
    } catch (e) {
      return ApiResponse.error('역지오코딩 중 오류 발생: $e');
    }
  }

  static String? _composeAddressFromReverse(Map<String, dynamic> item) {
    final region = item['region'] as Map<String, dynamic>?;
    final land = item['land'] as Map<String, dynamic>?;

    String part(dynamic m, String k) => (m is Map && m[k] is Map)
        ? (m[k]['name']?.toString() ?? '')
        : '';

    final a1 = part(region, 'area1');
    final a2 = part(region, 'area2');
    final a3 = part(region, 'area3');
    final a4 = part(region, 'area4');
    final road = land?['name']?.toString() ?? '';
    final num1 = land?['number1']?.toString() ?? '';
    final num2 = land?['number2']?.toString() ?? '';
    final building = land?['addition0'] is Map ? (land?['addition0']['value']?.toString() ?? '') : '';

    String joinNonEmpty(List<String> parts) {
      return parts.where((e) => e.trim().isNotEmpty).join(' ');
    }

    final base = joinNonEmpty([a1, a2, a3, a4]);
    final num = num2.isNotEmpty ? '$num1-$num2' : num1;
    final tail = joinNonEmpty([road, num, building]);

    final full = joinNonEmpty([base, tail]);
    return full.isEmpty ? null : full;
  }
}
