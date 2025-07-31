import 'package:flutter/material.dart';
import '../widget/widgets.dart';
import '../services/auth_service.dart';
import 'calendar_screen.dart';
import 'prayer_screen.dart';
import 'settings_screen.dart';
import 'qr_scan_screen.dart';
import 'notification_center_screen.dart';
import 'staff_directory_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? churchInfo;
  Map<String, dynamic>? userStats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // 교회 정보 로드 (임시 데이터)
      churchInfo = {
        'name': '새로운 교회',
        'pastor': '김목사',
        'phone': '031-123-4567',
        'email': 'church@example.com',
      };

      // 사용자 개인 통계 로드 (임시 데이터)
      userStats = {
        'myAttendanceRate': 85,
        'monthlyAttendance': 12,
        'upcomingBirthdays': 3,
        'unreadNotices': 2,
      };

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: churchInfo?['name'] ?? '스마트 교회요람',
        actions: [
          // 개발용 로그아웃 버튼 (테스트 목적)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: '개발용 로그아웃',
            onPressed: () => _showDevLogoutDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 교회 정보 카드
              _buildChurchInfoCard(),
              const SizedBox(height: 16),
              
              // 내 통계
              _buildMyStats(),
              const SizedBox(height: 24),
              
              // 빠른 메뉴
              _buildQuickMenus(),
              const SizedBox(height: 24),
              
              // 더 많은 기능
              _buildMoreFeaturesSection(),
              const SizedBox(height: 24),
              
              // 최근 공지사항
              _buildRecentNotices(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChurchInfoCard() {
    return InfoCardWidget(
      title: churchInfo?['name'] ?? '교회명',
      icon: Icons.church,
      items: [
        InfoItem(
          label: '담임목사',
          value: churchInfo?['pastor'] ?? '김목사',
          icon: Icons.person,
        ),
        InfoItem(
          label: '전화번호',
          value: churchInfo?['phone'] ?? '031-123-4567',
          icon: Icons.phone,
        ),
        InfoItem(
          label: '이메일',
          value: churchInfo?['email'] ?? 'church@example.com',
          icon: Icons.email,
        ),
      ],
    );
  }

  Widget _buildMyStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '내 정보'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              '내 출석률',
              '${userStats?['myAttendanceRate'] ?? 0}%',
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              '이번달 출석',
              '${userStats?['monthlyAttendance'] ?? 0}회',
              Icons.calendar_today,
              Colors.blue,
            ),
            _buildStatCard(
              '다가오는 생일',
              '${userStats?['upcomingBirthdays'] ?? 0}명',
              Icons.cake,
              Colors.orange,
            ),
            _buildStatCard(
              '읽지 않은 공지',
              '${userStats?['unreadNotices'] ?? 0}건',
              Icons.notifications,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '빠른 메뉴'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            QuickMenuItem(
              title: '출석체크',
              icon: Icons.check_circle,
              onTap: () {
                Navigator.pushNamed(context, '/attendance');
              },
            ),
            QuickMenuItem(
              title: '일정',
              icon: Icons.calendar_today,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
            ),
            QuickMenuItem(
              title: '기도요청',
              icon: Icons.favorite,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrayerScreen()),
                );
              },
            ),
            QuickMenuItem(
              title: 'QR체크',
              icon: Icons.qr_code,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScanScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoreFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '더 많은 기능'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FeatureCard(
                title: '교회 소식',
                icon: Icons.announcement,
                description: '공지사항과 교회 소식을 확인하세요',
                onTap: () {
                  Navigator.pushNamed(context, '/notices');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FeatureCard(
                title: '교인 명단',
                icon: Icons.people,
                description: '교인들의 연락처를 찾아보세요',
                onTap: () {
                  Navigator.pushNamed(context, '/members');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FeatureCard(
                title: '주보',
                icon: Icons.book,
                description: '이번 주 주보를 확인하세요',
                onTap: () {
                  Navigator.pushNamed(context, '/bulletin');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FeatureCard(
                title: '교역자 명단',
                icon: Icons.people,
                description: '교역자와 임직자 연락처를 확인하세요',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StaffDirectoryScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FeatureCard(
                title: '관리자',
                icon: Icons.admin_panel_settings,
                description: '교회 관리 및 시스템 설정',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FeatureCard(
                title: '설정',
                icon: Icons.settings,
                description: '앱 설정과 개인정보를 관리하세요',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentNotices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(title: '최근 공지사항'),
            CommonButton(
              text: '더보기',
              type: ButtonType.text,
              onPressed: () {
                Navigator.pushNamed(context, '/notices');
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Notice 객체가 필요하므로 임시로 ListTile 사용
              return ListTile(
                leading: const Icon(Icons.announcement, size: 20),
                title: Text('공지사항 제목 ${index + 1}'),
                subtitle: Text('2024.01.${30 - index}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // 공지사항 상세로 이동
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 개발용 로그아웃 다이얼로그
  void _showDevLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개발용 로그아웃'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('로그인 화면 테스트를 위한 개발용 기능입니다.'),
            SizedBox(height: 8),
            Text('선택하신 옵션:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logoutOnly();
            },
            child: const Text('로그아웃만'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logoutAndDisableAutoLogin();
            },
            child: const Text('로그아웃 + 자동로그인 비활성화'),
          ),
        ],
      ),
    );
  }

  // 로그아웃만 수행
  Future<void> _logoutOnly() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다. 다음 앱 시작 시 자동 로그인됩니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 로그아웃 + 자동 로그인 비활성화
  Future<void> _logoutAndDisableAutoLogin() async {
    try {
      await _authService.logout();
      await _authService.setAutoLoginEnabled(false);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었고 자동 로그인이 비활성화되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
