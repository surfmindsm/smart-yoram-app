import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:smart_yoram_app/models/community_post.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/community_service.dart';

/// 커뮤니티 메인 화면
/// 권한에 따라 다른 메뉴를 보여줌
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final CommunityService _communityService = CommunityService();

  User? _currentUser;
  bool _isLoading = true;

  // 탭 관련
  late TabController _tabController;
  List<CommunityTab> _tabs = [];

  // 현재 선택된 탭의 게시글 목록
  List<CommunityPost> _posts = [];
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndInitialize();
  }

  /// 사용자 정보 로드 및 초기화
  Future<void> _loadUserAndInitialize() async {
    try {
      final userResponse = await _authService.getCurrentUser();

      if (userResponse.success && userResponse.data != null) {
        setState(() {
          _currentUser = userResponse.data;
          _tabs = _getTabsForUserRole(_currentUser!);
          _tabController = TabController(length: _tabs.length, vsync: this);
          _isLoading = false;
        });

        // 탭 변경 리스너
        _tabController.addListener(() {
          if (!_tabController.indexIsChanging) {
            _loadPostsForCurrentTab();
          }
        });

        // 첫 번째 탭 데이터 로드
        _loadPostsForCurrentTab();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ COMMUNITY_SCREEN: 사용자 정보 로드 실패 - $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 사용자 권한에 따른 탭 목록 반환
  List<CommunityTab> _getTabsForUserRole(User user) {
    // 일반 교인 (member)
    if (user.isMember && !user.isAdmin) {
      return [
        CommunityTab(
          label: '무료나눔',
          category: 'free_sharing',
          icon: Icons.card_giftcard_outlined,
        ),
        CommunityTab(
          label: '물품 판매',
          category: 'sale',
          icon: Icons.sell_outlined,
        ),
        CommunityTab(
          label: '물품 요청',
          category: 'request',
          icon: Icons.shopping_cart_outlined,
        ),
        CommunityTab(
          label: '내가 쓴 글',
          category: 'my_posts',
          icon: Icons.edit_note_outlined,
        ),
        CommunityTab(
          label: '찜한 글',
          category: 'favorites',
          icon: Icons.favorite_border_outlined,
        ),
      ];
    }

    // 커뮤니티 관리자 (community_admin)
    if (user.isCommunityAdmin) {
      return [
        CommunityTab(
          label: '전체',
          category: 'all',
          icon: Icons.view_list_outlined,
        ),
        CommunityTab(
          label: '무료나눔',
          category: 'free_sharing',
          icon: Icons.card_giftcard_outlined,
        ),
        CommunityTab(
          label: '물품 판매',
          category: 'sale',
          icon: Icons.sell_outlined,
        ),
        CommunityTab(
          label: '물품 요청',
          category: 'request',
          icon: Icons.shopping_cart_outlined,
        ),
        CommunityTab(
          label: '신고 관리',
          category: 'reports',
          icon: Icons.report_outlined,
        ),
        CommunityTab(
          label: '통계',
          category: 'stats',
          icon: Icons.analytics_outlined,
        ),
      ];
    }

    // 교회 관리자 (church_admin, church_super_admin, system_admin)
    if (user.isChurchAdmin) {
      return [
        CommunityTab(
          label: '전체',
          category: 'all',
          icon: Icons.view_list_outlined,
        ),
        CommunityTab(
          label: '무료나눔',
          category: 'free_sharing',
          icon: Icons.card_giftcard_outlined,
        ),
        CommunityTab(
          label: '물품 판매',
          category: 'sale',
          icon: Icons.sell_outlined,
        ),
        CommunityTab(
          label: '물품 요청',
          category: 'request',
          icon: Icons.shopping_cart_outlined,
        ),
        CommunityTab(
          label: '내가 쓴 글',
          category: 'my_posts',
          icon: Icons.edit_note_outlined,
        ),
        CommunityTab(
          label: '찜한 글',
          category: 'favorites',
          icon: Icons.favorite_border_outlined,
        ),
        CommunityTab(
          label: '신고 관리',
          category: 'reports',
          icon: Icons.report_outlined,
        ),
      ];
    }

    // 기본값 (모든 사용자)
    return [
      CommunityTab(
        label: '전체',
        category: 'all',
        icon: Icons.view_list_outlined,
      ),
    ];
  }

  /// 현재 탭에 맞는 게시글 로드
  Future<void> _loadPostsForCurrentTab() async {
    if (_isLoadingPosts) return;

    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final currentTab = _tabs[_tabController.index];
      List<CommunityPost> posts = [];

      switch (currentTab.category) {
        case 'all':
          posts = await _communityService.getPosts();
          break;
        case 'my_posts':
          posts = await _communityService.getMyPosts();
          break;
        case 'favorites':
          posts = await _communityService.getFavoritePosts();
          break;
        case 'reports':
        case 'stats':
          // TODO: 신고 관리 및 통계 기능 구현
          posts = [];
          break;
        default:
          // 카테고리별 게시글 조회
          posts = await _communityService.getPosts(category: currentTab.category);
          break;
      }

      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('❌ COMMUNITY_SCREEN: 게시글 로드 실패 - $e');
      setState(() {
        _posts = [];
        _isLoadingPosts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NewAppColor.neutral100,
        body: Center(
          child: CircularProgressIndicator(
            color: NewAppColor.primary600,
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: NewAppColor.neutral100,
        body: Center(
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
                '로그인이 필요합니다',
                style: FigmaTextStyles().headline5.copyWith(
                      color: NewAppColor.neutral600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '커뮤니티',
          style: FigmaTextStyles().headline3.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        actions: [
          // 글쓰기 버튼
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: NewAppColor.neutral700,
            ),
            onPressed: () {
              // TODO: 글쓰기 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('글쓰기 기능은 준비 중입니다')),
              );
            },
          ),
          // 검색 버튼
          IconButton(
            icon: Icon(
              Icons.search,
              color: NewAppColor.neutral700,
            ),
            onPressed: () {
              // TODO: 검색 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('검색 기능은 준비 중입니다')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: NewAppColor.primary600,
          unselectedLabelColor: NewAppColor.neutral500,
          labelStyle: FigmaTextStyles().subtitle3,
          unselectedLabelStyle: FigmaTextStyles().body2,
          indicatorColor: NewAppColor.primary600,
          indicatorWeight: 2,
          tabs: _tabs.map((tab) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 18.sp),
                  SizedBox(width: 4.w),
                  Text(tab.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return _buildPostList();
        }).toList(),
      ),
    );
  }

  /// 게시글 목록 위젯
  Widget _buildPostList() {
    if (_isLoadingPosts) {
      return Center(
        child: CircularProgressIndicator(
          color: NewAppColor.primary600,
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64.sp,
              color: NewAppColor.neutral300,
            ),
            SizedBox(height: 16.h),
            Text(
              '게시글이 없습니다',
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral500,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPostsForCurrentTab,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        itemCount: _posts.length,
        separatorBuilder: (context, index) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _PostCard(post: post);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// 탭 정보 클래스
class CommunityTab {
  final String label;
  final String category;
  final IconData icon;

  CommunityTab({
    required this.label,
    required this.category,
    required this.icon,
  });
}

/// 게시글 카드 위젯
class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: 게시글 상세 화면으로 이동
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('게시글 상세: ${post.title}')),
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 카테고리 뱃지 + 작성자 정보
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: NewAppColor.primary100,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        post.categoryName,
                        style: FigmaTextStyles().caption2.copyWith(
                              color: NewAppColor.primary700,
                            ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    CircleAvatar(
                      radius: 12.r,
                      backgroundImage: post.authorProfileUrl != null
                          ? NetworkImage(post.authorProfileUrl!)
                          : null,
                      backgroundColor: NewAppColor.neutral200,
                      child: post.authorProfileUrl == null
                          ? Icon(
                              Icons.person,
                              size: 14.sp,
                              color: NewAppColor.neutral500,
                            )
                          : null,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      post.authorName,
                      style: FigmaTextStyles().caption2.copyWith(
                            color: NewAppColor.neutral600,
                          ),
                    ),
                    Spacer(),
                    Text(
                      post.formattedDate,
                      style: FigmaTextStyles().caption3.copyWith(
                            color: NewAppColor.neutral400,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // 제목
                Text(
                  post.title,
                  style: FigmaTextStyles().subtitle2.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                // 내용 미리보기
                Text(
                  post.content,
                  style: FigmaTextStyles().body3.copyWith(
                        color: NewAppColor.neutral600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // 이미지가 있으면 표시
                if (post.imageUrls.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      post.imageUrls.first,
                      height: 120.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120.h,
                          color: NewAppColor.neutral100,
                          child: Icon(
                            Icons.image_not_supported,
                            color: NewAppColor.neutral300,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                // 하단: 조회수, 좋아요, 댓글, 가격
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 16.sp,
                      color: NewAppColor.neutral400,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${post.viewCount}',
                      style: FigmaTextStyles().caption3.copyWith(
                            color: NewAppColor.neutral500,
                          ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.favorite_border,
                      size: 16.sp,
                      color: NewAppColor.neutral400,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${post.likeCount}',
                      style: FigmaTextStyles().caption3.copyWith(
                            color: NewAppColor.neutral500,
                          ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 16.sp,
                      color: NewAppColor.neutral400,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${post.commentCount}',
                      style: FigmaTextStyles().caption3.copyWith(
                            color: NewAppColor.neutral500,
                          ),
                    ),
                    Spacer(),
                    if (post.price != null)
                      Text(
                        post.formattedPrice,
                        style: FigmaTextStyles().subtitle3.copyWith(
                              color: NewAppColor.primary600,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
