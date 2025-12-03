import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/daily_verse.dart';
import '../services/auth_service.dart';

class DailyVerseService {
  static final DailyVerseService _instance = DailyVerseService._internal();
  factory DailyVerseService() => _instance;
  DailyVerseService._internal();

  final AuthService _authService = AuthService();

  /// 랜덤 오늘의 말씀 가져오기
  Future<DailyVerse?> getRandomVerse() async {
    try {
      developer.log('🙏 DailyVerseService: 랜덤 오늘의 말씀 요청', name: 'DailyVerseService');

      // Bearer 토큰 가져오기
      final token = _authService.getStoredToken();
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dailyVersesRandom}'),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final verse = DailyVerse.fromJson(jsonData);
        developer.log('✅ DailyVerseService: 오늘의 말씀 로드 성공', name: 'DailyVerseService');
        return verse;
      } else {
        developer.log('❌ DailyVerseService: 응답 오류 ${response.statusCode}', name: 'DailyVerseService');
        return _getSampleVerse();
      }

    } catch (e, stackTrace) {
      developer.log(
        '❌ DailyVerseService: 오늘의 말씀 로드 실패: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'DailyVerseService',
      );

      // 에러 시 샘플 데이터 반환
      return _getSampleVerse();
    }
  }

  /// 샘플 말씀 데이터 반환 (에러 또는 API 실패 시)
  DailyVerse _getSampleVerse() {
    final sampleVerse = DailyVerse(
      id: 1,
      verse: '여호와는 나의 목자시니 내게 부족함이 없으리로다',
      reference: '시편 23:1',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    developer.log('📝 DailyVerseService: 샘플 말씀 데이터 사용', name: 'DailyVerseService');
    return sampleVerse;
  }




}
