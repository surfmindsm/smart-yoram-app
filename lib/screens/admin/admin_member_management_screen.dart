import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/index.dart';
import '../../components/admin/member_card.dart';
import '../../models/member.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
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
    extends State<AdminMemberManagementScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();

  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = false;
  String _selectedStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
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
          AppToast.show(
            context,
            response.message.isNotEmpty
                ? response.message
                : '교인 목록을 불러오는데 실패했습니다',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '교인 목록 조회 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Member> filtered = _members;

    // 상태 필터
    if (_selectedStatus == 'active') {
      filtered = filtered.where((m) => m.memberStatus == 'active').toList();
    } else if (_selectedStatus == 'inactive') {
      filtered = filtered.where((m) => m.memberStatus != 'active').toList();
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

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminMemberEditScreen(),
      ),
    );

    if (result == true) {
      _loadMembers(); // 성공 시 목록 새로고침
    }
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
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교인 관리',
          style: const FigmaTextStyles().title2.copyWith(
            color: NewAppColor.neutral900,
          ),
        ),
        actions: [
          material.IconButton(
            icon: const Icon(Icons.person_add, color: Colors.black),
            onPressed: _navigateToAdd,
          ),
          material.IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Column(
              children: [
                AppInput(
                  controller: _searchController,
                  placeholder: '이름, 전화번호, 이메일로 검색',
                  prefixIcon: Icons.search,
                  onChanged: _onSearchChanged,
                ),
                SizedBox(height: 12.h),
                // 상태 필터 칩
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('전체', 'all'),
                      SizedBox(width: 8.w),
                      _buildFilterChip('활성', 'active'),
                      SizedBox(width: 8.w),
                      _buildFilterChip('비활성', 'inactive'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 결과 카운트
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            color: NewAppColor.neutral100,
            child: Row(
              children: [
                Text(
                  '총 ${_filteredMembers.length}명',
                  style: const FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral700,
                  ),
                ),
              ],
            ),
          ),
          // 교인 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Text(
                          '교인이 없습니다',
                          style: const FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.neutral600,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            return MemberCard(
                              member: member,
                              onTap: () => _navigateToDetail(member),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;

    return GestureDetector(
      onTap: () => _onStatusFilterChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.primary600 : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : NewAppColor.neutral700,
          ),
        ),
      ),
    );
  }
}