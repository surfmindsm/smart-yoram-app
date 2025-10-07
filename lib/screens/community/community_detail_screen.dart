import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/wishlist_service.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:smart_yoram_app/screens/community/community_create_screen.dart';

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
  int _currentImageIndex = 0;

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

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;

    final postType = _getPostType();
    if (postType == null || _post == null) return;

    setState(() => _isFavoriteLoading = true);

    try {
      if (_isFavorited) {
        // 찜하기 해제
        await _wishlistService.removeFromWishlist(
          postType: postType,
          postId: widget.postId,
        );
      } else {
        // 찜하기 추가
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

        await _wishlistService.addToWishlist(
          postType: postType,
          postId: widget.postId,
          postTitle: title,
          postDescription: description ?? '',
        );
      }

      setState(() {
        _isFavorited = !_isFavorited;
        _isFavoriteLoading = false;
      });
    } catch (e) {
      print('❌ COMMUNITY_DETAIL: 찜하기 토글 실패 - $e');
      setState(() => _isFavoriteLoading = false);
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
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited ? Colors.red : Colors.black,
              ),
              onPressed: _toggleFavorite,
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
    String? authorProfilePhotoUrl = '';
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
      authorProfilePhotoUrl = post.authorProfilePhotoUrl;
      churchName = post.churchName;
      churchLocation = post.displayLocation; // province + district
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

    return SingleChildScrollView(
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
                ],
                // 작성자 정보 카드
                Container(
                  color: Colors.white,
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
                // 연락처 정보 (물품 나눔/판매 게시글만)
                if (_post is SharingItem) ...[
                  Container(
                    height: 8.h,
                    color: NewAppColor.neutral100,
                  ),
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '연락처 정보',
                          style: TextStyle(
                            color: NewAppColor.neutral900,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // 전화번호
                        if ((_post as SharingItem).contactPhone.isNotEmpty)
                          _buildContactItem(
                            icon: Icons.phone_outlined,
                            label: '전화번호',
                            value: (_post as SharingItem).contactPhone,
                            onTap: () => _showContactDialog((_post as SharingItem).contactPhone),
                          ),
                        // 이메일
                        if ((_post as SharingItem).contactEmail != null &&
                            (_post as SharingItem).contactEmail!.isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          _buildContactItem(
                            icon: Icons.email_outlined,
                            label: '이메일',
                            value: (_post as SharingItem).contactEmail!,
                            onTap: () {
                              // TODO: 이메일 보내기 기능
                            },
                          ),
                        ],
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

  void _showPostMenu() {
    // 작성자 확인
    final isAuthor = _currentUser != null &&
                     _post != null &&
                     (_post as CommunityBasePost).authorId == _currentUser!.id;

    if (!isAuthor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 작성자만 수정할 수 있습니다')),
      );
      return;
    }

    // 현재 상태 확인
    final currentStatus = (_post as CommunityBasePost).status;
    final isCompleted = currentStatus == 'completed' || currentStatus == 'closed';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상태 변경
              ListTile(
                leading: Icon(
                  isCompleted ? Icons.restart_alt : Icons.check_circle_outline,
                  color: isCompleted ? NewAppColor.primary600 : NewAppColor.success600,
                ),
                title: Text(isCompleted ? '진행중으로 변경' : '완료로 변경'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePostStatus();
                },
              ),
              const Divider(height: 1),
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

  /// 게시글 상태 토글 (완료 <-> 진행중)
  Future<void> _togglePostStatus() async {
    if (_post == null) return;

    final currentStatus = (_post as CommunityBasePost).status;
    final isCompleted = currentStatus == 'completed' || currentStatus == 'closed';

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
}
