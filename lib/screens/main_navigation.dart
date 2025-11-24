import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'home_screen.dart';
import 'bulletin_screen.dart';
import 'notices_screen.dart';
import 'settings_screen.dart';
import 'members_screen.dart';
import 'community_screen.dart';
// import 'sermons_screen.dart'; // 명설교 주석처리

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final AuthService _authService = AuthService();

  int _currentIndex = 0;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userResponse = await _authService.getCurrentUser();
    setState(() {
      _currentUser = userResponse.data;
      _isLoading = false;
    });
  }

  List<Widget> get _screens {
    if (_currentUser == null) {
      return [const HomeScreen()];
    }

    // community_admin은 커뮤니티만 표시
    if (_currentUser!.isCommunityAdmin) {
      return [const CommunityScreen()];
    }

    // 일반 사용자 및 교회 관리자: 모든 메뉴 표시
    return [
      const HomeScreen(),
      const MembersScreen(),
      const BulletinScreen(),
      const NoticesScreen(showAppBar: false), // main navigation에서는 앱바 없음
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
          icon: Icons.home_outlined,
          label: '홈',
          isActive: true,
          onTap: () {},
        ),
      ];
    }

    // community_admin: 커뮤니티만 표시
    if (_currentUser!.isCommunityAdmin) {
      return [
        _NavItem(
          icon: Icons.forum_outlined,
          label: '커뮤니티',
          isActive: _currentIndex == 0,
          onTap: () => _onTap(0),
        ),
      ];
    }

    // 일반 사용자 및 교회 관리자
    final items = <Widget>[
      _NavItem(
        icon: Icons.home_outlined,
        label: '홈',
        isActive: _currentIndex == 0,
        onTap: () => _onTap(0),
      ),
      _NavItem(
        icon: Icons.group_outlined,
        label: '주소록',
        isActive: _currentIndex == 1,
        onTap: () => _onTap(1),
      ),
      _NavItem(
        icon: Icons.menu_book_outlined,
        label: '주보',
        isActive: _currentIndex == 2,
        onTap: () => _onTap(2),
      ),
      _NavItem(
        icon: Icons.campaign_outlined,
        label: '교회소식',
        isActive: _currentIndex == 3,
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
          icon: Icons.forum_outlined,
          label: '커뮤니티',
          isActive: _currentIndex == 4, // 명설교 주석처리로 인덱스 변경 5 -> 4
          onTap: () => _onTap(4),
        ),
      );
    }

    return items;
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

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
              Icon(
                icon,
                size: 24.w,
                color: iconColor,
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
