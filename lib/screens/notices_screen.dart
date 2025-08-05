import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../utils/announcement_categories.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen>
    with TickerProviderStateMixin {
  final _announcementService = AnnouncementService();

  List<Announcement> announcements = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  late TabController _tabController;

  final List<Map<String, String>> tabCategories =
      AnnouncementCategories.getTabCategories();

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
    print('🔄 공지사항 로드 시작 - 카테고리: $selectedCategory');
    setState(() => isLoading = true);

    try {
      final apiCategory = selectedCategory == 'all' ? null : selectedCategory;

      print('📞 API 호출 중... 카테고리: $apiCategory');
      final announcementList = await _announcementService.getAnnouncements(
        skip: 0,
        limit: 100,
        category: apiCategory,
        isActive: true,
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
      backgroundColor: Colors.grey[50],
      // appBar: AppBar(
      //   title: const Text(
      //     '공지사항',
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       color: Colors.white,
      //     ),
      //   ),
      //   backgroundColor: AppColor.primary600,
      //   elevation: 0,
      //   centerTitle: true,
      //   bottom: PreferredSize(
      //     preferredSize: const Size.fromHeight(48.0),
      //     child: Container(
      //       color: AppColor.primary600,
      //       child: TabBar(
      //         controller: _tabController,
      //         isScrollable: false,
      //         indicatorColor: Colors.white,
      //         indicatorWeight: 3,
      //         labelColor: Colors.white,
      //         unselectedLabelColor: Colors.white70,
      //         labelStyle: const TextStyle(
      //           fontWeight: FontWeight.bold,
      //           fontSize: 14,
      //         ),
      //         unselectedLabelStyle: const TextStyle(
      //           fontWeight: FontWeight.normal,
      //           fontSize: 14,
      //         ),
      //         tabs: tabCategories
      //             .map((category) => Tab(text: category['label']))
      //             .toList(),
      //       ),
      //     ),
      //   ),
      // ),
      body: Column(
        children: [
          // SafeArea와 탭바 추가
          Container(
            color: AppColor.primary600,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 탭바
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14.sp,
                    ),
                    tabs: tabCategories
                        .map((category) => Tab(text: category['label']))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          // TabBarView를 Expanded로 감싸기
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.announcement_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '공지사항이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '기다려주세요. 공지사항이 등록되는 대로\n여기에 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewNoticeDetail(announcement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (제목, 고정, 카테고리)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 고정 아이콘
                  if (announcement.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red[500],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '고정',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // 카테고리 태그
                  if (announcement.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(announcement.category!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AnnouncementCategories.getCategoryLabel(
                            announcement.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // 서브카테고리
                  if (announcement.subcategory != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AnnouncementCategories.getSubcategoryLabel(
                            announcement.category, announcement.subcategory),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
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
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'worship':
        return Colors.blue[600]!;
      case 'member_news':
        return Colors.green[600]!;
      case 'event':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (announcement.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red[500],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '고정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                announcement.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 카테고리 정보
              if (announcement.category != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(announcement.category!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AnnouncementCategories.getCategoryLabel(
                              announcement.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (announcement.subcategory != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AnnouncementCategories.getSubcategoryLabel(
                                announcement.category,
                                announcement.subcategory),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              // 내용
              Text(
                announcement.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // 작성자 및 날짜
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      announcement.authorName ?? '관리자',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${announcement.createdAt.year}.${announcement.createdAt.month.toString().padLeft(2, '0')}.${announcement.createdAt.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareAnnouncement(announcement);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary600,
            ),
            child: const Text(
              '공유하기',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _shareAnnouncement(Announcement announcement) {
    // 공유 기능은 나중에 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('공유 기능이 준비 중입니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
