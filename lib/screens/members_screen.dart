import 'package:flutter/material.dart';
import '../services/member_service.dart';
import '../models/member.dart';
import '../widget/widgets.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Member> allMembers = [];
  List<Member> filteredMembers = [];
  String selectedFilter = '전체';
  String selectedStatus = '전체';
  bool isLoading = true;

  final List<String> filterOptions = ['전체', '교역자', '장로', '권사', '집사', '성도'];
  final List<String> statusOptions = ['전체', 'active', 'inactive', 'transferred'];

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({String? search}) async {
    setState(() => isLoading = true);
    
    try {
      // 백엔드 API에서 교인 목록 가져오기
      final response = await _memberService.getMembers(
        search: search?.isNotEmpty == true ? search : null,
        memberStatus: selectedStatus != '전체' ? selectedStatus : null,
        limit: 100,
      );
      
      if (response.success && response.data != null) {
        allMembers = response.data!;
        _filterMembers();
      } else {
        throw Exception(response.message);
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('교인 정보 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _filterMembers() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      filteredMembers = allMembers.where((member) {
        bool matchesSearch = query.isEmpty ||
                           member.name.toLowerCase().contains(query) ||
                           member.phone.contains(query);
        
        bool matchesPosition = selectedFilter == '전체' || 
                             (member.position != null && member.position!.contains(selectedFilter));
        
        return matchesSearch && matchesPosition;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '교인 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddMemberDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 및 필터
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // 검색창
                SearchBarWidget(
                  controller: _searchController,
                  hintText: '이름 또는 전화번호로 검색',
                  onChanged: (value) => _filterMembers(),
                ),
                const SizedBox(height: 12),
                
                // 필터 옵션
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((filter) {
                      bool isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedFilter = filter;
                            });
                            _filterMembers();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // 멤버 목록
          Expanded(
            child: isLoading
                ? const LoadingWidget()
                : filteredMembers.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: '교인 정보가 없습니다',
                        subtitle: '지정된 조건에 맞는 교인이 없습니다',
                      )
                    : ListView.builder(
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0] : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(member.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.phone),
                                  if (member.position != null)
                                    Text(member.position!, style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.green),
                                    onPressed: () => _makePhoneCall(member.phone),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.message, color: Colors.blue),
                                    onPressed: () => _sendMessage(member.phone),
                                  ),
                                ],
                              ),
                              onTap: () => _showMemberDetail(member),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }





  void _showMemberDetail(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('전화번호: ${member.phone}'),
              Text('성별: ${member.gender}'),
              if (member.position != null) Text('직분: ${member.position}'),
              if (member.district != null) Text('구역: ${member.district}'),
              Text('상태: ${member.memberStatus}'),
              if (member.address != null) Text('주소: ${member.address}'),
              if (member.birthdate != null) Text('생년월일: ${member.birthdate!.toLocal().toString().split(' ')[0]}'),
              if (member.age != null) Text('나이: ${member.age}세'),
              if (member.registrationDate != null) Text('등록일: ${member.registrationDate!.toLocal().toString().split(' ')[0]}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditMemberDialog(member);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    // 교인 추가 다이얼로그
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('교인 추가'),
        content: const Text('교인 추가 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(Member member) {
    // 교인 수정 다이얼로그
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.name} 정보 수정'),
        content: const Text('교인 정보 수정 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String? phone) {
    if (phone != null) {
      // 전화 걸기 기능 구현
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$phone 로 전화를 걸어요')),
      );
    }
  }

  void _sendMessage(String? phone) {
    if (phone != null) {
      // 문자 보내기 기능 구현
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$phone 로 문자를 보내요')),
      );
    }
  }
}
