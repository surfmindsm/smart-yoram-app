import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../utils/announcement_categories.dart';
import '../utils/date_filter.dart';
import '../components/index.dart' hide IconButton;
import 'notice_detail_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NoticesScreen extends StatefulWidget {
  final bool showAppBar;

  const NoticesScreen({
    super.key,
    this.showAppBar = true, // 기본값은 true (홈에서 들어올 때)
  });

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen>
    with TickerProviderStateMixin {
  final _announcementService = AnnouncementService();
  final _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Announcement> announcements = [];
  List<Announcement> _filteredAnnouncementsCache = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  String selectedDateFilter = 'latest';
  DateTime? customStartDate;
  DateTime? customEndDate;
  late TabController _tabController;

  final List<Map<String, String>> tabCategories =
      AnnouncementCategories.getTabCategories();
  final List<DateFilter> dateFilters = DateFilter.getFilterOptions();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabCategories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _updateFilteredAnnouncements();
    });
  }

  void _updateFilteredAnnouncements() {
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isEmpty) {
      _filteredAnnouncementsCache = announcements;
    } else {
      _filteredAnnouncementsCache = announcements.where((announcement) {
        return announcement.title.toLowerCase().contains(searchQuery) ||
            announcement.content.toLowerCase().contains(searchQuery) ||
            (announcement.authorName?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final newCategory = tabCategories[_tabController.index]['key']!;
    if (newCategory != selectedCategory) {
      setState(() {
        selectedCategory = newCategory;
      });
      _loadAnnouncements();
    }
  }

  Future<void> _loadAnnouncements() async {
    print('🔄 공지사항 로드 시작 - 카테고리: $selectedCategory, 날짜필터: $selectedDateFilter');
    setState(() => isLoading = true);

    try {
      final apiCategory = selectedCategory == 'all' ? null : selectedCategory;

      // 날짜 필터 설정
      final dateRange = DateFilter.getDateRange(
        selectedDateFilter,
        customStart: customStartDate,
        customEnd: customEndDate,
      );
      final sortOrder = DateFilter.getSortOrder(selectedDateFilter);

      print(
          '📞 API 호출 중... 카테고리: $apiCategory, 날짜: ${dateRange['startDate']} ~ ${dateRange['endDate']}, 정렬: $sortOrder');
      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      final churchId = userResponse.data?.churchId;

      final announcementList = await _announcementService.getAnnouncements(
        skip: 0,
        limit: 100,
        category: apiCategory,
        isActive: true,
        startDate: dateRange['startDate'],
        endDate: dateRange['endDate'],
        sortOrder: sortOrder,
        churchId: churchId,
      );

      print('✅ API 호출 성공: ${announcementList.length}개 공지사항');

      if (mounted) {
        setState(() {
          announcements = announcementList;
          _updateFilteredAnnouncements();
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ API 호출 실패: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          announcements = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공지사항을 불러올 수 없습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 1.2.0 C 방향: 검색(#F1F5F9 채움) + 카테고리 칩 + 카드 리스트
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      body: Column(
        children: [
          // 상단 흰 영역 (검색 + 카테고리 칩). 통합 화면 안에서는 검색만 노출되도록 padding 조절.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: NewAppColor.borderSoft),
              ),
            ),
            padding: EdgeInsets.only(
              // 통합 화면 안에 들어오면 상단에 이미 흰 헤더가 있으니 상단 여유만 조금
              top: widget.showAppBar
                  ? MediaQuery.of(context).padding.top + 6.h
                  : 12.h,
              left: 18.w,
              right: 18.w,
              bottom: 12.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showAppBar) ...[
                  // 직접 진입 시 뒤로가기 + 타이틀
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Icon(
                            LucideIcons.arrowLeft,
                            color: NewAppColor.textStrong,
                            size: 22.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '교회소식',
                        style: FigmaTextStyles().subtitle1.copyWith(
                              color: NewAppColor.textStrong,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
                // 검색바 — #F1F5F9 채움형 무테
                Container(
                  decoration: BoxDecoration(
                    color: NewAppColor.borderSoft,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                            hintText: '교회 소식 검색',
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
                SizedBox(height: 12.h),
                // 카테고리 칩 row (가로 스크롤)
                SizedBox(
                  height: 30.h,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(tabCategories.length, (index) {
                        final category = tabCategories[index];
                        final isSelected = _tabController.index == index;
                        return Padding(
                          padding: EdgeInsets.only(right: 7.w),
                          child: _buildCategoryChip(
                            label: category['label']!,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _tabController.animateTo(index);
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 공지사항 목록
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabCategories.map((category) {
                return RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  color: NewAppColor.skyPrimary,
                  child: _buildAnnouncementList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 1.2.0 카테고리 칩 (활성=skyPrimary/흰글자, 비활성=흰배경+borderStrong+textSecondary)
  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.skyPrimary : Colors.white,
          border: isSelected
              ? null
              : Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: FigmaTextStyles().caption2.copyWith(
                color: isSelected ? Colors.white : NewAppColor.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5.sp,
              ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(NewAppColor.skyPrimary),
            ),
            SizedBox(height: 16.h),
            Text(
              '교회 소식을 불러오는 중...',
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    if (_filteredAnnouncementsCache.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.megaphone,
              size: 56.sp,
              color: NewAppColor.iconFaint,
            ),
            SizedBox(height: 14.h),
            Text(
              '교회 소식이 없습니다',
              style: FigmaTextStyles().subtitle2.copyWith(
                    color: NewAppColor.textSecondary,
                  ),
            ),
            SizedBox(height: 6.h),
            Text(
              '새로운 소식이 등록되는 대로 알려드릴게요',
              style: FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 18.h),
      itemCount: _filteredAnnouncementsCache.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final announcement = _filteredAnnouncementsCache[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  // 1.2.0 C 방향: Flex Row 카드 (라운드 14 + 1px borderHair + chevron-right)
  Widget _buildAnnouncementCard(Announcement announcement) {
    return InkWell(
      onTap: () => _viewNoticeDetail(announcement),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: NewAppColor.borderHair, width: 1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 태그(들)
                  Row(
                    children: [
                      _buildCategoryTag(
                        AnnouncementCategories.getCategoryLabel(
                          announcement.category,
                        ),
                      ),
                      if (announcement.subcategory != null &&
                          announcement.subcategory!.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        _buildSubcategoryTag(
                          AnnouncementCategories.getSubcategoryLabel(
                            announcement.category,
                            announcement.subcategory,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 10.h),
                  // 제목
                  Text(
                    announcement.title,
                    style: FigmaTextStyles().cardTitleSm.copyWith(
                          color: NewAppColor.textStrong,
                          fontSize: 15.5.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  // 내용 한 줄 미리보기
                  Text(
                    announcement.content,
                    style: FigmaTextStyles().body3.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 13.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 14.h),
                  // 메타 행 (user/clock + textTertiary)
                  Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 13.sp,
                        color: NewAppColor.textTertiary,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          announcement.authorName ?? '관리자',
                          style: FigmaTextStyles().caption2.copyWith(
                                color: NewAppColor.textTertiary,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        LucideIcons.clock,
                        size: 13.sp,
                        color: NewAppColor.textTertiary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatDate(announcement.createdAt),
                        style: FigmaTextStyles().caption2.copyWith(
                              color: NewAppColor.textTertiary,
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
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

  // 1.2.0: skyTint/skyDeep + 라운드 999px
  Widget _buildCategoryTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: NewAppColor.skyTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: FigmaTextStyles().badgeSm.copyWith(
              color: NewAppColor.skyDeep,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  // 1.2.0: 보조 태그 — 회색 톤
  Widget _buildSubcategoryTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: NewAppColor.borderSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: FigmaTextStyles().badgeSm.copyWith(
              color: NewAppColor.textSecondary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewNoticeDetail(Announcement announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(
          announcement: announcement,
        ),
      ),
    );
  }
}
