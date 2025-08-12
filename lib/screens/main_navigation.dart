import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
import 'package:smart_yoram_app/resource/text_style.dart';
import 'home_screen.dart';

import 'bulletin_screen.dart';
import 'notices_screen.dart';
import 'settings_screen.dart';
import 'members_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MembersScreen(),
    const BulletinScreen(),
    const NoticesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
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
            children: [
              _NavItem(
                iconPath: 'assets/icons/icon_home.svg',
                label: '홈',
                isActive: _currentIndex == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                iconPath: 'assets/icons/icon_member.svg',
                label: '주소록',
                isActive: _currentIndex == 1,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                iconPath: 'assets/icons/icon_bulletin.svg',
                label: '주보',
                isActive: _currentIndex == 2,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                iconPath: 'assets/icons/icon_notice.svg',
                label: '교회소식',
                isActive: _currentIndex == 3,
                onTap: () => _onTap(3),
              ),
              _NavItem(
                iconPath: 'assets/icons/icon_setting.svg',
                label: '설정',
                isActive: _currentIndex == 4,
                onTap: () => _onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppColor.secondary06 : AppColor.secondary04;
    final textColor = isActive ? AppColor.secondary06 : AppColor.secondary04;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(
                  iconColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyle(
                  color: textColor,
                ).c2(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
