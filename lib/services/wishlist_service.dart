import 'package:smart_yoram_app/models/api_response.dart';
import 'package:smart_yoram_app/models/wishlist_models.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 찜하기 서비스
/// Supabase Edge Function (wishlists) 연동
class WishlistService {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  /// 찜한 글 목록 조회
  Future<WishlistData> getWishlists({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ WISHLIST_SERVICE: 로그인된 사용자 없음');
        return WishlistData(
          items: [],
          pagination: WishlistPagination(
            page: 1,
            limit: 20,
            total: 0,
            totalPages: 0,
          ),
        );
      }

      print('📋 WISHLIST_SERVICE: 찜한 글 조회 - page: $page, limit: $limit');

      // Temp Token 생성
      final tempToken = _authService.getTempToken();
      if (tempToken == null) {
        print('❌ WISHLIST_SERVICE: Temp Token 생성 실패');
        return WishlistData(
          items: [],
          pagination: WishlistPagination(
            page: 1,
            limit: 20,
            total: 0,
            totalPages: 0,
          ),
        );
      }

      // Edge Function URL 생성
      const supabaseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co';
      final functionUrl = '$supabaseUrl/functions/v1/wishlists?page=$page&limit=$limit';

      print('📋 WISHLIST_SERVICE: GET 요청 - $functionUrl');

      // HTTP GET 요청
      final response = await http.get(
        Uri.parse(functionUrl),
        headers: {
          'temp-token': tempToken,
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkemhkc2FqZGFtcmZsdnliaHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NDg5ODEsImV4cCI6MjA2OTQyNDk4MX0.pgn6M5_ihDFt3ojQmCoc3Qf8pc7LzRvQEIDT7g1nW3c',
          'Content-Type': 'application/json',
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkemhkc2FqZGFtcmZsdnliaHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NDg5ODEsImV4cCI6MjA2OTQyNDk4MX0.pgn6M5_ihDFt3ojQmCoc3Qf8pc7LzRvQEIDT7g1nW3c',
        },
      );

      print('📋 WISHLIST_SERVICE: Edge Function 응답 - status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final items = jsonData['data']['items'] as List;
          print('📋 WISHLIST_SERVICE: 조회 성공 - ${items.length}개');
          return WishlistData.fromJson(jsonData['data']);
        } else {
          print('❌ WISHLIST_SERVICE: 조회 실패 - ${jsonData}');
          return WishlistData(
            items: [],
            pagination: WishlistPagination(
              page: 1,
              limit: 20,
              total: 0,
              totalPages: 0,
            ),
          );
        }
      } else {
        print('❌ WISHLIST_SERVICE: HTTP 오류 - ${response.statusCode}: ${response.body}');
        return WishlistData(
          items: [],
          pagination: WishlistPagination(
            page: 1,
            limit: 20,
            total: 0,
            totalPages: 0,
          ),
        );
      }
    } catch (e) {
      print('❌ WISHLIST_SERVICE: 찜한 글 조회 실패 - $e');
      return WishlistData(
        items: [],
        pagination: WishlistPagination(
          page: 1,
          limit: 20,
          total: 0,
          totalPages: 0,
        ),
      );
    }
  }

  /// 찜하기 추가
  Future<ApiResponse<WishlistItem>> addToWishlist({
    required String postType,
    required int postId,
    required String postTitle,
    required String postDescription,
    String? postImageUrl,
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

      print('💗 WISHLIST_SERVICE: 찜하기 추가 - $postType:$postId');

      // Temp Token 생성
      final tempToken = _authService.getTempToken();
      if (tempToken == null) {
        return ApiResponse(
          success: false,
          message: '인증 토큰 생성 실패',
          data: null,
        );
      }

      final wishlistData = {
        'post_type': postType,
        'post_id': postId,
        'post_title': postTitle,
        'post_description': postDescription,
        'post_image_url': postImageUrl,
      };

      // Edge Function 호출
      final response = await _supabaseService.client.functions.invoke(
        'wishlists',
        body: wishlistData,
        headers: {
          'temp-token': tempToken,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        print('💗 WISHLIST_SERVICE: 찜하기 추가 성공');
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? '찜하기에 추가되었습니다',
          data: WishlistItem.fromJson(response.data['data']),
        );
      } else {
        print('❌ WISHLIST_SERVICE: 찜하기 추가 실패 - ${response.data}');
        return ApiResponse(
          success: false,
          message: response.data?['message'] ?? '찜하기 추가에 실패했습니다',
          data: null,
        );
      }
    } catch (e) {
      print('❌ WISHLIST_SERVICE: 찜하기 추가 실패 - $e');
      return ApiResponse(
        success: false,
        message: '찜하기 추가에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 찜하기 제거
  Future<ApiResponse<void>> removeFromWishlist({
    required String postType,
    required int postId,
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

      print('💔 WISHLIST_SERVICE: 찜하기 제거 - $postType:$postId');

      // Temp Token 생성
      final tempToken = _authService.getTempToken();
      if (tempToken == null) {
        return ApiResponse(
          success: false,
          message: '인증 토큰 생성 실패',
          data: null,
        );
      }

      final removeData = {
        'post_type': postType,
        'post_id': postId,
      };

      // Edge Function 호출 (DELETE는 body로 전달)
      final response = await _supabaseService.client.functions.invoke(
        'wishlists',
        body: {...removeData, 'method': 'DELETE'},
        headers: {
          'temp-token': tempToken,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        print('💔 WISHLIST_SERVICE: 찜하기 제거 성공');
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? '찜하기에서 제거되었습니다',
          data: null,
        );
      } else {
        print('❌ WISHLIST_SERVICE: 찜하기 제거 실패 - ${response.data}');
        return ApiResponse(
          success: false,
          message: response.data?['message'] ?? '찜하기 제거에 실패했습니다',
          data: null,
        );
      }
    } catch (e) {
      print('❌ WISHLIST_SERVICE: 찜하기 제거 실패 - $e');
      return ApiResponse(
        success: false,
        message: '찜하기 제거에 실패했습니다: $e',
        data: null,
      );
    }
  }

  /// 찜 상태 확인
  Future<bool> checkWishlistStatus({
    required String postType,
    required int postId,
  }) async {
    try {
      print('🔍 WISHLIST_SERVICE: 찜 상태 확인 - $postType:$postId');

      // 전체 찜한 글 조회 (최대 100개)
      final wishlists = await getWishlists(page: 1, limit: 100);

      print('🔍 WISHLIST_SERVICE: 찜한 글 총 ${wishlists.items.length}개');

      final isFavorited = wishlists.items.any(
        (item) => item.postType == postType && item.postId == postId,
      );

      print('🔍 WISHLIST_SERVICE: 찜 상태 결과 - $isFavorited');

      return isFavorited;
    } catch (e) {
      print('❌ WISHLIST_SERVICE: 찜 상태 확인 실패 - $e');
      return false;
    }
  }

  /// 게시물 타입을 postType 문자열로 변환
  static String getPostType(String categoryId) {
    const typeMap = {
      'free-sharing': 'community-sharing',
      'item-sale': 'sharing-offer',
      'item-request': 'item-request',
      'job-posting': 'job-posting',
      'music-team-recruit': 'music-team-recruit',
      'music-team-seeking': 'music-team-seeking',
      'church-news': 'church-events',
    };
    return typeMap[categoryId] ?? categoryId;
  }
}
