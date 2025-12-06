import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/chat_service.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, RealtimeChannel, PostgresChangeEvent;
import 'home_screen.dart';
import 'bulletin_notices_integrated_screen.dart';
import 'members_screen.dart';
import 'community_screen.dart';
import 'chat/chat_list_screen.dart';
import 'settings_screen.dart';
// import 'sermons_screen.dart'; // 명설교 주석처리

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  int _currentIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  int _unreadChatCount = 0;
  RealtimeChannel? _chatBadgeChannel;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadCount();
    _subscribeToChatUpdates();
  }

  @override
  void dispose() {
    _chatBadgeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userResponse = await _authService.getCurrentUser();
    setState(() {
      _currentUser = userResponse.data;
      _isLoading = false;
    });
  }

  /// 안 읽은 채팅 개수 로드
  Future<void> _loadUnreadCount() async {
    final count = await _chatService.getTotalUnreadCount();
    if (mounted) {
      setState(() {
        _unreadChatCount = count;
      });
    }
  }

  /// 채팅 업데이트 실시간 구독
  void _subscribeToChatUpdates() {
    try {
      _chatBadgeChannel = Supabase.instance.client
          .channel('main_nav_chat_badge')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'p2p_chat_participants',
            callback: (payload) {
              // 참여자 테이블이 변경되면 배지 업데이트
              _loadUnreadCount();
            },
          )
          .subscribe();
    } catch (e) {
      print('❌ MAIN_NAV: 채팅 배지 구독 실패 - $e');
    }
  }

  List<Widget> get _screens {
    if (_currentUser == null) {
      return [const HomeScreen()];
    }

    // community_admin은 커뮤니티 + 채팅 + 설정 표시
    if (_currentUser!.isCommunityAdmin) {
      return [
        const CommunityScreen(),
        const ChatListScreen(),
        const SettingsScreen(),
      ];
    }

    // 일반 사용자 및 교회 관리자: 모든 메뉴 표시
    return [
      const HomeScreen(),
      const MembersScreen(),
      const BulletinNoticesIntegratedScreen(), // 주보+교회소식 통합
      const ChatListScreen(), // 채팅 목록
      // const SermonsScreen(), // 명설교 화면 추가 (주석처리)
      if (_currentUser!.hasCommunityAccess) const CommunityScreen(),
    ];
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

    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          height: 52.h,
          child: Row(
            children: _buildNavItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    if (_currentUser == null) {
      return [
        _NavItem(
          icon: LucideIcons.house,
          label: '홈',
          isActive: true,
          onTap: () {},
        ),
      ];
    }

    // community_admin: 커뮤니티 + 채팅 + 설정 표시
    if (_currentUser!.isCommunityAdmin) {
      return [
        _NavItem(
          icon: LucideIcons.usersRound,
          label: '커뮤니티',
          isActive: _currentIndex == 0,
          onTap: () => _onTap(0),
        ),
        _NavItem(
          icon: LucideIcons.messageCircle,
          label: '채팅',
          isActive: _currentIndex == 1,
          badgeCount: _unreadChatCount,
          onTap: () => _onTap(1),
        ),
        _NavItem(
          icon: LucideIcons.settings,
          label: '설정',
          isActive: _currentIndex == 2,
          onTap: () => _onTap(2),
        ),
      ];
    }

    // 일반 사용자 및 교회 관리자
    final items = <Widget>[
      _NavItem(
        icon: LucideIcons.house,
        label: '홈',
        isActive: _currentIndex == 0,
        onTap: () => _onTap(0),
      ),
      _NavItem(
        icon: LucideIcons.users,
        label: '주소록',
        isActive: _currentIndex == 1,
        onTap: () => _onTap(1),
      ),
      _NavItem(
        icon: LucideIcons.newspaper,
        label: '교회소식',
        isActive: _currentIndex == 2,
        onTap: () => _onTap(2),
      ),
      _NavItem(
        icon: LucideIcons.messageCircle,
        label: '채팅',
        isActive: _currentIndex == 3,
        badgeCount: _unreadChatCount,
        onTap: () => _onTap(3),
      ),
      // _NavItem(
      //   icon: Icons.video_library_outlined,
      //   label: '명설교',
      //   isActive: _currentIndex == 4,
      //   onTap: () => _onTap(4),
      // ),
    ];

    // 커뮤니티 접근 권한이 있으면 커뮤니티 탭 추가
    if (_currentUser!.hasCommunityAccess) {
      items.add(
        _NavItem(
          icon: LucideIcons.usersRound,
          label: '커뮤니티',
          isActive: _currentIndex == 4, // 주보+교회소식 통합으로 인덱스 변경
          onTap: () => _onTap(4),
        ),
      );
    }

    return items;
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    // 채팅 탭으로 이동하면 잠시 후 배지 새로고침 (읽음 처리 반영)
    // community_admin은 index 1이 채팅, 일반 사용자는 index 3이 채팅
    final isChatTab = (_currentUser!.isCommunityAdmin && index == 1) ||
                      (!_currentUser!.isCommunityAdmin && index == 3);

    if (isChatTab && _currentUser != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadUnreadCount();
      });
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isActive ? NewAppColor.neutral800 : NewAppColor.neutral400;
    final textColor =
        isActive ? NewAppColor.neutral800 : NewAppColor.neutral400;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘 + 배지
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24.w,
                    color: iconColor,
                  ),
                  // 배지 표시 (개수가 0보다 클 때만)
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: badgeCount > 9 ? 5.w : 6.w,
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
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
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
              const SizedBox(height: 4),
              Text(
                label,
                style: FigmaTextStyles().captionText2.copyWith(
                      color: textColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
