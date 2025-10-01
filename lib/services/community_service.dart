import 'package:smart_yoram_app/models/api_response.dart';
import 'package:smart_yoram_app/models/community_post.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';

/// 커뮤니티 게시글 관리 서비스
class CommunityService {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  /// 게시글 목록 조회
  Future<List<CommunityPost>> getPosts({
    String? category,
    int page = 1,
    int limit = 20,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      final churchId = currentUser.churchId;
      final userId = currentUser.id;

      // Supabase 직접 쿼리
      dynamic query = _supabaseService.client
          .from('community_posts')
          .select()
          .eq('church_id', churchId)
          .eq('status', 'active');

      // 카테고리 필터
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // 정렬
      query = query.order(orderBy, ascending: ascending);

      // 페이지네이션
      final offset = (page - 1) * limit;
      query = query.range(offset, offset + limit - 1);

      final response = await query;

      print('✅ COMMUNITY_SERVICE: 게시글 ${response.length}개 조회');

      return (response as List)
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 게시글 조회 실패 - $e');
      return [];
    }
  }

  /// 내가 쓴 글 조회
  Future<List<CommunityPost>> getMyPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      final userId = currentUser.id;

      final offset = (page - 1) * limit;
      final response = await _supabaseService.client
          .from('community_posts')
          .select()
          .eq('author_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('✅ COMMUNITY_SERVICE: 내 게시글 ${response.length}개 조회');

      return (response as List)
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 내 게시글 조회 실패 - $e');
      return [];
    }
  }

  /// 찜한 글 조회
  Future<List<CommunityPost>> getFavoritePosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      final userId = currentUser.id;

      // community_favorites 테이블과 JOIN
      final offset = (page - 1) * limit;
      final response = await _supabaseService.client
          .from('community_favorites')
          .select('post_id, community_posts(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('✅ COMMUNITY_SERVICE: 찜한 게시글 ${response.length}개 조회');

      return (response as List)
          .map((item) {
            final postData = item['community_posts'] as Map<String, dynamic>;
            return CommunityPost.fromJson(postData);
          })
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 찜한 게시글 조회 실패 - $e');
      return [];
    }
  }

  /// 게시글 상세 조회
  Future<CommunityPost?> getPostDetail(int postId) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ COMMUNITY_SERVICE: 로그인된 사용자 없음');
        return null;
      }

      final response = await _supabaseService.client
          .from('community_posts')
          .select()
          .eq('id', postId)
          .single();

      // 조회수 증가
      await _incrementViewCount(postId);

      print('✅ COMMUNITY_SERVICE: 게시글 상세 조회 성공');

      return CommunityPost.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 게시글 상세 조회 실패 - $e');
      return null;
    }
  }

  /// 게시글 작성
  Future<ApiResponse<CommunityPost>> createPost({
    required String category,
    required String title,
    required String content,
    List<String> imageUrls = const [],
    int? price,
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

      final postData = {
        'church_id': currentUser.churchId,
        'author_id': currentUser.id,
        'author_name': currentUser.fullName,
        'category': category,
        'title': title,
        'content': content,
        'image_urls': imageUrls,
        'price': price,
        'status': 'active',
        'view_count': 0,
        'like_count': 0,
        'comment_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('community_posts')
          .insert(postData)
          .select()
          .single();

      final post = CommunityPost.fromJson(response as Map<String, dynamic>);

      print('✅ COMMUNITY_SERVICE: 게시글 작성 성공');

      return ApiResponse(
        success: true,
        message: '게시글이 작성되었습니다',
        data: post,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 게시글 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '게시글 작성에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 게시글 수정
  Future<ApiResponse<CommunityPost>> updatePost({
    required int postId,
    String? title,
    String? content,
    List<String>? imageUrls,
    int? price,
    String? status,
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

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (imageUrls != null) updateData['image_urls'] = imageUrls;
      if (price != null) updateData['price'] = price;
      if (status != null) updateData['status'] = status;

      final response = await _supabaseService.client
          .from('community_posts')
          .update(updateData)
          .eq('id', postId)
          .eq('author_id', currentUser.id) // 작성자만 수정 가능
          .select()
          .single();

      final post = CommunityPost.fromJson(response as Map<String, dynamic>);

      print('✅ COMMUNITY_SERVICE: 게시글 수정 성공');

      return ApiResponse(
        success: true,
        message: '게시글이 수정되었습니다',
        data: post,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 게시글 수정 실패 - $e');
      return ApiResponse(
        success: false,
        message: '게시글 수정에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 게시글 삭제
  Future<ApiResponse<void>> deletePost(int postId) async {
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
            .from('community_posts')
            .update({'status': 'deleted'})
            .eq('id', postId);
      } else {
        // 일반 사용자는 본인 게시글만 삭제 가능
        await _supabaseService.client
            .from('community_posts')
            .update({'status': 'deleted'})
            .eq('id', postId)
            .eq('author_id', currentUser.id);
      }

      print('✅ COMMUNITY_SERVICE: 게시글 삭제 성공');

      return ApiResponse(
        success: true,
        message: '게시글이 삭제되었습니다',
        data: null,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 게시글 삭제 실패 - $e');
      return ApiResponse(
        success: false,
        message: '게시글 삭제에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 좋아요 토글
  Future<ApiResponse<bool>> toggleLike(int postId) async {
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

      final userId = currentUser.id;

      // 좋아요 여부 확인
      final existingLike = await _supabaseService.client
          .from('community_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      bool isLiked;

      if (existingLike != null) {
        // 좋아요 취소
        await _supabaseService.client
            .from('community_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        await _decrementLikeCount(postId);
        isLiked = false;
        print('✅ COMMUNITY_SERVICE: 좋아요 취소');
      } else {
        // 좋아요 추가
        await _supabaseService.client
            .from('community_likes')
            .insert({
              'post_id': postId,
              'user_id': userId,
              'created_at': DateTime.now().toIso8601String(),
            });

        await _incrementLikeCount(postId);
        isLiked = true;
        print('✅ COMMUNITY_SERVICE: 좋아요 추가');
      }

      return ApiResponse(
        success: true,
        message: isLiked ? '좋아요' : '좋아요 취소',
        data: isLiked,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 좋아요 토글 실패 - $e');
      return ApiResponse(
        success: false,
        message: '좋아요 처리에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 찜하기 토글
  Future<ApiResponse<bool>> toggleFavorite(int postId) async {
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

      final userId = currentUser.id;

      // 찜 여부 확인
      final existingFavorite = await _supabaseService.client
          .from('community_favorites')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      bool isFavorited;

      if (existingFavorite != null) {
        // 찜 취소
        await _supabaseService.client
            .from('community_favorites')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);

        isFavorited = false;
        print('✅ COMMUNITY_SERVICE: 찜 취소');
      } else {
        // 찜 추가
        await _supabaseService.client
            .from('community_favorites')
            .insert({
              'post_id': postId,
              'user_id': userId,
              'created_at': DateTime.now().toIso8601String(),
            });

        isFavorited = true;
        print('✅ COMMUNITY_SERVICE: 찜 추가');
      }

      return ApiResponse(
        success: true,
        message: isFavorited ? '찜 목록에 추가했습니다' : '찜 목록에서 제거했습니다',
        data: isFavorited,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 찜하기 토글 실패 - $e');
      return ApiResponse(
        success: false,
        message: '찜하기 처리에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 조회수 증가 (내부 메서드)
  Future<void> _incrementViewCount(int postId) async {
    try {
      await _supabaseService.client.rpc('increment_post_view_count', params: {
        'post_id': postId,
      });
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 조회수 증가 실패 - $e');
    }
  }

  /// 좋아요 수 증가 (내부 메서드)
  Future<void> _incrementLikeCount(int postId) async {
    try {
      await _supabaseService.client.rpc('increment_post_like_count', params: {
        'post_id': postId,
      });
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 좋아요 수 증가 실패 - $e');
    }
  }

  /// 좋아요 수 감소 (내부 메서드)
  Future<void> _decrementLikeCount(int postId) async {
    try {
      await _supabaseService.client.rpc('decrement_post_like_count', params: {
        'post_id': postId,
      });
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 좋아요 수 감소 실패 - $e');
    }
  }

  /// 댓글 목록 조회
  Future<List<CommunityComment>> getComments(int postId) async {
    try {
      final response = await _supabaseService.client
          .from('community_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      print('✅ COMMUNITY_SERVICE: 댓글 ${response.length}개 조회');

      return (response as List)
          .map((item) => CommunityComment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 댓글 조회 실패 - $e');
      return [];
    }
  }

  /// 댓글 작성
  Future<ApiResponse<CommunityComment>> createComment({
    required int postId,
    required String content,
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

      final commentData = {
        'post_id': postId,
        'author_id': currentUser.id,
        'author_name': currentUser.fullName,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.client
          .from('community_comments')
          .insert(commentData)
          .select()
          .single();

      // 댓글 수 증가
      await _incrementCommentCount(postId);

      final comment = CommunityComment.fromJson(response as Map<String, dynamic>);

      print('✅ COMMUNITY_SERVICE: 댓글 작성 성공');

      return ApiResponse(
        success: true,
        message: '댓글이 작성되었습니다',
        data: comment,
      );
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 댓글 작성 실패 - $e');
      return ApiResponse(
        success: false,
        message: '댓글 작성에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 댓글 수 증가 (내부 메서드)
  Future<void> _incrementCommentCount(int postId) async {
    try {
      await _supabaseService.client.rpc('increment_post_comment_count', params: {
        'post_id': postId,
      });
    } catch (e) {
      print('❌ COMMUNITY_SERVICE: 댓글 수 증가 실패 - $e');
    }
  }
}
