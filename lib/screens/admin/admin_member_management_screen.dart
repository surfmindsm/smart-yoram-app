import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/member.dart';
import '../../services/member_service.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../components/index.dart' hide IconButton;
import '../../utils/korean_search_util.dart';
import 'admin_member_detail_screen.dart';
import 'admin_member_create_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  List<Member> allMembers = [];
  List<Member> filteredMembers = [];
  bool isLoading = true;

  // 필터 상태
  String? selectedPositionCategory; // 선택된 직분 카테고리
  String? selectedDepartment; // 선택된 부서
  String? selectedDistrict; // 선택된 구역 (조직) - organizationId 값
  String? selectedDistrictName; // 선택된 구역 이름 (표시용)

  // 정렬 상태
  bool sortAscending = true; // true: 오름차순, false: 내림차순

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
      final response = await _memberService.getMembers(
        search: search?.isNotEmpty == true ? search : null,
        limit: 1000,
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
      if (allMembers.isEmpty) {
        filteredMembers = [];
        return;
      }

      List<Member> baseList = allMembers;

      // 직분별 필터링 (position_main 컬럼 기반)
      if (selectedPositionCategory != null) {
        baseList = baseList.where((m) {
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

      // 검색 필터링 (초성 검색 지원)
      if (query.isNotEmpty) {
        filteredMembers = baseList.where((member) {
          // 초성 검색을 포함한 통합 검색
          return KoreanSearchUtil.searchMultipleFields([
            member.name,
            member.phone,
            member.positionLabel,
          ], query);
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

    for (var m in allMembers) {
      if (m.organizationId != null && m.organizationId!.isNotEmpty) {
        districtsSet.add(m.organizationId!);
      }
    }

    return districtsSet.toList();
  }

  @override
  // 1.2.0 C 방향: 주소록 화면(members_screen)과 동일한 패턴 + 우측 user-plus 액션
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교인 관리',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.userPlus,
                color: NewAppColor.skyDeep, size: 22.sp),
            onPressed: _navigateToCreate,
          ),
        ],
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: Column(
        children: [
          // 상단 흰 영역 (검색 + 필터)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: 12.h,
              left: 18.w,
              right: 18.w,
              bottom: 14.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: NewAppColor.borderSoft),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 검색바 — borderSoft 채움형 무테
                Container(
                  decoration: BoxDecoration(
                    color: NewAppColor.borderSoft,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 18.sp,
                        color: NewAppColor.textTertiary,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '이름·연락처 검색',
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
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 11.h),
                // 필터 칩 + 정렬 버튼
                Row(
                  children: [
                    Expanded(child: _buildFilterBar()),
                    SizedBox(width: 8.w),
                    _buildSortButton(),
                  ],
                ),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // '전체 N' 칩 — 시안 §267 (총 인원 표시 + 활성 색)
            _buildDropdownButton(
              label: '전체 ${filteredMembers.length}',
              isSelected: true,
              hideChevron: true,
              onTap: () {
                // 모든 필터 해제 + 검색 초기화
                setState(() {
                  selectedPositionCategory = null;
                  selectedDepartment = null;
                  selectedDistrict = null;
                  selectedDistrictName = null;
                  _searchController.clear();
                });
                _filterMembers();
              },
            ),
            SizedBox(width: 7.w),
            // 직분별 필터
            _buildDropdownButton(
              label: selectedPositionCategory != null
                  ? positionCategories[selectedPositionCategory]!
                  : '직분',
              isSelected: selectedPositionCategory != null,
              onTap: _showPositionFilter,
            ),
            SizedBox(width: 7.w),
            // 부서별 필터
            _buildDropdownButton(
              label: selectedDepartment != null
                  ? MemberDepartmentOptions.getLabel(selectedDepartment) ??
                      selectedDepartment!
                  : '부서',
              isSelected: selectedDepartment != null,
              onTap: _showDepartmentFilter,
            ),
            SizedBox(width: 7.w),
            // 구역 필터
            _buildDropdownButton(
              label: selectedDistrictName ?? '구역',
              isSelected: selectedDistrict != null,
              onTap: _showDistrictFilter,
            ),
          ],
        ),
      ),
    );
  }

  // 1.2.0 C 방향: 정렬 버튼 (라운드 10 + skyDeep 아이콘)
  Widget _buildSortButton() {
    return GestureDetector(
      onTap: _toggleSort,
      child: Container(
        width: 34.w,
        height: 34.h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.arrowUpDown,
          size: 16.sp,
          color: NewAppColor.skyDeep,
        ),
      ),
    );
  }

  // 1.2.0 C 방향: 필터 칩 (활성=skyPrimary 채움/흰글자, 비활성=흰배경 + borderStrong + textSecondary)
  Widget _buildDropdownButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool hideChevron = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.skyPrimary : Colors.white,
          border: isSelected
              ? null
              : Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: FigmaTextStyles().caption2.copyWith(
                    color:
                        isSelected ? Colors.white : NewAppColor.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                  ),
            ),
            if (!hideChevron) ...[
              SizedBox(width: 4.w),
              Icon(
                LucideIcons.chevronDown,
                size: 14.sp,
                color: isSelected ? Colors.white : NewAppColor.textSecondary,
              ),
            ],
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
                              ? Icon(LucideIcons.check, color: NewAppColor.primary600)
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
                                ? Icon(LucideIcons.check,
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
                              ? Icon(LucideIcons.check, color: NewAppColor.primary600)
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
                                ? Icon(LucideIcons.check,
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

  // 1.2.0 C 방향: 초성 섹션 + 흰 카드 그룹 (주소록과 통일)
  Widget _buildMemberList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: NewAppColor.skyPrimary),
            SizedBox(height: 16.h),
            Text(
              '교인 정보를 불러오는 중...',
              style: FigmaTextStyles().body3.copyWith(
                    color: NewAppColor.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    if (filteredMembers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadMembers(),
        color: NewAppColor.skyPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300.h,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 56.sp,
                    color: NewAppColor.iconFaint,
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    '교인 정보가 없습니다',
                    style: FigmaTextStyles().subtitle2.copyWith(
                          color: NewAppColor.textSecondary,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '다른 카테고리를 선택하거나 검색어를 변경해보세요',
                    style: FigmaTextStyles().caption1.copyWith(
                          color: NewAppColor.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final grouped = _groupMembersByInitial(filteredMembers);

    return RefreshIndicator(
      onRefresh: () => _loadMembers(),
      color: NewAppColor.skyPrimary,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 18.h),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: grouped.length,
        itemBuilder: (context, sectionIndex) {
          final group = grouped[sectionIndex];
          final initial = group.$1;
          final members = group.$2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 섹션 헤더 (초성)
              Padding(
                padding: EdgeInsets.fromLTRB(6.w, 10.h, 6.w, 6.h),
                child: Text(
                  initial,
                  style: FigmaTextStyles().sectionHeader.copyWith(
                        color: NewAppColor.skyDeep,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                ),
              ),
              // 카드 그룹
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: NewAppColor.borderHair, width: 1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(members.length, (i) {
                    final isLast = i == members.length - 1;
                    return _buildMemberRow(members[i], isLast: isLast);
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 초성별로 그룹화 (members_screen과 동일)
  List<(String, List<Member>)> _groupMembersByInitial(List<Member> members) {
    final order = <String>[];
    final map = <String, List<Member>>{};
    for (final m in members) {
      final initial = _initialOf(m.name);
      if (!map.containsKey(initial)) {
        order.add(initial);
        map[initial] = [];
      }
      map[initial]!.add(m);
    }
    return order.map((k) => (k, map[k]!)).toList();
  }

  String _initialOf(String name) {
    if (name.isEmpty) return '#';
    final first = name[0];
    final chosung = KoreanSearchUtil.getChosung(first);
    if (chosung != null) return chosung;
    final code = first.codeUnitAt(0);
    final isAlpha = (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
    return isAlpha ? first.toUpperCase() : '#';
  }

  // 1.2.0 C 방향: 교인 행 (라운드 13 skyTint 아바타 + 이름 + 직분 배지 + 부서·구역 + chevron)
  // 시안 §273-276 — 우측 상태 배지(활동/새가족/장결) 제거 후 chevron만 표시
  Widget _buildMemberRow(Member member, {required bool isLast}) {
    final isPlain = member.positionLabel == '성도' || member.positionLabel == '교인';
    return InkWell(
      onTap: () => _navigateToDetail(member),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1, color: NewAppColor.borderHair),
                ),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아바타 — 라운드 13 skyTint
            Container(
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(13.r),
                image: (member.fullProfilePhotoUrl != null &&
                        member.fullProfilePhotoUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(member.fullProfilePhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: (member.fullProfilePhotoUrl == null ||
                      member.fullProfilePhotoUrl!.isEmpty)
                  ? Text(
                      member.name.isNotEmpty ? member.name[0] : '?',
                      style: TextStyle(
                        color: NewAppColor.skyDeep,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 13.w),
            // 이름 + 직분 배지 + 부서·구역
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          style: FigmaTextStyles().cardTitleSm.copyWith(
                                color: NewAppColor.textStrong,
                                fontSize: 15.5.sp,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.positionLabel.isNotEmpty) ...[
                        SizedBox(width: 7.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: isPlain
                                ? NewAppColor.borderSoft
                                : NewAppColor.skyTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            member.positionLabel,
                            style: TextStyle(
                              color: isPlain
                                  ? NewAppColor.textSecondary
                                  : NewAppColor.skyDeep,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _buildSubLine(member),
                    style: FigmaTextStyles().caption2.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              LucideIcons.chevronRight,
              size: 18.sp,
              color: NewAppColor.iconFaint,
            ),
          ],
        ),
      ),
    );
  }

  // 부서 · 구역 (시안 §273)
  String _buildSubLine(Member member) {
    final parts = <String>[];
    final dept = member.department;
    if (dept != null && dept.isNotEmpty) {
      parts.add(MemberDepartmentOptions.getLabel(dept) ?? dept);
    }
    final district = member.district;
    if (district != null && district.isNotEmpty) {
      parts.add(district);
    }
    return parts.isEmpty ? member.phone : parts.join(' · ');
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedPhone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('유효하지 않은 전화번호입니다')),
          );
        }
        return;
      }

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
        bool canLaunch = await canLaunchUrl(phoneUri);

        if (canLaunch) {
          await launchUrl(phoneUri);
        } else {
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
        bool canLaunch = await canLaunchUrl(smsUri);

        if (canLaunch) {
          await launchUrl(smsUri);
        } else {
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

  void _navigateToDetail(Member member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMemberDetailScreen(member: member),
      ),
    ).then((_) => _loadMembers());
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminMemberCreateScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadMembers(); // 교인 추가 성공 시 목록 새로고침
      }
    });
  }
}

// 조직 필터 바텀시트
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
  Map<String, String> organizationNames = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizationNames();
  }

  Future<void> _loadOrganizationNames() async {
    for (final id in widget.districtIds) {
      final name = await widget.memberService.getOrganizationPath(id);
      if (name != null) {
        organizationNames[id] = name;
      } else {
        organizationNames[id] = id;
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
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
                            ? Icon(LucideIcons.check, color: NewAppColor.primary600)
                            : null,
                        onTap: () {
                          widget.onDistrictSelected(null, null);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    ...widget.districtIds.map((districtId) {
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
                              ? Icon(LucideIcons.check, color: NewAppColor.primary600)
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
