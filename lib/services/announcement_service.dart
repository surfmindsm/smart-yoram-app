import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/announcement.dart';
import '../services/auth_service.dart';

class AnnouncementService {
  final AuthService _authService = AuthService();

  // HTTP 클라이언트에 인증 헤더 추가
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getStoredToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 공지사항 목록 조회
  Future<List<Announcement>> getAnnouncements({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcements}')
          .replace(queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      });

      log('📢 공지사항 목록 조회: $uri');

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      log('📢 응답 상태: ${response.statusCode}');
      log('📢 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        
        if (jsonResponse is List) {
          final announcements = jsonResponse
              .map((item) => Announcement.fromJson(item))
              .toList();
          
          log('📢 공지사항 ${announcements.length}개 조회 완료');
          return announcements;
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          final List<dynamic> data = jsonResponse['data'] ?? [];
          final announcements = data
              .map((item) => Announcement.fromJson(item))
              .toList();
          
          log('📢 공지사항 ${announcements.length}개 조회 완료');
          return announcements;
        }
      }

      throw Exception('공지사항 목록 조회 실패: ${response.statusCode}');
    } catch (e) {
      log('❌ 공지사항 목록 조회 오류: $e');
      throw Exception('공지사항 목록을 불러올 수 없습니다: $e');
    }
  }

  // 공지사항 상세 조회
  Future<Announcement> getAnnouncement(int id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcements}$id');

      log('📢 공지사항 상세 조회: $uri');

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      log('📢 응답 상태: ${response.statusCode}');
      log('📢 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return Announcement.fromJson(jsonResponse);
      }

      throw Exception('공지사항 조회 실패: ${response.statusCode}');
    } catch (e) {
      log('❌ 공지사항 조회 오류: $e');
      throw Exception('공지사항을 불러올 수 없습니다: $e');
    }
  }

  // 공지사항 생성
  Future<Announcement> createAnnouncement(AnnouncementCreateRequest request) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcements}');

      log('📢 공지사항 생성: $uri');
      log('📢 요청 데이터: ${json.encode(request.toJson())}');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      log('📢 응답 상태: ${response.statusCode}');
      log('📢 응답 내용: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        log('✅ 공지사항 생성 성공');
        return Announcement.fromJson(jsonResponse);
      }

      throw Exception('공지사항 생성 실패: ${response.statusCode}');
    } catch (e) {
      log('❌ 공지사항 생성 오류: $e');
      throw Exception('공지사항을 생성할 수 없습니다: $e');
    }
  }

  // 공지사항 수정
  Future<Announcement> updateAnnouncement(int id, AnnouncementUpdateRequest request) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcements}$id');

      log('📢 공지사항 수정: $uri');
      log('📢 요청 데이터: ${json.encode(request.toJson())}');

      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      log('📢 응답 상태: ${response.statusCode}');
      log('📢 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        log('✅ 공지사항 수정 성공');
        return Announcement.fromJson(jsonResponse);
      }

      throw Exception('공지사항 수정 실패: ${response.statusCode}');
    } catch (e) {
      log('❌ 공지사항 수정 오류: $e');
      throw Exception('공지사항을 수정할 수 없습니다: $e');
    }
  }

  // 공지사항 삭제
  Future<bool> deleteAnnouncement(int id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcements}$id');

      log('📢 공지사항 삭제: $uri');

      final response = await http.delete(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      log('📢 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        log('✅ 공지사항 삭제 성공');
        return true;
      }

      throw Exception('공지사항 삭제 실패: ${response.statusCode}');
    } catch (e) {
      log('❌ 공지사항 삭제 오류: $e');
      throw Exception('공지사항을 삭제할 수 없습니다: $e');
    }
  }

  // 공지사항 고정 토글
  Future<Announcement> togglePin(int id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.announcementsTogglePin.replaceAll('{id}', id.toString())}'
      );

      log('📢 공지사항 고정 토글: $uri');

      final response = await http.put(uri, headers: headers).timeout(
        const Duration(seconds: 30),
      );

      log('📢 응답 상태: ${response.statusCode}');
      log('📢 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        log('✅ 공지사항 고정 토글 성공');
        return Announcement.fromJson(jsonResponse);
      }

      throw Exception('공지사항 고정 토글 실패: ${response.statusCode}');
    } catch (e) {
      log('❌ 공지사항 고정 토글 오류: $e');
      throw Exception('공지사항 고정 설정을 변경할 수 없습니다: $e');
    }
  }


}
