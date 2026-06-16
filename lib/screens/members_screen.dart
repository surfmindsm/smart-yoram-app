import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import '../utils/korean_search_util.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      body: Column(
        children: [
          // 1.2.0 C 방향: 상단 타이틀 + 검색 + 필터 영역 (흰 배경 카드처럼)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6.h,
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
                // 타이틀 + 전체 인원수
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '주소록',
                        style: FigmaTextStyles().pageTitle.copyWith(
                              color: NewAppColor.textStrong,
                              fontSize: 21.sp,
                            ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '전체 ${filteredMembers.length}명',
                        style: FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                // 검색바 — #F1F5F9 채움형 무테
                Container(
                  decoration: BoxDecoration(
                    color: NewAppColor.borderSoft, // #F1F5F9
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
                            hintText: '이름, 전화번호 검색 (초성 가능)',
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
    ));
  }

  // 1.2.0 C 방향: 가로 스크롤 필터 칩 row
  Widget _buildFilterBar() {
    return SingleChildScrollView(
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
          SizedBox(width: 7.w),
          // 부서별 필터
          _buildDropdownButton(
            label: selectedDepartment != null
                ? MemberDepartmentOptions.getLabel(selectedDepartment) ??
                    selectedDepartment!
                : '부서별',
            isSelected: selectedDepartment != null,
            onTap: _showDepartmentFilter,
          ),
          SizedBox(width: 7.w),
          // 조직별 필터 (구역)
          _buildDropdownButton(
            label: selectedDistrictName ?? '조직별',
            isSelected: selectedDistrict != null,
            onTap: _showDistrictFilter,
          ),
        ],
      ),
    );
  }

  // 1.2.0 C 방향: 정렬 버튼 (라운드 10px + skyDeep 아이콘)
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
          // 목업: 양방향 정렬 아이콘. 오름/내림차순 상태 그대로 보존
          sortAscending ? LucideIcons.arrowUpDown : LucideIcons.arrowUpDown,
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
                    color: isSelected ? Colors.white : NewAppColor.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                  ),
            ),
            SizedBox(width: 4.w),
            Icon(
              LucideIcons.chevronDown,
              size: 14.sp,
              color: isSelected ? Colors.white : NewAppColor.textSecondary,
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

  // 1.2.0 C 방향: 공용 필터 바텀시트 컨테이너 (핸들바 + 제목 + 항목 리스트)
  Widget _filterSheetContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        // iPhone safe area + 14px 여유
        bottom: MediaQuery.of(context).padding.bottom + 14.h,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들바
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: NewAppColor.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 12.h),
              child: Text(
                title,
                style: FigmaTextStyles().cardTitle.copyWith(
                      color: NewAppColor.textStrong,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1.2.0 C 방향: 필터 시트 행 (선택=skyTint+skyDeep+체크, 비선택=일반)
  Widget _filterSheetRow({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isSelected ? NewAppColor.skyTint : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: FigmaTextStyles().body2.copyWith(
                          color: isSelected
                              ? NewAppColor.skyDeep
                              : NewAppColor.neutral700,
                          fontSize: 15.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    LucideIcons.check,
                    color: NewAppColor.skyDeep,
                    size: 19.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPositionFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return _filterSheetContainer(
          title: '직분별 필터',
          children: [
            _filterSheetRow(
              label: '전체',
              isSelected: selectedPositionCategory == null,
              onTap: () {
                setState(() {
                  selectedPositionCategory = null;
                });
                _filterMembers();
                Navigator.pop(context);
              },
            ),
            ...positionCategories.entries.map((entry) {
              final isSelected = selectedPositionCategory == entry.key;
              return _filterSheetRow(
                label: entry.value,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    selectedPositionCategory = entry.key;
                  });
                  _filterMembers();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showDepartmentFilter() {
    final departments = availableDepartments;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return _filterSheetContainer(
          title: '부서별 필터',
          children: [
            _filterSheetRow(
              label: '전체',
              isSelected: selectedDepartment == null,
              onTap: () {
                setState(() {
                  selectedDepartment = null;
                });
                _filterMembers();
                Navigator.pop(context);
              },
            ),
            ...departments.map((dept) {
              final label = MemberDepartmentOptions.getLabel(dept) ?? dept;
              final isSelected = selectedDepartment == dept;
              return _filterSheetRow(
                label: label,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    selectedDepartment = dept;
                  });
                  _filterMembers();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showDistrictFilter() {
    final districtIds = availableDistricts;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
            CircularProgressIndicator(color: NewAppColor.skyPrimary),
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
        color: NewAppColor.skyPrimary,
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

    // 1.2.0 C 방향: 초성별 그룹화 — 섹션 헤더 + 흰 카드 묶음
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
              // 카드 그룹 (흰 배경 + 1px borderSoft + 라운드 14)
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

  // 초성별로 그룹화. 정렬 결과는 _filterMembers의 sortAscending을 그대로 따라간다.
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
    // 영문은 대문자, 그 외(숫자/기호)는 #
    final code = first.codeUnitAt(0);
    final isAlpha = (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
    return isAlpha ? first.toUpperCase() : '#';
  }

  // 1.2.0 C 방향: 교인 행 (라운드 13 skyTint 아바타 + 이름 + 직분 배지 + 전화 + 통화/메시지 30원형)
  Widget _buildMemberRow(Member member, {required bool isLast}) {
    return InkWell(
      onTap: () => _showMemberDetail(member),
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
              width: 44.w,
              height: 44.h,
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
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 13.w),
            // 이름 + 직분 배지 + 전화번호
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
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.positionLabel.isNotEmpty) ...[
                        SizedBox(width: 7.w),
                        _buildPositionBadge(member.positionLabel),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    member.phone,
                    style: FigmaTextStyles().caption2.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // 통화 — 30원형 skyTint + skyDeep
            _buildMemberActionButton(
              icon: LucideIcons.phone,
              onTap: () => _makePhoneCall(member.phone),
            ),
            SizedBox(width: 8.w),
            _buildMemberActionButton(
              icon: LucideIcons.messageCircle,
              onTap: () => _sendMessage(member.phone),
            ),
          ],
        ),
      ),
    );
  }

  // 직분 배지 — 일반 직분은 skyTint/skyDeep, '성도'는 회색 톤 (목업 §113)
  Widget _buildPositionBadge(String label) {
    final isPlain = label == '성도' || label == '교인';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isPlain ? NewAppColor.borderSoft : NewAppColor.skyTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: FigmaTextStyles().badgeSm.copyWith(
              color: isPlain ? NewAppColor.textSecondary : NewAppColor.skyDeep,
              fontSize: 10.5.sp,
            ),
      ),
    );
  }

  // 통화/메시지 30원형 액션 (skyTint + skyDeep)
  Widget _buildMemberActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 30.w,
        height: 30.h,
        decoration: BoxDecoration(
          color: NewAppColor.skyTint,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: NewAppColor.skyDeep,
          size: 15.sp,
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    AppToast.show(context, '교인 추가 기능은 준비 중입니다');
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

  // 1.2.0 C 방향: 시트 행 (members_screen의 _filterSheetRow와 동일 사양)
  Widget _row({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isSelected ? NewAppColor.skyTint : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: FigmaTextStyles().body2.copyWith(
                          color: isSelected
                              ? NewAppColor.skyDeep
                              : NewAppColor.neutral700,
                          fontSize: 15.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    LucideIcons.check,
                    color: NewAppColor.skyDeep,
                    size: 19.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 14.h,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들바
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: NewAppColor.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 12.h),
              child: Text(
                '조직별 필터',
                style: FigmaTextStyles().cardTitle.copyWith(
                      color: NewAppColor.textStrong,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Center(
                  child: CircularProgressIndicator(
                    color: NewAppColor.skyPrimary,
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row(
                        label: '전체',
                        isSelected: widget.selectedDistrictId == null,
                        onTap: () {
                          widget.onDistrictSelected(null, null);
                          Navigator.pop(context);
                        },
                      ),
                      ..._sortOrganizationPaths(widget.districtIds)
                          .map((districtId) {
                        final isSelected =
                            widget.selectedDistrictId == districtId;
                        final displayName =
                            organizationNames[districtId] ?? districtId;
                        return _row(
                          label: displayName,
                          isSelected: isSelected,
                          onTap: () {
                            widget.onDistrictSelected(districtId, displayName);
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
