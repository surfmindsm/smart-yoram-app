import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/member_service.dart';
import '../services/statistics_service.dart';
import '../models/user.dart' as app_user;
import '../models/member.dart';
import '../models/statistics_model.dart';
import '../models/api_response.dart';
import '../widget/widgets.dart';

/// 실제 백엔드 API 데이터를 조회하는 화면
/// users 테이블과 members 테이블의 실제 데이터를 보여줍니다.
class UsersDataScreen extends StatefulWidget {
  const UsersDataScreen({super.key});

  @override
  State<UsersDataScreen> createState() => _UsersDataScreenState();
}

class _UsersDataScreenState extends State<UsersDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final MemberService _memberService = MemberService();
  final StatisticsService _statisticsService = StatisticsService();

  bool _isLoading = false;
  List<app_user.User> _users = [];
  List<Member> _members = [];
  MemberDemographics? _memberStats;
  DashboardStats? _dashboardStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 병렬로 데이터 로드
      final results = await Future.wait([
        _userService.getUsers(limit: 50),
        _memberService.getMembers(limit: 100),
        _statisticsService.getMemberDemographics(),
        _statisticsService.getDashboardStats(),
      ]);

      final usersResponse = results[0] as ApiResponse<List<app_user.User>>;
      final membersResponse = results[1] as ApiResponse<List<Member>>;
      final statsResponse = results[2] as ApiResponse<MemberDemographics>;
      final dashboardResponse = results[3] as ApiResponse<DashboardStats>;

      setState(() {
        _users = usersResponse.success ? (usersResponse.data ?? []) : [];
        _members = membersResponse.success ? (membersResponse.data ?? []) : [];
        _memberStats = statsResponse.success ? statsResponse.data : null;
        _dashboardStats = dashboardResponse.success ? dashboardResponse.data : null;
      });

      if (usersResponse.success && membersResponse.success) {
        _showSuccessMessage();
      } else {
        String errorMsg = '';
        if (!usersResponse.success) errorMsg += '사용자: ${usersResponse.message}\n';
        if (!membersResponse.success) errorMsg += '교인: ${membersResponse.message}\n';
        if (!statsResponse.success) errorMsg += '통계: ${statsResponse.message}\n';
        _showErrorMessage('일부 데이터 로드 실패:\n$errorMsg');
      }
    } catch (e) {
      _showErrorMessage('데이터 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('데이터 로드 완료: 사용자 ${_users.length}명, 교인 ${_members.length}명'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '실제 데이터 조회',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 통계 카드들
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.people,
                    value: '${_users.length}',
                    title: '사용자',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.person,
                    value: '${_members.length}',
                    title: '교인',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle,
                    value: '${_dashboardStats?.activeMembers ?? 0}',
                    title: '활성 교인',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // 탭바
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.people),
                text: '사용자',
              ),
              Tab(
                icon: Icon(Icons.person),
                text: '교인',
              ),
              Tab(
                icon: Icon(Icons.analytics),
                text: '통계',
              ),
            ],
          ),

          // 탭바 뷰
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: '데이터를 불러오는 중...')
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUsersTab(),
                      _buildMembersTab(),
                      _buildStatisticsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: '사용자가 없습니다',
        description: '등록된 사용자가 없거나 데이터 로드에 실패했습니다.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                user.fullName?.substring(0, 1) ?? '?',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user.fullName ?? '이름 없음',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.email != null)
                  Text('이메일: ${user.email}'),
                if (user.username != null)
                  Text('사용자명: ${user.username}'),
                Text('권한: ${_getRoleDisplayName(user.role)}'),
                if (user.createdAt != null)
                  Text('가입일: ${_formatDate(user.createdAt!)}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive == true ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive == true ? '활성' : '비활성',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showUserDetail(user),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.person_outline,
        title: '교인이 없습니다',
        description: '등록된 교인이 없거나 데이터 로드에 실패했습니다.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return MemberCardWidget(
          member: member,
          onTap: () => _showMemberDetail(member),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    final stats = [
      {
        'title': '전체 사용자',
        'value': _users.length,
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': '전체 교인',
        'value': _members.length,
        'icon': Icons.person,
        'color': Colors.green,
      },
      {
        'title': '활성 교인',
        'value': _dashboardStats?.activeMembers ?? 0,
        'icon': Icons.check_circle,
        'color': Colors.orange,
      },
      {
        'title': '비활성 교인',
        'value': (_dashboardStats?.totalMembers ?? 0) - (_dashboardStats?.activeMembers ?? 0),
        'icon': Icons.cancel,
        'color': Colors.grey,
      },
      {
        'title': '남성',
        'value': _memberStats?.genderDistribution.where((g) => g.gender == 'M').fold(0, (sum, g) => sum + g.count) ?? 0,
        'icon': Icons.male,
        'color': Colors.blue[600],
      },
      {
        'title': '여성',
        'value': _memberStats?.genderDistribution.where((g) => g.gender == 'F').fold(0, (sum, g) => sum + g.count) ?? 0,
        'icon': Icons.female,
        'color': Colors.pink[400],
      },
      {
        'title': '이번 주 출석',
        'value': _dashboardStats?.thisWeekAttendance ?? 0,
        'icon': Icons.new_releases,
        'color': Colors.green[600],
      },
      {
        'title': '이번 달 신규 가입',
        'value': _dashboardStats?.newMembersThisMonth ?? 0,
        'icon': Icons.trending_up,
        'color': Colors.purple,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...stats.map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InfoCardWidget(
                  title: stat['title'] as String,
                  value: '${stat['value']}',
                  icon: stat['icon'] as IconData,
                  color: stat['color'] as Color,
                ),
              )),
          const SizedBox(height: 32),
          CommonButton(
            text: '데이터 새로고침',
            onPressed: _loadData,
            icon: Icons.refresh,
            type: CommonButtonType.primary,
          ),
        ],
      ),
    );
  }

  void _showUserDetail(app_user.User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName ?? '사용자 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', '${user.id}'),
            _buildDetailRow('사용자명', user.username ?? '-'),
            _buildDetailRow('이메일', user.email ?? '-'),
            _buildDetailRow('권한', _getRoleDisplayName(user.role)),
            _buildDetailRow('상태', user.isActive == true ? '활성' : '비활성'),
            if (user.createdAt != null)
              _buildDetailRow('가입일', _formatDate(user.createdAt!)),
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

  void _showMemberDetail(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name ?? '교인 정보'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', '${member.id}'),
              _buildDetailRow('이름', member.name ?? '-'),
              _buildDetailRow('전화번호', member.phone ?? '-'),
              _buildDetailRow('이메일', member.email ?? '-'),
              _buildDetailRow('생년월일', member.birthdate ?? '-'),
              _buildDetailRow('성별', member.gender ?? '-'),
              _buildDetailRow('주소', member.address ?? '-'),
              _buildDetailRow('상태', member.memberStatus ?? '-'),
              if (member.invitationSent == true)
                _buildDetailRow('초대 발송', '발송됨'),
              if (member.createdAt != null)
                _buildDetailRow('등록일', _formatDate(member.createdAt!)),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'pastor':
        return '목회자';
      case 'member':
        return '교인';
      default:
        return '미정';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
