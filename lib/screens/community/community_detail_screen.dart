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
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryTitle,
          style: FigmaTextStyles().headline4.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        actions: [
          // 내 게시글인 경우 수정/삭제 메뉴
          if (_canEdit()) ...[
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: _showPostMenu,
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: NewAppColor.neutral200,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _buildBottomBar(),
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
    String status = '';
    String date = '';
    int viewCount = 0;
    int likes = 0;
    String? authorName = '';
    String? churchName = '';
    String? location = '';

    // 타입별 필드 매핑
    if (_post is SharingItem) {
      final post = _post as SharingItem;
      title = post.title;
      description = post.description;
      images = post.images;
      status = post.statusDisplayName;
      date = post.formattedDate;
      viewCount = post.viewCount;
      likes = post.likes;
      authorName = post.authorName;
      churchName = post.displayChurchName;
      location = post.location;
    } else if (_post is RequestItem) {
      final post = _post as RequestItem;
      title = post.title;
      description = post.description;
      status = post.statusDisplayName;
      date = post.formattedDate;
      viewCount = post.viewCount;
      likes = post.likes;
      authorName = post.authorName;
      churchName = post.displayChurchName;
      location = post.location;
    } else if (_post is JobPost) {
      final post = _post as JobPost;
      title = post.title;
      description = post.description;
      status = post.statusDisplayName;
      date = post.formattedDate;
      viewCount = post.viewCount;
      likes = post.likes;
      authorName = post.authorName;
      churchName = post.displayChurchName;
      location = post.location;
    } else if (_post is MusicTeamRecruitment) {
      final post = _post as MusicTeamRecruitment;
      title = post.title;
      description = post.description;
      status = post.statusDisplayName;
      date = post.formattedDate;
      viewCount = post.viewCount;
      likes = post.likes;
      authorName = post.authorName;
      churchName = post.displayChurchName;
      location = post.location;
    } else if (_post is MusicTeamSeeker) {
      final post = _post as MusicTeamSeeker;
      title = post.title;
      description = post.introduction;
      status = post.statusDisplayName;
      date = post.formattedDate;
      viewCount = post.viewCount;
      likes = post.likes;
      authorName = post.authorName;
      churchName = post.displayChurchName;
    } else if (_post is ChurchNews) {
      final post = _post as ChurchNews;
      title = post.title;
      description = post.content ?? post.description;
      images = post.images ?? [];
      status = post.statusDisplayName;
      date = post.formattedDate;
      viewCount = post.viewCount;
      likes = post.likes;
      authorName = post.authorName;
      churchName = post.displayChurchName;
      location = post.location;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 정보
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 뱃지
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    status,
                    style: FigmaTextStyles().caption3.copyWith(
                          color: _getStatusColor(status),
                        ),
                  ),
                ),
                SizedBox(height: 16.h),
                // 제목
                Text(
                  title,
                  style: FigmaTextStyles().headline4.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                ),
                SizedBox(height: 12.h),
                // 작성자 정보
                Row(
                  children: [
                    if (authorName != null && authorName.isNotEmpty) ...[
                      Text(
                        authorName,
                        style: FigmaTextStyles().body3.copyWith(
                              color: NewAppColor.neutral600,
                            ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Text(
                      date,
                      style: FigmaTextStyles().caption3.copyWith(
                            color: NewAppColor.neutral400,
                          ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.visibility_outlined,
                      size: 14.sp,
                      color: NewAppColor.neutral400,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '$viewCount',
                      style: FigmaTextStyles().caption3.copyWith(
                            color: NewAppColor.neutral500,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // 교회/지역 정보
                Row(
                  children: [
                    if (churchName != null && churchName.isNotEmpty) ...[
                      Icon(
                        Icons.church_outlined,
                        size: 14.sp,
                        color: NewAppColor.neutral400,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        churchName,
                        style: FigmaTextStyles().caption3.copyWith(
                              color: NewAppColor.neutral500,
                            ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    if (location != null && location.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 14.sp,
                        color: NewAppColor.neutral400,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        location,
                        style: FigmaTextStyles().caption3.copyWith(
                              color: NewAppColor.neutral500,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // 이미지 갤러리
          if (images.isNotEmpty) ...[
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16.r),
              child: SizedBox(
                height: 200.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (context, index) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        images[index],
                        height: 200.h,
                        width: 200.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200.h,
                            width: 200.w,
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
            ),
            SizedBox(height: 8.h),
          ],
          // 본문
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            child: Text(
              description ?? '',
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral800,
                    height: 1.6,
                  ),
            ),
          ),
          SizedBox(height: 8.h),
          // 댓글 영역 (TODO)
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '댓글',
                  style: FigmaTextStyles().subtitle2.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    '댓글 기능은 준비 중입니다',
                    style: FigmaTextStyles().body3.copyWith(
                          color: NewAppColor.neutral400,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_post == null) return const SizedBox.shrink();

    int likes = 0;
    if (_post is CommunityBasePost) {
      likes = (_post as CommunityBasePost).likes;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        child: Row(
          children: [
            // 찜하기 버튼
            InkWell(
              onTap: _isFavoriteLoading ? null : _toggleFavorite,
              child: _isFavoriteLoading
                  ? SizedBox(
                      width: 24.sp,
                      height: 24.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.pink,
                        ),
                      ),
                    )
                  : Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      size: 24.sp,
                      color: _isFavorited ? Colors.pink : NewAppColor.neutral600,
                    ),
            ),
            SizedBox(width: 24.w),
            // 좋아요 버튼
            InkWell(
              onTap: _toggleLike,
              child: Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 24.sp,
                    color: NewAppColor.neutral600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '$likes',
                    style: FigmaTextStyles().body3.copyWith(
                          color: NewAppColor.neutral600,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 24.w),
            // 공유 버튼
            InkWell(
              onTap: _share,
              child: Icon(
                Icons.share_outlined,
                size: 24.sp,
                color: NewAppColor.neutral600,
              ),
            ),
            const Spacer(),
            // 연락하기 버튼 (물품/구인 등)
            if (_shouldShowContactButton()) ...[
              ElevatedButton(
                onPressed: _contact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NewAppColor.primary600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  '연락하기',
                  style: FigmaTextStyles().button2.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case '진행중':
      case '나눔가능':
      case '모집중':
      case '요청중':
        return NewAppColor.success600;
      case 'completed':
      case '완료':
      case '마감':
        return NewAppColor.neutral500;
      case 'cancelled':
      case '취소':
        return Colors.red;
      case 'reserved':
      case '예약중':
        return NewAppColor.warning600;
      default:
        return NewAppColor.primary600;
    }
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

  bool _shouldShowContactButton() {
    // 물품 나눔/판매, 물품 요청, 구인/구직 등에만 연락하기 버튼 표시
    return widget.tableName == 'community_sharing' ||
        widget.tableName == 'community_requests' ||
        widget.tableName == 'job_posts';
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

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    final postType = _getPostType();
    if (postType == null) return;

    setState(() => _isFavoriteLoading = true);

    try {
      if (_isFavorited) {
        // 찜하기 제거
        final response = await _wishlistService.removeFromWishlist(
          postType: postType,
          postId: widget.postId,
        );

        if (mounted) {
          if (response.success) {
            setState(() {
              _isFavorited = false;
              _isFavoriteLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message)),
            );
          } else {
            setState(() => _isFavoriteLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message)),
            );
          }
        }
      } else {
        // 찜하기 추가
        String title = '';
        String description = '';
        String? imageUrl;

        if (_post is SharingItem) {
          final post = _post as SharingItem;
          title = post.title;
          description = post.description ?? '';
          imageUrl = post.images.isNotEmpty ? post.images.first : null;
        } else if (_post is RequestItem) {
          final post = _post as RequestItem;
          title = post.title;
          description = post.description ?? '';
        } else if (_post is JobPost) {
          final post = _post as JobPost;
          title = post.title;
          description = post.description ?? '';
        } else if (_post is MusicTeamRecruitment) {
          final post = _post as MusicTeamRecruitment;
          title = post.title;
          description = post.description ?? '';
        } else if (_post is MusicTeamSeeker) {
          final post = _post as MusicTeamSeeker;
          title = post.title;
          description = post.introduction ?? '';
        } else if (_post is ChurchNews) {
          final post = _post as ChurchNews;
          title = post.title;
          description = post.content ?? post.description ?? '';
          imageUrl = post.images?.isNotEmpty == true ? post.images!.first : null;
        }

        final response = await _wishlistService.addToWishlist(
          postType: postType,
          postId: widget.postId,
          postTitle: title,
          postDescription: description,
          postImageUrl: imageUrl,
        );

        if (mounted) {
          if (response.success) {
            setState(() {
              _isFavorited = true;
              _isFavoriteLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message)),
            );
          } else {
            setState(() => _isFavoriteLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message)),
            );
          }
        }
      }
    } catch (e) {
      print('❌ COMMUNITY_DETAIL: 찜하기 토글 실패 - $e');
      if (mounted) {
        setState(() => _isFavoriteLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오류가 발생했습니다')),
        );
      }
    }
  }

  void _toggleLike() {
    // TODO: 좋아요 토글
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('좋아요 기능은 준비 중입니다')),
    );
  }

  void _share() {
    // TODO: 공유 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 기능은 준비 중입니다')),
    );
  }

  void _contact() {
    // TODO: 연락하기 기능
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('연락하기 기능은 준비 중입니다')),
    );
  }
}
