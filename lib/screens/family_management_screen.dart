import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/index.dart' hide IconButton;
import '../resource/color_style_new.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> relationships = [];
  bool isLoading = true;
  String searchQuery = '';

  final List<String> relationshipTypes = [
    '부모', '자녀', '배우자', '형제', '자매',
    '조부모', '손자녀', '삼촌', '이모', '고모', '조카'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        members = [
          {
            'id': 1,
            'name': '김철수',
            'gender': '남',
            'date_of_birth': '1980-05-15',
            'phone': '010-1234-5678',
            'age': 44,
          },
          {
            'id': 2,
            'name': '김미영',
            'gender': '여',
            'date_of_birth': '1985-03-20',
            'phone': '010-9876-5432',
            'age': 39,
          },
          {
            'id': 3,
            'name': '김지민',
            'gender': '남',
            'date_of_birth': '2010-07-10',
            'phone': '010-1111-2222',
            'age': 14,
          },
          {
            'id': 4,
            'name': '김하늘',
            'gender': '여',
            'date_of_birth': '2012-12-25',
            'phone': '010-3333-4444',
            'age': 12,
          },
        ];

        relationships = [
          {
            'id': 1,
            'member_id': 1,
            'member_name': '김철수',
            'related_member_id': 2,
            'related_member_name': '김미영',
            'relationship_type': '배우자',
          },
          {
            'id': 2,
            'member_id': 1,
            'member_name': '김철수',
            'related_member_id': 3,
            'related_member_name': '김지민',
            'relationship_type': '자녀',
          },
          {
            'id': 3,
            'member_id': 1,
            'member_name': '김철수',
            'related_member_id': 4,
            'related_member_name': '김하늘',
            'relationship_type': '자녀',
          },
        ];

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) AppToast.error(context, '데이터를 불러오는데 실패했습니다');
    }
  }

  Future<void> _addRelationship() => _showRelationshipSheet();

  Future<void> _editRelationship(Map<String, dynamic> relationship) =>
      _showRelationshipSheet(relationship: relationship);

  Future<void> _showRelationshipSheet({Map<String, dynamic>? relationship}) async {
    final isEdit = relationship != null;
    Map<String, dynamic>? mainMember = isEdit
        ? members.firstWhere((m) => m['id'] == relationship['member_id'])
        : null;
    Map<String, dynamic>? relatedMember = isEdit
        ? members.firstWhere((m) => m['id'] == relationship['related_member_id'])
        : null;
    String relationType =
        relationship?['relationship_type'] ?? relationshipTypes[0];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(26.r)),
                ),
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: NewAppColor.borderStrong,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      isEdit ? '가족 관계 수정' : '새 가족 관계 추가',
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 18.h),
                    _SheetSelector(
                      label: '주 교인',
                      value: mainMember != null
                          ? '${mainMember!['name']} (${mainMember!['age']}세)'
                          : '선택',
                      disabled: isEdit,
                      onTap: () {
                        _showMemberPickSheet(
                          title: '주 교인 선택',
                          members: members,
                          onSelected: (m) =>
                              setSheetState(() => mainMember = m),
                        );
                      },
                    ),
                    SizedBox(height: 14.h),
                    _SheetSelector(
                      label: '관계',
                      value: relationType,
                      onTap: () {
                        _showRelationTypeSheet(
                          selected: relationType,
                          onSelected: (v) =>
                              setSheetState(() => relationType = v),
                        );
                      },
                    ),
                    SizedBox(height: 14.h),
                    _SheetSelector(
                      label: '관련 교인',
                      value: relatedMember != null
                          ? '${relatedMember!['name']} (${relatedMember!['age']}세)'
                          : '선택',
                      disabled: isEdit,
                      onTap: () {
                        final filtered = members
                            .where((m) => m['id'] != mainMember?['id'])
                            .toList();
                        _showMemberPickSheet(
                          title: '관련 교인 선택',
                          members: filtered,
                          onSelected: (m) =>
                              setSheetState(() => relatedMember = m),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48.h,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: NewAppColor.borderSoft,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                '취소',
                                style: TextStyle(
                                  color: NewAppColor.textSecondary,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: SizedBox(
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (mainMember != null &&
                                    relatedMember != null) {
                                  await _saveRelationship(
                                    isEdit: isEdit,
                                    relationshipId: relationship?['id'],
                                    memberId: mainMember!['id'],
                                    memberName: mainMember!['name'],
                                    relatedMemberId: relatedMember!['id'],
                                    relatedMemberName: relatedMember!['name'],
                                    relationshipType: relationType,
                                  );
                                  if (mounted) Navigator.pop(sheetContext);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NewAppColor.skyPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                isEdit ? '수정' : '추가',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMemberPickSheet({
    required String title,
    required List<Map<String, dynamic>> members,
    required ValueChanged<Map<String, dynamic>> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: NewAppColor.borderStrong,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 14.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 0.5.sh),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    color: NewAppColor.borderHair,
                  ),
                  itemBuilder: (_, index) {
                    final m = members[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSelected(m);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Text(
                          '${m['name']} (${m['age']}세)',
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRelationTypeSheet({
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: NewAppColor.borderStrong,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '관계 선택',
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 14.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 0.5.sh),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: relationshipTypes.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    color: NewAppColor.borderHair,
                  ),
                  itemBuilder: (_, index) {
                    final type = relationshipTypes[index];
                    final isSelected = type == selected;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSelected(type);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? NewAppColor.skyDeep
                                      : NewAppColor.textStrong,
                                  fontSize: 15.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                LucideIcons.check,
                                size: 18.sp,
                                color: NewAppColor.skyPrimary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveRelationship({
    required bool isEdit,
    int? relationshipId,
    required int memberId,
    required String memberName,
    required int relatedMemberId,
    required String relatedMemberName,
    required String relationshipType,
  }) async {
    try {
      if (isEdit) {
        final index = relationships.indexWhere((r) => r['id'] == relationshipId);
        if (index != -1) {
          setState(() {
            relationships[index] = {
              ...relationships[index],
              'relationship_type': relationshipType,
            };
          });
        }
      } else {
        setState(() {
          relationships.add({
            'id': relationships.length + 1,
            'member_id': memberId,
            'member_name': memberName,
            'related_member_id': relatedMemberId,
            'related_member_name': relatedMemberName,
            'relationship_type': relationshipType,
          });
        });
      }

      if (mounted) {
        AppToast.success(
          context,
          isEdit ? '가족 관계가 수정되었습니다' : '새 가족 관계가 추가되었습니다',
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '가족 관계 저장에 실패했습니다');
    }
  }

  Future<void> _deleteRelationship(Map<String, dynamic> relationship) async {
    final confirmed = await AppConfirmSheet.show(
      context: context,
      title: '가족 관계를 삭제할까요?',
      description:
          '${relationship['member_name']}님과 ${relationship['related_member_name']}님의 관계가 삭제됩니다.',
      confirmLabel: '삭제',
      tone: AppSheetTone.danger,
    );

    if (confirmed == true) {
      try {
        setState(() {
          relationships.removeWhere((r) => r['id'] == relationship['id']);
        });
        if (mounted) AppToast.success(context, '가족 관계가 삭제되었습니다');
      } catch (e) {
        if (mounted) AppToast.error(context, '가족 관계 삭제에 실패했습니다');
      }
    }
  }

  void _viewFamilyTree(Map<String, dynamic> member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyTreeScreen(member: member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRelationships = relationships.where((rel) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return rel['member_name'].toString().toLowerCase().contains(q) ||
          rel['related_member_name'].toString().toLowerCase().contains(q) ||
          rel['relationship_type'].toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '가족 관계 관리',
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: NewAppColor.textStrong,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              size: 26.sp, color: NewAppColor.textStrong),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(LucideIcons.refreshCw,
                size: 22.sp, color: NewAppColor.textStrong),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: NewAppColor.borderHair),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "family_fab",
        onPressed: _addRelationship,
        backgroundColor: NewAppColor.skyPrimary,
        elevation: 2,
        child: Icon(LucideIcons.plus, color: Colors.white, size: 24.sp),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: NewAppColor.skyPrimary),
                  SizedBox(height: 14.h),
                  Text(
                    '가족 관계 데이터를 불러오는 중...',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: NewAppColor.textMuted,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 검색바
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: NewAppColor.borderSoft,
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Icon(LucideIcons.search,
                            size: 18.sp, color: NewAppColor.textTertiary),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '교인명, 관계로 검색',
                              hintStyle: TextStyle(
                                color: NewAppColor.textTertiary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: TextStyle(
                              color: NewAppColor.textStrong,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 통계 카드
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: '총 관계 수',
                          value: '${relationships.length}건',
                          icon: LucideIcons.users,
                          tone: _StatTone.sky,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _StatCard(
                          label: '부부 관계',
                          value:
                              '${relationships.where((r) => r['relationship_type'] == '배우자').length}건',
                          icon: LucideIcons.heart,
                          tone: _StatTone.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                // 관계 목록
                Expanded(
                  child: relationships.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                          itemCount: filteredRelationships.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            return _buildRelationshipCard(
                                filteredRelationships[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
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
            child: Icon(LucideIcons.users,
                size: 32.sp, color: NewAppColor.textTertiary),
          ),
          SizedBox(height: 14.h),
          Text(
            '관계 데이터가 없습니다',
            style: TextStyle(
              color: NewAppColor.textSecondary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipCard(Map<String, dynamic> relationship) {
    final tone = _getRelationshipTone(relationship['relationship_type']);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair),
      ),
      padding: EdgeInsets.all(14.w),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: tone.bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getRelationshipIcon(relationship['relationship_type']),
              color: tone.fg,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        relationship['member_name'],
                        style: TextStyle(
                          color: NewAppColor.textStrong,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: tone.bg,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        relationship['relationship_type'],
                        style: TextStyle(
                          color: tone.fg,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        relationship['related_member_name'],
                        style: TextStyle(
                          color: NewAppColor.textStrong,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '${relationship['member_name']}님의 ${relationship['relationship_type']}',
                  style: TextStyle(
                    color: NewAppColor.textMuted,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showActionSheet(relationship),
            child: Container(
              padding: EdgeInsets.all(6.w),
              child: Icon(
                LucideIcons.ellipsisVertical,
                size: 18.sp,
                color: NewAppColor.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(Map<String, dynamic> relationship) {
    AppMenuSheet.show(
      context: context,
      items: [
        AppMenuItem(
          icon: LucideIcons.network,
          label: '가족도 보기',
          onTap: () {
            final member = members.firstWhere(
              (m) => m['id'] == relationship['member_id'],
            );
            _viewFamilyTree(member);
          },
        ),
        AppMenuItem(
          icon: LucideIcons.pencil,
          label: '수정',
          onTap: () => _editRelationship(relationship),
        ),
        AppMenuItem(
          icon: LucideIcons.trash2,
          label: '삭제',
          danger: true,
          onTap: () => _deleteRelationship(relationship),
        ),
      ],
    );
  }

  _RelationTone _getRelationshipTone(String type) {
    switch (type) {
      case '배우자':
        return _RelationTone(
            bg: NewAppColor.dangerBg, fg: NewAppColor.danger700);
      case '부모':
      case '자녀':
        return _RelationTone(
            bg: NewAppColor.skyTint, fg: NewAppColor.skyDeep);
      case '형제':
      case '자매':
        return _RelationTone(
            bg: NewAppColor.successBg, fg: NewAppColor.success700);
      case '조부모':
      case '손자녀':
        return _RelationTone(
            bg: NewAppColor.warningBg, fg: NewAppColor.warning700);
      default:
        return _RelationTone(
            bg: NewAppColor.borderSoft, fg: NewAppColor.textSecondary);
    }
  }

  IconData _getRelationshipIcon(String relationshipType) {
    switch (relationshipType) {
      case '배우자':
        return LucideIcons.heart;
      case '부모':
        return LucideIcons.user;
      case '자녀':
        return LucideIcons.baby;
      case '형제':
      case '자매':
        return LucideIcons.users;
      case '조부모':
        return LucideIcons.user;
      case '손자녀':
        return LucideIcons.baby;
      default:
        return LucideIcons.users;
    }
  }
}

enum _StatTone { sky, warning }

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final _StatTone tone;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = tone == _StatTone.sky
        ? NewAppColor.skyTint
        : NewAppColor.warningBg;
    final iconFg = tone == _StatTone.sky
        ? NewAppColor.skyPrimary
        : NewAppColor.warning700;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: NewAppColor.textMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 14.sp, color: iconFg),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationTone {
  final Color bg;
  final Color fg;
  const _RelationTone({required this.bg, required this.fg});
}

class _SheetSelector extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool disabled;

  const _SheetSelector({
    required this.label,
    required this.value,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: NewAppColor.textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: disabled ? null : onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: disabled ? NewAppColor.canvasAlt : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: NewAppColor.borderHair),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: disabled
                          ? NewAppColor.textTertiary
                          : NewAppColor.textStrong,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 18.sp,
                  color: NewAppColor.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 가족도 화면
class FamilyTreeScreen extends StatelessWidget {
  final Map<String, dynamic> member;

  const FamilyTreeScreen({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '${member['name']}님 가족도',
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: NewAppColor.textStrong,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              size: 26.sp, color: NewAppColor.textStrong),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: NewAppColor.borderHair),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.network,
                size: 38.sp,
                color: NewAppColor.skyPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '가족도 기능은 개발 중입니다',
              style: TextStyle(
                color: NewAppColor.textStrong,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'API 연동 후 가족 관계를 시각적으로 표시할 예정입니다.',
                style: TextStyle(
                  color: NewAppColor.textMuted,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
