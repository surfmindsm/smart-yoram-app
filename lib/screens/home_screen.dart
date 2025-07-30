import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(churchInfo?['name'] ?? '스마트 교회요람'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 알림 화면으로 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 설정 화면으로 이동
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
              
              // 최근 공지사항
              _buildRecentNotices(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChurchInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.church, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  churchInfo?['name'] ?? '교회명',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('담임목사: ${churchInfo?['pastor'] ?? ''}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(churchInfo?['phone'] ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내 정보',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
        const Text(
          '빠른 메뉴',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickMenu('출석 체크', Icons.qr_code_scanner, () {
              Navigator.pushNamed(context, '/attendance');
            }),
            _buildQuickMenu('내 정보', Icons.person, () {
              Navigator.pushNamed(context, '/members');
            }),
            _buildQuickMenu('주보', Icons.book, () {
              Navigator.pushNamed(context, '/bulletin');
            }),
            _buildQuickMenu('공지사항', Icons.announcement, () {
              Navigator.pushNamed(context, '/notices');
            }),
            _buildQuickMenu('교인증', Icons.card_membership, () {
              Navigator.pushNamed(context, '/member-card');
            }),
            _buildQuickMenu('연락처', Icons.contact_phone, () {
              Navigator.pushNamed(context, '/contacts');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickMenu(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue[700]),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '최근 공지사항',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notices');
              },
              child: const Text('더보기'),
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
}
