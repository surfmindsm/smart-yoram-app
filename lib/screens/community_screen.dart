import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/notification_service.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:smart_yoram_app/screens/community/community_favorites_screen.dart';
import 'package:smart_yoram_app/screens/notification_center_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, RealtimeChannel, PostgresChangeEvent;

/// 커뮤니티 메인 화면
/// 웹 명세서 기반 9개 카테고리 구조
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService.instance;

  User? _currentUser;
  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  RealtimeChannel? _notificationChannel;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadNotificationCount();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    super.dispose();
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

  /// 읽지 않은 알림 개수 로드
  Future<void> _loadUnreadNotificationCount() async {
    try {
      final response =
          await _notificationService.getMyNotifications(limit: 100);
      if (response.success && response.data != null) {
        final unreadCount = response.data!.where((n) => !n.isRead).length;
        if (mounted) {
          setState(() {
            _unreadNotificationCount = unreadCount;
          });
        }
      }
    } catch (e) {
      print('❌ COMMUNITY_SCREEN: 알림 개수 로드 실패 - $e');
    }
  }

  /// 알림 업데이트 실시간 구독
  void _subscribeToNotifications() {
    try {
      _notificationChannel = Supabase.instance.client
          .channel('community_notification_badge')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              // 알림 테이블이 변경되면 배지 업데이트
              _loadUnreadNotificationCount();
            },
          )
          .subscribe();
    } catch (e) {
      print('❌ COMMUNITY_SCREEN: 알림 구독 실패 - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: NewAppColor.skyPrimary,
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 56.sp,
                color: NewAppColor.iconFaint,
              ),
              SizedBox(height: 14.h),
              Text(
                '로그인이 필요합니다',
                style: FigmaTextStyles().subtitle2.copyWith(
                      color: NewAppColor.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // 1.2.0 C 방향: 흰 배경 + 헤더 + 카테고리 리스트
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 상단 헤더 (타이틀 + 알림/내글/찜 아이콘)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: NewAppColor.borderSoft),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6.h,
              left: 18.w,
              right: 18.w,
              bottom: 14.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 다른 화면과 동일하게 Padding(horizontal: 2.w) 적용
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Text(
                    '커뮤니티',
                    style: FigmaTextStyles().pageTitle.copyWith(
                          color: NewAppColor.textStrong,
                          fontSize: 21.sp,
                        ),
                  ),
                ),
                Row(
                  children: [
                    // 알림 아이콘
                    if (_currentUser!.role == 'member' ||
                        _currentUser!.role == 'community_admin')
                      _headerIconButton(
                        icon: LucideIcons.bell,
                        onTap: _navigateToNotifications,
                        badgeCount: _unreadNotificationCount,
                      ),
                    // 내 글
                    _headerIconButton(
                      icon: LucideIcons.filePen,
                      onTap: _navigateToMyPosts,
                    ),
                    // 찜
                    _headerIconButton(
                      icon: LucideIcons.heart,
                      onTap: _navigateToFavorites,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 카테고리 리스트
          Expanded(
            child: _buildCategoryList(),
          ),
        ],
      ),
    );
  }

  // 1.2.0 헤더 아이콘 버튼 (벨/내글/찜) — 배지 옵션
  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // 좌우는 터치 영역 유지, 상하는 타이틀과 baseline 정렬에 영향 안 가도록 최소화
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 22.sp,
              color: NewAppColor.textMuted,
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: -4,
                top: -3,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: badgeCount > 9 ? 4.w : 5.w,
                    vertical: 1.h,
                  ),
                  decoration: BoxDecoration(
                    color: NewAppColor.danger700,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.h,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 카테고리 리스트 빌드 (케이뱅크 스타일)
  Widget _buildCategoryList() {
    final categories = _getCategories();

    return Container(
      color: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isLast = index == categories.length - 1;
          return _CategoryListItem(
            category: category,
            isLast: isLast,
            onTap: () => _navigateToCategory(category),
          );
        },
      ),
    );
  }

  /// 권한에 따른 카테고리 목록 반환
  List<CommunityCategory> _getCategories() {
    // 1.2.0 C 방향: 스카이 단일 톤
    const iconColor = NewAppColor.skyDeep;
    const iconBgColor = NewAppColor.skyTint;

    final baseCategories = [
      CommunityCategory(
        id: 'sharing-market',
        title: '물품 판매',
        subtitle: '나눔하고 판매하는 물품',
        icon: LucideIcons.shoppingBag,
        color: iconColor,
        backgroundColor: iconBgColor,
      ),
      CommunityCategory(
        id: 'item-request',
        title: '물품 요청',
        subtitle: '필요한 물품 요청',
        icon: LucideIcons.search,
        color: iconColor,
        backgroundColor: iconBgColor,
      ),
    ];

    // community_admin은 제한된 메뉴만
    if (_currentUser!.isCommunityAdmin) {
      return [
        ...baseCategories,
        CommunityCategory(
          id: 'job-posting',
          title: '사역자 모집',
          subtitle: '교회/기관 채용',
          icon: LucideIcons.briefcase,
          color: iconColor,
          backgroundColor: iconBgColor,
        ),
        CommunityCategory(
          id: 'music-team-recruit',
          title: '행사팀 모집',
          subtitle: '행사팀 모집',
          icon: LucideIcons.users,
          color: iconColor,
          backgroundColor: iconBgColor,
        ),
        CommunityCategory(
          id: 'music-team-seeking',
          title: '행사팀 지원',
          subtitle: '행사팀 지원하기',
          icon: LucideIcons.userPlus,
          color: iconColor,
          backgroundColor: iconBgColor,
        ),
        CommunityCategory(
          id: 'church-news',
          title: '행사 소식',
          subtitle: '교회 행사 및 소식',
          icon: LucideIcons.megaphone,
          color: iconColor,
          backgroundColor: iconBgColor,
        ),
      ];
    }

    // 모든 사용자에게 전체 카테고리 표시
    return [
      ...baseCategories,
      CommunityCategory(
        id: 'job-posting',
        title: '사역자 모집',
        subtitle: '교회/기관 채용',
        icon: LucideIcons.briefcase,
        color: iconColor,
        backgroundColor: iconBgColor,
      ),
      CommunityCategory(
        id: 'music-team-recruit',
        title: '행사팀 모집',
        subtitle: '행사팀 모집',
        icon: LucideIcons.users,
        color: iconColor,
        backgroundColor: iconBgColor,
      ),
      CommunityCategory(
        id: 'music-team-seeking',
        title: '행사팀 지원',
        subtitle: '행사팀 지원하기',
        icon: LucideIcons.userPlus,
        color: iconColor,
        backgroundColor: iconBgColor,
      ),
      CommunityCategory(
        id: 'church-news',
        title: '행사 소식',
        subtitle: '교회 행사 및 소식',
        icon: LucideIcons.megaphone,
        color: iconColor,
        backgroundColor: iconBgColor,
      ),
    ];
  }

  /// 카테고리 네비게이션
  void _navigateToCategory(CommunityCategory category) {
    CommunityListType? listType;

    switch (category.id) {
      case 'sharing-market':
        listType =
            CommunityListType.freeSharing; // 통합된 나눔/판매 (임시로 freeSharing 사용)
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

  /// 내 글 관리로 이동
  void _navigateToMyPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityListScreen(
          categoryId: 'my-posts',
          title: '내 글 관리',
          type: CommunityListType.myPosts,
        ),
      ),
    );
  }

  /// 찜한 글로 이동
  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityFavoritesScreen(),
      ),
    );
  }

  /// 알림 센터로 이동
  void _navigateToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationCenterScreen(),
      ),
    );

    // 알림 화면에서 돌아왔을 때 배지 업데이트
    _loadUnreadNotificationCount();
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

/// 카테고리 리스트 아이템 (케이뱅크 스타일 - 구분선)
class _CategoryListItem extends StatelessWidget {
  final CommunityCategory category;
  final bool isLast;
  final VoidCallback onTap;

  const _CategoryListItem({
    required this.category,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    width: 1,
                    color: NewAppColor.borderHair,
                  ),
                ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        child: Row(
          children: [
            // 아이콘 타일 — 48×48 라운드 14 skyTint
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: category.backgroundColor,
                borderRadius: BorderRadius.circular(14.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                category.icon,
                size: 23.sp,
                color: category.color,
              ),
            ),
            SizedBox(width: 15.w),
            // 제목 + 부제
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: FigmaTextStyles().cardTitle.copyWith(
                          color: NewAppColor.textStrong,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    category.subtitle,
                    style: FigmaTextStyles().caption1.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // chevron-right (목업의 게시글 수 칩은 실제 데이터 연결 안 되어 있으므로 일단 제외)
            Icon(
              LucideIcons.chevronRight,
              size: 18.sp,
              color: NewAppColor.iconFaint,
            ),
          ],
        ),
      ),
    );
  }
}
