import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final _announcementService = AnnouncementService();
  
  List<Announcement> allAnnouncements = [];
  List<Announcement> filteredAnnouncements = [];
  bool isLoading = true;
  String selectedFilter = '전체';

  final List<String> filterOptions = ['전체', '고정', '일반'];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    print('🔄 공지사항 로드 시작');
    setState(() => isLoading = true);
    
    try {
      // AnnouncementService를 통해 실제 API 호출
      print('📞 API 호출 중...');
      final announcements = await _announcementService.getAnnouncements(
        skip: 0,
        limit: 100,
      );
      
      print('✅ API 호출 성공: ${announcements.length}개 공지사항');
      allAnnouncements = announcements;
      _filterAnnouncements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공지사항 ${announcements.length}개를 불러왔습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      print('❌ API 호출 실패: $e');
      setState(() => isLoading = false);
      
      // 실제 API에 공지사항이 없을 수 있으므로 빈 목록으로 설정
      allAnnouncements = [];
      _filterAnnouncements();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공지사항을 불러올 수 없습니다. 서버에 등록된 공지사항이 없을 수 있습니다.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }



  void _filterAnnouncements() {
    setState(() {
      if (selectedFilter == '전체') {
        filteredAnnouncements = List.from(allAnnouncements);
      } else if (selectedFilter == '고정') {
        filteredAnnouncements = allAnnouncements.where((announcement) => announcement.isPinned).toList();
      } else {
        filteredAnnouncements = allAnnouncements.where((announcement) => !announcement.isPinned).toList();
      }
      
      // 고정된 공지사항을 맨 위로 정렬
      filteredAnnouncements.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt); // 최신순
      });
    });
  }
  
  void _onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    _filterAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 필터 탭
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: filterOptions.map((filter) {
                bool isSelected = selectedFilter == filter;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        _onFilterChanged(filter);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[700] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          filter,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // 공지사항 목록
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAnnouncements.isEmpty
                    ? Center(
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
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAnnouncements,
                        child: ListView.builder(
                          itemCount: filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            return _buildAnnouncementCard(filteredAnnouncements[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewNoticeDetail(announcement),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목과 중요도 표시
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (announcement.isPinned) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '중요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 내용 미리보기
              Text(
                announcement.truncatedContent,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 작성자와 날짜
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    announcement.authorName ?? '관리자',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    announcement.formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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

  void _viewNoticeDetail(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                children: [
                  if (announcement.isPinned) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
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
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 작성자와 날짜
              Row(
                children: [
                  Text(
                    announcement.authorName ?? '관리자',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${announcement.createdAt.year}.${announcement.createdAt.month.toString().padLeft(2, '0')}.${announcement.createdAt.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // 내용
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    announcement.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _shareAnnouncement(announcement);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('공유'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareAnnouncement(Announcement announcement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${announcement.title}이 공유되었습니다'),
      ),
    );
  }




}
