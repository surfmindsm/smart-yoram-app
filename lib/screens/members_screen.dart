import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/church_member.dart';
import '../widget/widgets.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<ChurchMember> allMembers = [];
  List<ChurchMember> filteredMembers = [];
  String selectedFilter = '전체';
  bool isLoading = true;

  final List<String> filterOptions = ['전체', '교역자', '장로', '권사', '집사', '성도'];

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
          SnackBar(content: Text('교인 정보 로드 실패: $e')),
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
        status: '등록',
        gender: '여',
      ),
    ];
  }

  void _filterMembers() {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      filteredMembers = allMembers.where((member) {
        bool matchesSearch = member.name.toLowerCase().contains(query) ||
                           (member.phone?.contains(query) ?? false);
        
        bool matchesFilter = selectedFilter == '전체' || 
                           member.position == selectedFilter;
        
        return matchesSearch && matchesFilter;
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
                          return MemberCardWidget(
                            member: member,
                            onTap: () => _showMemberDetail(member),
                            actionButtons: [
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () => _makePhoneCall(member.phone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.message, color: Colors.blue),
                                onPressed: () => _sendMessage(member.phone),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }





  void _showMemberDetail(ChurchMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.phone != null) Text('전화번호: ${member.phone}'),
            if (member.email != null) Text('이메일: ${member.email}'),
            if (member.position != null) Text('직분: ${member.position}'),
            if (member.district != null) Text('구역: ${member.district}'),
            if (member.status != null) Text('상태: ${member.status}'),
          ],
        ),
        actions: [
          CommonButton(
            text: '닫기',
            type: ButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          CommonButton(
            text: '수정',
            type: ButtonType.primary,
            onPressed: () {
              Navigator.pop(context);
              _showEditMemberDialog(member);
            },
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    // 교인 추가 다이얼로그
    CommonDialog.showInfoDialog(
      context,
      title: '교인 추가',
      content: '교인 추가 기능은 준비 중입니다.',
    );
  }

  void _showEditMemberDialog(ChurchMember member) {
    // 교인 수정 다이얼로그
    CommonDialog.showInfoDialog(
      context,
      title: '${member.name} 정보 수정',
      content: '교인 정보 수정 기능은 준비 중입니다.',
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
