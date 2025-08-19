import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
import 'package:smart_yoram_app/resource/text_style.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
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

  List<Announcement> announcements = [];
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
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _onDateFilterChanged(String filterKey) {
    if (filterKey == 'custom') {
      _showDatePicker();
    } else {
      setState(() {
        selectedDateFilter = filterKey;
        customStartDate = null;
        customEndDate = null;
      });
      _loadAnnouncements();
    }
  }

  Future<void> _showDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: customStartDate != null && customEndDate != null
          ? DateTimeRange(start: customStartDate!, end: customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        selectedDateFilter = 'custom';
        customStartDate = picked.start;
        customEndDate = picked.end;
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
      final announcementList = await _announcementService.getAnnouncements(
        skip: 0,
        limit: 100,
        category: apiCategory,
        isActive: true,
        startDate: dateRange['startDate'],
        endDate: dateRange['endDate'],
        sortOrder: sortOrder,
      );

      print('✅ API 호출 성공: ${announcementList.length}개 공지사항');

      if (mounted) {
        setState(() {
          announcements = announcementList;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공지사항 ${announcementList.length}개를 불러왔습니다'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
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
      backgroundColor: AppColor.background,
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          '교회소식',
          style: AppTextStyle(
            color: AppColor.secondary07,
          ).h2(),
        ),
        backgroundColor: AppColor.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColor.secondary07,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) => _onDateFilterChanged(value),
            icon: Icon(
              Icons.filter_list,
              color: AppColor.secondary07,
              size: 20.sp,
            ),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'latest',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16),
                    SizedBox(width: 8),
                    Text('최신순'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16),
                    SizedBox(width: 8),
                    Text('오래된순'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 16),
                    SizedBox(width: 8),
                    Text('최근 7일'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16),
                    SizedBox(width: 8),
                    Text('최근 30일'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'this_month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 16),
                    SizedBox(width: 8),
                    Text('이번 달'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16),
                    SizedBox(width: 8),
                    Text('날짜 선택'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 16.w),
        ],
      ) : null,
      body: Column(
        children: [
          // main navigation에서 들어올 때 상단 여백 추가
          if (!widget.showAppBar)
            SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          
          // 탭바
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: AppCard(
              variant: CardVariant.elevated,
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColor.primary900,
                labelStyle:
                    AppTextStyle(color: AppColor.primary900).b2().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
                unselectedLabelColor: AppColor.secondary04,
                unselectedLabelStyle:
                    AppTextStyle(color: AppColor.secondary04).b2(),
                indicatorColor: AppColor.primary900,
                indicatorPadding: EdgeInsets.zero,
                indicatorWeight: 2.h,
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                tabs: tabCategories.map((category) {
                  return Tab(text: category['label']);
                }).toList(),
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              ),
            ),
          ),

          // 공지사항 목록
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabCategories.map((category) {
                return RefreshIndicator(
                  onRefresh: _loadAnnouncements,
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
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: AppCard(
              variant: CardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppSkeleton(
                          width: 40.w,
                          height: 16.h,
                          borderRadius: BorderRadius.circular(8)),
                      SizedBox(width: 8.w),
                      AppSkeleton(
                          width: 60.w,
                          height: 16.h,
                          borderRadius: BorderRadius.circular(8)),
                      const Spacer(),
                      AppSkeleton(
                          width: 20,
                          height: 20,
                          borderRadius: BorderRadius.circular(10)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  AppSkeleton(width: double.infinity, height: 20.h),
                  SizedBox(height: 8.h),
                  AppSkeleton(width: 0.8.sw, height: 16.h),
                  SizedBox(height: 8.h),
                  AppSkeleton(width: 0.6.sw, height: 16.h),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      AppSkeleton(
                          width: 16,
                          height: 16,
                          borderRadius: BorderRadius.circular(8)),
                      SizedBox(width: 4.w),
                      AppSkeleton(width: 80.w, height: 12.h),
                      SizedBox(width: 16.w),
                      AppSkeleton(
                          width: 16,
                          height: 16,
                          borderRadius: BorderRadius.circular(8)),
                      SizedBox(width: 4.w),
                      AppSkeleton(width: 60.w, height: 12.h),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppAlert(
            type: AlertType.info,
            title: '공지사항이 없습니다',
            description: '기다려주세요. 공지사항이 등록되는 대로 여기에 표시됩니다.',
            icon: Icon(Icons.announcement_outlined, size: 20),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: AppCard(
        variant: CardVariant.elevated,
        onTap: () => _viewNoticeDetail(announcement),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 영역
            Row(
              children: [
                // 고정 배지
                if (announcement.isPinned)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: AppBadge(
                      text: '고정',
                      variant: BadgeVariant.error,
                      size: BadgeSize.sm,
                    ),
                  ),
                // 카테고리 태그
                if (announcement.category != null)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: AppBadge(
                      text: AnnouncementCategories.getCategoryLabel(
                          announcement.category),
                      variant: _getBadgeVariant(announcement.category!),
                      size: BadgeSize.sm,
                    ),
                  ),
                // 서브카테고리
                if (announcement.subcategory != null)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: AppBadge(
                      text: AnnouncementCategories.getSubcategoryLabel(
                          announcement.category, announcement.subcategory),
                      variant: BadgeVariant.secondary,
                      size: BadgeSize.sm,
                    ),
                  ),
                const Spacer(),
                // 더보기 버튼
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'share') {
                      _shareAnnouncement(announcement);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 16),
                          SizedBox(width: 8),
                          Text('공유하기'),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 제목
            Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 내용 미리보기
            Text(
              announcement.content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // 하단 정보 (작성자, 날짜)
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  announcement.authorName ?? '관리자',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(announcement.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BadgeVariant _getBadgeVariant(String category) {
    switch (category) {
      case 'worship':
        return BadgeVariant.primary;
      case 'member_news':
        return BadgeVariant.success;
      case 'event':
        return BadgeVariant.warning;
      default:
        return BadgeVariant.secondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '어제';
    } else if (difference < 7) {
      return '${difference}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
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

  void _shareAnnouncement(Announcement announcement) {
    // 공유 기능은 나중에 구현
    AppToast.show(
      context,
      '공유 기능이 준비 중입니다',
      type: ToastType.info,
    );
  }
}
