import 'dart:developer';
import '../models/sermon.dart';
import 'supabase_service.dart';

class SermonService {
  final SupabaseService _supabaseService = SupabaseService();

  // 명설교 목록 조회 (Supabase)
  Future<List<Sermon>> getSermons({
    int skip = 0,
    int limit = 50,
    String? category,
    bool? isFeatured,
    bool onlyActive = true,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      log('🎤 명설교 목록 조회 시작 (Supabase)');

      dynamic query = _supabaseService.client
          .from('sermons')
          .select('*');

      // 필터 적용
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (isFeatured != null) {
        query = query.eq('is_featured', isFeatured);
      }

      // 정렬 적용
      // 추천 설교면 display_order 우선, 아니면 지정된 sortBy 사용
      if (isFeatured == true) {
        query = query.order('display_order', ascending: true);
      } else {
        query = query.order(sortBy, ascending: sortOrder == 'asc');
      }

      // 페이지네이션 적용
      if (limit > 0) {
        query = query.limit(limit);
      }
      if (skip > 0) {
        query = query.range(skip, skip + limit - 1);
      }

      final response = await query;

      log('🎤 Supabase 응답: ${response.length}개 명설교');

      final sermons = (response as List)
          .map((item) => Sermon.fromJson(item as Map<String, dynamic>))
          .toList();

      log('🎤 명설교 ${sermons.length}개 조회 완료');
      return sermons;
    } catch (e) {
      log('❌ 명설교 목록 조회 오류: $e');
      throw Exception('명설교 목록을 불러올 수 없습니다: $e');
    }
  }

  // 명설교 상세 조회 (Supabase)
  Future<Sermon> getSermon(String id) async {
    try {
      log('🎤 명설교 상세 조회 시작: ID $id');

      final response = await _supabaseService.client
          .from('sermons')
          .select('*')
          .eq('id', id)
          .single();

      final sermon = Sermon.fromJson(response);
      log('🎤 명설교 상세 조회 완료');
      return sermon;
    } catch (e) {
      log('❌ 명설교 조회 오류: $e');
      throw Exception('명설교를 불러올 수 없습니다: $e');
    }
  }

  // 추천 설교 조회 (is_featured = true, display_order 순서대로)
  Future<List<Sermon>> getFeaturedSermons({int limit = 5}) async {
    try {
      log('🎤 추천 명설교 조회 시작');
      return await getSermons(
        isFeatured: true,
        limit: limit,
        sortBy: 'display_order',
        sortOrder: 'asc',
      );
    } catch (e) {
      log('❌ 추천 명설교 조회 오류: $e');
      throw Exception('추천 명설교를 불러올 수 없습니다: $e');
    }
  }

  // 카테고리별 명설교 조회
  Future<List<Sermon>> getSermonsByCategory(String category, {int limit = 20}) async {
    try {
      log('🎤 카테고리별 명설교 조회: $category');
      return await getSermons(
        category: category,
        limit: limit,
        sortBy: 'sermon_date',
        sortOrder: 'desc',
      );
    } catch (e) {
      log('❌ 카테고리별 명설교 조회 오류: $e');
      throw Exception('카테고리별 명설교를 불러올 수 없습니다: $e');
    }
  }

  // 조회수 증가 (Supabase)
  Future<void> incrementViewCount(String id) async {
    try {
      log('🎤 명설교 조회수 증가: ID $id');

      // 현재 조회수를 가져옴
      final sermon = await getSermon(id);
      final newViewCount = sermon.viewCount + 1;

      // 조회수 업데이트
      await _supabaseService.client
          .from('sermons')
          .update({'view_count': newViewCount})
          .eq('id', id);

      log('🎤 조회수 증가 완료: $newViewCount');
    } catch (e) {
      log('❌ 조회수 증가 오류: $e');
      // 조회수 증가 실패는 무시 (사용자 경험에 영향 없음)
    }
  }

  // 명설교 생성 (관리자 전용)
  Future<Sermon> createSermon(Map<String, dynamic> sermonData) async {
    try {
      log('🎤 명설교 생성 시작');

      final response = await _supabaseService.client
          .from('sermons')
          .insert(sermonData)
          .select()
          .single();

      final sermon = Sermon.fromJson(response);
      log('🎤 명설교 생성 완료: ${sermon.id}');
      return sermon;
    } catch (e) {
      log('❌ 명설교 생성 오류: $e');
      throw Exception('명설교를 생성할 수 없습니다: $e');
    }
  }

  // 명설교 수정 (관리자 전용)
  Future<Sermon> updateSermon(String id, Map<String, dynamic> updateData) async {
    try {
      log('🎤 명설교 수정 시작: ID $id');

      final response = await _supabaseService.client
          .from('sermons')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final sermon = Sermon.fromJson(response);
      log('🎤 명설교 수정 완료');
      return sermon;
    } catch (e) {
      log('❌ 명설교 수정 오류: $e');
      throw Exception('명설교를 수정할 수 없습니다: $e');
    }
  }

  // 명설교 삭제 (관리자 전용 - 실제로는 is_active를 false로 변경)
  Future<void> deleteSermon(String id) async {
    try {
      log('🎤 명설교 삭제 시작: ID $id');

      await _supabaseService.client
          .from('sermons')
          .update({'is_active': false})
          .eq('id', id);

      log('🎤 명설교 삭제 완료');
    } catch (e) {
      log('❌ 명설교 삭제 오류: $e');
      throw Exception('명설교를 삭제할 수 없습니다: $e');
    }
  }

  // 카테고리 목록 조회 (중복 제거)
  Future<List<String>> getCategories() async {
    try {
      log('🎤 카테고리 목록 조회 시작');

      final response = await _supabaseService.client
          .from('sermons')
          .select('category')
          .eq('is_active', true)
          .not('category', 'is', null);

      // 중복 제거 및 정렬
      final categories = (response as List)
          .map((item) => item['category'] as String)
          .toSet()
          .toList()
        ..sort();

      log('🎤 카테고리 ${categories.length}개 조회 완료');
      return categories;
    } catch (e) {
      log('❌ 카테고리 조회 오류: $e');
      return ['주일설교', '수요예배', '특별집회']; // 기본 카테고리 반환
    }
  }

  // 유튜브 URL에서 비디오 ID 추출
  static String? extractYoutubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      // youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }

      // youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }

      // youtube.com/embed/VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
        return uri.pathSegments[1];
      }

      return null;
    } catch (e) {
      log('❌ 유튜브 비디오 ID 추출 오류: $e');
      return null;
    }
  }

  // ==================== 즐겨찾기 기능 ====================

  // 즐겨찾기 추가
  Future<bool> addToFavorites(String sermonId, int userId) async {
    try {
      log('❤️ 즐겨찾기 추가: sermon_id=$sermonId, user_id=$userId');

      await _supabaseService.client
          .from('sermon_favorites')
          .insert({
        'sermon_id': sermonId,
        'user_id': userId,
      });

      log('✅ 즐겨찾기 추가 완료');
      return true;
    } catch (e) {
      // UNIQUE 제약 위반 (이미 즐겨찾기에 있음)
      if (e.toString().contains('23505')) {
        log('ℹ️ 이미 즐겨찾기에 있습니다');
        return false;
      }
      log('❌ 즐겨찾기 추가 오류: $e');
      return false;
    }
  }

  // 즐겨찾기 삭제
  Future<bool> removeFromFavorites(String sermonId, int userId) async {
    try {
      log('💔 즐겨찾기 삭제: sermon_id=$sermonId, user_id=$userId');

      await _supabaseService.client
          .from('sermon_favorites')
          .delete()
          .eq('sermon_id', sermonId)
          .eq('user_id', userId);

      log('✅ 즐겨찾기 삭제 완료');
      return true;
    } catch (e) {
      log('❌ 즐겨찾기 삭제 오류: $e');
      return false;
    }
  }

  // 즐겨찾기 여부 확인
  Future<bool> isFavorited(String sermonId, int userId) async {
    try {
      final response = await _supabaseService.client
          .from('sermon_favorites')
          .select('id')
          .eq('sermon_id', sermonId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      log('❌ 즐겨찾기 확인 오류: $e');
      return false;
    }
  }

  // 즐겨찾기 토글 (추가/삭제)
  Future<bool> toggleFavorite(String sermonId, int userId) async {
    try {
      final isFav = await isFavorited(sermonId, userId);

      if (isFav) {
        return await removeFromFavorites(sermonId, userId);
      } else {
        return await addToFavorites(sermonId, userId);
      }
    } catch (e) {
      log('❌ 즐겨찾기 토글 오류: $e');
      return false;
    }
  }

  // 내 즐겨찾기 목록 조회
  Future<List<Sermon>> getMyFavoriteSermons(int userId) async {
    try {
      log('❤️ 내 즐겨찾기 목록 조회: user_id=$userId');

      final response = await _supabaseService.client
          .from('sermon_favorites')
          .select('sermon_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final sermonIds = (response as List)
          .map((item) => item['sermon_id'] as String)
          .toList();

      if (sermonIds.isEmpty) {
        log('ℹ️ 즐겨찾기한 설교가 없습니다');
        return [];
      }

      // 설교 정보 조회
      final sermonsResponse = await _supabaseService.client
          .from('sermons')
          .select('*')
          .inFilter('id', sermonIds);

      final sermons = (sermonsResponse as List)
          .map((item) => Sermon.fromJson(item as Map<String, dynamic>))
          .toList();

      log('❤️ 즐겨찾기 ${sermons.length}개 조회 완료');
      return sermons;
    } catch (e) {
      log('❌ 즐겨찾기 목록 조회 오류: $e');
      return [];
    }
  }
}
