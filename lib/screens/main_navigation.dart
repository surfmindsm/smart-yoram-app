import 'package:flutter/material.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
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

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: '홈',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.contacts),
      label: '주소록',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: '주보',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.announcement),
      label: '교회소식',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '설정',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }
}
