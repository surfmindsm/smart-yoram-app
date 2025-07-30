import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'attendance_screen.dart';
import 'bulletin_screen.dart';
import 'notices_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfileScreen(),
    const AttendanceScreen(),
    const BulletinScreen(),
    const NoticesScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: '홈',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: '내 정보',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.check_box),
      label: '출석',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: '주보',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.announcement),
      label: '공지',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
