import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/church_member.dart';
import 'member_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<ChurchMember> allMembers = [];
  List<ChurchMember> filteredMembers = [];
  bool isLoading = true;

  final List<String> tabs = ['전체', '교역자', '임직자', '부서별'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => isLoading = true);
    
    try {
      // 임시 교인 데이터 생성
      allMembers = _generateSampleMembers();
      filteredMembers = List.from(allMembers);
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연락처 정보 로드 실패: $e')),
        );
      }
    }
  }

  List<ChurchMember> _generateSampleMembers() {
    return [
      ChurchMember(
        id: '1',
        name: '김목사',
        phone: '010-1234-5678',
        email: 'pastor@church.com',
        position: '교역자',
        district: '1구역',
        department: '목회',
        status: '출석',
        gender: '남',
      ),
      ChurchMember(
        id: '2',
        name: '이장로',
        phone: '010-2345-6789',
        email: 'elder@church.com',
        position: '장로',
        district: '2구역',
        department: '당회',
        status: '출석',
        gender: '남',
      ),
      ChurchMember(
        id: '3',
        name: '박권사',
        phone: '010-3456-7890',
        email: 'deaconess@church.com',
        position: '권사',
        district: '1구역',
        department: '여전도회',
        status: '출석',
        gender: '여',
      ),
      ChurchMember(
        id: '4',
        name: '최집사',
        phone: '010-4567-8901',
        email: 'deacon@church.com',
        position: '집사',
        district: '3구역',
        department: '남전도회',
        status: '출석',
        gender: '남',
      ),
      ChurchMember(
        id: '5',
        name: '정성도',
        phone: '010-5678-9012',
        email: 'member@church.com',
        position: '성도',
        district: '2구역',
        department: '청년부',
        status: '등록',
        gender: '여',
      ),
    ];
  }

  void _filterMembers() {
    String query = _searchController.text.toLowerCase();
    int currentTab = _tabController.index;
    
    setState(() {
      List<ChurchMember> baseList = allMembers;
      
      // 탭에 따른 필터링
      switch (currentTab) {
        case 1: // 교역자
          baseList = allMembers.where((m) => m.position == '교역자').toList();
          break;
        case 2: // 임직자
          baseList = allMembers.where((m) => 
            ['교역자', '장로', '권사', '집사'].contains(m.position)
          ).toList();
          break;
        case 3: // 부서별 (임시로 전체 표시)
          break;
      }
      
      // 검색 필터링
      if (query.isNotEmpty) {
        filteredMembers = baseList.where((member) {
          return member.name.toLowerCase().contains(query) ||
                 (member.phone?.contains(query) ?? false) ||
                 (member.position?.toLowerCase().contains(query) ?? false);
        }).toList();
      } else {
        filteredMembers = List.from(baseList);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연락처'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (_) => _filterMembers(),
          tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Column(
        children: [
          // 검색창
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름, 전화번호, 직분으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          
          // 연락처 목록
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) => _buildContactList()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBulkMessageDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: '단체 문자',
      ),
    );
  }

  Widget _buildContactList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (filteredMembers.isEmpty) {
      return const Center(
        child: Text(
          '연락처가 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildContactCard(member);
      },
    );
  }

  Widget _buildContactCard(ChurchMember member) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPositionColor(member.position ?? ''),
          child: Text(
            member.name.isNotEmpty ? member.name[0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (member.position != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPositionColor(member.position!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  member.position!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.phone != null)
              Text('📞 ${member.phone}'),
            Row(
              children: [
                if (member.district != null)
                  Text('📍 ${member.district}'),
                const SizedBox(width: 16),
                if (member.department != null)
                  Text('🏢 ${member.department}'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: () => _makePhoneCall(member),
              tooltip: '전화 걸기',
            ),
            IconButton(
              icon: const Icon(Icons.message, color: Colors.blue),
              onPressed: () => _sendMessage(member),
              tooltip: '문자 보내기',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'email':
                    _sendEmail(member);
                    break;
                  case 'kakao':
                    _sendKakaoMessage(member);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'email',
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 16),
                      SizedBox(width: 8),
                      Text('이메일'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'kakao',
                  child: Row(
                    children: [
                      Icon(Icons.chat, size: 16),
                      SizedBox(width: 8),
                      Text('카카오톡'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showContactDetail(member),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case '교역자':
        return Colors.purple;
      case '장로':
        return Colors.red;
      case '권사':
        return Colors.orange;
      case '집사':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _makePhoneCall(ChurchMember member) {
    if (member.phone != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name}님(${member.phone})에게 전화를 걸어요')),
      );
    }
  }

  void _sendMessage(ChurchMember member) {
    if (member.phone != null) {
      _showMessageDialog(member);
    }
  }

  void _sendEmail(ChurchMember member) {
    if (member.email != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name}님(${member.email})에게 이메일을 보내요')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 주소가 없습니다')),
      );
    }
  }

  void _sendKakaoMessage(ChurchMember member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name}님에게 카카오톡을 보내요')),
    );
  }

  void _showContactDetail(ChurchMember member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberDetailScreen(member: member),
      ),
    );
  }



  void _showMessageDialog(ChurchMember member) {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.name}님에게 문자 보내기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('받는 사람: ${member.phone}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.name}님에게 문자를 보냈습니다')),
              );
            },
            child: const Text('보내기'),
          ),
        ],
      ),
    );
  }

  void _showBulkMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단체 문자'),
        content: const Text('단체 문자 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
