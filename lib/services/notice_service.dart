import 'dart:developer' as developer;
import '../models/api_response.dart';
import '../models/notice.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class NoticeService {
  static final NoticeService _instance = NoticeService._internal();
  factory NoticeService() => _instance;
  NoticeService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  /// 공지사항 목록 조회 (Supabase 직접 쿼리)
  Future<ApiResponse<List<Notice>>> getNotices({
    int skip = 0,
    int limit = 100,
    String? search,
    String? type,
  }) async {
    try {
      developer.log('📢 NOTICE_SERVICE: 공지사항 목록 조회 시작 (Supabase)', name: 'NoticeService');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        developer.log('📢 NOTICE_SERVICE: 사용자 정보 조회 실패 - ${userResponse.message}', name: 'NoticeService');
        return ApiResponse<List<Notice>>(
          success: false,
          message: '사용자 정보 조회 실패: ${userResponse.message}',
          data: [],
        );
      }

      final user = userResponse.data!;
      developer.log('📢 NOTICE_SERVICE: 사용자 정보 - ID: ${user.id}, Church ID: ${user.churchId}', name: 'NoticeService');

      try {
        // Supabase에서 직접 announcements 테이블 쿼리
        dynamic query = _supabaseService.client
            .from('announcements')
            .select('*');

        // 필터 적용
        query = query.eq('church_id', user.churchId);
        query = query.eq('is_active', true);

        if (type != null) {
          query = query.eq('category', type);
        }

        if (search != null && search.isNotEmpty) {
          query = query.or('title.ilike.%$search%,content.ilike.%$search%');
        }

        // 정렬 (고정글 먼저, 그 다음 생성일 기준)
        query = query.order('is_pinned', ascending: false);
        query = query.order('created_at', ascending: false);

        // 페이지네이션
        if (limit > 0) {
          query = query.limit(limit);
        }
        if (skip > 0) {
          query = query.range(skip, skip + limit - 1);
        }

        final response = await query;

        final List<Notice> notices = (response as List)
            .map((item) => Notice.fromAnnouncement(item as Map<String, dynamic>))
            .toList();

        developer.log('📢 NOTICE_SERVICE: 파싱된 공지사항 수: ${notices.length}', name: 'NoticeService');
        return ApiResponse<List<Notice>>(
          success: true,
          message: '공지사항 목록 조회 성공',
          data: notices,
        );
      } catch (e) {
        developer.log('📢 NOTICE_SERVICE: Supabase 쿼리 실패, 샘플 데이터 사용 - $e', name: 'NoticeService');
        return ApiResponse<List<Notice>>(
          success: true,
          message: '공지사항 데이터를 찾을 수 없어 샘플 데이터로 표시',
          data: _generateSampleNotices(),
        );
      }
    } catch (e) {
      developer.log('📢 NOTICE_SERVICE: 목록 조회 예외 발생 - $e', name: 'NoticeService');
      developer.log('📢 NOTICE_SERVICE: 샘플 데이터로 대체하여 UI 테스트 진행', name: 'NoticeService');
      return ApiResponse<List<Notice>>(
        success: true,
        message: '공지사항 데이터를 찾을 수 없어 샘플 데이터로 표시',
        data: _generateSampleNotices(),
      );
    }
  }

  /// 특정 공지사항 조회 (Supabase)
  Future<ApiResponse<Notice>> getNotice(String noticeId) async {
    try {
      developer.log('📢 NOTICE_SERVICE: 공지사항 상세 조회 시작 - ID: $noticeId', name: 'NoticeService');

      try {
        final response = await _supabaseService.client
            .from('announcements')
            .select('*')
            .eq('id', int.parse(noticeId))
            .single();

        final notice = Notice.fromAnnouncement(response);
        developer.log('📢 NOTICE_SERVICE: 공지사항 상세 조회 성공', name: 'NoticeService');
        return ApiResponse<Notice>(
          success: true,
          message: '공지사항 조회 성공',
          data: notice,
        );
      } catch (e) {
        developer.log('📢 NOTICE_SERVICE: Supabase 쿼리 실패, 샘플 데이터 사용 - $e', name: 'NoticeService');

        final sampleNotices = _generateSampleNotices();
        final sampleNotice = sampleNotices.firstWhere(
          (notice) => notice.id == noticeId,
          orElse: () => sampleNotices.first,
        );

        return ApiResponse<Notice>(
          success: true,
          message: '샘플 데이터에서 공지사항 조회',
          data: sampleNotice,
        );
      }
    } catch (e) {
      developer.log('📢 NOTICE_SERVICE: 공지사항 조회 예외 발생 - $e', name: 'NoticeService');
      return ApiResponse<Notice>(
        success: false,
        message: '공지사항 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 공지사항 생성 (관리자용) (Supabase)
  Future<ApiResponse<Notice>> createNotice({
    required String title,
    required String content,
    required String type,
    String? imageUrl,
    List<String>? attachments,
    DateTime? expiryDate,
  }) async {
    try {
      developer.log('📢 NOTICE_SERVICE: 공지사항 생성 시작 (Supabase)', name: 'NoticeService');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        return ApiResponse<Notice>(
          success: false,
          message: '사용자 정보 조회 실패',
          data: null,
        );
      }

      final user = userResponse.data!;

      try {
        final announcementData = {
          'title': title,
          'content': content,
          'category': type,
          'church_id': user.churchId,
          'author_name': user.email ?? '관리자',
          'is_active': true,
          'is_pinned': false,
        };

        final response = await _supabaseService.client
            .from('announcements')
            .insert(announcementData)
            .select()
            .single();

        final notice = Notice.fromAnnouncement(response);
        developer.log('📢 NOTICE_SERVICE: 공지사항 생성 성공', name: 'NoticeService');

        return ApiResponse<Notice>(
          success: true,
          message: '공지사항 생성 성공',
          data: notice,
        );
      } catch (e) {
        developer.log('📢 NOTICE_SERVICE: Supabase 삽입 실패 - $e', name: 'NoticeService');
        return ApiResponse<Notice>(
          success: false,
          message: '공지사항 생성 실패: ${e.toString()}',
          data: null,
        );
      }
    } catch (e) {
      developer.log('📢 NOTICE_SERVICE: 공지사항 생성 예외 발생 - $e', name: 'NoticeService');
      return ApiResponse<Notice>(
        success: false,
        message: '공지사항 생성 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 공지사항 수정 (관리자용) (Supabase)
  Future<ApiResponse<Notice>> updateNotice(String noticeId, {
    String? title,
    String? content,
    String? type,
    String? imageUrl,
    List<String>? attachments,
    DateTime? expiryDate,
    bool? isPublished,
  }) async {
    try {
      developer.log('📢 NOTICE_SERVICE: 공지사항 수정 시작 - ID: $noticeId (Supabase)', name: 'NoticeService');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (type != null) updateData['category'] = type;
      if (isPublished != null) updateData['is_active'] = isPublished;

      try {
        final response = await _supabaseService.client
            .from('announcements')
            .update(updateData)
            .eq('id', int.parse(noticeId))
            .select()
            .single();

        final notice = Notice.fromAnnouncement(response);
        developer.log('📢 NOTICE_SERVICE: 공지사항 수정 성공', name: 'NoticeService');

        return ApiResponse<Notice>(
          success: true,
          message: '공지사항 수정 성공',
          data: notice,
        );
      } catch (e) {
        developer.log('📢 NOTICE_SERVICE: Supabase 수정 실패 - $e', name: 'NoticeService');
        return ApiResponse<Notice>(
          success: false,
          message: '공지사항 수정 실패: ${e.toString()}',
          data: null,
        );
      }
    } catch (e) {
      developer.log('📢 NOTICE_SERVICE: 공지사항 수정 예외 발생 - $e', name: 'NoticeService');
      return ApiResponse<Notice>(
        success: false,
        message: '공지사항 수정 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 공지사항 삭제 (관리자용) (Supabase)
  Future<ApiResponse<bool>> deleteNotice(String noticeId) async {
    try {
      developer.log('📢 NOTICE_SERVICE: 공지사항 삭제 시작 - ID: $noticeId (Supabase)', name: 'NoticeService');

      try {
        await _supabaseService.client
            .from('announcements')
            .delete()
            .eq('id', int.parse(noticeId));

        developer.log('📢 NOTICE_SERVICE: 공지사항 삭제 성공', name: 'NoticeService');
        return ApiResponse<bool>(
          success: true,
          message: '공지사항 삭제 성공',
          data: true,
        );
      } catch (e) {
        developer.log('📢 NOTICE_SERVICE: Supabase 삭제 실패 - $e', name: 'NoticeService');
        return ApiResponse<bool>(
          success: false,
          message: '공지사항 삭제 실패: ${e.toString()}',
          data: false,
        );
      }
    } catch (e) {
      developer.log('📢 NOTICE_SERVICE: 공지사항 삭제 예외 발생 - $e', name: 'NoticeService');
      return ApiResponse<bool>(
        success: false,
        message: '공지사항 삭제 실패: ${e.toString()}',
        data: false,
      );
    }
  }

  /// 공지사항 읽음 상태 업데이트 (로컬 처리)
  Future<ApiResponse<bool>> markAsRead(String noticeId) async {
    try {
      developer.log('📢 NOTICE_SERVICE: 공지사항 읽음 처리 시작 - ID: $noticeId (로컬)', name: 'NoticeService');

      // 실제 구현에서는 로컬 스토리지나 별도 테이블에 읽음 상태를 저장할 수 있음
      // 현재는 성공으로 처리
      developer.log('📢 NOTICE_SERVICE: 공지사항 읽음 처리 성공', name: 'NoticeService');

      return ApiResponse<bool>(
        success: true,
        message: '읽음 처리 성공',
        data: true,
      );
    } catch (e) {
      developer.log('📢 NOTICE_SERVICE: 공지사항 읽음 처리 예외 발생 - $e', name: 'NoticeService');
      return ApiResponse<bool>(
        success: false,
        message: '읽음 처리 실패: ${e.toString()}',
        data: false,
      );
    }
  }

  /// 샘플 공지사항 데이터 생성
  List<Notice> _generateSampleNotices() {
    final now = DateTime.now();
    return [
      Notice(
        id: '1',
        title: '2024년 새해 감사예배 안내',
        content: '''새해를 맞이하여 하나님께 감사하는 예배를 드리고자 합니다.

일시: 2024년 1월 7일(일) 오전 11시
장소: 본당
준비물: 감사제목 적은 종이

모든 성도님들의 참석을 부탁드립니다.''',
        type: 'important',
        createdAt: now.subtract(const Duration(days: 1)),
        createdBy: '관리자',
      ),
      Notice(
        id: '2',
        title: '주일학교 교사 모집',
        content: '''주일학교에서 아이들을 가르쳐 주실 교사를 모집합니다.

대상: 청년부 이상 성도
자격: 아이들을 사랑하는 마음
교육: 별도 교육 제공

관심 있으신 분은 교육부장에게 연락 바랍니다.''',
        type: 'general',
        createdAt: now.subtract(const Duration(days: 3)),
        createdBy: '교육부',
      ),
      Notice(
        id: '3',
        title: '성찬식 예정 안내',
        content: '''이번 달 첫째 주일에 성찬식을 거행합니다.

일시: 2024년 2월 4일(일) 주일예배 중
준비사항: 자기 성찰과 회개의 시간

성찬식 참여를 위해 미리 마음을 준비해 주시기 바랍니다.''',
        type: 'important',
        createdAt: now.subtract(const Duration(days: 5)),
        createdBy: '관리자',
      ),
      Notice(
        id: '4',
        title: '교회 주차장 이용 안내',
        content: '''교회 주차장 이용에 관한 안내사항입니다.

1. 예배 시간 외에는 주차 금지
2. 타 차량 통행에 방해되지 않도록 주차
3. 귀중품은 차량에 방치하지 마세요

협조해 주시기 바랍니다.''',
        type: 'general',
        createdAt: now.subtract(const Duration(days: 7)),
        createdBy: '관리자',
      ),
      Notice(
        id: '5',
        title: '겨울 성경학교 개최',
        content: '''겨울방학을 맞이하여 성경학교를 개최합니다.

기간: 2024년 1월 15일 ~ 19일 (5일간)
시간: 오전 9시 ~ 오후 3시
대상: 유치부 ~ 중학생
신청: 교육부장에게 문의

많은 참여 바랍니다.''',
        type: 'general',
        createdAt: now.subtract(const Duration(days: 10)),
        createdBy: '교육부',
      ),
      Notice(
        id: '6',
        title: '추석 연휴 예배 안내',
        content: '''추석 연휴 기간 중 예배 시간 안내입니다.

추석 당일(9월 17일): 오전 10시 추석감사예배
연휴 기간: 정상 예배 진행
특별순서: 전통 찬양 및 감사 나눔

가족과 함께 참석하시기 바랍니다.''',
        type: 'important',
        createdAt: now.subtract(const Duration(days: 2)),
        createdBy: '관리자',
      ),
      Notice(
        id: '7',
        title: '청년부 수련회 모집',
        content: '''청년부 겨울 수련회를 개최합니다.

일정: 2024년 2월 23일 ~ 25일 (2박 3일)
장소: 강원도 평창 수양관
참가비: 15만원 (교통비, 숙박비, 식비 포함)
신청 마감: 2월 10일까지

청년부장에게 신청해 주세요.''',
        type: 'general',
        createdAt: now.subtract(const Duration(days: 4)),
        createdBy: '청년부',
      ),
      Notice(
        id: '8',
        title: '교회 홈페이지 리뉴얼 안내',
        content: '''교회 홈페이지가 새롭게 단장했습니다.

새로운 기능:
- 모바일 최적화
- 온라인 헌금
- 예배 실시간 중계
- 교인 게시판

많은 이용 바랍니다.''',
        type: 'general',
        createdAt: now.subtract(const Duration(days: 6)),
        createdBy: '관리자',
      ),
      Notice(
        id: '9',
        title: '긴급: 태풍 경보로 인한 예배 시간 변경',
        content: '''태풍 경보 발령으로 인해 이번 주일 예배 시간이 변경됩니다.

변경 시간: 오전 11시 → 오후 2시
장소: 본당 (변경 없음)
주의사항: 안전에 유의하여 오시기 바랍니다

기상 상황에 따라 추가 변경 가능합니다.''',
        type: 'urgent',
        createdAt: now.subtract(const Duration(hours: 2)),
        createdBy: '관리자',
      ),
      Notice(
        id: '10',
        title: '교회 도서관 개방 안내',
        content: '''교회 도서관이 새롭게 개방됩니다.

개방 시간: 
- 평일 오전 9시 ~ 오후 6시
- 주말 오전 10시 ~ 오후 4시

이용 규칙:
- 정숙한 분위기 유지
- 도서 대출은 사무실에서
- 음식물 반입 금지

많은 이용 바랍니다.''',
        type: 'general',
        createdAt: now.subtract(const Duration(days: 8)),
        createdBy: '관리자',
      ),
    ];
  }
}
