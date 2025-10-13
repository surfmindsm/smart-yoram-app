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
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                '교회 소식',
                style: const FigmaTextStyles().headline4.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: NewAppColor.primary600,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // 상단 안전 영역 - AppBar가 없을 때만 적용
          if (!widget.showAppBar)
            SizedBox(height: MediaQuery.of(context).padding.top + 22.h),

          // 탭바
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: NewAppColor.neutral200,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(tabCategories.length, (index) {
                final category = tabCategories[index];
                final isSelected = _tabController.index == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _tabController.animateTo(index);
                      });
                    },
                    child: Container(
                      height: 56.h,
                      decoration: isSelected ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 2,
                            color: NewAppColor.neutral900,
                          ),
                        ),
                      ) : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            category['label']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                ? NewAppColor.neutral900
                                : NewAppColor.neutral400,
                              fontSize: 15.sp,
                              fontFamily: 'Pretendard Variable',
                              fontWeight: FontWeight.w400,
                              height: 1.47,
                              letterSpacing: -0.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

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

    if (announcements.isEmpty) {
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
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
                              _buildCategoryTag('예배/모임'),
                              SizedBox(width: 4.w),
                              _buildSubcategoryTag('주말예배'),
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
      decoration: const BoxDecoration(
        color: Color(0xFF0078FF), // Primary_600
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
