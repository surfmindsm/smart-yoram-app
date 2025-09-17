import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  
  final List<String> _categories = ['전체', '목회진', '장로', '안수집사', '권사', '집사'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교역자/임직자 명단'),
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
            icon: const Icon(LucideIcons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 결과 표시
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '검색: "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Text('초기화'),
                  ),
                ],
              ),
            ),
          
          // 탭뷰 컨텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildStaffList(category);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "staff_fab",
        onPressed: _showContactAllDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(LucideIcons.mail, color: Colors.white),
      ),
    );
  }

  Widget _buildStaffList(String category) {
    final filteredStaff = _getFilteredStaff(category);
    
    if (filteredStaff.isEmpty) {
      return _buildEmptyState(category);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStaff.length,
      itemBuilder: (context, index) {
        final staff = filteredStaff[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.users,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '$category 명단이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '등록된 $category이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 사진
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: staff.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        staff.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, size: 30, color: Colors.grey[600]),
                      ),
                    )
                  : Icon(LucideIcons.user, size: 30, color: Colors.grey[600]),
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
                        staff.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPositionColor(staff.position).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getPositionColor(staff.position).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          staff.position,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPositionColor(staff.position),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  if (staff.department.isNotEmpty)
                    Text(
                      staff.department,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(LucideIcons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        staff.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  
                  if (staff.email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mail, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              staff.email,
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
                  onPressed: () => _makeCall(staff.phone),
                  icon: Icon(LucideIcons.phone, color: Colors.green[600]),
                  tooltip: '전화걸기',
                ),
                IconButton(
                  onPressed: () => _sendMessage(staff.phone),
                  icon: Icon(LucideIcons.messageCircle, color: Colors.blue[600]),
                  tooltip: '문자보내기',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case '담임목사':
      case '목사':
        return Colors.purple;
      case '전도사':
        return Colors.indigo;
      case '장로':
        return Colors.blue;
      case '안수집사':
        return Colors.teal;
      case '권사':
        return Colors.pink;
      case '집사':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<StaffMember> _getFilteredStaff(String category) {
    List<StaffMember> allStaff = _getAllStaff();
    
    // 검색어 필터링
    if (_searchQuery.isNotEmpty) {
      allStaff = allStaff.where((staff) =>
        staff.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        staff.position.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        staff.department.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // 카테고리 필터링
    if (category == '전체') return allStaff;
    
    final categoryMap = {
      '목회진': ['담임목사', '목사', '전도사'],
      '장로': ['장로'],
      '안수집사': ['안수집사'],
      '권사': ['권사'],
      '집사': ['집사'],
    };
    
    final positions = categoryMap[category] ?? [];
    return allStaff.where((staff) => positions.contains(staff.position)).toList();
  }

  List<StaffMember> _getAllStaff() {
    // 샘플 데이터 - 실제 구현시 백엔드에서 가져와야 함
    return [
      StaffMember(
        id: '1',
        name: '김담임',
        position: '담임목사',
        department: '목회진',
        phone: '010-1234-5678',
        email: 'pastor@church.com',
        appointmentDate: DateTime(2020, 3, 1),
      ),
      StaffMember(
        id: '2',
        name: '이전도',
        position: '전도사',
        department: '교육부',
        phone: '010-2345-6789',
        email: 'evangelist@church.com',
        appointmentDate: DateTime(2022, 1, 15),
      ),
      StaffMember(
        id: '3',
        name: '박장로',
        position: '장로',
        department: '당회',
        phone: '010-3456-7890',
        email: 'elder.park@church.com',
        appointmentDate: DateTime(2018, 6, 10),
      ),
      StaffMember(
        id: '4',
        name: '최안수',
        position: '안수집사',
        department: '관리위원회',
        phone: '010-4567-8901',
        email: 'deacon.choi@church.com',
        appointmentDate: DateTime(2019, 11, 20),
      ),
      StaffMember(
        id: '5',
        name: '김권사',
        position: '권사',
        department: '여전도회',
        phone: '010-5678-9012',
        email: 'kwonsa@church.com',
        appointmentDate: DateTime(2021, 4, 5),
      ),
      StaffMember(
        id: '6',
        name: '정집사',
        position: '집사',
        department: '청년부',
        phone: '010-6789-0123',
        email: 'deacon.jung@church.com',
        appointmentDate: DateTime(2023, 2, 28),
      ),
    ];
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchText = _searchQuery;
        return AlertDialog(
          title: const Text('명단 검색'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: '이름, 직분, 부서 검색',
              prefixIcon: Icon(LucideIcons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchText = value;
            },
            controller: TextEditingController(text: _searchQuery),
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
                  _searchQuery = searchText;
                });
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
    // TODO: 전화 걸기 기능 구현
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
              // TODO: url_launcher 패키지로 전화 앱 실행
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
    // TODO: 문자 보내기 기능 구현
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
              // TODO: url_launcher 패키지로 문자 앱 실행
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
              leading: const Icon(LucideIcons.messageCircle, color: Colors.blue),
              title: const Text('단체 문자 보내기'),
              subtitle: const Text('선택된 그룹에 단체 문자를 보냅니다'),
              onTap: () {
                Navigator.pop(context);
                _sendGroupMessage();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.mail, color: Colors.green),
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
    // TODO: 단체 문자 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('단체 문자 기능은 추후 구현 예정입니다')),
    );
  }

  void _sendGroupEmail() {
    // TODO: 단체 이메일 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('단체 이메일 기능은 추후 구현 예정입니다')),
    );
  }
}

class StaffMember {
  final String id;
  final String name;
  final String position;
  final String department;
  final String phone;
  final String email;
  final DateTime appointmentDate;
  final DateTime? retirementDate;
  final String? photoUrl;
  final String? memo;

  StaffMember({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    required this.phone,
    required this.email,
    required this.appointmentDate,
    this.retirementDate,
    this.photoUrl,
    this.memo,
  });
}
