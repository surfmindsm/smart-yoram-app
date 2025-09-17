import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // 메모리 캐시
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // 캐시 만료 시간 (분)
  static const int _defaultCacheMinutes = 15;
  static const int _longCacheMinutes = 60; // 1시간
  static const int _shortCacheMinutes = 5;  // 5분

  // 캐시 키 상수
  static const String USER_DATA = 'user_data';
  static const String CHURCH_DATA = 'church_data';
  static const String MEMBER_DATA = 'member_data';
  static const String DAILY_VERSE = 'daily_verse';
  static const String ANNOUNCEMENTS = 'announcements';
  static const String MEMBERS_LIST = 'members_list';

  /// 데이터를 메모리와 디스크에 캐시
  Future<void> cacheData(
    String key,
    dynamic data, {
    int cacheMinutes = _defaultCacheMinutes,
    bool persistToDisk = false,
  }) async {
    try {
      // 메모리 캐시
      _memoryCache[key] = data;
      _cacheTimestamps[key] = DateTime.now();

      // 디스크 캐시 (선택적)
      if (persistToDisk) {
        final prefs = await SharedPreferences.getInstance();
        final cacheData = {
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'cacheMinutes': cacheMinutes,
        };
        await prefs.setString('cache_$key', json.encode(cacheData));
      }

      print('📦 CACHE: 데이터 캐시됨 - $key (${cacheMinutes}분)');
    } catch (e) {
      print('❌ CACHE: 캐시 저장 실패 - $key: $e');
    }
  }

  /// 캐시된 데이터 가져오기 (메모리 우선, 그 다음 디스크)
  Future<T?> getCachedData<T>(
    String key, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      // 1. 메모리 캐시 확인
      if (_memoryCache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
        final timestamp = _cacheTimestamps[key]!;
        final now = DateTime.now();
        final diff = now.difference(timestamp).inMinutes;

        if (diff < _defaultCacheMinutes) {
          print('🎯 CACHE: 메모리 캐시 히트 - $key');
          return _memoryCache[key] as T?;
        } else {
          // 만료된 메모리 캐시 삭제
          _memoryCache.remove(key);
          _cacheTimestamps.remove(key);
        }
      }

      // 2. 디스크 캐시 확인
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cache_$key');

      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        final cacheMinutes = cacheData['cacheMinutes'] ?? _defaultCacheMinutes;
        final now = DateTime.now();
        final diff = now.difference(timestamp).inMinutes;

        if (diff < cacheMinutes) {
          final data = cacheData['data'];

          // 메모리 캐시에도 저장
          _memoryCache[key] = data;
          _cacheTimestamps[key] = timestamp;

          print('💾 CACHE: 디스크 캐시 히트 - $key');

          if (fromJson != null && data != null) {
            return fromJson(data);
          }
          return data as T?;
        } else {
          // 만료된 디스크 캐시 삭제
          await prefs.remove('cache_$key');
        }
      }

      print('❌ CACHE: 캐시 미스 - $key');
      return null;
    } catch (e) {
      print('❌ CACHE: 캐시 읽기 실패 - $key: $e');
      return null;
    }
  }

  /// 특정 키의 캐시 무효화
  Future<void> invalidateCache(String key) async {
    try {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');

      print('🗑️ CACHE: 캐시 무효화 - $key');
    } catch (e) {
      print('❌ CACHE: 캐시 무효화 실패 - $key: $e');
    }
  }

  /// 모든 캐시 클리어
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      _cacheTimestamps.clear();

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      print('🧹 CACHE: 모든 캐시 클리어됨');
    } catch (e) {
      print('❌ CACHE: 캐시 클리어 실패: $e');
    }
  }

  /// 캐시가 유효한지 확인
  bool isCacheValid(String key, {int cacheMinutes = _defaultCacheMinutes}) {
    if (!_cacheTimestamps.containsKey(key)) return false;

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    final diff = now.difference(timestamp).inMinutes;

    return diff < cacheMinutes;
  }

  /// 캐시 통계 정보
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCache_count': _memoryCache.length,
      'cached_keys': _memoryCache.keys.toList(),
      'cache_timestamps': _cacheTimestamps.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }
}