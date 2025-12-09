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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: Column(
        children: [
          // 상단 안전 영역
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

          // 검색창 (연락처 스타일) - 모든 경로에서 표시
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                // 홈에서 들어왔을 때만 뒤로가기 버튼
                if (widget.showAppBar) ...[
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Colors.black, size: 24.sp),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8.w),
                ],
                // 검색창
                Expanded(
                  child: Container(
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
                      margin: EdgeInsets.all(1.r),
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
                                hintText: '교회 소식 검색',
                                hintStyle:
                                    const FigmaTextStyles().body2.copyWith(
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
              ],
            ),
          ),


          // 탭바
          Container(
            height: 56.h,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.transparent,
                  width: 2.0,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Row(
                children: List.generate(tabCategories.length, (index) {
                  final category = tabCategories[index];
                  final isSelected = _tabController.index == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _tabController.animateTo(index);
                      });
                    },
                    child: Container(
                      height: 56.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                bottom: BorderSide(
                                  color: NewAppColor.primary600,
                                  width: 2.0,
                                ),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          category['label']!,
                          style: const FigmaTextStyles().title4.copyWith(
                                color: isSelected
                                    ? NewAppColor.primary600
                                    : NewAppColor.neutral400,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // 고정 여백
          SizedBox(height: 16.h),

          // 공지사항 목록
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabCategories.map((category) {
                return RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  color: NewAppColor.primary500,
                  child: _buildAnnouncementList(),
                );
              }).toList(),
            ),
          ),
        ],
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
              valueColor: AlwaysStoppedAnimation<Color>(NewAppColor.primary500),
            ),
            SizedBox(height: 16.h),
            Text(
              '교회 소식을 불러오는 중...',
              style: const FigmaTextStyles().body1.copyWith(
                    color: NewAppColor.neutral600,
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
              Icons.campaign,
              size: 64.sp,
              color: NewAppColor.neutral400,
            ),
            SizedBox(height: 16.h),
            Text(
              '교회 소식이 없습니다',
              style: const FigmaTextStyles().title3.copyWith(
                    color: NewAppColor.neutral600,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              '새로운 소식이 등록되는 대로 알려드릴게요',
              style: const FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.neutral600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      itemCount: _filteredAnnouncementsCache.length,
      itemBuilder: (context, index) {
        final announcement = _filteredAnnouncementsCache[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return GestureDetector(
      onTap: () => _viewNoticeDetail(announcement),
      child: Container(
        width: double.infinity,
        height: 154.h,
        margin: EdgeInsets.only(bottom: 8.h),
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
              top: 16.h,
              child: SizedBox(
                width: 318.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 영역 (태그 + 제목/내용)
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 태그 영역
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryTag(
                                AnnouncementCategories.getCategoryLabel(
                                  announcement.category,
                                ),
                              ),
                              if (announcement.subcategory != null &&
                                  announcement.subcategory!.isNotEmpty) ...[
                                SizedBox(width: 4.w),
                                _buildSubcategoryTag(
                                  AnnouncementCategories.getSubcategoryLabel(
                                    announcement.category,
                                    announcement.subcategory,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // 제목과 내용
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 318.w,
                                  child: Text(
                                    announcement.title,
                                    style: TextStyle(
                                      color: NewAppColor.neutral800,
                                      fontSize: 18.sp,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                      height: 1.44,
                                      letterSpacing: -0.45,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                SizedBox(
                                  width: 318.w,
                                  child: Text(
                                    announcement.content,
                                    style: TextStyle(
                                      color: NewAppColor.neutral400,
                                      fontSize: 14.sp,
                                      fontFamily: 'Pretendard Variable',
                                      fontWeight: FontWeight.w400,
                                      height: 1.43,
                                      letterSpacing: -0.35,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // 하단 정보 (작성자, 날짜)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 16.w,
                              height: 16.h,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(),
                              child: Icon(
                                Icons.person_outline,
                                size: 16.sp,
                                color: NewAppColor.neutral400,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              announcement.authorName ?? '관리자',
                              style: TextStyle(
                                color: NewAppColor.neutral400,
                                fontSize: 11.sp,
                                fontFamily: 'Pretendard Variable',
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 16.w,
                              height: 16.h,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(),
                              child: Icon(
                                Icons.access_time,
                                size: 16.sp,
                                color: NewAppColor.neutral400,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _formatDate(announcement.createdAt),
                              style: TextStyle(
                                color: NewAppColor.neutral400,
                                fontSize: 11.sp,
                                fontFamily: 'Pretendard Variable',
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0078FF), // Primary_600
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              color: NewAppColor.neutral100,
              fontSize: 11.sp,
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w400,
              height: 1.45,
              letterSpacing: -0.28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: NewAppColor.neutral100,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              color: NewAppColor.neutral800,
              fontSize: 11.sp,
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w400,
              height: 1.45,
              letterSpacing: -0.28,
            ),
          ),
        ],
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
