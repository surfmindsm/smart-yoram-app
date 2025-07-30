import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widget/widgets.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final String type; // 'birthday', 'church', 'personal'
  final String? description;
  final bool isAllDay;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.description,
    this.isAllDay = true,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  DateTime selectedDate = DateTime.now();
  List<Event> allEvents = [];
  List<Event> todayEvents = [];
  List<Event> upcomingEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);
    
    try {
      // 임시 이벤트 데이터 생성
      allEvents = _generateSampleEvents();
      _filterEvents();
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 로드 실패: $e')),
        );
      }
    }
  }

  List<Event> _generateSampleEvents() {
    final now = DateTime.now();
    return [
      Event(
        id: '1',
        title: '김성도님 생일',
        date: now.add(const Duration(days: 3)),
        type: 'birthday',
        description: '김성도님의 생일입니다',
      ),
      Event(
        id: '2',
        title: '주일 대예배',
        date: _getNextSunday(now),
        type: 'church',
        description: '매주 주일 오전 11시',
      ),
      Event(
        id: '3',
        title: '수요예배',
        date: _getNextWednesday(now),
        type: 'church',
        description: '매주 수요일 오후 7시 30분',
      ),
      Event(
        id: '4',
        title: '이장로님 생일',
        date: now.add(const Duration(days: 7)),
        type: 'birthday',
        description: '이장로님의 생일입니다',
      ),
      Event(
        id: '5',
        title: '청년부 모임',
        date: now.add(const Duration(days: 5)),
        type: 'church',
        description: '청년부 정기 모임',
      ),
      Event(
        id: '6',
        title: '새벽기도회',
        date: now.add(const Duration(days: 1)),
        type: 'church',
        description: '매일 새벽 5시 30분',
      ),
      Event(
        id: '7',
        title: '전도 활동',
        date: now.add(const Duration(days: 10)),
        type: 'church',
        description: '지역 전도 활동',
      ),
    ];
  }

  DateTime _getNextSunday(DateTime date) {
    final daysUntilSunday = (7 - date.weekday) % 7;
    return date.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }

  DateTime _getNextWednesday(DateTime date) {
    final daysUntilWednesday = (3 - date.weekday + 7) % 7;
    return date.add(Duration(days: daysUntilWednesday == 0 ? 7 : daysUntilWednesday));
  }

  void _filterEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    todayEvents = allEvents.where((event) {
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate.isAtSameMomentAs(today);
    }).toList();

    upcomingEvents = allEvents.where((event) {
      final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
      return eventDate.isAfter(today);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEventDialog();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '오늘'),
            Tab(text: '예정'),
            Tab(text: '전체'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildUpcomingTab(),
          _buildAllEventsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodayTab() {
    if (isLoading) {
      return const LoadingWidget();
    }
    
    if (todayEvents.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.today_outlined,
        title: '오늘 일정이 없습니다',
        subtitle: '좋은 하루 보내세요!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: Column(
        children: [
          // 오늘 날짜 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  _formatWeekday(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // 오늘 일정 목록
          Expanded(
            child: ListView.builder(
              itemCount: todayEvents.length,
              itemBuilder: (context, index) {
                final event = todayEvents[index];
                return _buildEventCard(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (isLoading) {
      return const LoadingWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: upcomingEvents.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.event_note,
              title: '예정된 일정이 없습니다',
              subtitle: '새로운 일정을 추가하세요!',
            )
          : ListView.builder(
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = upcomingEvents[index];
                return _buildEventCard(event);
              },
            ),
    );
  }

  Widget _buildAllEventsTab() {
    if (isLoading) {
      return const LoadingWidget();
    }
    

    // 월별로 그룹화
    final groupedEvents = <String, List<Event>>{};
    for (final event in allEvents) {
      final key = '${event.date.year}년 ${event.date.month}월';
      groupedEvents.putIfAbsent(key, () => []).add(event);
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        itemCount: groupedEvents.length,
        itemBuilder: (context, index) {
          final monthKey = groupedEvents.keys.elementAt(index);
          final monthEvents = groupedEvents[monthKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey[100],
                child: Text(
                  monthKey,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...monthEvents.map((event) => _buildEventCard(event)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventColor(event.type),
          child: Icon(
            _getEventIcon(event.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatEventDate(event.date),
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (event.description != null)
              Text(
                event.description!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editEvent(event);
                break;
              case 'delete':
                _deleteEvent(event);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('수정'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showEventDetail(event),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'birthday':
        return Colors.pink;
      case 'church':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'birthday':
        return Icons.cake;
      case 'church':
        return Icons.church;
      case 'personal':
        return Icons.person;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _formatWeekday(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${weekdays[date.weekday - 1]}요일';
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '내일';
    } else if (difference < 7) {
      return '${difference}일 후';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  void _showEventDetail(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getEventIcon(event.type), size: 16),
                const SizedBox(width: 8),
                Text(_getEventTypeText(event.type)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 8),
                Text(_formatEventDate(event.date)),
              ],
            ),
            if (event.description != null) ...[
              const SizedBox(height: 12),
              Text(event.description!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  String _getEventTypeText(String type) {
    switch (type) {
      case 'birthday':
        return '생일';
      case 'church':
        return '교회 행사';
      case 'personal':
        return '개인 일정';
      default:
        return '기타';
    }
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 추가'),
        content: const Text('일정 추가 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _editEvent(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${event.title} 수정 기능은 준비 중입니다')),
    );
  }

  void _deleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('${event.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                allEvents.removeWhere((e) => e.id == event.id);
                _filterEvents();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정이 삭제되었습니다')),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
