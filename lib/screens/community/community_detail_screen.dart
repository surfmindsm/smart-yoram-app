import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/wishlist_service.dart';
import 'package:smart_yoram_app/services/chat_service.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/services/notification_service.dart';
import 'package:smart_yoram_app/services/report_service.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:smart_yoram_app/models/report_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:smart_yoram_app/screens/community/community_create_screen.dart';
import 'package:smart_yoram_app/screens/chat/chat_room_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

/// 커뮤니티 게시글 상세 화면 (공통)
/// 모든 카테고리의 게시글을 표시할 수 있는 공통 화면
class CommunityDetailScreen extends StatefulWidget {
  final int postId;
  final String tableName;
  final String categoryTitle;

  const CommunityDetailScreen({
    super.key,
    required this.postId,
    required this.tableName,
    required this.categoryTitle,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  final WishlistService _wishlistService = WishlistService();
  final SupabaseService _supabaseService = SupabaseService();
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  dynamic _post;
  User? _currentUser;
  bool _isFavorited = false;
  bool _isFavoriteLoading = false;
  int _currentImageIndex = 0;
  String? _authorPhone; // 작성자 전화번호
  bool _hasChanges = false; // 상태 변경 여부 추적

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 현재 사용자 정보 로드
      final userResponse = await _authService.getCurrentUser();
      _currentUser = userResponse.data;

      // 게시글 상세 정보 로드
      dynamic post;
      switch (widget.tableName) {
        case 'community_sharing':
          post = await _communityService.getSharingItem(widget.postId);
          break;
        case 'community_requests':
          post = await _communityService.getRequestItem(widget.postId);
          break;
        case 'job_posts':
          post = await _communityService.getJobPost(widget.postId);
          break;
        case 'community_music_teams':
          post = await _communityService.getMusicTeamRecruitment(widget.postId);
          break;
        case 'music_team_seekers':
          post = await _communityService.getMusicTeamSeeker(widget.postId);
          break;
        case 'church_news':
          post = await _communityService.getChurchNewsItem(widget.postId);
          break;
        default:
          post = null;
      }

      setState(() {
        _post = post;
        _isLoading = false;
      });

      // 찜하기 상태 확인
      if (post != null) {
        _checkFavoriteStatus();

        // 작성자 전화번호 조회
        _loadAuthorPhone();
      }
    } catch (e) {
      print('❌ COMMUNITY_DETAIL: 데이터 로드 실패 - $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final postType = _getPostType();
    if (postType == null) return;

    final isFavorited = await _wishlistService.checkWishlistStatus(
      postType: postType,
      postId: widget.postId,
    );

    setState(() {
      _isFavorited = isFavorited;
    });
  }

  /// 작성자 전화번호 조회
  Future<void> _loadAuthorPhone() async {
    if (_post == null) return;

    try {
      // 게시글 작성자 ID 추출
      int? authorId;
      if (_post is CommunityBasePost) {
        authorId = (_post as CommunityBasePost).authorId;
      }

      if (authorId == null) return;

      // 본인 게시글이면 전화번호 조회 안 함
      if (_currentUser != null && authorId == _currentUser!.id) return;

      // users 테이블에서 전화번호 조회
      final user = await _supabaseService.getUser(authorId);
      if (user != null && user.phone != null) {
        setState(() {
          _authorPhone = user.phone;
        });
      }
    } catch (e) {
      print('❌ COMMUNITY_DETAIL: 작성자 전화번호 조회 실패 - $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;

    final postType = _getPostType();
    if (postType == null || _post == null) return;

    setState(() => _isFavoriteLoading = true);

    // 이전 상태 저장 (롤백용)
    final previousState = _isFavorited;

    try {
      if (_isFavorited) {
        // 찜하기 해제
        print('💔 COMMUNITY_DETAIL: 찜하기 해제 시작');
        final response = await _wishlistService.removeFromWishlist(
          postType: postType,
          postId: widget.postId,
        );

        if (!response.success) {
          throw Exception('찜하기 해제 실패: ${response.message}');
        }

        print('✅ COMMUNITY_DETAIL: 찜하기 해제 성공');
      } else {
        // 찜하기 추가
        print('💗 COMMUNITY_DETAIL: 찜하기 추가 시작');
        String title = '';
        String? description = '';

        // 타입별 제목과 설명 추출
        if (_post is SharingItem) {
          final post = _post as SharingItem;
          title = post.title;
          description = post.description;
        } else if (_post is RequestItem) {
          final post = _post as RequestItem;
          title = post.title;
          description = post.description;
        } else if (_post is JobPost) {
          final post = _post as JobPost;
          title = post.title;
          description = post.description;
        } else if (_post is MusicTeamRecruitment) {
          final post = _post as MusicTeamRecruitment;
          title = post.title;
          description = post.description;
        } else if (_post is MusicTeamSeeker) {
          final post = _post as MusicTeamSeeker;
          title = post.title;
          description = post.introduction;
        } else if (_post is ChurchNews) {
          final post = _post as ChurchNews;
          title = post.title;
          description = post.content ?? post.description;
        }

        final response = await _wishlistService.addToWishlist(
          postType: postType,
          postId: widget.postId,
          postTitle: title,
          postDescription: description ?? '',
        );

        if (!response.success) {
          throw Exception('찜하기 추가 실패: ${response.message}');
        }

        print('✅ COMMUNITY_DETAIL: 찜하기 추가 성공');

        // 찜하기 성공 시, 글 작성자에게 푸시 알림 전송 (백그라운드로 실행)
        _sendLikeNotificationToAuthor(title);
      }

      // UI 즉시 업데이트
      setState(() {
        _isFavorited = !_isFavorited;
        _isFavoriteLoading = false;
      });

      print('🎨 COMMUNITY_DETAIL: UI 업데이트 완료 - _isFavorited: $_isFavorited');
    } catch (e) {
      print('❌ COMMUNITY_DETAIL: 찜하기 토글 실패 - $e');

      // 실패 시 이전 상태로 롤백
      setState(() {
        _isFavorited = previousState;
        _isFavoriteLoading = false;
      });

      // 사용자에게 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorited ? '찜하기 해제에 실패했습니다' : '찜하기 추가에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 좋아요 시 작성자에게 푸시 알림 전송
  Future<void> _sendLikeNotificationToAuthor(String postTitle) async {
    try {
      // 작성자 ID 가져오기
      int? authorId;
      if (_post is CommunityBasePost) {
        authorId = (_post as CommunityBasePost).authorId;
      }

      // 작성자 본인이 좋아요를 누른 경우 알림 전송하지 않음
      if (authorId == null ||
          (_currentUser != null && authorId == _currentUser!.id)) {
        print('💗 COMMUNITY_DETAIL: 작성자 본인이므로 알림 전송 생략');
        return;
      }

      // 현재 사용자 이름
      final userName = _currentUser?.fullName ?? '누군가';

      // 푸시 알림 전송 시도
      print(
          '💗 COMMUNITY_DETAIL: 좋아요 알림 전송 시도 - authorId: $authorId, userName: $userName');

      // 1. 먼저 작성자의 FCM 토큰 조회
      final authorTokens = await _supabaseService.client
          .from('device_tokens')
          .select('fcm_token, platform')
          .eq('user_id', authorId)
          .eq('is_active', true);

      if (authorTokens == null || (authorTokens as List).isEmpty) {
        print('⚠️ COMMUNITY_DETAIL: 작성자의 FCM 토큰이 없음 (user_id: $authorId)');
        return;
      }

      print(
          '📱 COMMUNITY_DETAIL: FCM 토큰 조회 성공 - ${(authorTokens as List).length}개');

      // 2. Supabase Edge Function으로 푸시 알림 전송
      try {
        print('🚀 COMMUNITY_DETAIL: Supabase Edge Function 호출 시작');

        final response = await _supabaseService.client.functions.invoke(
          'send-like-notification',
          body: {
            'author_id': authorId,
            'liker_id': _currentUser?.id ?? 0,
            'liker_name': userName,
            'post_title': postTitle,
            'post_id': widget.postId,
            'table_name': widget.tableName,
            'category_title': widget.categoryTitle,
          },
        );

        if (response.data != null && response.data['success'] == true) {
          print('✅ COMMUNITY_DETAIL: 좋아요 푸시 알림 전송 성공');
          print('📊 COMMUNITY_DETAIL: ${response.data['message']}');

          // notifications 테이블에도 저장 (알림 센터용)
          try {
            await _supabaseService.client.from('notifications').insert({
              'user_id': authorId,
              'title': '좋아요',
              'body': '$userName님이 회원님의 게시글을 좋아합니다.',
              'type': 'like',
              'related_id': widget.postId,
              'related_type': widget.tableName,
              'data': {
                'liker_id': _currentUser?.id ?? 0,
                'liker_name': userName,
                'post_title': postTitle,
                'category_title': widget.categoryTitle,
              },
            });
            print('✅ COMMUNITY_DETAIL: 알림 센터에 좋아요 알림 저장 성공');
          } catch (insertError) {
            print('⚠️ COMMUNITY_DETAIL: 알림 센터 저장 실패 - $insertError');
          }
        } else {
          print('⚠️ COMMUNITY_DETAIL: 좋아요 푸시 알림 전송 실패 - ${response.data}');
        }
      } catch (edgeFunctionError) {
        print('❌ COMMUNITY_DETAIL: Edge Function 호출 오류 - $edgeFunctionError');
      }
    } catch (e, stackTrace) {
      print('❌ COMMUNITY_DETAIL: 좋아요 알림 전송 중 오류 - $e');
      print('❌ COMMUNITY_DETAIL: 스택 트레이스 - $stackTrace');
      // 알림 전송 실패는 사용자 경험에 영향을 주지 않도록 조용히 처리
    }
  }

  String? _getPostType() {
    switch (widget.tableName) {
      case 'community_sharing':
        if (_post is SharingItem) {
          return (_post as SharingItem).isFree
              ? 'community-sharing'
              : 'sharing-offer';
        }
        return null;
      case 'community_requests':
        return 'item-request';
      case 'job_posts':
        return 'job-posting';
      case 'community_music_teams':
        return 'music-team-recruit';
      case 'music_team_seekers':
        return 'music-team-seeking';
      case 'church_news':
        return 'church-events';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop && _hasChanges) {
          // 뒤로 가기 후 리스트 새로고침을 위해 결과 전달
          // PopScope는 pop 후에 호출되므로 여기서는 처리할 수 없음
        }
      },
      child: Scaffold(
        backgroundColor: NewAppColor.neutral100,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Container(
            margin: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: Colors.black),
              onPressed: () => Navigator.pop(context, _hasChanges),
              padding: EdgeInsets.zero,
            ),
          ),
          actions: [
            // 모든 사용자에게 더보기 버튼 표시 (작성자: 수정/삭제, 타인: 신고하기)
            Container(
              margin: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onPressed: _showPostMenu,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _post == null
                ? _buildErrorState()
                : Column(
                    children: [
                      // 컨텐츠 - Expanded로 감싸서 남은 공간 차지
                      Expanded(
                        child: _buildContent(),
                      ),

                      // 하단 버튼들 - 항상 하단에 고정
                      if (_post != null)
                        Container(
                          decoration: BoxDecoration(
                            color: NewAppColor.neutral100,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                // 작성자인 경우: 상태 수정 버튼만
                                if (_isAuthor())
                                  Expanded(
                                    child: widget.tableName ==
                                            'community_sharing'
                                        ? _buildSharingStatusDropdown()
                                        : widget.tableName == 'job_posts'
                                            ? _buildJobPostingStatusDropdown()
                                            : ElevatedButton(
                                                onPressed: _togglePostStatus,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      NewAppColor.primary600,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 14.h),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12.r),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  _getStatusButtonText(),
                                                  style: FigmaTextStyles()
                                                      .button1
                                                      .copyWith(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                  ),
                                // 작성자가 아닌 경우: 좋아요 + 전화/채팅 버튼
                                if (!_isAuthor()) ...[
                                  // 좋아요 버튼
                                  OutlinedButton(
                                    onPressed: _toggleFavorite,
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 14.h,
                                      ),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                    ),
                                    child: Icon(
                                      _isFavorited
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _isFavorited
                                          ? Colors.red
                                          : NewAppColor.neutral400,
                                      size: 28.w,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  // 전화 버튼 (전화번호가 있을 때만) - 주석처리
                                  // if (_authorPhone != null) ...[
                                  //   Expanded(
                                  //     child: OutlinedButton(
                                  //       onPressed: _onPhoneButtonPressed,
                                  //       style: OutlinedButton.styleFrom(
                                  //         padding: EdgeInsets.symmetric(
                                  //             vertical: 14.h),
                                  //         side: BorderSide(
                                  //           color: NewAppColor.primary600,
                                  //           width: 1.5,
                                  //         ),
                                  //         shape: RoundedRectangleBorder(
                                  //           borderRadius:
                                  //               BorderRadius.circular(12.r),
                                  //         ),
                                  //       ),
                                  //       child: Text(
                                  //         '전화하기',
                                  //         style: FigmaTextStyles()
                                  //             .button1
                                  //             .copyWith(
                                  //               color: NewAppColor.primary600,
                                  //             ),
                                  //       ),
                                  //     ),
                                  //   ),
                                  //   SizedBox(width: 8.w),
                                  // ],
                                  // 채팅 버튼
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _onChatButtonPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: NewAppColor.primary600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 14.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        '채팅하기',
                                        style:
                                            FigmaTextStyles().button1.copyWith(
                                                  color: Colors.white,
                                                ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: NewAppColor.neutral400,
          ),
          SizedBox(height: 16.h),
          Text(
            '게시글을 불러올 수 없습니다',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 공통 필드 추출
    String title = '';
    String? description = '';
    List<String> images = [];
    String date = '';
    int viewCount = 0;
    String? authorName = '';
    String? authorProfilePhotoUrl = '';
    String? churchName = '';
    String? churchLocation = '';
    String? category; // 카테고리
    String? status; // 상태

    // 타입별 필드 매핑
    if (_post is SharingItem) {
      final post = _post as SharingItem;
      title = post.title;
      description = post.description;
      images = post.images;
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      authorProfilePhotoUrl = post.authorProfilePhotoUrl;
      churchName = post.churchName;
      churchLocation = post.displayLocation; // province + district
      category = post.category;
      status = post.statusDisplayName;
    } else if (_post is RequestItem) {
      final post = _post as RequestItem;
      title = post.title;
      description = post.description;
      images = post.images ?? [];
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      authorProfilePhotoUrl = post.authorProfilePhotoUrl;
      churchName = post.churchName;
      churchLocation = post.displayLocation;
      category = post.category;
      status = post.statusDisplayName;
    } else if (_post is JobPost) {
      final post = _post as JobPost;
      title = post.title;
      description = post.description;
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      churchName = post.churchName;
      churchLocation = post.location;
    } else if (_post is MusicTeamRecruitment) {
      final post = _post as MusicTeamRecruitment;
      title = post.title;
      description = post.description;
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      churchName = post.churchName;
      churchLocation = post.location;
    } else if (_post is MusicTeamSeeker) {
      final post = _post as MusicTeamSeeker;
      title = post.title;
      description = post.introduction;
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      churchName = post.churchName;
    } else if (_post is ChurchNews) {
      final post = _post as ChurchNews;
      title = post.title;
      description = post.content ?? post.description;
      images = post.images ?? [];
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      churchName = post.churchName;
      churchLocation = post.location;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지가 있는 경우에만 이미지 슬라이더 표시
          if (images.isNotEmpty) ...[
            Stack(
              children: [
                SizedBox(
                  height: 400.h,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(images, index),
                        child: Image.network(
                          images[index],
                          height: 400.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 400.h,
                              color: NewAppColor.neutral100,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 이미지 카운터
                Positioned(
                  right: 16.w,
                  bottom: 16.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${images.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 이미지가 없는 경우 상단 여백만 추가 (AppBar 높이만큼)
            SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top),
          ],

          // === 무료나눔/물품판매 전용 레이아웃 ===
          if (_post is SharingItem) ...[
            _buildSharingLayout(_post as SharingItem, date, authorName,
                authorProfilePhotoUrl, churchName, churchLocation, description),
          ]
          // === 물품요청 전용 레이아웃 ===
          else if (_post is RequestItem) ...[
            _buildRequestLayout(_post as RequestItem, date, authorName,
                authorProfilePhotoUrl, churchName, churchLocation, description),
          ]
          // === 사역자 모집 전용 레이아웃 ===
          else if (_post is JobPost) ...[
            _buildJobPostingLayout(_post as JobPost, date, authorName,
                authorProfilePhotoUrl, churchName, churchLocation, description),
          ]
          // === 행사팀 지원 전용 레이아웃 ===
          else if (_post is MusicTeamSeeker) ...[
            _buildMusicTeamSeekerLayout(_post as MusicTeamSeeker, date,
                authorName, authorProfilePhotoUrl, churchName),
          ]
          // === 기타 게시글 기본 레이아웃 ===
          else ...[
            // 작성자 정보 카드
            Container(
              color: NewAppColor.neutral100,
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 프로필 이미지
                      _buildProfileImage(authorProfilePhotoUrl),
                      SizedBox(width: 12.w),
                      // 작성자 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName ?? '알 수 없음',
                              style: TextStyle(
                                color: NewAppColor.neutral900,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard Variable',
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              [
                                if (churchName != null && churchName.isNotEmpty)
                                  churchName,
                                if (churchLocation != null &&
                                    churchLocation.isNotEmpty)
                                  churchLocation,
                              ].join(' · '),
                              style: TextStyle(
                                color: NewAppColor.neutral600,
                                fontSize: 13.sp,
                                fontFamily: 'Pretendard Variable',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 작성자인 경우 상태 변경 드롭다운 표시
                  if (_isAuthor()) ...[
                    SizedBox(height: 12.h),
                    _buildStatusDropdown(),
                  ],
                ],
              ),
            ),
            Container(
              height: 8.h,
              color: NewAppColor.neutral100,
            ),
            // 제목 및 본문
            Container(
              color: NewAppColor.neutral100,
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    title,
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // 시간
                  Text(
                    date,
                    style: TextStyle(
                      color: NewAppColor.neutral600,
                      fontSize: 13.sp,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // 본문
                  Text(
                    description ?? '',
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontFamily: 'Pretendard Variable',
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? profilePhotoUrl) {
    // 프로필 이미지 URL 변환
    String? fullUrl = _getFullProfilePhotoUrl(profilePhotoUrl);

    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: NewAppColor.neutral200,
        shape: BoxShape.circle,
      ),
      child: fullUrl != null && fullUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                fullUrl,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    color: NewAppColor.neutral500,
                    size: 24.sp,
                  );
                },
              ),
            )
          : Icon(
              Icons.person,
              color: NewAppColor.neutral500,
              size: 24.sp,
            ),
    );
  }

  String? _getFullProfilePhotoUrl(String? profilePhotoUrl) {
    if (profilePhotoUrl == null || profilePhotoUrl.isEmpty) return null;

    // 이미 전체 URL이면 그대로 반환
    if (profilePhotoUrl.startsWith('http')) return profilePhotoUrl;

    // Supabase Storage public URL 생성
    const supabaseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co';

    // profilePhotoUrl이 상대경로일 경우
    final cleanPath = profilePhotoUrl.startsWith('/')
        ? profilePhotoUrl.substring(1)
        : profilePhotoUrl;

    // Supabase Storage public URL 형식
    return '$supabaseUrl/storage/v1/object/public/member-photos/$cleanPath';
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: NewAppColor.neutral100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: NewAppColor.primary100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: NewAppColor.primary600,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: NewAppColor.neutral600,
                      fontSize: 12.sp,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: NewAppColor.neutral400,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(List<String> images, int initialIndex) {
    int currentIndex = initialIndex;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              elevation: 0,
            ),
            body: Stack(
              children: [
                // 이미지 뷰어
                Center(
                  child: PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                              size: 64,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                // 이미지 인디케이터 (하단)
                Positioned(
                  bottom: 40.h,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContactDialog(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: NewAppColor.neutral300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: NewAppColor.neutral900,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // 전화 걸기
                    ListTile(
                      leading: Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: NewAppColor.primary100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone,
                          color: NewAppColor.primary600,
                          size: 24.sp,
                        ),
                      ),
                      title: Text(
                        '전화 걸기',
                        style: TextStyle(
                          color: NewAppColor.neutral900,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _makePhoneCall(phoneNumber);
                      },
                    ),
                    // 메시지 보내기
                    ListTile(
                      leading: Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: NewAppColor.primary100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.message,
                          color: NewAppColor.primary600,
                          size: 24.sp,
                        ),
                      ),
                      title: Text(
                        '메시지 보내기',
                        style: TextStyle(
                          color: NewAppColor.neutral900,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _sendMessage(phoneNumber);
                      },
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화를 걸 수 없습니다')),
        );
      }
    }
  }

  void _sendMessage(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지를 보낼 수 없습니다')),
        );
      }
    }
  }

  /// 포트폴리오 파일 다운로드 및 열기
  Future<void> _downloadAndOpenFile(String fileUrl) async {
    try {
      // 로딩 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 다운로드 중입니다...')),
        );
      }

      // 파일 다운로드
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode != 200) {
        throw Exception('파일 다운로드 실패');
      }

      // 파일명 추출 (URL에서 마지막 부분)
      final uri = Uri.parse(fileUrl);
      String fileName = uri.pathSegments.last;

      // 파일명에서 특수문자 제거 및 정리
      if (fileName.contains('?')) {
        fileName = fileName.split('?').first;
      }

      // 확장자가 없으면 기본값 추가
      if (!fileName.contains('.')) {
        fileName = '$fileName.pdf';
      }

      // 임시 디렉토리에 파일 저장
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // 파일 공유 (사용자가 앱을 선택하여 열 수 있음)
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: '포트폴리오 파일',
      );

      if (mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파일을 열었습니다')),
          );
        }
      }
    } catch (e) {
      print('❌ FILE_DOWNLOAD_ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일을 다운로드할 수 없습니다: $e')),
        );
      }
    }
  }

  bool _canEdit() {
    if (_currentUser == null || _post == null) return false;

    // 본인 게시글만 수정 가능 (관리자 권한 제거)
    if (_post is CommunityBasePost) {
      return (_post as CommunityBasePost).authorId == _currentUser!.id;
    }

    return false;
  }

  /// 작성자 여부 확인
  bool _isAuthor() {
    if (_currentUser == null || _post == null) return false;
    if (_post is CommunityBasePost) {
      return (_post as CommunityBasePost).authorId == _currentUser!.id;
    }
    return false;
  }

  /// 타입별 상태 옵션 가져오기
  List<Map<String, String>> _getStatusOptions() {
    if (_post is SharingItem) {
      final isFree = (_post as SharingItem).isFree;
      if (isFree) {
        // 무료나눔: 나눔가능, 예약중, 나눔완료
        return [
          {'value': 'active', 'label': '나눔가능'},
          {'value': 'ing', 'label': '예약중'},
          {'value': 'completed', 'label': '나눔완료'},
        ];
      } else {
        // 물품판매: 판매중, 예약중, 판매완료
        return [
          {'value': 'active', 'label': '판매중'},
          {'value': 'ing', 'label': '예약중'},
          {'value': 'completed', 'label': '판매 완료'},
        ];
      }
    } else if (_post is RequestItem) {
      // 물품요청: 요청중, 완료
      return [
        {'value': 'requesting', 'label': '요청중'},
        {'value': 'completed', 'label': '완료'},
      ];
    } else if (_post is JobPost) {
      // 사역자모집: 모집중, 마감
      return [
        {'value': 'open', 'label': '모집중'},
        {'value': 'closed', 'label': '마감'},
      ];
    } else if (_post is MusicTeamRecruitment) {
      // 행사팀모집: 모집중, 마감
      return [
        {'value': 'open', 'label': '모집중'},
        {'value': 'closed', 'label': '마감'},
      ];
    } else if (_post is MusicTeamSeeker) {
      // 행사팀지원: 지원가능, 완료
      return [
        {'value': 'available', 'label': '지원가능'},
        {'value': 'completed', 'label': '완료'},
      ];
    } else if (_post is ChurchNews) {
      // 교회소식: 진행중, 완료
      return [
        {'value': 'active', 'label': '진행중'},
        {'value': 'completed', 'label': '완료'},
      ];
    }
    return [];
  }

  /// 상태 변경 드롭다운 위젯
  Widget _buildStatusDropdown() {
    final options = _getStatusOptions();
    if (options.isEmpty) return const SizedBox.shrink();

    final currentStatus = (_post as CommunityBasePost).status;

    // 현재 상태가 옵션에 없으면 첫 번째 옵션으로 설정
    final validStatus = options.any((opt) => opt['value'] == currentStatus)
        ? currentStatus
        : options.first['value']!;

    // 드롭다운 아이템 생성 (상태 옵션 + 취소)
    final dropdownItems = [
      ...options.map((option) {
        return DropdownMenuItem<String?>(
          value: option['value'],
          child: Text(option['label']!),
        );
      }),
      DropdownMenuItem<String?>(
        value: null, // null 값으로 취소 표시
        child: Row(
          children: [
            Icon(Icons.close, size: 16.sp, color: NewAppColor.neutral600),
            SizedBox(width: 8.w),
            Text(
              '취소',
              style: TextStyle(
                color: NewAppColor.neutral600,
                fontFamily: 'Pretendard Variable',
              ),
            ),
          ],
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: NewAppColor.neutral100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: NewAppColor.neutral300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18.sp, color: NewAppColor.neutral700),
          SizedBox(width: 8.w),
          Text(
            '상태:',
            style: TextStyle(
              color: NewAppColor.neutral700,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard Variable',
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: DropdownButton<String?>(
              value: validStatus,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: TextStyle(
                color: NewAppColor.neutral900,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard Variable',
              ),
              items: dropdownItems,
              onChanged: (newStatus) {
                // null이면 취소 선택 (아무것도 하지 않음)
                if (newStatus == null) return;

                // 같은 상태면 아무것도 하지 않음
                if (newStatus == currentStatus) return;

                // 상태 변경
                _updateStatus(newStatus);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 업데이트
  Future<void> _updateStatus(String newStatus) async {
    if (_post == null) return;

    print('🔄 DETAIL: 상태 업데이트 시작 - $newStatus');

    // 상태 업데이트 API 호출
    final response = await _communityService.updatePostStatus(
      tableName: widget.tableName,
      postId: widget.postId,
      newStatus: newStatus,
    );

    print('✅ DETAIL: 상태 업데이트 응답 - success: ${response.success}');

    if (mounted) {
      if (response.success) {
        // 상태 변경 플래그 설정
        _hasChanges = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
        print('🔄 DETAIL: _loadData() 호출');
        // 데이터 다시 로드
        await _loadData();
        print(
            '✅ DETAIL: _loadData() 완료 - 현재 상태: ${(_post as CommunityBasePost?)?.status}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    }
  }

  /// 사역자 모집 상태 드롭다운 버튼
  Widget _buildJobPostingStatusDropdown() {
    if (_post == null) return const SizedBox.shrink();

    final currentStatus = (_post as CommunityBasePost).status;

    // 현재 상태에 따른 스타일 정의
    Color getStatusColor(String status) {
      switch (status) {
        case 'open':
        case 'active': // 'active'도 모집중으로 처리
          return NewAppColor.primary600;
        case 'closed':
          return NewAppColor.neutral600;
        default:
          return NewAppColor.neutral600;
      }
    }

    String getStatusText(String status) {
      switch (status) {
        case 'open':
        case 'active': // 'active'도 모집중으로 처리
          return '모집중';
        case 'closed':
          return '마감';
        default:
          return '상태 없음';
      }
    }

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'open':
        case 'active': // 'active'도 모집중으로 처리
          return Icons.work_outline;
        case 'closed':
          return Icons.work_off_outlined;
        default:
          return Icons.help_outline;
      }
    }

    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      onSelected: (String newStatus) {
        if (newStatus != currentStatus) {
          _updateStatus(newStatus);
        }
      },
      itemBuilder: (BuildContext context) {
        final isOpen = currentStatus == 'open' || currentStatus == 'active';
        return [
          PopupMenuItem<String>(
            value: 'open',
            enabled: !isOpen,
            child: Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: NewAppColor.primary600,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '모집중',
                  style: FigmaTextStyles().button1.copyWith(
                        color: isOpen
                            ? NewAppColor.neutral400
                            : NewAppColor.neutral900,
                      ),
                ),
                if (isOpen) ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: NewAppColor.primary600,
                    size: 20.sp,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'closed',
            enabled: currentStatus != 'closed',
            child: Row(
              children: [
                Icon(
                  Icons.work_off_outlined,
                  color: NewAppColor.neutral600,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '마감',
                  style: FigmaTextStyles().button1.copyWith(
                        color: currentStatus == 'closed'
                            ? NewAppColor.neutral400
                            : NewAppColor.neutral900,
                      ),
                ),
                if (currentStatus == 'closed') ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: NewAppColor.neutral600,
                    size: 20.sp,
                  ),
                ],
              ],
            ),
          ),
        ];
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: getStatusColor(currentStatus),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getStatusIcon(currentStatus),
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              getStatusText(currentStatus),
              style: FigmaTextStyles().button1.copyWith(
                    color: Colors.white,
                  ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  /// 물품 판매/나눔 상태 드롭다운 버튼
  Widget _buildSharingStatusDropdown() {
    if (_post == null) return const SizedBox.shrink();

    final currentStatus = (_post as CommunityBasePost).status;

    // 현재 상태에 따른 스타일 정의
    Color getStatusColor(String status) {
      switch (status) {
        case 'active':
          return NewAppColor.primary600;
        case 'ing':
          return NewAppColor.warning600;
        case 'completed':
          return NewAppColor.success600;
        default:
          return NewAppColor.neutral600;
      }
    }

    String getStatusText(String status) {
      switch (status) {
        case 'active':
          return '판매중';
        case 'ing':
          return '예약중';
        case 'completed':
          return '판매완료';
        default:
          return '상태 없음';
      }
    }

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'active':
          return Icons.shopping_bag_outlined;
        case 'ing':
          return Icons.schedule_outlined;
        case 'completed':
          return Icons.check_circle_outline;
        default:
          return Icons.help_outline;
      }
    }

    return PopupMenuButton<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      onSelected: (String newStatus) {
        if (newStatus != currentStatus) {
          _updateStatus(newStatus);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'active',
            enabled: currentStatus != 'active',
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: NewAppColor.primary600,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '판매중',
                  style: FigmaTextStyles().button1.copyWith(
                        color: currentStatus == 'active'
                            ? NewAppColor.neutral400
                            : NewAppColor.neutral900,
                      ),
                ),
                if (currentStatus == 'active') ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: NewAppColor.primary600,
                    size: 20.sp,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'ing',
            enabled: currentStatus != 'ing',
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: NewAppColor.warning600,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '예약중',
                  style: FigmaTextStyles().button1.copyWith(
                        color: currentStatus == 'ing'
                            ? NewAppColor.neutral400
                            : NewAppColor.neutral900,
                      ),
                ),
                if (currentStatus == 'ing') ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: NewAppColor.warning600,
                    size: 20.sp,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'completed',
            enabled: currentStatus != 'completed',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: NewAppColor.success600,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  '판매완료',
                  style: FigmaTextStyles().button1.copyWith(
                        color: currentStatus == 'completed'
                            ? NewAppColor.neutral400
                            : NewAppColor.neutral900,
                      ),
                ),
                if (currentStatus == 'completed') ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: NewAppColor.success600,
                    size: 20.sp,
                  ),
                ],
              ],
            ),
          ),
        ];
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: getStatusColor(currentStatus),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getStatusIcon(currentStatus),
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              getStatusText(currentStatus),
              style: FigmaTextStyles().button1.copyWith(
                    color: Colors.white,
                  ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  /// 상태 버튼 텍스트 반환
  String _getStatusButtonText() {
    if (_post == null) return '상태 변경';

    final currentStatus = (_post as CommunityBasePost).status;

    // 다른 타입들은 기존 로직 유지
    final isCompleted =
        currentStatus == 'completed' || currentStatus == 'closed';
    return isCompleted ? '진행중으로 변경' : '완료로 변경';
  }

  void _showPostMenu() {
    // 작성자 확인
    final isAuthor = _currentUser != null &&
        _post != null &&
        (_post as CommunityBasePost).authorId == _currentUser!.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: NewAppColor.neutral100,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NewAppColor.neutral300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                SizedBox(height: 20.h),

                // 제목
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isAuthor ? '게시글 관리' : '게시글 신고',
                      style: FigmaTextStyles().subtitle1.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: NewAppColor.neutral900,
                          ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // 작성자인 경우: 수정/삭제 옵션 표시
                if (isAuthor) ...[
                  // 수정
                  _buildMenuOption(
                    icon: Icons.edit_outlined,
                    iconColor: NewAppColor.neutral700,
                    iconBgColor: NewAppColor.neutral100,
                    title: '수정',
                    onTap: () {
                      Navigator.pop(context);
                      _editPost();
                    },
                  ),

                  // 삭제
                  _buildMenuOption(
                    icon: LucideIcons.trash2,
                    iconColor: NewAppColor.danger600,
                    iconBgColor: NewAppColor.danger100,
                    title: '삭제',
                    titleColor: NewAppColor.danger600,
                    onTap: () {
                      Navigator.pop(context);
                      _deletePost();
                    },
                  ),
                ],

                // 작성자가 아닌 경우: 신고하기 옵션만 표시
                if (!isAuthor) ...[
                  _buildMenuOption(
                    icon: Icons.report_outlined,
                    iconColor: NewAppColor.danger600,
                    iconBgColor: NewAppColor.danger100,
                    title: '신고하기',
                    titleColor: NewAppColor.danger600,
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog();
                    },
                  ),
                ],

                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 메뉴 옵션 위젯
  Widget _buildMenuOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                size: 20.sp,
                color: iconColor,
              ),
            ),
            SizedBox(width: 16.w),
            // 타이틀
            Text(
              title,
              style: FigmaTextStyles().body1.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? NewAppColor.neutral900,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 게시글 상태 토글 (완료 <-> 진행중)
  Future<void> _togglePostStatus() async {
    if (_post == null) return;

    final currentStatus = (_post as CommunityBasePost).status;
    final isCompleted =
        currentStatus == 'completed' || currentStatus == 'closed';

    // 새로운 상태 결정
    String newStatus;
    if (isCompleted) {
      // 완료/마감 상태에서 진행중으로 변경
      if (widget.tableName == 'community_sharing') {
        newStatus = 'active'; // 무료나눔/물품판매 모두 active
      } else if (widget.tableName == 'community_requests') {
        newStatus = 'requesting';
      } else if (widget.tableName == 'job_posts' ||
          widget.tableName == 'community_music_teams') {
        newStatus = 'open';
      } else {
        newStatus = 'active';
      }
    } else {
      // 진행중에서 완료/마감으로 변경
      if (widget.tableName == 'job_posts' ||
          widget.tableName == 'community_music_teams') {
        newStatus = 'closed';
      } else {
        newStatus = 'completed';
      }
    }

    // 상태 업데이트 API 호출
    final response = await _communityService.updatePostStatus(
      tableName: widget.tableName,
      postId: widget.postId,
      newStatus: newStatus,
    );

    if (mounted) {
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
        // 데이터 다시 로드
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    }
  }

  void _editPost() {
    // 게시글 타입에 따라 CommunityListType 결정
    CommunityListType? typeOrNull;

    if (_post is SharingItem) {
      typeOrNull = (_post as SharingItem).isFree
          ? CommunityListType.freeSharing
          : CommunityListType.itemSale;
    } else if (_post is RequestItem) {
      typeOrNull = CommunityListType.itemRequest;
    } else if (_post is JobPost) {
      typeOrNull = CommunityListType.jobPosting;
    } else if (_post is MusicTeamRecruitment) {
      typeOrNull = CommunityListType.musicTeamRecruit;
    } else if (_post is MusicTeamSeeker) {
      typeOrNull = CommunityListType.musicTeamSeeking;
    } else if (_post is ChurchNews) {
      typeOrNull = CommunityListType.churchNews;
    }

    if (typeOrNull == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정할 수 없는 게시글입니다')),
      );
      return;
    }

    final type = typeOrNull; // non-null after check

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityCreateScreen(
          type: type,
          categoryTitle: widget.categoryTitle,
          existingPost: _post,
        ),
      ),
    ).then((result) {
      // 수정 후 돌아오면 데이터 새로고침
      if (result == true) {
        _hasChanges = true; // 변경사항 플래그 설정
        _loadData();
      }
    });
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final response = await _communityService.deletePost(
        widget.tableName,
        widget.postId,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
          Navigator.pop(context, true); // 목록 화면으로 돌아가며 새로고침 트리거
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    }
  }

  /// 신고하기 다이얼로그 표시
  void _showReportDialog() {
    ReportReason? selectedReason;
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: NewAppColor.neutral100,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 핸들
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: 12.h),
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: NewAppColor.neutral300,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // 제목
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          '게시글 신고',
                          style: FigmaTextStyles().subtitle1.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: NewAppColor.neutral900,
                              ),
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          '신고 사유를 선택해주세요',
                          style: FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.neutral600,
                                fontSize: 14.sp,
                              ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // 신고 사유 선택
                      ...ReportReason.values.map((reason) {
                        final isSelected = selectedReason == reason;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedReason = reason;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            color: isSelected
                                ? NewAppColor.primary100
                                : Colors.white,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? NewAppColor.primary600
                                      : NewAppColor.neutral400,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  reason.label,
                                  style: FigmaTextStyles().body1.copyWith(
                                        fontSize: 15.sp,
                                        color: isSelected
                                            ? NewAppColor.primary600
                                            : NewAppColor.neutral900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      SizedBox(height: 16.h),

                      // 상세 내용 입력
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '상세 내용 (선택)',
                              style: FigmaTextStyles().body2.copyWith(
                                    color: NewAppColor.neutral700,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: descriptionController,
                              maxLines: 4,
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText: '신고 사유를 자세히 작성해주세요',
                                hintStyle: FigmaTextStyles().body2.copyWith(
                                      color: NewAppColor.neutral400,
                                    ),
                                filled: true,
                                fillColor: NewAppColor.neutral100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.all(12.w),
                              ),
                              style: FigmaTextStyles().body2.copyWith(
                                    color: NewAppColor.neutral900,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // 버튼
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  side: BorderSide(
                                    color: NewAppColor.neutral300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  '취소',
                                  style: FigmaTextStyles().button1.copyWith(
                                        color: NewAppColor.neutral700,
                                      ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selectedReason == null
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        _submitReport(
                                          selectedReason!,
                                          descriptionController.text.trim(),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NewAppColor.danger600,
                                  disabledBackgroundColor:
                                      NewAppColor.neutral300,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '신고하기',
                                  style: FigmaTextStyles().button1.copyWith(
                                        color: selectedReason == null
                                            ? NewAppColor.neutral500
                                            : Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 신고 제출
  Future<void> _submitReport(ReportReason reason, String description) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await _reportService.createReport(
        reportedType: ReportType.post,
        reportedId: widget.postId,
        reportedTable: widget.tableName,
        reason: reason,
        description: description.isEmpty ? null : description,
      );

      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      // 결과 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: response.success
                ? NewAppColor.success600
                : NewAppColor.danger600,
          ),
        );
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      // 에러 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 접수 중 오류가 발생했습니다: $e'),
            backgroundColor: NewAppColor.danger600,
          ),
        );
      }
    }
  }

  /// 무료나눔/물품판매 전용 레이아웃
  Widget _buildSharingLayout(
    SharingItem item,
    String date,
    String? authorName,
    String? authorProfilePhotoUrl,
    String? churchName,
    String? churchLocation,
    String? description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === 1. 프로필 정보 섹션 ===
        Container(
          color: NewAppColor.neutral100,
          padding: EdgeInsets.all(20.r),
          child: Row(
            children: [
              // 프로필 이미지
              _buildProfileImage(authorProfilePhotoUrl),
              SizedBox(width: 12.w),
              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 이름
                    Text(
                      authorName ?? '알 수 없음',
                      style: FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.neutral900,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    // 교회 정보 + 지역
                    Text(
                      [
                        if (churchName != null && churchName.isNotEmpty)
                          churchName
                        else
                          '커뮤니티 회원',
                        if (churchLocation != null && churchLocation.isNotEmpty)
                          churchLocation,
                      ].join(' · '),
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral600,
                            fontSize: 13.sp,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        Container(height: 1.h, color: NewAppColor.neutral200),

        // === 2. 상품 기본 정보 (제목, 가격, 카테고리, 시간) ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                item.title,
                style: FigmaTextStyles().header1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
              ),
              SizedBox(height: 12.h),

              // 가격
              Text(
                item.formattedPrice,
                style: FigmaTextStyles().header2.copyWith(
                      color: NewAppColor.black,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 12.h),

              // 카테고리 + 올린시간
              Row(
                children: [
                  // 카테고리
                  Text(
                    item.category,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral600,
                          fontSize: 13.sp,
                        ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '·',
                    style: TextStyle(color: NewAppColor.neutral400),
                  ),
                  SizedBox(width: 8.w),
                  // 올린시간
                  Text(
                    date,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral500,
                          fontSize: 13.sp,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 3. 상품 설명 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   '상품 설명',
              //   style: FigmaTextStyles().body1.copyWith(
              //         color: NewAppColor.neutral900,
              //         fontSize: 16.sp,
              //         fontWeight: FontWeight.w600,
              //       ),
              // ),
              // SizedBox(height: 12.h),
              Text(
                description ?? '상품 설명이 없습니다.',
                style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral800,
                      fontSize: 15.sp,
                      height: 1.6,
                    ),
              ),
              // SizedBox(height: 80.h),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 2. 상품 정보 카드 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   '상품 정보',
              //   style: FigmaTextStyles().body1.copyWith(
              //         color: NewAppColor.neutral900,
              //         fontSize: 16.sp,
              //         fontWeight: FontWeight.w600,
              //       ),
              // ),
              // SizedBox(height: 16.h),

              // 상품 정보 그리드
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(label: '카테고리', value: item.category),
                    SizedBox(height: 12.h),
                    _buildInfoRow(label: '상태', value: item.condition),
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                        label: '구매 시기', value: item.formattedPurchaseDate),
                    SizedBox(height: 12.h),
                    _buildInfoRow(label: '지역', value: item.displayLocation),
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                      label: '택배',
                      value: item.deliveryAvailable ? '가능' : '불가능',
                      valueColor: item.deliveryAvailable
                          ? NewAppColor.success600
                          : NewAppColor.neutral600,
                      valueWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 4. 연락처 정보 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '연락처 정보',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),
              // 전화번호
              if (item.contactPhone != null && item.contactPhone!.isNotEmpty)
                _buildContactItem(
                  icon: Icons.phone_outlined,
                  label: '전화번호',
                  value: item.contactPhone!,
                  onTap: () => _showContactDialog(item.contactPhone!),
                ),
              // 이메일
              if (item.contactEmail != null &&
                  item.contactEmail!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _buildContactItem(
                  icon: Icons.email_outlined,
                  label: '이메일',
                  value: item.contactEmail!,
                  onTap: () {
                    // TODO: 이메일 보내기 기능
                  },
                ),
              ],
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ],
    );
  }

  /// 상태에 따른 배지 색상
  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'active':
        return NewAppColor.success600;
      case 'ing':
        return NewAppColor.warning600;
      case 'completed':
      case 'sold':
        return NewAppColor.neutral500;
      default:
        return NewAppColor.primary600;
    }
  }

  /// 상품 정보 행
  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral600,
              ),
        ),
        Text(
          value,
          style: FigmaTextStyles().body2.copyWith(
                color: valueColor ?? NewAppColor.neutral900,
                fontWeight: valueWeight ?? FontWeight.w500,
              ),
        ),
      ],
    );
  }

  /// 사역자 모집 전용 레이아웃
  Widget _buildJobPostingLayout(
    JobPost item,
    String date,
    String? authorName,
    String? authorProfilePhotoUrl,
    String? churchName,
    String? churchLocation,
    String? description,
  ) {
    // 직책 표시명 변환
    String getPositionDisplayName(String position) {
      switch (position) {
        case 'pastor':
          return '목사';
        case 'minister':
          return '전도사';
        case 'worship':
          return '찬양사역자';
        case 'admin':
          return '행정간사';
        case 'education':
          return '교육간사';
        case 'other':
          return '기타';
        default:
          return position;
      }
    }

    // 고용형태 표시명 변환
    String getEmploymentTypeDisplayName(String type) {
      switch (type) {
        case 'full-time':
          return '정규직';
        case 'part-time':
          return '시간제';
        case 'contract':
          return '계약직';
        case 'volunteer':
          return '자원봉사';
        default:
          return type;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === 1. 프로필 정보 섹션 ===
        Container(
          color: NewAppColor.neutral100,
          padding: EdgeInsets.all(20.r),
          child: Row(
            children: [
              // 프로필 이미지
              _buildProfileImage(authorProfilePhotoUrl),
              SizedBox(width: 12.w),
              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 이름
                    Text(
                      authorName ?? '알 수 없음',
                      style: FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.neutral900,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    // 교회 정보 + 지역
                    Text(
                      [
                        if (churchName != null && churchName.isNotEmpty)
                          churchName
                        else
                          '커뮤니티 회원',
                        if (churchLocation != null && churchLocation.isNotEmpty)
                          churchLocation,
                      ].join(' · '),
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral600,
                            fontSize: 13.sp,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        Container(height: 1.h, color: NewAppColor.neutral200),

        // === 2. 모집 기본 정보 (제목, 시간) ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                item.title,
                style: FigmaTextStyles().header1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
              ),
              SizedBox(height: 8.h),
              // 올린시간
              Text(
                date,
                style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral600,
                      fontSize: 13.sp,
                    ),
              ),
            ],
          ),
        ),

        // === 3. 상세 내용 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description ?? '상세 내용이 없습니다.',
                style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral800,
                      fontSize: 15.sp,
                      height: 1.6,
                    ),
              ),
            ],
          ),
        ),

        // === 4. 모집 정보 카드 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    if (item.company != null && item.company!.isNotEmpty) ...[
                      _buildInfoRow(label: '교회/기관명', value: item.company!),
                      SizedBox(height: 12.h),
                    ],
                    _buildInfoRow(
                        label: '직책', value: getPositionDisplayName(item.position)),
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                        label: '고용형태',
                        value: getEmploymentTypeDisplayName(item.employmentType)),
                    SizedBox(height: 12.h),
                    _buildInfoRow(label: '급여', value: item.salary),
                    if (churchLocation != null && churchLocation.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _buildInfoRow(label: '근무 지역', value: churchLocation),
                    ],
                    if (item.deadline != null && item.deadline!.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _buildInfoRow(
                        label: '지원 마감일',
                        value: item.deadline!,
                        valueColor: NewAppColor.warning600,
                        valueWeight: FontWeight.w600,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // === 5. 연락처 정보 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '연락처 정보',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),
              // 전화번호
              if (item.contactPhone != null && item.contactPhone!.isNotEmpty)
                _buildContactItem(
                  icon: Icons.phone_outlined,
                  label: '전화번호',
                  value: item.contactPhone!,
                  onTap: () => _showContactDialog(item.contactPhone!),
                ),
              // 이메일
              if (item.contactEmail != null &&
                  item.contactEmail!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _buildContactItem(
                  icon: Icons.email_outlined,
                  label: '이메일',
                  value: item.contactEmail!,
                  onTap: () {
                    // TODO: 이메일 보내기 기능
                  },
                ),
              ],
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ],
    );
  }

  /// 물품요청 전용 레이아웃
  Widget _buildRequestLayout(
    RequestItem item,
    String date,
    String? authorName,
    String? authorProfilePhotoUrl,
    String? churchName,
    String? churchLocation,
    String? description,
  ) {
    // 우선순위 표시 텍스트
    String urgencyLabel = '보통';
    Color urgencyColor = NewAppColor.neutral600;
    switch (item.urgency.toLowerCase()) {
      case 'low':
        urgencyLabel = '낮음';
        urgencyColor = NewAppColor.neutral600;
        break;
      case 'normal':
        urgencyLabel = '보통';
        urgencyColor = NewAppColor.primary600;
        break;
      case 'medium':
        urgencyLabel = '중간';
        urgencyColor = NewAppColor.warning600;
        break;
      case 'high':
        urgencyLabel = '높음';
        urgencyColor = NewAppColor.danger600;
        break;
    }

    // 보상 정보 포맷팅
    String rewardText = '없음';
    if (item.rewardType == 'exchange') {
      rewardText = '교환 가능';
    } else if (item.rewardType == 'payment' && item.rewardAmount != null) {
      rewardText = '${item.rewardAmount!.toStringAsFixed(0)}원';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === 1. 프로필 정보 섹션 ===
        Container(
          color: NewAppColor.neutral100,
          padding: EdgeInsets.all(20.r),
          child: Row(
            children: [
              // 프로필 이미지
              _buildProfileImage(authorProfilePhotoUrl),
              SizedBox(width: 12.w),
              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 사용자 이름
                    Text(
                      authorName ?? '알 수 없음',
                      style: FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.neutral900,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    // 교회 정보 + 지역
                    Text(
                      [
                        if (churchName != null && churchName.isNotEmpty)
                          churchName
                        else
                          '커뮤니티 회원',
                        if (churchLocation != null && churchLocation.isNotEmpty)
                          churchLocation,
                      ].join(' · '),
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral600,
                            fontSize: 13.sp,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        Container(height: 1.h, color: NewAppColor.neutral200),

        // === 2. 요청 기본 정보 (제목, 우선순위, 카테고리, 시간) ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                item.title,
                style: FigmaTextStyles().header1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
              ),
              SizedBox(height: 12.h),

              // // 우선순위
              // Container(
              //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              //   decoration: BoxDecoration(
              //     color: urgencyColor.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(6.r),
              //     border: Border.all(color: urgencyColor, width: 1.5),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(Icons.priority_high, size: 16.sp, color: urgencyColor),
              //       SizedBox(width: 4.w),
              //       Text(
              //         urgencyLabel,
              //         style: FigmaTextStyles().caption2.copyWith(
              //               color: urgencyColor,
              //               fontSize: 13.sp,
              //               fontWeight: FontWeight.w600,
              //             ),
              //       ),
              //     ],
              //   ),
              // ),
              // SizedBox(height: 12.h),

              // 카테고리 + 올린시간
              Row(
                children: [
                  // 카테고리
                  Text(
                    item.category,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral600,
                          fontSize: 13.sp,
                        ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '·',
                    style: TextStyle(color: NewAppColor.neutral400),
                  ),
                  SizedBox(width: 8.w),
                  // 올린시간
                  Text(
                    date,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral500,
                          fontSize: 13.sp,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),
        // === 3. 상세 설명 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   '상세 설명',
              //   style: FigmaTextStyles().body1.copyWith(
              //         color: NewAppColor.neutral900,
              //         fontSize: 16.sp,
              //         fontWeight: FontWeight.w600,
              //       ),
              // ),
              // SizedBox(height: 12.h),
              Text(
                description ?? '상세 설명이 없습니다.',
                style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral800,
                      fontSize: 15.sp,
                      height: 1.6,
                    ),
              ),
              // SizedBox(height: 80.h),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 2. 요청 정보 카드 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '요청 정보',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),
              // 요청 정보 그리드
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(label: '카테고리', value: item.category),
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                      label: '우선순위',
                      value: urgencyLabel,
                      valueColor: urgencyColor,
                      valueWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoRow(label: '지역', value: item.displayLocation),
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                      label: '택배',
                      value: item.deliveryAvailable ? '가능' : '불가능',
                      valueColor: item.deliveryAvailable
                          ? NewAppColor.success600
                          : NewAppColor.neutral600,
                      valueWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                      label: '보상',
                      value: rewardText,
                      valueColor: item.rewardType == 'payment'
                          ? NewAppColor.primary600
                          : NewAppColor.neutral600,
                      valueWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 4. 연락처 정보 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '연락처 정보',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),
              // 전화번호
              if (item.contactPhone != null && item.contactPhone!.isNotEmpty)
                _buildContactItem(
                  icon: Icons.phone_outlined,
                  label: '전화번호',
                  value: item.contactPhone!,
                  onTap: () => _showContactDialog(item.contactPhone!),
                ),
              // 이메일
              if (item.contactEmail != null &&
                  item.contactEmail!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _buildContactItem(
                  icon: Icons.email_outlined,
                  label: '이메일',
                  value: item.contactEmail!,
                  onTap: () {
                    // TODO: 이메일 보내기 기능
                  },
                ),
              ],
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ],
    );
  }

  /// 행사팀 지원 전용 레이아웃
  Widget _buildMusicTeamSeekerLayout(
    MusicTeamSeeker item,
    String date,
    String? authorName,
    String? authorProfilePhotoUrl,
    String? churchName,
  ) {
    // 팀 형태 표시 텍스트 변환
    final teamTypeLabels = {
      'solo': '현재 솔로 활동',
      'praise-team': '찬양팀',
      'worship-team': '워십팀',
      'acoustic-team': '어쿠스틱 팀',
      'band': '밴드',
      'orchestra': '오케스트라',
      'choir': '합창단',
      'dance-team': '무용팀',
      'other': '기타',
    };

    String teamTypeDisplay = teamTypeLabels[item.instrument] ?? item.instrument;

    // 활동 가능 시간대 표시 텍스트
    String availableTimeDisplay = item.availableTime ?? '미입력';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === 1. 제목 + 상태 섹션 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                item.title,
                style: FigmaTextStyles().header1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
              ),
              SizedBox(height: 12.h),

              // 상태 배지
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: item.status == 'available'
                          ? NewAppColor.success600
                          : NewAppColor.neutral500,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      item.status == 'available' ? '지원가능' : '완료',
                      style: FigmaTextStyles().caption2.copyWith(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // 작성 시간 + 조회수
              Row(
                children: [
                  Text(
                    date,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral500,
                          fontSize: 13.sp,
                        ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '·',
                    style: TextStyle(color: NewAppColor.neutral400),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.visibility_outlined,
                      size: 14.sp, color: NewAppColor.neutral500),
                  SizedBox(width: 4.w),
                  Text(
                    '${item.viewCount}',
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral500,
                          fontSize: 13.sp,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 2. 기본 정보 카드 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기본 정보',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),

              // 기본 정보 그리드
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    if (item.teamName != null &&
                        item.teamName!.isNotEmpty &&
                        item.teamName != '없음') ...[
                      _buildInfoRow(label: '현재 활동 팀명', value: item.teamName!),
                      SizedBox(height: 12.h),
                    ],
                    _buildInfoRow(label: '전공 파트', value: teamTypeDisplay),
                    if (item.instruments != null &&
                        item.instruments!.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _buildInfoRow(
                        label: '호환 악기',
                        value: item.instruments!.join(', '),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 3. 경력 정보 ===
        if (item.experience.isNotEmpty) ...[
          Container(
            color: NewAppColor.neutral100,
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '연주 경력',
                  style: FigmaTextStyles().body1.copyWith(
                        color: NewAppColor.neutral900,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 12.h),
                Text(
                  item.experience,
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral800,
                        fontSize: 15.sp,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
          Container(height: 8.h, color: NewAppColor.white),
        ],

        // === 4. 활동 조건 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '활동 조건',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),

              // 활동 조건 그리드
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    // 활동 가능 지역
                    if (item.preferredLocation.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '활동 가능 지역',
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral600,
                                ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 6.w,
                              runSpacing: 6.h,
                              children: item.preferredLocation.map((location) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: NewAppColor.primary100,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    location,
                                    style: FigmaTextStyles().body2.copyWith(
                                          color: NewAppColor.primary700,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                    ],
                    // 활동 가능 요일
                    if (item.availableDays.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '활동 가능 요일',
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral600,
                                ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 4.w,
                              runSpacing: 4.h,
                              children: item.availableDays.map((day) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: NewAppColor.success00,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    day,
                                    style: FigmaTextStyles().body2.copyWith(
                                          color: NewAppColor.success700,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                    ],
                    // 활동 가능 시간대
                    _buildInfoRow(
                      label: '활동 가능 시간대',
                      value: availableTimeDisplay,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 5. 포트폴리오 ===
        if ((item.portfolio.isNotEmpty) ||
            (item.portfolioFile != null && item.portfolioFile!.isNotEmpty)) ...[
          Container(
            color: NewAppColor.neutral100,
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '포트폴리오',
                  style: FigmaTextStyles().body1.copyWith(
                        color: NewAppColor.neutral900,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 16.h),

                // YouTube 링크
                if (item.portfolio.isNotEmpty) ...[
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(item.portfolio);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: NewAppColor.neutral100,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: NewAppColor.neutral200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.red,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YouTube 영상',
                                  style: FigmaTextStyles().body2.copyWith(
                                        color: NewAppColor.neutral600,
                                        fontSize: 12.sp,
                                      ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  item.portfolio,
                                  style: FigmaTextStyles().body2.copyWith(
                                        color: NewAppColor.neutral900,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: NewAppColor.neutral400,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (item.portfolioFile != null &&
                      item.portfolioFile!.isNotEmpty)
                    SizedBox(height: 12.h),
                ],

                // 포트폴리오 파일
                if (item.portfolioFile != null &&
                    item.portfolioFile!.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _downloadAndOpenFile(item.portfolioFile!),
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: NewAppColor.neutral100,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: NewAppColor.neutral200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: NewAppColor.primary100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.insert_drive_file,
                              color: NewAppColor.primary600,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '포트폴리오 파일',
                                  style: FigmaTextStyles().body2.copyWith(
                                        color: NewAppColor.neutral600,
                                        fontSize: 12.sp,
                                      ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '파일 열기',
                                  style: FigmaTextStyles().body2.copyWith(
                                        color: NewAppColor.neutral900,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            color: NewAppColor.neutral400,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 8.h, color: NewAppColor.white),
        ],

        // === 6. 자기소개 ===
        if (item.introduction != null && item.introduction!.isNotEmpty) ...[
          Container(
            color: NewAppColor.neutral100,
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '자기소개',
                  style: FigmaTextStyles().body1.copyWith(
                        color: NewAppColor.neutral900,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 12.h),
                Text(
                  item.introduction!,
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral800,
                        fontSize: 15.sp,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
          Container(height: 8.h, color: NewAppColor.white),
        ],

        // === 7. 작성자 정보 ===
        Container(
          color: NewAppColor.neutral100,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '지원자 정보',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  _buildProfileImage(authorProfilePhotoUrl),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName ?? '알 수 없음',
                          style: FigmaTextStyles().body1.copyWith(
                                color: NewAppColor.neutral900,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: 4.h),
                        if (churchName != null && churchName.isNotEmpty)
                          Text(
                            churchName,
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral600,
                                  fontSize: 13.sp,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // 작성자인 경우 상태 변경 드롭다운
              if (_isAuthor()) ...[
                SizedBox(height: 16.h),
                _buildStatusDropdown(),
              ],
            ],
          ),
        ),

        // 구분선
        // Container(height: 8.h, color: NewAppColor.white),

        // === 8. 연락처 정보 ===
        Container(
          color: NewAppColor.neutral100,
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '연락처 정보',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: 16.h),
              // 전화번호
              if (item.contactPhone != null && item.contactPhone!.isNotEmpty)
                _buildContactItem(
                  icon: Icons.phone_outlined,
                  label: '전화번호',
                  value: item.contactPhone!,
                  onTap: () => _showContactDialog(item.contactPhone!),
                ),
              // 이메일
              if (item.contactEmail != null &&
                  item.contactEmail!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                _buildContactItem(
                  icon: Icons.email_outlined,
                  label: '이메일',
                  value: item.contactEmail!,
                  onTap: () {
                    // TODO: 이메일 보내기 기능
                  },
                ),
              ],
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ],
    );
  }

  /// 전화 버튼 클릭 핸들러
  Future<void> _onPhoneButtonPressed() async {
    if (_authorPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성자의 전화번호가 없습니다')),
      );
      return;
    }

    // 전화/문자 선택 bottom sheet 표시
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(
            top: 20.h,
            bottom: 20.h + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 전화 걸기
              ListTile(
                leading: Icon(Icons.phone, color: NewAppColor.primary600),
                title: Text(
                  '전화 걸기',
                  style: FigmaTextStyles().body1,
                ),
                subtitle: Text(
                  _authorPhone!,
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral400,
                      ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('tel:$_authorPhone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('전화를 걸 수 없습니다')),
                      );
                    }
                  }
                },
              ),
              Divider(height: 1, color: NewAppColor.neutral200),
              // 문자 보내기
              ListTile(
                leading: Icon(Icons.message, color: NewAppColor.primary600),
                title: Text(
                  '문자 보내기',
                  style: FigmaTextStyles().body1,
                ),
                subtitle: Text(
                  _authorPhone!,
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral400,
                      ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('sms:$_authorPhone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('문자를 보낼 수 없습니다')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 문의하기 버튼 클릭 핸들러
  Future<void> _onChatButtonPressed() async {
    if (_post == null || _currentUser == null) return;

    // 게시글 작성자 ID 추출
    int? authorId;
    String title = '';

    if (_post is CommunityBasePost) {
      authorId = (_post as CommunityBasePost).authorId;
      title = (_post as dynamic).title ?? '커뮤니티 게시글';
    }

    if (authorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성자 정보를 불러올 수 없습니다')),
      );
      return;
    }

    // 본인 게시글인 경우
    if (authorId == _currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본인 게시글에는 문의할 수 없습니다')),
      );
      return;
    }

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final chatService = ChatService();

      // 채팅방 생성 또는 조회
      final chatRoom = await chatService.createOrGetChatRoom(
        postId: widget.postId,
        postTable: widget.tableName,
        postTitle: title,
        otherUserId: authorId,
      );

      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.pop(context);

      if (chatRoom == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('채팅방 생성에 실패했습니다')),
          );
        }
        return;
      }

      // 채팅방으로 이동
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
          ),
        );
      }
    } catch (e) {
      print('❌ COMMUNITY_DETAIL: 채팅방 생성 실패 - $e');

      // 로딩 다이얼로그가 열려있으면 닫기
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 생성에 실패했습니다: $e')),
        );
      }
    }
  }
}
