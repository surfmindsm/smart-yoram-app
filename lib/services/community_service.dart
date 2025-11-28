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

      final responseList = response as List;
      if (responseList.isEmpty) return [];

      print('📋 COMMUNITY_SERVICE: 첫 번째 항목 - ${responseList[0]}');

      // 모든 author_id와 church_id 수집
      final authorIds = responseList
          .map((item) => item['author_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final churchIds = responseList
          .map((item) => item['church_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      print('📋 COMMUNITY_SERVICE: authorIds - $authorIds');
      print('📋 COMMUNITY_SERVICE: churchIds - $churchIds');

      // 한 번에 author 정보 조회 (users 테이블에서 full_name)
      Map<int, String> authorNames = {};
      if (authorIds.isNotEmpty) {
        try {
          print('📋 COMMUNITY_SERVICE: users 테이블 조회 시작 - ids: $authorIds');

          final authorsResponse = await _supabaseService.client
              .from('users')
              .select('id, full_name')
              .inFilter('id', authorIds);

          print('📋 COMMUNITY_SERVICE: authorsResponse - $authorsResponse');

          for (var author in authorsResponse as List) {
            authorNames[author['id'] as int] = author['full_name'] as String;
          }

          print('📋 COMMUNITY_SERVICE: authorNames - $authorNames');
        } catch (e, stackTrace) {
          print('⚠️ COMMUNITY_SERVICE: authors 조회 실패 - $e');
          print('⚠️ COMMUNITY_SERVICE: stackTrace - $stackTrace');
        }
      }

      // 한 번에 church 정보 조회 (name, address)
      Map<int, String> churchNames = {};
      Map<int, String> churchLocations = {}; // 도시 + 구/동
      if (churchIds.isNotEmpty) {
        try {
          final churchesResponse = await _supabaseService.client
              .from('churches')
              .select('id, name, address')
              .inFilter('id', churchIds);

          print('📋 COMMUNITY_SERVICE: churchesResponse - $churchesResponse');

          for (var church in churchesResponse as List) {
            churchNames[church['id'] as int] = church['name'] as String;

            // 주소에서 도시 + 구/동만 추출
            if (church['address'] != null) {
              final location = _extractCityDistrict(church['address'] as String);
              if (location != null) {
                churchLocations[church['id'] as int] = location;
              }
            }
          }

          print('📋 COMMUNITY_SERVICE: churchNames - $churchNames');
          print('📋 COMMUNITY_SERVICE: churchLocations - $churchLocations');
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: churches 조회 실패 - $e');
        }
      }

      // 데이터 병합
      final items = <SharingItem>[];
      for (var item in responseList) {
        final itemMap = item as Map<String, dynamic>;

        // author_name 추가
        if (itemMap['author_id'] != null) {
          itemMap['author_name'] = authorNames[itemMap['author_id']];
        }

        // church_name, location 추가
        if (itemMap['church_id'] != null) {
          itemMap['church_name'] = churchNames[itemMap['church_id']];
          itemMap['church_location'] = churchLocations[itemMap['church_id']];
        }

        print('📋 COMMUNITY_SERVICE: 병합된 항목 - author_name: ${itemMap['author_name']}, church_name: ${itemMap['church_name']}, location: ${itemMap['church_location']}');

        items.add(SharingItem.fromJson(itemMap));
      }

      return items;
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

      final itemMap = response as Map<String, dynamic>;

      // author 정보 가져오기 (users와 members 조인)
      if (itemMap['author_id'] != null) {
        try {
          // users 테이블에서 기본 정보 조회
          final userResponse = await _supabaseService.client
              .from('users')
              .select('full_name, id')
              .eq('id', itemMap['author_id'])
              .single();
          itemMap['author_name'] = userResponse['full_name'];

          // members 테이블에서 프로필 이미지 조회
          try {
            final memberResponse = await _supabaseService.client
                .from('members')
                .select('profile_photo_url')
                .eq('user_id', itemMap['author_id'])
                .single();
            itemMap['author_profile_photo_url'] = memberResponse['profile_photo_url'];
          } catch (e) {
            print('⚠️ COMMUNITY_SERVICE: member profile 조회 실패 - $e');
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: author 조회 실패 - $e');
        }
      }

      // church 정보 가져오기
      if (itemMap['church_id'] != null) {
        try {
          final churchResponse = await _supabaseService.client
              .from('churches')
              .select('name, address')
              .eq('id', itemMap['church_id'])
              .single();
          itemMap['church_name'] = churchResponse['name'];

          // 주소에서 도시 + 구/동 추출
          if (churchResponse['address'] != null) {
            final location = _extractCityDistrict(churchResponse['address'] as String);
            if (location != null) {
              itemMap['church_location'] = location;
            }
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: church 조회 실패 - $e');
        }
      }

      return SharingItem.fromJson(itemMap);
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
    String? province,
    String? district,
    bool? deliveryAvailable,
    required List<String> images,
    required bool isFree,
    int? price,
    String? purchaseDate,
    required String contactPhone,
    String? contactEmail,
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
        'province': province,
        'district': district,
        'delivery_available': deliveryAvailable ?? false,
        'images': images,
        'is_free': isFree,
        'price': price,
        'purchase_date': purchaseDate,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
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
          .select('*');

      if (category != null) query = query.eq('category', category);
      if (urgency != null) query = query.eq('urgency', urgency);
      if (status != null) query = query.eq('status', status);
      if (search != null) {
        query = query.or('title.ilike.%$search%,description.ilike.%$search%');
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;

      final responseList = response as List;
      print('📋 COMMUNITY_SERVICE: 물품 요청 조회 결과 - ${responseList.length}개');

      if (responseList.isEmpty) return [];

      // 모든 author_id와 church_id 수집
      final authorIds = responseList
          .map((item) => item['author_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      final churchIds = responseList
          .map((item) => item['church_id'] as int?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // 한 번에 author 정보 조회 (users 테이블)
      Map<int, String> authorNames = {};
      Map<int, String?> authorPhotos = {};

      if (authorIds.isNotEmpty) {
        try {
          final authorsResponse = await _supabaseService.client
              .from('users')
              .select('id, full_name')
              .inFilter('id', authorIds);

          for (var author in authorsResponse as List) {
            authorNames[author['id'] as int] = author['full_name'] as String;
          }

          // members 테이블에서 profile_photo_url 일괄 조회
          final membersResponse = await _supabaseService.client
              .from('members')
              .select('user_id, profile_photo_url')
              .inFilter('user_id', authorIds);

          for (var member in membersResponse as List) {
            authorPhotos[member['user_id'] as int] = member['profile_photo_url'] as String?;
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: authors 조회 실패 - $e');
        }
      }

      // 한 번에 church 정보 조회
      Map<int, String> churchNames = {};

      if (churchIds.isNotEmpty) {
        try {
          final churchesResponse = await _supabaseService.client
              .from('churches')
              .select('id, name')
              .inFilter('id', churchIds);

          for (var church in churchesResponse as List) {
            churchNames[church['id'] as int] = church['name'] as String;
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: churches 조회 실패 - $e');
        }
      }

      // 데이터 조합
      final List<RequestItem> items = [];
      for (var itemData in responseList) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(itemData);

        // author 정보 추가
        if (data['author_id'] != null) {
          final authorId = data['author_id'] as int;
          data['author_name'] = authorNames[authorId];
          data['author_profile_photo_url'] = authorPhotos[authorId];
        }

        // church 정보 추가
        if (data['church_id'] != null) {
          final churchId = data['church_id'] as int;
          data['church_name'] = churchNames[churchId];
        }

        items.add(RequestItem.fromJson(data));
      }

      return items;
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

      final itemMap = response as Map<String, dynamic>;

      // author 정보 가져오기 (users와 members 테이블에서)
      if (itemMap['author_id'] != null) {
        try {
          // users 테이블에서 full_name 조회
          final authorResponse = await _supabaseService.client
              .from('users')
              .select('full_name')
              .eq('id', itemMap['author_id'])
              .single();
          itemMap['author_name'] = authorResponse['full_name'];

          // members 테이블에서 profile_photo_url 조회
          try {
            final memberResponse = await _supabaseService.client
                .from('members')
                .select('profile_photo_url')
                .eq('user_id', itemMap['author_id'])
                .maybeSingle();

            if (memberResponse != null) {
              itemMap['author_profile_photo_url'] = memberResponse['profile_photo_url'];
            }
          } catch (e) {
            print('⚠️ COMMUNITY_SERVICE: member profile 조회 실패 - $e');
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: author 조회 실패 - $e');
        }
      }

      // church 정보 가져오기
      if (itemMap['church_id'] != null) {
        try {
          final churchResponse = await _supabaseService.client
              .from('churches')
              .select('name, address')
              .eq('id', itemMap['church_id'])
              .single();
          itemMap['church_name'] = churchResponse['name'];

          // 주소에서 도시 + 구/동 추출
          if (churchResponse['address'] != null) {
            final location = _extractCityDistrict(churchResponse['address'] as String);
            if (location != null) {
              itemMap['location'] = location;
            }
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: church 조회 실패 - $e');
        }
      }

      return RequestItem.fromJson(itemMap);
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
    String? province,
    String? district,
    bool? deliveryAvailable,
    required String urgency,
    required List<String> images,
    required String contactPhone,
    String? contactEmail,
    String? rewardType,
    double? rewardAmount,
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
        'province': province,
        'district': district,
        'delivery_available': deliveryAvailable ?? false,
        'urgency': urgency,
        'images': images,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'reward_type': rewardType,
        'reward_amount': rewardAmount,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
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
      print('🔍 COMMUNITY_SERVICE: 조회수 증가 시도 - $tableName/$id');

      // 현재 조회수 가져오기
      final current = await _supabaseService.client
          .from(tableName)
          .select('view_count')
          .eq('id', id)
          .single();

      final currentCount = current['view_count'] as int? ?? 0;
      print('🔍 COMMUNITY_SERVICE: 현재 조회수 - $currentCount');

      // 조회수 1 증가
      final updateResult = await _supabaseService.client
          .from(tableName)
          .update({'view_count': currentCount + 1})
          .eq('id', id)
          .select();

      print('✅ COMMUNITY_SERVICE: 조회수 증가 완료 - $tableName/$id: $currentCount → ${currentCount + 1}');
      print('✅ UPDATE 결과: $updateResult');
    } catch (e, stackTrace) {
      print('❌ COMMUNITY_SERVICE: 조회수 증가 실패 - $tableName/$id');
      print('❌ 에러 타입: ${e.runtimeType}');
      print('❌ 에러 내용: $e');
      print('❌ 스택 트레이스: $stackTrace');
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

      // 조회수 증가
      await _incrementViewCount('job_posts', id);

      final itemMap = response as Map<String, dynamic>;

      // author 정보 가져오기
      if (itemMap['author_id'] != null) {
        try {
          final authorResponse = await _supabaseService.client
              .from('users')
              .select('full_name')
              .eq('id', itemMap['author_id'])
              .single();
          itemMap['author_name'] = authorResponse['full_name'];
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: author 조회 실패 - $e');
        }
      }

      // church 정보 가져오기
      if (itemMap['church_id'] != null) {
        try {
          final churchResponse = await _supabaseService.client
              .from('churches')
              .select('name, address')
              .eq('id', itemMap['church_id'])
              .single();
          itemMap['church_name'] = churchResponse['name'];

          // 주소에서 도시 + 구/동 추출
          if (churchResponse['address'] != null) {
            final location = _extractCityDistrict(churchResponse['address'] as String);
            if (location != null) {
              itemMap['location'] = location;
            }
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: church 조회 실패 - $e');
        }
      }

      return JobPost.fromJson(itemMap);
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

      // 조회수 증가
      await _incrementViewCount('community_music_teams', id);

      final itemMap = response as Map<String, dynamic>;

      // author 정보 가져오기
      if (itemMap['author_id'] != null) {
        try {
          final authorResponse = await _supabaseService.client
              .from('users')
              .select('full_name')
              .eq('id', itemMap['author_id'])
              .single();
          itemMap['author_name'] = authorResponse['full_name'];
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: author 조회 실패 - $e');
        }
      }

      // church 정보 가져오기
      if (itemMap['church_id'] != null) {
        try {
          final churchResponse = await _supabaseService.client
              .from('churches')
              .select('name, address')
              .eq('id', itemMap['church_id'])
              .single();
          itemMap['church_name'] = churchResponse['name'];

          // 주소에서 도시 + 구/동 추출
          if (churchResponse['address'] != null) {
            final location = _extractCityDistrict(churchResponse['address'] as String);
            if (location != null) {
              itemMap['location'] = location;
            }
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: church 조회 실패 - $e');
        }
      }

      return MusicTeamRecruitment.fromJson(itemMap);
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

      // 조회수 증가
      await _incrementViewCount('music_team_seekers', id);

      final itemMap = response as Map<String, dynamic>;

      // author 정보 가져오기
      if (itemMap['author_id'] != null) {
        try {
          final authorResponse = await _supabaseService.client
              .from('users')
              .select('full_name')
              .eq('id', itemMap['author_id'])
              .single();
          itemMap['author_name'] = authorResponse['full_name'];
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: author 조회 실패 - $e');
        }
      }

      // church 정보 가져오기
      if (itemMap['church_id'] != null) {
        try {
          final churchResponse = await _supabaseService.client
              .from('churches')
              .select('name, address')
              .eq('id', itemMap['church_id'])
              .single();
          itemMap['church_name'] = churchResponse['name'];
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: church 조회 실패 - $e');
        }
      }

      return MusicTeamSeeker.fromJson(itemMap);
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

      // 조회수 증가
      await _incrementViewCount('church_news', id);

      final itemMap = response as Map<String, dynamic>;

      // author 정보 가져오기
      if (itemMap['author_id'] != null) {
        try {
          final authorResponse = await _supabaseService.client
              .from('users')
              .select('full_name')
              .eq('id', itemMap['author_id'])
              .single();
          itemMap['author_name'] = authorResponse['full_name'];
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: author 조회 실패 - $e');
        }
      }

      // church 정보 가져오기
      if (itemMap['church_id'] != null) {
        try {
          final churchResponse = await _supabaseService.client
              .from('churches')
              .select('name, address')
              .eq('id', itemMap['church_id'])
              .single();
          itemMap['church_name'] = churchResponse['name'];

          // 주소에서 도시 + 구/동 추출
          if (churchResponse['address'] != null) {
            final location = _extractCityDistrict(churchResponse['address'] as String);
            if (location != null) {
              itemMap['location'] = location;
            }
          }
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: church 조회 실패 - $e');
        }
      }

      return ChurchNews.fromJson(itemMap);
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
    String? province,
    String? district,
    bool? deliveryAvailable,
    String? deadline,
    required String contactPhone,
    String? contactEmail,
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

      // province + district를 합쳐서 location 생성
      String? location;
      if (province != null && district != null) {
        location = '$province $district';
      } else if (province != null) {
        location = province;
      }

      // contact_phone + contact_email을 합쳐서 contact_info 생성
      String contactInfo = contactPhone;
      if (contactEmail != null && contactEmail.isNotEmpty) {
        contactInfo = '$contactPhone / $contactEmail';
      }

      // description에 교회소개와 모집분야 정보 추가
      String fullDescription = description;
      if (churchIntro.isNotEmpty) {
        fullDescription = '【교회 소개】\n$churchIntro\n\n【모집 분야】\n$position\n\n【상세 내용】\n$description';
      } else if (position.isNotEmpty) {
        fullDescription = '【모집 분야】\n$position\n\n【상세 내용】\n$description';
      }

      final data = {
        'title': title,
        'description': fullDescription,
        'company_name': company,
        'job_type': jobType,
        'employment_type': employmentType,
        'salary_range': salary,
        'requirements': qualifications,
        'location': location,
        'application_deadline': deadline,
        'contact_info': contactInfo,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
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
    required String eventType,
    required String teamType,
    String? eventDate,
    String? rehearsalSchedule,
    required String location,
    String? requirements,
    String? compensation, // UI에서는 compensation으로 받지만 DB에는 benefits로 저장
    required String contactPhone,
    String? contactEmail,
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

      // contact_method 결정 (email이 있으면 email, 없으면 phone)
      final contactMethod = (contactEmail != null && contactEmail.isNotEmpty) ? 'email' : 'phone';

      // contact_info 생성
      String contactInfo = contactPhone;
      if (contactEmail != null && contactEmail.isNotEmpty) {
        contactInfo = '$contactPhone / $contactEmail';
      }

      final data = {
        'title': title,
        'team_name': title, // 필수: 팀명은 제목으로 대체
        'worship_type': eventType, // 필수: 예배 형태 (기존 eventType 매핑)
        'team_types': [teamType], // JSONB 배열
        'instruments_needed': null, // JSON - 현재는 null
        'positions_needed': null, // 현재는 null
        'experience_required': '무관', // 필수: 기본값 '무관'
        'practice_location': location, // 필수: 연습 장소
        'practice_schedule': rehearsalSchedule ?? '협의', // 필수: 연습 일정
        'commitment': null,
        'description': description,
        'requirements': requirements,
        'benefits': compensation, // ⭐ compensation → benefits로 변경
        'contact_method': contactMethod, // 필수: 연락 방법
        'contact_info': contactInfo, // 필수: 연락처 정보
        'current_members': null,
        'target_members': null,
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'status': 'active',
        'created_at': DateTime.now().toUtc().toIso8601String(),
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
    required String teamName,
    required String instrument,
    required String experience,
    required String portfolio,
    String? portfolioFile,
    required List<String> preferredLocation,
    required List<String> availableDays,
    required String availableTime,
    required String contactPhone,
    String? contactEmail,
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

      // author_name 필수 (NOT NULL 제약조건)
      String authorName = currentUser.fullName ?? '알 수 없음';

      // church_name 가져오기
      String? churchName;
      if (currentUser.churchId != null) {
        try {
          final churchResponse = await _supabaseService.client
              .from('churches')
              .select('name')
              .eq('id', currentUser.churchId!)
              .single();
          churchName = churchResponse['name'] as String?;
        } catch (e) {
          print('⚠️ COMMUNITY_SERVICE: church 조회 실패 - $e');
        }
      }

      final data = {
        'title': title,
        'team_name': teamName,
        'instrument': instrument,
        'experience': experience.isNotEmpty ? experience : null,
        'portfolio': portfolio.isNotEmpty ? portfolio : null,
        'portfolio_file': portfolioFile,
        'preferred_location': preferredLocation.isNotEmpty ? preferredLocation : null,
        'available_days': availableDays.isNotEmpty ? availableDays : null,
        'available_time': availableTime.isNotEmpty ? availableTime : null,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'author_id': currentUser.id,
        'author_name': authorName, // NOT NULL 필드
        'church_id': currentUser.churchId,
        'church_name': churchName,
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

      // 🔍 디버깅: JWT 토큰 확인
      final session = _supabaseService.currentSession;
      final authUser = _supabaseService.currentUser;
      print('🔐 JWT 토큰: ${session?.accessToken?.substring(0, 50) ?? "없음"}...');
      print('🔐 Auth User ID: ${authUser?.id ?? "없음"}');
      print('🔐 Session 유효: ${session != null}');

      final data = {
        'title': title,
        'content': description,  // church_news 테이블은 content 컬럼 사용
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

  /// 주소에서 도시 + 구/동 추출
  /// 예: "서울특별시 강남구 신사동 123-45" → "강남구 신사동"
  /// 예: "경기도 성남시 분당구 정자동" → "성남시 분당구"
  String? _extractCityDistrict(String fullAddress) {
    if (fullAddress.isEmpty) return null;

    try {
      // 공백으로 분리
      final parts = fullAddress.split(' ');
      if (parts.length < 2) return null;

      // 첫 번째 파트가 광역시/도인 경우
      final first = parts[0];

      // 서울특별시, 부산광역시 등 → 구 + 동
      if (first.contains('서울') || first.contains('부산') ||
          first.contains('대구') || first.contains('인천') ||
          first.contains('광주') || first.contains('대전') ||
          first.contains('울산') || first.contains('세종')) {
        // parts[1]은 구, parts[2]는 동
        if (parts.length >= 3) {
          return '${parts[1]} ${parts[2]}';
        } else if (parts.length >= 2) {
          return parts[1];
        }
      }

      // 경기도, 충청도 등 → 시 + 구/동
      if (first.contains('도')) {
        if (parts.length >= 3) {
          return '${parts[1]} ${parts[2]}';
        } else if (parts.length >= 2) {
          return parts[1];
        }
      }

      // 기타: 앞 2개 파트 반환
      return '${parts[0]} ${parts[1]}';
    } catch (e) {
      print('⚠️ COMMUNITY_SERVICE: 주소 파싱 실패 - $e');
      return null;
    }
  }

  // ==========================================================================
  // 상태 업데이트
  // ==========================================================================

  /// 게시글 상태 업데이트
  /// tableName: 테이블명 (community_sharing, community_requests, job_posts 등)
  /// postId: 게시글 ID
  /// newStatus: 새로운 상태 값
  Future<ApiResponse<bool>> updatePostStatus({
    required String tableName,
    required int postId,
    required String newStatus,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: false,
        );
      }

      print('🔄 COMMUNITY_SERVICE: 상태 업데이트 - $tableName/$postId → $newStatus');

      // 게시글 소유자 확인
      final post = await _supabaseService.client
          .from(tableName)
          .select('author_id')
          .eq('id', postId)
          .single();

      if (post['author_id'] != currentUser.id) {
        return ApiResponse(
          success: false,
          message: '권한이 없습니다',
          data: false,
        );
      }

      // 상태 업데이트
      await _supabaseService.client
          .from(tableName)
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', postId);

      print('✅ COMMUNITY_SERVICE: 상태 업데이트 완료');

      return ApiResponse(
        success: true,
        message: '상태가 변경되었습니다',
        data: true,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 상태 업데이트 실패 - $e');
      return ApiResponse(
        success: false,
        message: '상태 변경에 실패했습니다: $e',
        data: false,
      );
    }
  }
}
