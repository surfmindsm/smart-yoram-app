import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/wishlist_service.dart';
import 'package:smart_yoram_app/models/user.dart';

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

  bool _isLoading = true;
  dynamic _post;
  User? _currentUser;
  bool _isFavorited = false;
  bool _isFavoriteLoading = false;

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
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
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
              icon: const Icon(Icons.share_outlined, color: Colors.black),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
          if (_canEdit())
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
              : _buildContent(),
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
    String? churchName = '';
    String? churchLocation = '';

    // 타입별 필드 매핑
    if (_post is SharingItem) {
      final post = _post as SharingItem;
      title = post.title;
      description = post.description;
      images = post.images;
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      churchName = post.churchName;
      churchLocation = post.churchLocation;
    } else if (_post is RequestItem) {
      final post = _post as RequestItem;
      title = post.title;
      description = post.description;
      date = post.formattedDate;
      viewCount = post.viewCount;
      authorName = post.authorName;
      churchName = post.churchName;
      churchLocation = post.location;
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

    return Column(
      children: [
        // 이미지 갤러리 (최상단)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty) ...[
                  Stack(
                    children: [
                      SizedBox(
                        height: 400.h,
                        child: PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
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
                            '1 / ${images.length}',
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
                ],
                // 작성자 정보 카드
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      // 프로필 아이콘
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: NewAppColor.neutral200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: NewAppColor.neutral500,
                          size: 24.sp,
                        ),
                      ),
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
                                if (churchName != null && churchName.isNotEmpty) churchName,
                                if (churchLocation != null && churchLocation.isNotEmpty) churchLocation,
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
                ),
                Container(
                  height: 8.h,
                  color: NewAppColor.neutral100,
                ),
                // 제목 및 본문
                Container(
                  color: Colors.white,
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
            ),
          ),
        ),
        // 하단 입력 바
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: NewAppColor.neutral200,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SafeArea(
            child: Row(
              children: [
                // 좋아요 아이콘
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.favorite_border,
                    color: NewAppColor.neutral600,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                // 입력 필드
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: NewAppColor.neutral100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '안녕하세요. 관심 있어서 문의드려요.',
                      style: TextStyle(
                        color: NewAppColor.neutral500,
                        fontSize: 14.sp,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // 보내기 버튼
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.primary600,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '보내기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  bool _canEdit() {
    if (_currentUser == null || _post == null) return false;

    // 관리자는 모든 게시글 수정 가능
    if (_currentUser!.isChurchAdmin || _currentUser!.isCommunityAdmin) {
      return true;
    }

    // 본인 게시글만 수정 가능
    if (_post is CommunityBasePost) {
      return (_post as CommunityBasePost).authorId == _currentUser!.id;
    }

    return false;
  }

  void _showPostMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('수정'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editPost() {
    // TODO: 게시글 수정
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수정 기능은 준비 중입니다')),
    );
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
}
