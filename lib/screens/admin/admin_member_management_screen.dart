import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../services/member_service.dart';
import 'admin_member_detail_screen.dart';
import 'admin_member_edit_screen.dart';

/// 관리자용 교인 관리 화면
class AdminMemberManagementScreen extends StatefulWidget {
  const AdminMemberManagementScreen({super.key});

  @override
  State<AdminMemberManagementScreen> createState() =>
      _AdminMemberManagementScreenState();
}

class _AdminMemberManagementScreenState
    extends State<AdminMemberManagementScreen> with TickerProviderStateMixin {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = false;

  // TabBar 카테고리 (주소록과 동일)
  final List<String> _categories = ['전체', '목회진', '장로', '안수집사', '권사', '집사'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_applyFilters);
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    try {
      final response = await _memberService.getMembers(limit: 1000);

      if (response.success && response.data != null) {
        setState(() {
          _members = response.data!;
          _applyFilters();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty
                  ? response.message
                  : '교인 목록을 불러오는데 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('교인 목록 조회 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Member> filtered = _members;

    // TabBar 직분별 필터링 (주소록과 동일)
    final selectedCategory = _categories[_tabController.index];
    if (selectedCategory != '전체') {
      filtered = filtered.where((m) {
        final positionMain = m.positionMain ?? 'MEMBER';
        final positionDetail = m.positionDetail;

        switch (selectedCategory) {
          case '목회진':
            return positionMain == 'CLERGY';
          case '장로':
            return positionMain == 'ELDER';
          case '안수집사':
            return positionMain == 'DEACON' && positionDetail == 'ORDAINED_DEACON';
          case '권사':
            return positionMain == 'DEACONESS';
          case '집사':
            return positionMain == 'DEACON' && positionDetail != 'ORDAINED_DEACON';
          default:
            return true;
        }
      }).toList();
    }

    // 검색 필터
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.name.toLowerCase().contains(query) ||
            (m.email?.toLowerCase().contains(query) ?? false) ||
            m.phone.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredMembers = filtered;
    });
  }

  void _onSearchChanged(String value) {
    _applyFilters();
  }

  void _navigateToDetail(Member member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMemberDetailScreen(member: member),
      ),
    ).then((_) => _loadMembers()); // 돌아올 때 목록 새로고침
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교인 관리'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 결과 표시
          if (_searchController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '검색: "${_searchController.text}"',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchController.text = '';
                      });
                      _applyFilters();
                    },
                    child: const Text('초기화'),
                  ),
                ],
              ),
            ),
          // 교인 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          return _buildMemberCard(member);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "admin_member_fab",
        onPressed: _showContactAllDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.email, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '교인이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '등록된 교인이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(member),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
            // 프로필 사진
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: member.fullProfilePhotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        member.fullProfilePhotoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, size: 30, color: Colors.grey[600]),
                      ),
                    )
                  : Icon(Icons.person, size: 30, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),

            // 정보 섹션
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPositionColor(member.positionLabel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getPositionColor(member.positionLabel).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          member.positionLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPositionColor(member.positionLabel),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (member.department != null && member.department!.isNotEmpty)
                    Text(
                      member.department!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        member.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  if (member.email != null && member.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              member.email!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 액션 버튼들
            Column(
              children: [
                IconButton(
                  onPressed: () => _makeCall(member.phone),
                  icon: Icon(Icons.phone, color: Colors.green[600]),
                  tooltip: '전화걸기',
                ),
                IconButton(
                  onPressed: () => _sendMessage(member.phone),
                  icon: Icon(Icons.chat, color: Colors.blue[600]),
                  tooltip: '문자보내기',
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    if (position.contains('목사') || position.contains('교역')) {
      return Colors.purple;
    } else if (position.contains('전도사')) {
      return Colors.indigo;
    } else if (position.contains('장로')) {
      return Colors.blue;
    } else if (position.contains('안수집사')) {
      return Colors.teal;
    } else if (position.contains('권사')) {
      return Colors.pink;
    } else if (position.contains('집사')) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchText = _searchController.text;
        return AlertDialog(
          title: const Text('교인 검색'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: '이름, 전화번호, 이메일 검색',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchText = value;
            },
            controller: TextEditingController(text: _searchController.text),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.text = searchText;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('검색'),
            ),
          ],
        );
      },
    );
  }

  void _makeCall(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전화 걸기'),
        content: Text('$phoneNumber 로 전화를 걸겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('전화 걸기 기능은 추후 구현 예정입니다')),
              );
            },
            child: const Text('전화'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문자 보내기'),
        content: Text('$phoneNumber 로 문자를 보내겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('문자 보내기 기능은 추후 구현 예정입니다')),
              );
            },
            child: const Text('문자'),
          ),
        ],
      ),
    );
  }

  void _showContactAllDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '단체 연락',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.blue),
              title: const Text('단체 문자 보내기'),
              subtitle: const Text('선택된 그룹에 단체 문자를 보냅니다'),
              onTap: () {
                Navigator.pop(context);
                _sendGroupMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: const Text('단체 이메일 보내기'),
              subtitle: const Text('선택된 그룹에 단체 이메일을 보냅니다'),
              onTap: () {
                Navigator.pop(context);
                _sendGroupEmail();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendGroupMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('단체 문자 기능은 추후 구현 예정입니다')),
    );
  }

  void _sendGroupEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('단체 이메일 기능은 추후 구현 예정입니다')),
    );
  }
}