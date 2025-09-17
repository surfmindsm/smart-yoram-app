import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String _selectedFilter = '전체';
  final List<String> _filterOptions = ['전체', '중요', '공지', '일정', '출석'];
  
  // 샘플 알림 데이터
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: '주일예배 안내',
      message: '이번 주 주일예배는 오전 11시에 시작됩니다.',
      type: NotificationType.important,
      isRead: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      icon: LucideIcons.church,
    ),
    NotificationItem(
      id: '2',
      title: '새로운 공지사항',
      message: '교회 리모델링 계획에 대한 공지사항이 등록되었습니다.',
      type: NotificationType.notice,
      isRead: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      icon: LucideIcons.megaphone,
    ),
    NotificationItem(
      id: '3',
      title: '출석 체크 완료',
      message: '오늘 주일예배 출석이 확인되었습니다.',
      type: NotificationType.attendance,
      isRead: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      icon: LucideIcons.checkCircle,
    ),
    NotificationItem(
      id: '4',
      title: '생일 축하',
      message: '김성도님의 생일을 축하합니다! 🎉',
      type: NotificationType.schedule,
      isRead: true,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: LucideIcons.cake,
    ),
    NotificationItem(
      id: '5',
      title: '기도 요청',
      message: '새로운 기도 요청이 등록되었습니다.',
      type: NotificationType.notice,
      isRead: false,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      icon: LucideIcons.heart,
    ),
  ];

  List<NotificationItem> get filteredNotifications {
    if (_selectedFilter == '전체') return _notifications;
    
    final typeMap = {
      '중요': NotificationType.important,
      '공지': NotificationType.notice,
      '일정': NotificationType.schedule,
      '출석': NotificationType.attendance,
    };
    
    final filterType = typeMap[_selectedFilter];
    if (filterType != null) {
      return _notifications.where((notification) => notification.type == filterType).toList();
    }
    
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림센터'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                '모두 읽음',
                style: TextStyle(color: Colors.white),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical),
            onSelected: (value) {
              if (value == 'settings') {
                _showNotificationSettings();
              } else if (value == 'clear') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(LucideIcons.settings),
                    SizedBox(width: 8),
                    Text('알림 설정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash),
                    SizedBox(width: 8),
                    Text('모든 알림 삭제'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 탭
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        }
                      },
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[700],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // 알림 통계
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.bell, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    '읽지 않은 알림 $unreadCount개',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // 알림 리스트
          Expanded(
            child: filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.bellOff,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 알림이 있으면 여기에 표시됩니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 1 : 3,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.icon,
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: notification.isRead ? Colors.grey[600] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildNotificationTypeChip(notification.type),
                const Spacer(),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'read') {
              _markAsRead(notification.id);
            } else if (value == 'delete') {
              _deleteNotification(notification.id);
            }
          },
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle),
                    SizedBox(width: 8),
                    Text('읽음 표시'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash),
                  SizedBox(width: 8),
                  Text('삭제'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeChip(NotificationType type) {
    final typeInfo = _getNotificationTypeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: typeInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeInfo['color'].withOpacity(0.3)),
      ),
      child: Text(
        typeInfo['label'],
        style: TextStyle(
          fontSize: 11,
          color: typeInfo['color'],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.important:
        return Colors.red;
      case NotificationType.notice:
        return Colors.blue;
      case NotificationType.schedule:
        return Colors.green;
      case NotificationType.attendance:
        return Colors.orange;
    }
  }

  Map<String, dynamic> _getNotificationTypeInfo(NotificationType type) {
    switch (type) {
      case NotificationType.important:
        return {'label': '중요', 'color': Colors.red};
      case NotificationType.notice:
        return {'label': '공지', 'color': Colors.blue};
      case NotificationType.schedule:
        return {'label': '일정', 'color': Colors.green};
      case NotificationType.attendance:
        return {'label': '출석', 'color': Colors.orange};
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }
    
    // TODO: 알림 유형에 따른 화면 이동
    switch (notification.type) {
      case NotificationType.notice:
        // 공지사항 화면으로 이동
        break;
      case NotificationType.schedule:
        // 캘린더 화면으로 이동
        break;
      case NotificationType.attendance:
        // 출석 화면으로 이동
        break;
      default:
        break;
    }
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 알림 삭제'),
        content: const Text('모든 알림을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알림 설정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('푸시 알림'),
              subtitle: const Text('앱 알림 받기'),
              value: true,
              onChanged: (value) {
                // TODO: 푸시 알림 설정 저장
              },
            ),
            SwitchListTile(
              title: const Text('공지사항 알림'),
              subtitle: const Text('새로운 공지사항 알림'),
              value: true,
              onChanged: (value) {
                // TODO: 공지사항 알림 설정 저장
              },
            ),
            SwitchListTile(
              title: const Text('일정 알림'),
              subtitle: const Text('교회 행사 및 개인 일정 알림'),
              value: true,
              onChanged: (value) {
                // TODO: 일정 알림 설정 저장
              },
            ),
            SwitchListTile(
              title: const Text('출석 알림'),
              subtitle: const Text('출석 체크 관련 알림'),
              value: false,
              onChanged: (value) {
                // TODO: 출석 알림 설정 저장
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum NotificationType {
  important,
  notice,
  schedule,
  attendance,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime timestamp;
  final IconData icon;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timestamp,
    required this.icon,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? timestamp,
    IconData? icon,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      icon: icon ?? this.icon,
    );
  }
}
