import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/member_service.dart';
import '../models/member.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../widgets/member_detail_modal.dart';
import '../components/index.dart' hide IconButton;
import '../scripts/check_member_data.dart';

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
  bool isLoading = true;

  // 필터 상태
  String? selectedPositionCategory; // 선택된 직분 카테고리
  String? selectedDepartment; // 선택된 부서
  String? selectedDistrict; // 선택된 구역 (조직) - organizationId 값
  String? selectedDistrictName; // 선택된 구역 이름 (표시용)

  // 조직 ID -> 조직명 매핑 캐시
  Map<String, String> organizationNameCache = {};

  // 정렬 상태
  bool sortAscending = true; // true: 오름차순, false: 내림차순

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);

    // 🔍 백엔드 데이터 구조 확인 (디버깅용)
    _checkBackendData();
  }

  Future<void> _checkBackendData() async {
    try {
      await MemberDataChecker.checkMemberData();
    } catch (e) {
      print('⚠️ 데이터 체커 실행 실패: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({String? search}) async {
    print('📁 MEMBERS_SCREEN: _loadMembers 시작');
    setState(() => isLoading = true);

    try {
      // 백엔드 API에서 교인 목록 가져오기
      print('📁 MEMBERS_SCREEN: getMembers API 호출 시작');
      final response = await _memberService.getMembers(
        search: search?.isNotEmpty == true ? search : null,
        limit: 1000,
      );

      print('📁 MEMBERS_SCREEN: API 응답 - success: ${response.success}');
      print('📁 MEMBERS_SCREEN: API 응답 - message: "${response.message}"');

      if (response.success && response.data != null) {
        allMembers = response.data!;
        print('📁 MEMBERS_SCREEN: 받은 교인 수: ${allMembers.length}');

        // 처음 5명 상세 정보 로그
        for (int i = 0; i < allMembers.length && i < 5; i++) {
          final member = allMembers[i];
          print(
              '📁 MEMBERS_SCREEN: [$i] ID: ${member.id}, 이름: ${member.name}, 전화: ${member.phone}');
        }

        _filterMembers();
      } else {
        print('📁 MEMBERS_SCREEN: API 응답 실패 - ${response.message}');
        throw Exception(response.message);
      }

      setState(() => isLoading = false);
      print('📁 MEMBERS_SCREEN: _loadMembers 완료');
    } catch (e) {
      print('📁 MEMBERS_SCREEN: _loadMembers 예외 - $e');
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
      // allMembers가 비어있는 경우 빈 리스트 반환
      if (allMembers.isEmpty) {
        filteredMembers = [];
        return;
      }

      List<Member> baseList = allMembers;

      // 직분별 필터링 (position_main 컬럼 기반)
      if (selectedPositionCategory != null) {
        baseList = baseList.where((m) {
          // position_main이 null이면 'MEMBER'(성도)로 간주
          final positionMain = m.positionMain ?? 'MEMBER';
          return positionMain == selectedPositionCategory;
        }).toList();
      }

      // 부서별 필터링
      if (selectedDepartment != null) {
        baseList =
            baseList.where((m) => m.department == selectedDepartment).toList();
      }

      // 조직별(구역) 필터링 - organizationId 필드 기준
      if (selectedDistrict != null) {
        baseList = baseList
            .where((m) => m.organizationId == selectedDistrict)
            .toList();
      }

      // 검색 필터링
      if (query.isNotEmpty) {
        filteredMembers = baseList.where((member) {
          return member.name.toLowerCase().contains(query) ||
              member.phone.contains(query) ||
              member.positionLabel.toLowerCase().contains(query);
        }).toList();
      } else {
        filteredMembers = List.from(baseList);
      }

      // 정렬 (이름순)
      filteredMembers.sort((a, b) =>
          sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    });
  }

  // 직분 카테고리 목록 (한글) - position_main 컬럼 기반
  Map<String, String> get positionCategories {
    return {
      'CLERGY': '교역자',
      'ELDER': '장로',
      'DEACONESS': '권사',
      'DEACON': '집사',
      'CHURCH_SCHOOL': '교회학교',
      'MEMBER': '성도',
    };
  }

  // 사용 가능한 부서 목록 추출
  List<String> get availableDepartments {
    final departments = allMembers
        .where((m) => m.department != null && m.department!.isNotEmpty)
        .map((m) => m.department!)
        .toSet()
        .toList();
    departments.sort();
    return departments;
  }

  // 사용 가능한 구역 목록 추출 (조직) - organizationId 사용
  List<String> get availableDistricts {
    final Set<String> districtsSet = {};

    // organizationId가 있는 교인들의 조직 ID 수집
    for (var m in allMembers) {
      if (m.organizationId != null && m.organizationId!.isNotEmpty) {
        districtsSet.add(m.organizationId!);
      }
    }

    return districtsSet.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          // 검색창
          Container(
            padding: EdgeInsets.all(16.r),
            color: Colors.transparent,
            child: Container(
              width: 350.w,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: LinearGradient(
                  colors: [
                    NewAppColor.primary600,
                    NewAppColor.primary600.withValues(alpha: 0.7),
                    NewAppColor.primary600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(1.r), // 그라디언트 보더 두께
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11.r),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.search,
                      size: 20.r,
                      color: NewAppColor.neutral500,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '이름 또는 전화번호로 검색',
                          hintStyle: const FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.neutral500,
                              ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 필터 바와 정렬 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(child: _buildFilterBar()),
                SizedBox(width: 8.w),
                _buildSortButton(),
              ],
            ),
          ),

          // 교인 목록
          Expanded(
            child: _buildMemberList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 직분별 필터
            _buildDropdownButton(
              label: selectedPositionCategory != null
                  ? positionCategories[selectedPositionCategory]!
                  : '직분별',
              isSelected: selectedPositionCategory != null,
              onTap: _showPositionFilter,
            ),
            SizedBox(width: 8.w),

            // 부서별 필터
            _buildDropdownButton(
              label: selectedDepartment != null
                  ? MemberDepartmentOptions.getLabel(selectedDepartment) ??
                      selectedDepartment!
                  : '부서별',
              isSelected: selectedDepartment != null,
              onTap: _showDepartmentFilter,
            ),
            SizedBox(width: 8.w),

            // 조직별 필터 (구역)
            _buildDropdownButton(
              label: selectedDistrictName ?? '조직별',
              isSelected: selectedDistrict != null,
              onTap: _showDistrictFilter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: _toggleSort,
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: NewAppColor.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이름순',
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(width: 4.w),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16.sp,
              color: NewAppColor.neutral700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral200,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: FigmaTextStyles().body2.copyWith(
                    color: isSelected ? Colors.white : NewAppColor.neutral700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16.sp,
              color: isSelected ? Colors.white : NewAppColor.neutral700,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSort() {
    setState(() {
      sortAscending = !sortAscending;
    });
    _filterMembers();
  }

  void _showPositionFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '직분별 필터',
                style: FigmaTextStyles().headline6.copyWith(
                      color: NewAppColor.neutral900,
                    ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 전체 옵션
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        decoration: BoxDecoration(
                          color: selectedPositionCategory == null
                              ? NewAppColor.primary100
                              : null,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ListTile(
                          title: const Text('전체'),
                          trailing: selectedPositionCategory == null
                              ? Icon(Icons.check, color: NewAppColor.primary600)
                              : null,
                          onTap: () {
                            setState(() {
                              selectedPositionCategory = null;
                            });
                            _filterMembers();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      ...positionCategories.entries.map((entry) {
                        final isSelected =
                            selectedPositionCategory == entry.key;
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isSelected ? NewAppColor.primary100 : null,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: ListTile(
                            title: Text(entry.value),
                            trailing: isSelected
                                ? Icon(Icons.check,
                                    color: NewAppColor.primary600)
                                : null,
                            onTap: () {
                              setState(() {
                                selectedPositionCategory = entry.key;
                              });
                              _filterMembers();
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showDepartmentFilter() {
    final departments = availableDepartments;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '부서별 필터',
                style: FigmaTextStyles().headline6.copyWith(
                      color: NewAppColor.neutral900,
                    ),
              ),
              SizedBox(height: 16.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 전체 옵션
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        decoration: BoxDecoration(
                          color: selectedDepartment == null
                              ? NewAppColor.primary100
                              : null,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ListTile(
                          title: const Text('전체'),
                          trailing: selectedDepartment == null
                              ? Icon(Icons.check, color: NewAppColor.primary600)
                              : null,
                          onTap: () {
                            setState(() {
                              selectedDepartment = null;
                            });
                            _filterMembers();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      ...departments.map((dept) {
                        final label =
                            MemberDepartmentOptions.getLabel(dept) ?? dept;
                        final isSelected = selectedDepartment == dept;
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isSelected ? NewAppColor.primary100 : null,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: ListTile(
                            title: Text(label),
                            trailing: isSelected
                                ? Icon(Icons.check,
                                    color: NewAppColor.primary600)
                                : null,
                            onTap: () {
                              setState(() {
                                selectedDepartment = dept;
                              });
                              _filterMembers();
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showDistrictFilter() {
    final districtIds = availableDistricts;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return _DistrictFilterSheet(
          districtIds: districtIds,
          selectedDistrictId: selectedDistrict,
          memberService: _memberService,
          onDistrictSelected: (String? districtId, String? districtName) {
            setState(() {
              selectedDistrict = districtId;
              selectedDistrictName = districtName;
            });
            _filterMembers();
          },
        );
      },
    );
  }

  Widget _buildMemberList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: NewAppColor.primary600),
            SizedBox(height: 16.h),
            Text(
              '교인 정보를 불러오는 중...',
              style: const FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral500,
                  ),
            ),
          ],
        ),
      );
    }

    if (filteredMembers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadMembers(),
        color: NewAppColor.primary600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300.h,
            child: Center(
              child: SizedBox(
                width: 272.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(),
                      child: SvgPicture.asset(
                        'assets/icons/members_empty.svg',
                        width: 48.w,
                        height: 48.h,
                        colorFilter: ColorFilter.mode(
                          NewAppColor.neutral800,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '교인 정보가 없습니다',
                            textAlign: TextAlign.center,
                            style: FigmaTextStyles().title3.copyWith(
                                  color: NewAppColor.neutral800,
                                ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '다른 카테고리를 선택하거나 검색어를 변경해보세요',
                            textAlign: TextAlign.center,
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMembers(),
      color: NewAppColor.primary600,
      child: ListView.separated(
        padding: EdgeInsets.all(20.w),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredMembers.length,
        separatorBuilder: (context, index) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          // 안전한 인덱스 체크 추가
          if (index >= filteredMembers.length) {
            return const SizedBox.shrink();
          }
          final member = filteredMembers[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return GestureDetector(
      onTap: () => _showMemberDetail(member),
      child: Container(
        width: double.infinity,
        height: 76.h,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16.w,
              top: 7.h,
              child: SizedBox(
                width: 253.w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.h,
                      decoration: ShapeDecoration(
                        image: member.fullProfilePhotoUrl != null &&
                                member.fullProfilePhotoUrl!.isNotEmpty
                            ? DecorationImage(
                                image:
                                    NetworkImage(member.fullProfilePhotoUrl!),
                                fit: BoxFit.fill,
                              )
                            : null,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: NewAppColor.neutral300,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: member.fullProfilePhotoUrl == null ||
                              member.fullProfilePhotoUrl!.isEmpty
                          ? Center(
                              child: Text(
                                member.name.isNotEmpty ? member.name[0] : '?',
                                style: TextStyle(
                                  color: NewAppColor.neutral900,
                                  fontSize: 16.sp,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 16.w),
                    SizedBox(
                      width: 195.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 195.w,
                                  child: Text(
                                    member.name,
                                    style: TextStyle(
                                      color: NewAppColor.neutral900,
                                      fontSize: 16.sp,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                      height: 1.50,
                                      letterSpacing: -0.40,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 195.w,
                                  child: Text(
                                    member.phone,
                                    style: TextStyle(
                                      color: NewAppColor.neutral600,
                                      fontSize: 13.sp,
                                      fontFamily: 'Pretendard Variable',
                                      fontWeight: FontWeight.w400,
                                      height: 1.38,
                                      letterSpacing: -0.33,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          SizedBox(
                            width: 195.w,
                            child: Text(
                              member.positionLabel,
                              style: TextStyle(
                                color: NewAppColor.neutral600,
                                fontSize: 11.sp,
                                fontFamily: 'Pretendard Variable',
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 269.w,
              top: 24.h,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28.w,
                    height: 28.h,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: NewAppColor.success200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.phone,
                        color: NewAppColor.success600,
                        size: 16.sp,
                      ),
                      onPressed: () => _makePhoneCall(member.phone),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Container(
                    width: 28.w,
                    height: 28.h,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: NewAppColor.primary200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.chat_bubble,
                        color: NewAppColor.primary600,
                        size: 16.sp,
                      ),
                      onPressed: () => _sendMessage(member.phone),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      // 전화번호에서 하이픈, 공백 등 제거
      String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedPhone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('유효하지 않은 전화번호입니다')),
          );
        }
        return;
      }

      // 전화 권한 확인 (선택적)
      try {
        PermissionStatus phonePermission = await Permission.phone.status;
        if (phonePermission.isDenied) {
          await Permission.phone.request();
        }
      } catch (e) {
        // 권한 오류는 무시하고 계속 진행
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedPhone);

      try {
        // 먼저 일반적인 방법 시도
        bool canLaunch = await canLaunchUrl(phoneUri);

        if (canLaunch) {
          await launchUrl(phoneUri);
        } else {
          // canLaunchUrl이 false라도 LaunchMode.externalApplication으로 시도
          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('전화 앱을 열 수 없습니다')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화번호가 없습니다')),
        );
      }
    }
  }

  Future<void> _sendMessage(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      // 전화번호에서 하이픈, 공백 등 제거
      String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedPhone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('유효하지 않은 전화번호입니다')),
          );
        }
        return;
      }

      final Uri smsUri = Uri(scheme: 'sms', path: cleanedPhone);

      try {
        // 먼저 일반적인 방법 시도
        bool canLaunch = await canLaunchUrl(smsUri);

        if (canLaunch) {
          await launchUrl(smsUri);
        } else {
          // canLaunchUrl이 false라도 LaunchMode.externalApplication으로 시도
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('메시지 앱을 열 수 없습니다')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화번호가 없습니다')),
        );
      }
    }
  }

  void _showMemberDetail(Member member) {
    showDialog(
      context: context,
      builder: (context) => MemberDetailModal(member: member),
    );
  }
}

// 조직 필터 바텀시트 (StatefulWidget)
class _DistrictFilterSheet extends StatefulWidget {
  final List<String> districtIds;
  final String? selectedDistrictId;
  final MemberService memberService;
  final Function(String?, String?) onDistrictSelected;

  const _DistrictFilterSheet({
    required this.districtIds,
    required this.selectedDistrictId,
    required this.memberService,
    required this.onDistrictSelected,
  });

  @override
  State<_DistrictFilterSheet> createState() => _DistrictFilterSheetState();
}

class _DistrictFilterSheetState extends State<_DistrictFilterSheet> {
  Map<String, String> organizationNames = {}; // ID -> 이름 매핑
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizationNames();
  }

  Future<void> _loadOrganizationNames() async {
    // 각 조직 ID에 대해 이름 조회
    for (final id in widget.districtIds) {
      final name = await widget.memberService.getOrganizationPath(id);
      if (name != null) {
        organizationNames[id] = name;
      } else {
        organizationNames[id] = id; // 이름 조회 실패시 ID 표시
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 조직 경로를 계층 구조에 맞게 정렬
  /// 예: "1교구>1구역", "1교구>1구역>1셀", "1교구>1구역>2셀"
  List<String> _sortOrganizationPaths(List<String> districtIds) {
    final sorted = List<String>.from(districtIds);

    sorted.sort((a, b) {
      final nameA = organizationNames[a] ?? a;
      final nameB = organizationNames[b] ?? b;

      // '>' 기준으로 분리
      final partsA = nameA.split(' > ');
      final partsB = nameB.split(' > ');

      // 각 레벨별로 비교
      for (int i = 0; i < partsA.length && i < partsB.length; i++) {
        final partA = partsA[i];
        final partB = partsB[i];

        // 숫자 추출 (예: "1교구" -> 1, "2구역" -> 2)
        final numA = int.tryParse(partA.replaceAll(RegExp(r'[^0-9]'), ''));
        final numB = int.tryParse(partB.replaceAll(RegExp(r'[^0-9]'), ''));

        if (numA != null && numB != null) {
          if (numA != numB) {
            return numA.compareTo(numB);
          }
        } else {
          // 숫자가 없으면 문자열 비교
          final comparison = partA.compareTo(partB);
          if (comparison != 0) {
            return comparison;
          }
        }
      }

      // 같은 경로라면 길이가 짧은 것이 먼저 (상위 조직 우선)
      return partsA.length.compareTo(partsB.length);
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '조직별 필터',
            style: FigmaTextStyles().headline6.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 16.h),
          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: CircularProgressIndicator(
                  color: NewAppColor.primary600,
                ),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 전체 옵션
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      decoration: BoxDecoration(
                        color: widget.selectedDistrictId == null
                            ? NewAppColor.primary100
                            : null,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: ListTile(
                        title: const Text('전체'),
                        trailing: widget.selectedDistrictId == null
                            ? Icon(Icons.check, color: NewAppColor.primary600)
                            : null,
                        onTap: () {
                          widget.onDistrictSelected(null, null);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    // 조직 목록 (정렬됨)
                    ..._sortOrganizationPaths(widget.districtIds)
                        .map((districtId) {
                      final isSelected =
                          widget.selectedDistrictId == districtId;
                      final displayName =
                          organizationNames[districtId] ?? districtId;
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isSelected ? NewAppColor.primary100 : null,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ListTile(
                          title: Text(displayName),
                          trailing: isSelected
                              ? Icon(Icons.check, color: NewAppColor.primary600)
                              : null,
                          onTap: () {
                            widget.onDistrictSelected(districtId, displayName);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
