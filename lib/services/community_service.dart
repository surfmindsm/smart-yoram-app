import 'package:smart_yoram_app/models/api_response.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';

/// 커뮤니티 서비스
/// 웹의 Supabase Edge Functions 구조를 따름
class CommunityService {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  // ==========================================================================
  // 1. 무료 나눔 / 물품 판매 (community-sharing Edge Function)
  // ==========================================================================

  /// 무료 나눔/물품 판매 목록 조회
  /// 전국 모든 교회의 게시글 조회 (church_id 필터 없음)
  Future<List<SharingItem>> getSharingItems({
    int limit = 50,
    String? category,
    String? status,
    String? search,
    bool? isFree, // true: 무료나눔, false: 물품판매
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      print('📋 COMMUNITY_SERVICE: 무료나눔/판매 조회 - isFree: $isFree');

      // Supabase 직접 쿼리 (church_id 필터 제거 - 전국 공유)
      dynamic query = _supabaseService.client
          .from('community_sharing')
          .select();

      if (category != null) query = query.eq('category', category);
      if (status != null) query = query.eq('status', status);
      if (isFree != null) query = query.eq('is_free', isFree);
      if (search != null) {
        query = query.or('title.ilike.%$search%,description.ilike.%$search%');
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;
      print('📋 COMMUNITY_SERVICE: 조회 결과 - ${(response as List).length}개');

      if ((response as List).isNotEmpty) {
        print('📋 COMMUNITY_SERVICE: 첫 번째 항목 - ${response[0]}');
      }

      return (response as List)
          .map((item) => SharingItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 나눔/판매 목록 조회 실패 - $e');
      return [];
    }
  }

  /// 무료 나눔/물품 판매 상세 조회
  Future<SharingItem?> getSharingItem(int id) async {
    try {
      final response = await _supabaseService.client
          .from('community_sharing')
          .select()
          .eq('id', id)
          .single();

      // 조회수 증가
      await _incrementViewCount('community_sharing', id);

      return SharingItem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 나눔/판매 상세 조회 실패 - $e');
      return null;
    }
  }

  /// 무료 나눔/물품 판매 작성
  Future<ApiResponse<SharingItem>> createSharingItem({
    required String title,
    required String description,
    required String category,
    required String condition,
    required int quantity,
    required String location,
    required List<String> images,
    required bool isFree,
    int? price,
    String? deliveryMethod,
    String? purchaseDate,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📝 COMMUNITY_SERVICE: 나눔/판매 작성 - $title');

      final data = {
        'title': title,
        'description': description,
        'category': category,
        'condition': condition,
        'quantity': quantity,
        'location': location,
        'images': images,
        'is_free': isFree,
        'price': price,
        'delivery_method': deliveryMethod,
        'purchase_date': purchaseDate,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('community_sharing')
          .insert(data)
          .select()
          .single();

      print('✅ COMMUNITY_SERVICE: 나눔/판매 작성 성공');

      return ApiResponse(
        success: true,
        message: '등록되었습니다',
        data: SharingItem.fromJson(response as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 나눔/판매 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '등록에 실패했습니다: $e',
        data: null,
      );
    }
  }

  // ==========================================================================
  // 2. 물품 요청 (community-requests Edge Function)
  // ==========================================================================

  /// 물품 요청 목록 조회
  /// 전국 모든 교회의 게시글 조회 (church_id 필터 없음)
  Future<List<RequestItem>> getRequestItems({
    int limit = 50,
    String? category,
    String? urgency,
    String? status,
    String? search,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      dynamic query = _supabaseService.client
          .from('community_requests')
          .select();

      if (category != null) query = query.eq('category', category);
      if (urgency != null) query = query.eq('urgency', urgency);
      if (status != null) query = query.eq('status', status);
      if (search != null) {
        query = query.or('title.ilike.%$search%,description.ilike.%$search%');
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;

      return (response as List)
          .map((item) => RequestItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 물품 요청 목록 조회 실패 - $e');
      return [];
    }
  }

  /// 물품 요청 상세 조회
  Future<RequestItem?> getRequestItem(int id) async {
    try {
      final response = await _supabaseService.client
          .from('community_requests')
          .select()
          .eq('id', id)
          .single();

      await _incrementViewCount('community_requests', id);

      return RequestItem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 물품 요청 상세 조회 실패 - $e');
      return null;
    }
  }

  /// 물품 요청 작성
  Future<ApiResponse<RequestItem>> createRequestItem({
    required String title,
    required String description,
    required String category,
    required String requestedItem,
    required int quantity,
    required String reason,
    String? neededDate,
    required String location,
    required String priceRange,
    required String urgency,
    required List<String> images,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📝 COMMUNITY_SERVICE: 물품 요청 작성 - $title');

      final data = {
        'title': title,
        'description': description,
        'category': category,
        'requested_item': requestedItem,
        'quantity': quantity,
        'reason': reason,
        'needed_date': neededDate,
        'location': location,
        'price_range': priceRange,
        'urgency': urgency,
        'images': images,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('community_requests')
          .insert(data)
          .select()
          .single();

      print('✅ COMMUNITY_SERVICE: 물품 요청 작성 성공');

      return ApiResponse(
        success: true,
        message: '등록되었습니다',
        data: RequestItem.fromJson(response as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 물품 요청 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '등록에 실패했습니다: $e',
        data: null,
      );
    }
  }

  // ==========================================================================
  // 3. 구인 공고 (job_posts - 레거시 API)
  // ==========================================================================

  /// 구인 공고 목록 조회
  /// 전국 모든 교회의 게시글 조회 (church_id 필터 없음)
  Future<List<JobPost>> getJobPosts({
    int limit = 50,
    String? jobType,
    String? status,
    String? search,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      dynamic query = _supabaseService.client
          .from('job_posts')
          .select();

      if (jobType != null) query = query.eq('job_type', jobType);
      if (status != null) query = query.eq('status', status);
      if (search != null) {
        query = query.or('title.ilike.%$search%,description.ilike.%$search%');
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;

      return (response as List)
          .map((item) => JobPost.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 구인 공고 목록 조회 실패 - $e');
      return [];
    }
  }

  // ==========================================================================
  // 4. 음악팀 모집 (music-teams Edge Function)
  // ==========================================================================

  /// 음악팀 모집 목록 조회
  /// 전국 모든 교회의 게시글 조회 (church_id 필터 없음)
  Future<List<MusicTeamRecruitment>> getMusicTeamRecruitments({
    int limit = 50,
    String? worshipType,
    String? status,
    String? search,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      dynamic query = _supabaseService.client
          .from('community_music_teams')
          .select();

      if (worshipType != null) query = query.eq('worship_type', worshipType);
      if (status != null) query = query.eq('status', status);
      if (search != null) {
        query = query.or('title.ilike.%$search%,description.ilike.%$search%');
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;

      return (response as List)
          .map((item) => MusicTeamRecruitment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 음악팀 모집 목록 조회 실패 - $e');
      return [];
    }
  }

  // ==========================================================================
  // 5. 음악팀 참여 신청 (music-seekers Edge Function)
  // ==========================================================================

  /// 음악팀 참여 신청 목록 조회
  /// 전국 모든 교회의 게시글 조회 (church_id 필터 없음)
  Future<List<MusicTeamSeeker>> getMusicTeamSeekers({
    int limit = 50,
    String? instrument,
    String? status,
    String? search,
  }) async {
    try {
      print('📋 COMMUNITY_SERVICE: 행사팀 지원 조회 시작');

      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      print('📋 COMMUNITY_SERVICE: 행사팀 지원 쿼리 실행');

      dynamic query = _supabaseService.client
          .from('music_team_seekers')
          .select();

      if (instrument != null) query = query.eq('instrument', instrument);
      if (status != null) query = query.eq('status', status);
      if (search != null) {
        query = query.or('title.ilike.%$search%,name.ilike.%$search%');
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;

      print('📋 COMMUNITY_SERVICE: 행사팀 지원 조회 결과 - ${(response as List).length}개');

      return (response as List)
          .map((item) => MusicTeamSeeker.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 음악팀 참여 목록 조회 실패 - $e');
      return [];
    }
  }

  // ==========================================================================
  // 6. 교회 소식 (church-news Edge Function)
  // ==========================================================================

  /// 교회 소식 목록 조회
  /// 전국 모든 교회의 게시글 조회 (church_id 필터 없음)
  Future<List<ChurchNews>> getChurchNews({
    int limit = 50,
    String? category,
    String? priority,
    String? status,
    String? search,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      dynamic query = _supabaseService.client
          .from('church_news')
          .select();

      if (category != null) query = query.eq('category', category);
      if (priority != null) query = query.eq('priority', priority);
      if (status != null) query = query.eq('status', status);
      if (search != null) {
        query = query.or('title.ilike.%$search%,content.ilike.%$search%');
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;

      return (response as List)
          .map((item) => ChurchNews.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 교회 소식 목록 조회 실패 - $e');
      return [];
    }
  }

  // ==========================================================================
  // 공통 기능
  // ==========================================================================

  /// 조회수 증가
  Future<void> _incrementViewCount(String tableName, int id) async {
    try {
      await _supabaseService.client
          .from(tableName)
          .update({'view_count': _supabaseService.client.from(tableName).select('view_count').eq('id', id)})
          .eq('id', id);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 조회수 증가 실패 - $e');
    }
  }

  /// 게시글 삭제
  Future<ApiResponse<void>> deletePost(String tableName, int id) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      // 관리자는 모든 게시글 삭제 가능
      if (currentUser.isChurchAdmin || currentUser.isCommunityAdmin) {
        await _supabaseService.client
            .from(tableName)
            .delete()
            .eq('id', id);
      } else {
        // 일반 사용자는 본인 게시글만 삭제 가능
        await _supabaseService.client
            .from(tableName)
            .delete()
            .eq('id', id)
            .eq('author_id', currentUser.id);
      }

      return ApiResponse(
        success: true,
        message: '삭제되었습니다',
        data: null,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 게시글 삭제 실패 - $e');
      return ApiResponse(
        success: false,
        message: '삭제에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 내가 작성한 모든 게시글 조회
  Future<List<Map<String, dynamic>>> getMyPosts() async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      final userId = currentUser.id;
      final List<Map<String, dynamic>> allPosts = [];

      // 각 테이블에서 내 게시글 조회
      final tables = [
        'community_sharing',
        'community_requests',
        'job_posts',
        'community_music_teams',
        'music_team_seekers',
        'church_news',
      ];

      for (final table in tables) {
        try {
          final response = await _supabaseService.client
              .from(table)
              .select()
              .eq('author_id', userId)
              .order('created_at', ascending: false)
              .limit(10);

          for (final item in response as List) {
            allPosts.add({
              ...item as Map<String, dynamic>,
              'table': table,
            });
          }
        } catch (e) {
          print('❌ COMMUNITY_SERVICE: $table 조회 실패 - $e');
        }
      }

      // 날짜순 정렬
      allPosts.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] ?? DateTime.now().toIso8601String());
        final bDate = DateTime.parse(b['created_at'] ?? DateTime.now().toIso8601String());
        return bDate.compareTo(aDate);
      });

      return allPosts;
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 내 게시글 조회 실패 - $e');
      return [];
    }
  }

  /// 사역자 모집 단일 조회
  Future<JobPost?> getJobPost(int id) async {
    try {
      final response = await _supabaseService.client
          .from('job_posts')
          .select()
          .eq('id', id)
          .single();

      return JobPost.fromJson(response);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 사역자 모집 조회 실패 - $e');
      return null;
    }
  }

  /// 행사팀 모집 단일 조회
  Future<MusicTeamRecruitment?> getMusicTeamRecruitment(int id) async {
    try {
      final response = await _supabaseService.client
          .from('community_music_teams')
          .select()
          .eq('id', id)
          .single();

      return MusicTeamRecruitment.fromJson(response);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 행사팀 모집 조회 실패 - $e');
      return null;
    }
  }

  /// 행사팀 지원 단일 조회
  Future<MusicTeamSeeker?> getMusicTeamSeeker(int id) async {
    try {
      final response = await _supabaseService.client
          .from('music_team_seekers')
          .select()
          .eq('id', id)
          .single();

      return MusicTeamSeeker.fromJson(response);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 행사팀 지원 조회 실패 - $e');
      return null;
    }
  }

  /// 행사 소식 단일 조회
  Future<ChurchNews?> getChurchNewsItem(int id) async {
    try {
      final response = await _supabaseService.client
          .from('church_news')
          .select()
          .eq('id', id)
          .single();

      return ChurchNews.fromJson(response);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 행사 소식 조회 실패 - $e');
      return null;
    }
  }

  // ==========================================================================
  // CREATE 메서드들 (글쓰기)
  // ==========================================================================

  /// 사역자 모집 글 작성
  Future<ApiResponse<JobPost>> createJobPost({
    required String title,
    required String description,
    required String company,
    required String churchIntro,
    required String position,
    required String jobType,
    required String employmentType,
    required String salary,
    required String qualifications,
    required String location,
    String? deadline,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📝 COMMUNITY_SERVICE: 사역자 모집 작성 - $title');

      final data = {
        'title': title,
        'description': description,
        'company': company,
        'church_intro': churchIntro,
        'position': position,
        'job_type': jobType,
        'employment_type': employmentType,
        'salary': salary,
        'qualifications': qualifications,
        'location': location,
        'deadline': deadline,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('job_posts')
          .insert(data)
          .select()
          .single();

      print('✅ COMMUNITY_SERVICE: 사역자 모집 작성 성공');

      return ApiResponse(
        success: true,
        message: '등록되었습니다',
        data: JobPost.fromJson(response),
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 사역자 모집 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '등록에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 행사팀 모집 글 작성
  Future<ApiResponse<MusicTeamRecruitment>> createMusicTeamRecruitment({
    required String title,
    required String description,
    required String recruitmentType,
    required String worshipType,
    required List<String> instrumentsNeeded,
    required String schedule,
    required String location,
    required String requirements,
    required String compensation,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📝 COMMUNITY_SERVICE: 행사팀 모집 작성 - $title');

      final data = {
        'title': title,
        'description': description,
        'recruitment_type': recruitmentType,
        'worship_type': worshipType,
        'instruments_needed': instrumentsNeeded,
        'schedule': schedule,
        'location': location,
        'requirements': requirements,
        'compensation': compensation,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('community_music_teams')
          .insert(data)
          .select()
          .single();

      print('✅ COMMUNITY_SERVICE: 행사팀 모집 작성 성공');

      return ApiResponse(
        success: true,
        message: '등록되었습니다',
        data: MusicTeamRecruitment.fromJson(response),
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 행사팀 모집 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '등록에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 행사팀 지원 글 작성
  Future<ApiResponse<MusicTeamSeeker>> createMusicTeamSeeker({
    required String title,
    required String description,
    required String name,
    required String teamName,
    required String instrument,
    required List<String> instruments,
    required String experience,
    required String portfolio,
    String? portfolioFile,
    required List<String> preferredLocation,
    required List<String> availableDays,
    required String availableTime,
    required String introduction,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📝 COMMUNITY_SERVICE: 행사팀 지원 작성 - $title');

      final data = {
        'title': title,
        'description': description,
        'name': name,
        'team_name': teamName,
        'instrument': instrument,
        'instruments': instruments,
        'experience': experience,
        'portfolio': portfolio,
        'portfolio_file': portfolioFile,
        'preferred_location': preferredLocation,
        'available_days': availableDays,
        'available_time': availableTime,
        'introduction': introduction,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('music_team_seekers')
          .insert(data)
          .select()
          .single();

      print('✅ COMMUNITY_SERVICE: 행사팀 지원 작성 성공');

      return ApiResponse(
        success: true,
        message: '등록되었습니다',
        data: MusicTeamSeeker.fromJson(response),
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 행사팀 지원 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '등록에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 교회 소식 글 작성
  Future<ApiResponse<ChurchNews>> createChurchNews({
    required String title,
    required String description,
    required String category,
    required String priority,
    String? eventDate,
    String? eventTime,
    required String location,
    required String organizer,
    required String targetAudience,
    required String participationFee,
    required String contactPerson,
    required List<String> images,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📝 COMMUNITY_SERVICE: 교회 소식 작성 - $title');

      final data = {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'event_date': eventDate,
        'event_time': eventTime,
        'location': location,
        'organizer': organizer,
        'target_audience': targetAudience,
        'participation_fee': participationFee,
        'contact_person': contactPerson,
        'images': images,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('church_news')
          .insert(data)
          .select()
          .single();

      print('✅ COMMUNITY_SERVICE: 교회 소식 작성 성공');

      return ApiResponse(
        success: true,
        message: '등록되었습니다',
        data: ChurchNews.fromJson(response),
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 교회 소식 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '등록에 실패했습니다: $e',
        data: null,
      );
    }
  }
}
