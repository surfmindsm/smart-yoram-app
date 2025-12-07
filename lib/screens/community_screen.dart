import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/notification_service.dart';
import 'package:smart_yoram_app/screens/community/community_list_screen.dart';
import 'package:smart_yoram_app/screens/community/community_favorites_screen.dart';
import 'package:smart_yoram_app/screens/notification_center_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, RealtimeChannel, PostgresChangeEvent;

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
      final response = await _notificationService.getMyNotifications(limit: 100);
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
      backgroundColor: NewAppColor.neutral100,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              height: 56.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '커뮤니티',
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  Row(
                    children: [
                      // 알림
                      GestureDetector(
                        onTap: _navigateToNotifications,
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                size: 24.sp,
                                color: NewAppColor.neutral700,
                              ),
                              // 읽지 않은 알림 배지
                              if (_unreadNotificationCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: _unreadNotificationCount > 9 ? 4.w : 5.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NewAppColor.danger600,
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 18.w,
                                      minHeight: 18.w,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _unreadNotificationCount > 99
                                            ? '99+'
                                            : _unreadNotificationCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Pretendard Variable',
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // 내 글 관리
                      TextButton.icon(
                        onPressed: _navigateToMyPosts,
                        icon: Icon(
                          Icons.edit_note,
                          size: 20.sp,
                          color: NewAppColor.neutral700,
                        ),
                        label: Text(
                          '내 글',
                          style: TextStyle(
                            color: NewAppColor.neutral700,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // 내가 찜한 글
                      TextButton.icon(
                        onPressed: _navigateToFavorites,
                        icon: Icon(
                          Icons.favorite_border,
                          size: 20.sp,
                          color: NewAppColor.neutral700,
                        ),
                        label: Text(
                          '찜',
                          style: TextStyle(
                            color: NewAppColor.neutral700,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                        ),
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
        color: NewAppColor.transparent,
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
        id: 'sharing-market',
        title: '물품 판매',
        subtitle: '나눔하고 판매하는 물품',
        icon: Icons.storefront_outlined,
        color: NewAppColor.primary600,
        backgroundColor: NewAppColor.primary200,
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
      ];
    }

    // 모든 사용자에게 전체 카테고리 표시
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
