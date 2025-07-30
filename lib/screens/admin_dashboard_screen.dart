import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showAdminMenu,
            icon: const Icon(Icons.admin_panel_settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 통계 요약 카드
            _buildStatsSection(),
            const SizedBox(height: 24),
            
            // 빠른 작업
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            
            // 최근 활동
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
            
            // 관리 메뉴
            _buildManagementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '교회 현황',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('총 교인수', '342명', Icons.people, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('이번주 출석', '287명', Icons.check_circle, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('새가족', '12명', Icons.person_add, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('신규공지', '3개', Icons.announcement, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 작업',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickActionCard('교인 등록', Icons.person_add, () => _addMember()),
            _buildQuickActionCard('공지 작성', Icons.edit, () => _createNotice()),
            _buildQuickActionCard('출석 관리', Icons.fact_check, () => _manageAttendance()),
            _buildQuickActionCard('주보 업로드', Icons.upload, () => _uploadBulletin()),
            _buildQuickActionCard('단체 문자', Icons.message, () => _sendGroupMessage()),
            _buildQuickActionCard('통계 보기', Icons.analytics, () => _viewStatistics()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue[600]),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '최근 활동',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _viewAllActivities(),
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                '김성도님이 출석체크를 완료했습니다',
                '5분 전',
                Icons.check_circle,
                Colors.green,
              ),
              _buildActivityItem(
                '새로운 공지사항이 등록되었습니다',
                '30분 전',
                Icons.announcement,
                Colors.blue,
              ),
              _buildActivityItem(
                '이신규님이 새가족으로 등록되었습니다',
                '2시간 전',
                Icons.person_add,
                Colors.orange,
              ),
              _buildActivityItem(
                '주보가 업데이트되었습니다',
                '4시간 전',
                Icons.book,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String message, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '관리 메뉴',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildManagementItem(
                '교인 관리',
                '교인 정보 등록, 수정, 삭제',
                Icons.people_outline,
                () => _manageMembersScreen(),
              ),
              _buildDivider(),
              _buildManagementItem(
                '권한 관리',
                '사용자 권한 설정 및 관리',
                Icons.admin_panel_settings,
                () => _managePermissions(),
              ),
              _buildDivider(),
              _buildManagementItem(
                '데이터 관리',
                '엑셀 업로드/다운로드, 백업',
                Icons.storage,
                () => _manageData(),
              ),
              _buildDivider(),
              _buildManagementItem(
                '결제 관리',
                '구독 상태 및 결제 내역',
                Icons.payment,
                () => _managePayments(),
              ),
              _buildDivider(),
              _buildManagementItem(
                '시스템 설정',
                '교회 정보 및 앱 설정',
                Icons.settings,
                () => _systemSettings(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue[600]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200]);
  }

  void _showAdminMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '관리자 메뉴',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('데이터 백업'),
              onTap: () {
                Navigator.pop(context);
                _backupData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('데이터 동기화'),
              onTap: () {
                Navigator.pop(context);
                _syncData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('시스템 진단'),
              onTap: () {
                Navigator.pop(context);
                _systemDiagnostics();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('관리자 로그아웃'),
              onTap: () {
                Navigator.pop(context);
                _adminLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 빠른 작업 함수들
  void _addMember() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('교인 등록 화면으로 이동합니다')),
    );
  }

  void _createNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공지사항 작성 화면으로 이동합니다')),
    );
  }

  void _manageAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('출석 관리 화면으로 이동합니다')),
    );
  }

  void _uploadBulletin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('주보 업로드 화면으로 이동합니다')),
    );
  }

  void _sendGroupMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('단체 문자 발송 화면으로 이동합니다')),
    );
  }

  void _viewStatistics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('통계 화면으로 이동합니다')),
    );
  }

  void _viewAllActivities() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 활동 로그 화면으로 이동합니다')),
    );
  }

  // 관리 메뉴 함수들
  void _manageMembersScreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('교인 관리 화면으로 이동합니다')),
    );
  }

  void _managePermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('권한 관리 화면으로 이동합니다')),
    );
  }

  void _manageData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 관리'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.upload),
              title: Text('엑셀 업로드'),
              subtitle: Text('교인 정보 일괄 등록'),
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('엑셀 다운로드'),
              subtitle: Text('교인 정보 내보내기'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _managePayments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결제 관리 화면으로 이동합니다')),
    );
  }

  void _systemSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('시스템 설정 화면으로 이동합니다')),
    );
  }

  // 관리자 메뉴 함수들
  void _backupData() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('데이터 백업 중...'),
          ],
        ),
      ),
    );

    // 백업 시뮬레이션
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터 백업이 완료되었습니다')),
      );
    });
  }

  void _syncData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('데이터 동기화를 시작합니다')),
    );
  }

  void _systemDiagnostics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시스템 진단 결과'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ 데이터베이스 연결: 정상'),
            Text('✅ 서버 상태: 정상'),
            Text('✅ 백업 상태: 정상'),
            Text('⚠️ 저장공간: 75% 사용중'),
            Text('✅ 마지막 업데이트: 2시간 전'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _adminLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('관리자 로그아웃'),
        content: const Text('관리자 모드에서 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('관리자 모드에서 로그아웃되었습니다')),
              );
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
