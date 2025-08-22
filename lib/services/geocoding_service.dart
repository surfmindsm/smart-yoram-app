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
  static Future<ApiResponse<GeoAddress>> geocode(String query) async {
    try {
      print('🔍 GEOCODING_SERVICE: 지오코딩 요청 - "$query"');
      
      if (!_hasValidKeys()) {
        return ApiResponse.error('Naver Open API 키가 설정되지 않았습니다.');
      }

      final uri = Uri.parse(
        '${NaverMapConfig.geocodeUrl}?query=${Uri.encodeQueryComponent(query)}',
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
        final addresses = (json['addresses'] as List?) ?? [];
        if (addresses.isEmpty) {
          return ApiResponse.error('주소를 찾을 수 없습니다: "$query"');
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
        print('✅ GEOCODING_SERVICE: 지오코딩 성공');
        return ApiResponse.success(result);
      } else {
        return ApiResponse.error('지오코딩 실패: HTTP ${res.statusCode}\n${body.length < 800 ? body : body.substring(0, 800)}');
      }
    } catch (e) {
      return ApiResponse.error('지오코딩 중 오류 발생: $e');
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
