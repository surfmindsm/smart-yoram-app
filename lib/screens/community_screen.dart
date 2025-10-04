import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:smart_yoram_app/screens/community/community_favorites_screen.dart';
import 'package:smart_yoram_app/screens/settings_screen.dart';

/// 커뮤니티 메인 화면
/// 웹 명세서 기반 9개 카테고리 구조
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = true;
  String _selectedLocation = '신사동';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final userResponse = await _authService.getCurrentUser();

      if (userResponse.success && userResponse.data != null) {
        setState(() {
          _currentUser = userResponse.data;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: NewAppColor.neutral100,
        body: const Center(
          child: CircularProgressIndicator(),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // 지역 선택 드롭다운
            InkWell(
              onTap: _showLocationPicker,
              child: Row(
                children: [
                  Text(
                    _selectedLocation,
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: NewAppColor.neutral900,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // 햄버거 메뉴
          IconButton(
            icon: Icon(
              Icons.menu,
              color: NewAppColor.neutral900,
              size: 28.sp,
            ),
            onPressed: () {},
          ),
          // 검색
          IconButton(
            icon: Icon(
              Icons.search,
              color: NewAppColor.neutral900,
              size: 28.sp,
            ),
            onPressed: () {},
          ),
          // 알림
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: NewAppColor.neutral900,
                  size: 28.sp,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8.w,
                top: 8.h,
                child: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // community_admin인 경우 설정 버튼 표시
          if (_currentUser!.isCommunityAdmin)
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: NewAppColor.neutral700,
                size: 28.sp,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildCategoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 글쓰기 화면으로 이동
        },
        backgroundColor: NewAppColor.primary600,
        child: Icon(Icons.add, color: Colors.white, size: 32.sp),
      ),
    );
  }

  /// 카테고리 리스트 빌드 (당근마켓 스타일)
  Widget _buildCategoryList() {
    final categories = _getCategories();

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: categories.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        indent: 72.w,
        color: NewAppColor.neutral200,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryListItem(
          category: category,
          onTap: () => _navigateToCategory(category),
        );
      },
    );
  }

  /// 권한에 따른 카테고리 목록 반환
  List<CommunityCategory> _getCategories() {
    final baseCategories = [
      CommunityCategory(
        id: 'free-sharing',
        title: '무료 나눔',
        subtitle: '나눔하고 싶은 물품',
        icon: Icons.card_giftcard_outlined,
        color: NewAppColor.success600,
        backgroundColor: NewAppColor.success200,
      ),
      CommunityCategory(
        id: 'item-sale',
        title: '물품 판매',
        subtitle: '판매하고 싶은 물품',
        icon: Icons.sell_outlined,
        color: NewAppColor.warning600,
        backgroundColor: NewAppColor.warning200,
      ),
      CommunityCategory(
        id: 'item-request',
        title: '물품 요청',
        subtitle: '필요한 물품 요청',
        icon: Icons.shopping_cart_outlined,
        color: NewAppColor.primary600,
        backgroundColor: NewAppColor.primary200,
      ),
    ];

    // community_admin은 제한된 메뉴만
    if (_currentUser!.isCommunityAdmin) {
      return [
        ...baseCategories,
        CommunityCategory(
          id: 'music-team-recruit',
          title: ' 모집',
          subtitle: '찬양팀 멤버 모집',
          icon: Icons.music_note_outlined,
          color: NewAppColor.secondary600,
          backgroundColor: NewAppColor.secondary200,
        ),
        CommunityCategory(
          id: 'music-team-seeking',
          title: '음악팀 참여',
          subtitle: '음악팀 지원하기',
          icon: Icons.queue_music_outlined,
          color: NewAppColor.secondary600,
          backgroundColor: NewAppColor.secondary200,
        ),
        CommunityCategory(
          id: 'church-news',
          title: '교회 소식',
          subtitle: '교회 행사 및 소식',
          icon: Icons.event_outlined,
          color: Colors.purple,
          backgroundColor: Colors.purple.shade50,
        ),
        CommunityCategory(
          id: 'my-posts',
          title: '내 게시글',
          subtitle: '내가 작성한 글',
          icon: Icons.edit_note_outlined,
          color: NewAppColor.neutral700,
          backgroundColor: NewAppColor.neutral200,
        ),
        CommunityCategory(
          id: 'my-favorites',
          title: '찜한 글',
          subtitle: '내가 찜한 글',
          icon: Icons.favorite_border,
          color: Colors.pink,
          backgroundColor: Colors.pink.shade50,
        ),
      ];
    }

    // member 권한: 기본 카테고리만 (사역자 모집, 행사팀 모집/지원 제외)
    if (_currentUser!.isMember) {
      return [
        ...baseCategories,
        CommunityCategory(
          id: 'church-news',
          title: '교회 소식',
          subtitle: '교회 행사 및 소식',
          icon: Icons.event_outlined,
          color: Colors.purple,
          backgroundColor: Colors.purple.shade50,
        ),
        CommunityCategory(
          id: 'my-posts',
          title: '내 게시글',
          subtitle: '내가 작성한 글',
          icon: Icons.edit_note_outlined,
          color: NewAppColor.neutral700,
          backgroundColor: NewAppColor.neutral200,
        ),
        CommunityCategory(
          id: 'my-favorites',
          title: '찜한 글',
          subtitle: '내가 찜한 글',
          icon: Icons.favorite_border,
          color: Colors.pink,
          backgroundColor: Colors.pink.shade50,
        ),
      ];
    }

    // 일반 사용자 및 교회 관리자 (member가 아닌 경우)
    return [
      ...baseCategories,
      CommunityCategory(
        id: 'job-posting',
        title: '사역자 모집',
        subtitle: '교회/기관 채용',
        icon: Icons.work_outline,
        color: Colors.blue,
        backgroundColor: Colors.blue.shade50,
      ),
      CommunityCategory(
        id: 'music-team-recruit',
        title: '행사팀 모집',
        subtitle: '행사팀 모집',
        icon: Icons.music_note_outlined,
        color: NewAppColor.secondary600,
        backgroundColor: NewAppColor.secondary200,
      ),
      CommunityCategory(
        id: 'music-team-seeking',
        title: '행사팀 지원',
        subtitle: '행사팀 지원하기',
        icon: Icons.queue_music_outlined,
        color: NewAppColor.secondary600,
        backgroundColor: NewAppColor.secondary200,
      ),
      CommunityCategory(
        id: 'church-news',
        title: '행사 소식',
        subtitle: '교회 행사 및 소식',
        icon: Icons.event_outlined,
        color: Colors.purple,
        backgroundColor: Colors.purple.shade50,
      ),
      CommunityCategory(
        id: 'my-posts',
        title: '내 글 관리',
        subtitle: '내가 작성한 글',
        icon: Icons.edit_note_outlined,
        color: NewAppColor.neutral700,
        backgroundColor: NewAppColor.neutral200,
      ),
      CommunityCategory(
        id: 'my-favorites',
        title: '내가 찜한 글',
        subtitle: '내가 찜한 글',
        icon: Icons.favorite_border,
        color: Colors.pink,
        backgroundColor: Colors.pink.shade50,
      ),
    ];
  }

  /// 카테고리 네비게이션
  void _navigateToCategory(CommunityCategory category) {
    CommunityListType? listType;

    switch (category.id) {
      case 'free-sharing':
        listType = CommunityListType.freeSharing;
        break;
      case 'item-sale':
        listType = CommunityListType.itemSale;
        break;
      case 'item-request':
        listType = CommunityListType.itemRequest;
        break;
      case 'job-posting':
        listType = CommunityListType.jobPosting;
        break;
      case 'music-team-recruit':
        listType = CommunityListType.musicTeamRecruit;
        break;
      case 'music-team-seeking':
        listType = CommunityListType.musicTeamSeeking;
        break;
      case 'church-news':
        listType = CommunityListType.churchNews;
        break;
      case 'my-posts':
        listType = CommunityListType.myPosts;
        break;
      case 'my-favorites':
        // 찜한 글은 별도 화면 사용
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CommunityFavoritesScreen(),
          ),
        );
        return;
    }

    if (listType != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityListScreen(
            categoryId: category.id,
            title: category.title,
            type: listType!,
          ),
        ),
      );
    }
  }

  /// 지역 선택 다이얼로그
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        final locations = ['신사동', '역삼동', '논현동', '청담동', '압구정동'];

        return Container(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '지역 선택',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard Variable',
                ),
              ),
              SizedBox(height: 16.h),
              ...locations.map((location) {
                return ListTile(
                  title: Text(
                    location,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  selected: _selectedLocation == location,
                  selectedTileColor: NewAppColor.primary100,
                  onTap: () {
                    setState(() {
                      _selectedLocation = location;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

/// 커뮤니티 카테고리 모델
class CommunityCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  CommunityCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

/// 카테고리 리스트 아이템 (당근마켓 스타일)
class _CategoryListItem extends StatelessWidget {
  final CommunityCategory category;
  final VoidCallback onTap;

  const _CategoryListItem({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: category.backgroundColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                category.icon,
                size: 24.sp,
                color: category.color,
              ),
            ),
            SizedBox(width: 16.w),
            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    category.subtitle,
                    style: TextStyle(
                      color: NewAppColor.neutral600,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ],
              ),
            ),
            // 화살표
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
}
