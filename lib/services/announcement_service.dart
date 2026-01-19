import 'dart:developer';
import '../models/announcement.dart';
import '../models/api_response.dart';
import 'supabase_service.dart';

class AnnouncementService {
  final SupabaseService _supabaseService = SupabaseService();

  // 공지사항 목록 조회 (Supabase 테이블 직접 쿼리)
  Future<List<Announcement>> getAnnouncements({
    int skip = 0,
    int limit = 50,
    String? category,
    bool? isActive = true,
    DateTime? startDate,
    DateTime? endDate,
    String? sortOrder = 'desc',
    int? churchId,
  }) async {
    try {
      log('📢 공지사항 목록 조회 시작 (Supabase)');
      log('📢 전달받은 churchId: $churchId');

      dynamic query = _supabaseService.client
          .from('announcements')
          .select('*');

      // 필터 적용
      if (churchId != null) {
        log('📢 churchId 필터 적용: church_id = $churchId');
        query = query.eq('church_id', churchId);
      } else {
        log('⚠️ churchId가 null이므로 필터링하지 않음');
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // 정렬 적용 (고정글을 먼저, 그 다음 생성일 기준)
      query = query.order('is_pinned', ascending: false);
      query = query.order('created_at', ascending: sortOrder == 'asc');

      // 페이지네이션 적용
      if (limit > 0) {
        query = query.limit(limit);
      }
      if (skip > 0) {
        query = query.range(skip, skip + limit - 1);
      }

      final response = await query;

      log('📢 Supabase 응답: ${response.length}개 공지사항');
      if (response.isNotEmpty) {
        log('📢 첫 번째 공지사항 church_id: ${response[0]['church_id']}');
      }

      final responseList = response as List;

      // 웹과 동일한 로직: author_id로 users 테이블의 full_name 조회
      if (responseList.isNotEmpty) {
        // 모든 author_id 수집
        final authorIds = responseList
            .map((item) => item['author_id'] as int?)
            .where((id) => id != null)
            .toSet()
            .toList();

        if (authorIds.isNotEmpty) {
          try {
            log('📢 users 테이블에서 작성자 이름 조회: $authorIds');

            // users 테이블에서 full_name 배치 조회
            final usersResponse = await _supabaseService.client
                .from('users')
                .select('id, full_name')
                .inFilter('id', authorIds);

            // author_id -> full_name 매핑
            final Map<int, String> authorNames = {};
            for (var user in usersResponse as List) {
              authorNames[user['id'] as int] = user['full_name'] as String;
            }

            log('📢 조회된 작성자 이름: $authorNames');

            // author_name enrichment (웹과 동일한 우선순위)
            for (var item in responseList) {
              final itemMap = item as Map<String, dynamic>;
              final authorId = itemMap['author_id'] as int?;

              if (authorId != null && authorNames.containsKey(authorId)) {
                // 우선순위 1: users 테이블의 full_name
                itemMap['author_name'] = authorNames[authorId];
              } else if (itemMap['author_name'] == null || (itemMap['author_name'] as String).isEmpty) {
                // 우선순위 3: 기본값 '관리자'
                itemMap['author_name'] = '관리자';
              }
              // 우선순위 2: 기존 author_name 컬럼 값은 그대로 유지
            }
          } catch (e) {
            log('⚠️ users 테이블 조회 실패, author_name 컬럼 사용: $e');
          }
        }
      }

      final announcements = responseList
          .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
          .toList();

      log('📢 공지사항 ${announcements.length}개 조회 완료');
      return announcements;
    } catch (e) {
      log('❌ 공지사항 목록 조회 오류: $e');
      throw Exception('공지사항 목록을 불러올 수 없습니다: $e');
    }
  }

  // 공지사항 상세 조회 (Supabase)
  Future<Announcement> getAnnouncement(int id) async {
    try {
      log('📢 공지사항 상세 조회 시작: ID $id');

      final response = await _supabaseService.client
          .from('announcements')
          .select('*')
          .eq('id', id)
          .single();

      final itemMap = response as Map<String, dynamic>;

      // 웹과 동일한 로직: author_id로 users 테이블의 full_name 조회
      if (itemMap['author_id'] != null) {
        try {
          final authorId = itemMap['author_id'] as int;
          log('📢 users 테이블에서 작성자 이름 조회: $authorId');

          final userResponse = await _supabaseService.client
              .from('users')
              .select('full_name')
              .eq('id', authorId)
              .single();

          // 우선순위 1: users 테이블의 full_name
          itemMap['author_name'] = userResponse['full_name'];
          log('📢 조회된 작성자 이름: ${userResponse['full_name']}');
        } catch (e) {
          log('⚠️ users 테이블 조회 실패, author_name 컬럼 사용: $e');
          // 우선순위 2: 기존 author_name 컬럼 또는 3: 기본값 '관리자'
          if (itemMap['author_name'] == null || (itemMap['author_name'] as String).isEmpty) {
            itemMap['author_name'] = '관리자';
          }
        }
      } else if (itemMap['author_name'] == null || (itemMap['author_name'] as String).isEmpty) {
        // author_id가 없고 author_name도 없으면 '관리자'
        itemMap['author_name'] = '관리자';
      }

      final announcement = Announcement.fromJson(itemMap);
      log('📢 공지사항 상세 조회 완료');
      return announcement;
    } catch (e) {
      log('❌ 공지사항 조회 오류: $e');
      throw Exception('공지사항을 불러올 수 없습니다: $e');
    }
  }

  // 공지사항 생성 (Supabase)
  Future<Announcement> createAnnouncement(Map<String, dynamic> announcementData) async {
    try {
      log('📢 공지사항 생성 시작 (Supabase)');

      final response = await _supabaseService.client
          .from('announcements')
          .insert(announcementData)
          .select()
          .single();

      final announcement = Announcement.fromJson(response);
      log('✅ 공지사항 생성 성공');
      return announcement;
    } catch (e) {
      log('❌ 공지사항 생성 오류: $e');
      throw Exception('공지사항을 생성할 수 없습니다: $e');
    }
  }

  // 공지사항 수정 (Supabase)
  Future<Announcement> updateAnnouncement(int id, Map<String, dynamic> updateData) async {
    try {
      log('📢 공지사항 수정 시작: ID $id');

      final response = await _supabaseService.client
          .from('announcements')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final announcement = Announcement.fromJson(response);
      log('✅ 공지사항 수정 성공');
      return announcement;
    } catch (e) {
      log('❌ 공지사항 수정 오류: $e');
      throw Exception('공지사항을 수정할 수 없습니다: $e');
    }
  }

  // 공지사항 삭제 (Supabase)
  Future<bool> deleteAnnouncement(int id) async {
    try {
      log('📢 공지사항 삭제 시작: ID $id');

      await _supabaseService.client
          .from('announcements')
          .delete()
          .eq('id', id);

      log('✅ 공지사항 삭제 성공');
      return true;
    } catch (e) {
      log('❌ 공지사항 삭제 오류: $e');
      throw Exception('공지사항을 삭제할 수 없습니다: $e');
    }
  }

  // 공지사항 고정 토글 (Supabase)
  Future<Announcement> togglePin(int id) async {
    try {
      log('📢 공지사항 고정 토글 시작: ID $id');

      // 현재 상태 조회
      final current = await getAnnouncement(id);

      // 고정 상태 토글
      final response = await _supabaseService.client
          .from('announcements')
          .update({'is_pinned': !current.isPinned})
          .eq('id', id)
          .select()
          .single();

      final announcement = Announcement.fromJson(response);
      log('✅ 공지사항 고정 토글 성공');
      return announcement;
    } catch (e) {
      log('❌ 공지사항 고정 토글 오류: $e');
      throw Exception('공지사항 고정 설정을 변경할 수 없습니다: $e');
    }
  }
}
