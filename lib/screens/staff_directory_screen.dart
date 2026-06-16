import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart' hide IconButton;
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '교역자/임직자 명단',
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: NewAppColor.textStrong,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, size: 26.sp, color: NewAppColor.textStrong),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: NewAppColor.borderHair),
        ),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
            child: Container(
              decoration: BoxDecoration(
                color: NewAppColor.borderSoft,
                borderRadius: BorderRadius.circular(11.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 18.sp, color: NewAppColor.textTertiary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '이름·직분·부서 검색',
                        hintStyle: FigmaTextStyles().body3.copyWith(
                              color: NewAppColor.textTertiary,
                            ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: FigmaTextStyles().body3.copyWith(
                            color: NewAppColor.textStrong,
                          ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                      child: Icon(
                        LucideIcons.x,
                        size: 18.sp,
                        color: NewAppColor.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 카테고리 탭 (1.2.0 스타일)
          Container(
            height: 42.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => SizedBox(width: 7.w),
              itemBuilder: (context, index) {
                final isSelected = _tabController.index == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tabController.animateTo(index);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? NewAppColor.skyPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: isSelected
                            ? NewAppColor.skyPrimary
                            : NewAppColor.borderHair,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : NewAppColor.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
          // 탭뷰 컨텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
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
        backgroundColor: NewAppColor.skyPrimary,
        elevation: 2,
        child: Icon(LucideIcons.mail, color: Colors.white, size: 22.sp),
      ),
    );
  }

  Widget _buildStaffList(String category) {
    final filteredStaff = _getFilteredStaff(category);

    if (filteredStaff.isEmpty) {
      return _buildEmptyState(category);
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
      itemCount: filteredStaff.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        return _buildStaffCard(filteredStaff[index]);
      },
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: NewAppColor.borderSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.users,
              size: 32.sp,
              color: NewAppColor.textTertiary,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            '$category 명단이 없습니다',
            style: TextStyle(
              color: NewAppColor.textSecondary,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '등록된 $category이 없습니다',
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
    final positionTone = _getPositionTone(staff.position);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair),
      ),
      padding: EdgeInsets.all(14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 사진
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: NewAppColor.borderSoft,
              shape: BoxShape.circle,
            ),
            child: staff.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      staff.photoUrl!,
                      width: 52.w,
                      height: 52.w,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        LucideIcons.user,
                        size: 26.sp,
                        color: NewAppColor.textTertiary,
                      ),
                    ),
                  )
                : Icon(
                    LucideIcons.user,
                    size: 26.sp,
                    color: NewAppColor.textTertiary,
                  ),
          ),
          SizedBox(width: 12.w),
          // 정보 섹션
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        staff.name,
                        style: TextStyle(
                          color: NewAppColor.textStrong,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: positionTone.bg,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        staff.position,
                        style: TextStyle(
                          color: positionTone.fg,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
                if (staff.department.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    staff.department,
                    style: TextStyle(
                      color: NewAppColor.textMuted,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                _buildContactRow(LucideIcons.phone, staff.phone),
                if (staff.email.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  _buildContactRow(LucideIcons.mail, staff.email),
                ],
              ],
            ),
          ),
          // 액션 버튼
          Column(
            children: [
              _buildActionIcon(
                LucideIcons.phone,
                onTap: () => _makeCall(staff.phone),
              ),
              SizedBox(height: 6.h),
              _buildActionIcon(
                LucideIcons.messageCircle,
                onTap: () => _sendMessage(staff.phone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13.sp, color: NewAppColor.textTertiary),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: NewAppColor.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: NewAppColor.skyTint,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 16.sp, color: NewAppColor.skyPrimary),
      ),
    );
  }

  _PositionTone _getPositionTone(String position) {
    switch (position) {
      case '담임목사':
      case '목사':
        return _PositionTone(
          bg: NewAppColor.skyTint,
          fg: NewAppColor.skyDeep,
        );
      case '전도사':
        return _PositionTone(
          bg: NewAppColor.skyTint,
          fg: NewAppColor.skyPrimary,
        );
      case '장로':
        return _PositionTone(
          bg: NewAppColor.warningBg,
          fg: NewAppColor.warning700,
        );
      case '안수집사':
        return _PositionTone(
          bg: NewAppColor.successBg,
          fg: NewAppColor.success700,
        );
      case '권사':
        return _PositionTone(
          bg: NewAppColor.dangerBg,
          fg: NewAppColor.danger700,
        );
      case '집사':
        return _PositionTone(
          bg: NewAppColor.borderSoft,
          fg: NewAppColor.textSecondary,
        );
      default:
        return _PositionTone(
          bg: NewAppColor.borderSoft,
          fg: NewAppColor.textSecondary,
        );
    }
  }

  List<StaffMember> _getFilteredStaff(String category) {
    List<StaffMember> allStaff = _getAllStaff();

    if (_searchQuery.isNotEmpty) {
      allStaff = allStaff.where((staff) =>
        staff.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        staff.position.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        staff.department.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

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

  Future<void> _makeCall(String phoneNumber) async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '전화를 걸까요?',
      description: phoneNumber,
      confirmLabel: '전화',
      icon: LucideIcons.phone,
    );
    if (ok == true && mounted) {
      AppToast.show(context, '전화 걸기 기능은 추후 구현 예정입니다');
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '문자를 보낼까요?',
      description: phoneNumber,
      confirmLabel: '문자',
      icon: LucideIcons.messageCircle,
    );
    if (ok == true && mounted) {
      AppToast.show(context, '문자 보내기 기능은 추후 구현 예정입니다');
    }
  }

  void _showContactAllDialog() {
    AppMenuSheet.show(
      context: context,
      items: [
        AppMenuItem(
          icon: LucideIcons.messageCircle,
          label: '단체 문자 보내기',
          onTap: _sendGroupMessage,
        ),
        AppMenuItem(
          icon: LucideIcons.mail,
          label: '단체 이메일 보내기',
          onTap: _sendGroupEmail,
        ),
      ],
    );
  }

  void _sendGroupMessage() {
    AppToast.show(context, '단체 문자 기능은 추후 구현 예정입니다');
  }

  void _sendGroupEmail() {
    AppToast.show(context, '단체 이메일 기능은 추후 구현 예정입니다');
  }
}

class _PositionTone {
  final Color bg;
  final Color fg;
  const _PositionTone({required this.bg, required this.fg});
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
