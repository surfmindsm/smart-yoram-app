import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bulletin.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final supabase = Supabase.instance.client;
  
  List<Notice> allNotices = [];
  List<Notice> filteredNotices = [];
  bool isLoading = true;
  String selectedFilter = '전체';

  final List<String> filterOptions = ['전체', '중요', '일반'];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => isLoading = true);
    
    try {
      // 임시 공지사항 데이터 생성
      allNotices = _generateSampleNotices();
      _filterNotices();
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공지사항 로드 실패: $e')),
        );
      }
    }
  }

  List<Notice> _generateSampleNotices() {
    final now = DateTime.now();
    return [
      Notice(
        id: '1',
        title: '2024년 새해 감사예배 안내',
        content: '''새해를 맞이하여 하나님께 감사하는 예배를 드리고자 합니다.

일시: 2024년 1월 7일(일) 오전 11시
장소: 본당
준비물: 감사제목 적은 종이

모든 성도님들의 참석을 부탁드립니다.''',
        isImportant: true,
        createdAt: now.subtract(const Duration(days: 1)),
        createdBy: '관리자',
      ),
      Notice(
        id: '2',
        title: '주일학교 교사 모집',
        content: '''주일학교에서 아이들을 가르쳐 주실 교사를 모집합니다.

대상: 청년부 이상 성도
자격: 아이들을 사랑하는 마음
교육: 별도 교육 제공

관심 있으신 분은 교육부장에게 연락 바랍니다.''',
        isImportant: false,
        createdAt: now.subtract(const Duration(days: 3)),
        createdBy: '교육부',
      ),
      Notice(
        id: '3',
        title: '성찬식 예정 안내',
        content: '''이번 달 첫째 주일에 성찬식을 거행합니다.

일시: 2024년 2월 4일(일) 주일예배 중
준비사항: 자기 성찰과 회개의 시간

성찬식 참여를 위해 미리 마음을 준비해 주시기 바랍니다.''',
        isImportant: true,
        createdAt: now.subtract(const Duration(days: 5)),
        createdBy: '관리자',
      ),
      Notice(
        id: '4',
        title: '교회 주차장 이용 안내',
        content: '''교회 주차장 이용에 관한 안내사항입니다.

1. 예배 시간 외에는 주차 금지
2. 타 차량 통행에 방해되지 않도록 주차
3. 귀중품은 차량에 방치하지 마세요

협조해 주시기 바랍니다.''',
        isImportant: false,
        createdAt: now.subtract(const Duration(days: 7)),
        createdBy: '관리자',
      ),
      Notice(
        id: '5',
        title: '겨울 성경학교 개최',
        content: '''겨울방학을 맞이하여 성경학교를 개최합니다.

기간: 2024년 1월 15일 ~ 19일 (5일간)
시간: 오전 9시 ~ 오후 3시
대상: 유치부 ~ 중학생
신청: 교육부장에게 문의

많은 참여 바랍니다.''',
        isImportant: false,
        createdAt: now.subtract(const Duration(days: 10)),
        createdBy: '교육부',
      ),
    ];
  }

  void _filterNotices() {
    setState(() {
      if (selectedFilter == '전체') {
        filteredNotices = List.from(allNotices);
      } else if (selectedFilter == '중요') {
        filteredNotices = allNotices.where((notice) => notice.isImportant).toList();
      } else {
        filteredNotices = allNotices.where((notice) => !notice.isImportant).toList();
      }
    });
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
                        setState(() {
                          selectedFilter = filter;
                        });
                        _filterNotices();
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
                : filteredNotices.isEmpty
                    ? const Center(
                        child: Text(
                          '공지사항이 없습니다',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotices,
                        child: ListView.builder(
                          itemCount: filteredNotices.length,
                          itemBuilder: (context, index) {
                            final notice = filteredNotices[index];
                            return _buildNoticeCard(notice);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoticeDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewNoticeDetail(notice),
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
                  if (notice.isImportant) ...[
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
                      notice.title,
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
                notice.content,
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
                    notice.createdBy,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _formatDate(notice.createdAt),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}.${date.day}';
    }
  }

  void _viewNoticeDetail(Notice notice) {
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
                  if (notice.isImportant) ...[
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
                      notice.title,
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
                    notice.createdBy,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${notice.createdAt.year}.${notice.createdAt.month.toString().padLeft(2, '0')}.${notice.createdAt.day.toString().padLeft(2, '0')}',
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
                    notice.content,
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
                      _shareNotice(notice);
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

  void _shareNotice(Notice notice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notice.title}이 공유되었습니다'),
      ),
    );
  }

  void _showAddNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지사항 추가'),
        content: const Text('공지사항 추가 기능은 관리자 권한이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
