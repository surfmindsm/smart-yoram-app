import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/index.dart';
import '../models/notification.dart';
import '../models/push_notification.dart';
import '../models/api_response.dart';
import '../resource/text_style_new.dart';
import '../resource/color_style_new.dart';
import '../services/notification_service.dart';
import '../services/badge_service.dart';
import '../services/announcement_service.dart';
import 'notification_settings_screen.dart';
import 'community/community_detail_screen.dart';
import 'notice_detail_screen.dart';

/// 알림 화면 — 1.2.0 C 방향
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  final AnnouncementService _announcementService = AnnouncementService();
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    print('📱 NOTIFICATION_CENTER: 알림 로드 시작');
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response = await _notificationService
          .getMyNotifications(limit: 100)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => ApiResponse.error('타임아웃'),
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          notifications = response.data!
              .map((my) => _convertToNotificationModel(my))
              .toList();
        });
      } else {
        setState(() => notifications = []);
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ NOTIFICATION_CENTER: 알림 로드 실패 - $e');
      setState(() => notifications = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  NotificationModel _convertToNotificationModel(MyNotification my) {
    NotificationCategory category;
    switch (my.type.toLowerCase()) {
      case 'announcement':
      case 'notice':
        category = NotificationCategory.notice;
        break;
      case 'important':
        category = NotificationCategory.important;
        break;
      case 'schedule':
      case 'worship':
        category = NotificationCategory.schedule;
        break;
      case 'attendance':
        category = NotificationCategory.attendance;
        break;
      case 'message':
      case 'chat':
        category = NotificationCategory.message;
        break;
      case 'like':
        category = NotificationCategory.like;
        break;
      case 'comment':
        category = NotificationCategory.comment;
        break;
      case 'custom':
      case 'custom_message':
        category = NotificationCategory.custom;
        break;
      case 'pastoral_care_request':
      case 'pastoral_care_approved':
      case 'pastoral_care':
        category = NotificationCategory.pastoralCare;
        break;
      default:
        category = NotificationCategory.notice;
    }

    return NotificationModel(
      id: my.id,
      title: my.title,
      message: my.body,
      category: category,
      createdAt: my.createdAt,
      isRead: my.isRead,
      isImportant: my.type.toLowerCase() == 'important',
      userId: my.userId,
      relatedId: my.relatedId,
      relatedType: my.relatedType,
      data: my.data,
    );
  }

  int get unreadCount =>
      notifications.where((n) => !n.isRead).length;

  Future<void> _markAllAsRead() async {
    try {
      final unread = notifications.where((n) => !n.isRead).toList();
      for (final n in unread) {
        await _notificationService.markNotificationAsRead(n.id);
      }
      setState(() {
        notifications =
            notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      BadgeService.instance.updateBadge().catchError((e) {
        print('❌ NOTIFICATION_CENTER: 배지 업데이트 실패 - $e');
      });
      if (mounted) AppToast.success(context, '모든 알림을 읽음 처리했습니다');
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 전체 읽음 처리 실패 - $e');
      if (mounted) AppToast.error(context, '읽음 처리 중 오류가 발생했습니다');
    }
  }

  // 더보기 메뉴 — AppMenuSheet 헬퍼 사용
  void _showDeleteMenu() {
    AppMenuSheet.show(
      context: context,
      items: [
        AppMenuItem(
          icon: LucideIcons.checkCheck,
          label: '모두 읽음',
          enabled: unreadCount > 0,
          onTap: _markAllAsRead,
        ),
        AppMenuItem(
          icon: LucideIcons.trash2,
          label: '전체 삭제',
          danger: true,
          enabled: notifications.isNotEmpty,
          onTap: _confirmDeleteAll,
        ),
      ],
    );
  }

  void _goToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '모든 알림을 삭제할까요?',
      description: '삭제한 알림은 되돌릴 수 없어요.',
      confirmLabel: '삭제',
      tone: AppSheetTone.danger,
    );
    if (ok == true) await _deleteAllNotifications();
  }

  Future<void> _confirmDeleteOne(NotificationModel notification) async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '알림을 삭제할까요?',
      description: '삭제한 알림은 되돌릴 수 없어요.',
      confirmLabel: '삭제',
      tone: AppSheetTone.danger,
    );
    if (ok == true) await _deleteNotification(notification);
  }

  Future<void> _deleteAllNotifications() async {
    try {
      final response = await _notificationService.deleteAllNotifications();
      if (response.success) {
        setState(() => notifications.clear());
        if (mounted) AppToast.success(context, '모든 알림을 삭제했습니다');
      } else {
        if (mounted) AppToast.error(context, '삭제 실패: ${response.message}');
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 모든 알림 삭제 실패 - $e');
      if (mounted) AppToast.error(context, '알림 삭제 중 오류가 발생했습니다');
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      final response =
          await _notificationService.deleteNotification(notification.id);
      if (response.success) {
        setState(() {
          notifications.removeWhere((n) => n.id == notification.id);
        });
        if (mounted) AppToast.success(context, '알림을 삭제했습니다');
      } else {
        if (mounted) AppToast.error(context, '삭제 실패: ${response.message}');
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 알림 삭제 예외 - $e');
      if (mounted) AppToast.error(context, '알림 삭제 중 오류가 발생했습니다');
    }
  }

  Future<void> _navigateToNotificationTarget(
      NotificationModel notification) async {
    try {
      switch (notification.category) {
        case NotificationCategory.like:
        case NotificationCategory.comment:
          if (notification.relatedId == null) return;
          final tableName = notification.relatedType ?? 'community_sharing';
          final categoryTitle = _getCategoryTitle(tableName);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityDetailScreen(
                postId: notification.relatedId!,
                tableName: tableName,
                categoryTitle: categoryTitle,
              ),
            ),
          );
          break;

        case NotificationCategory.message:
          if (mounted) AppToast.show(context, '채팅 탭에서 확인해주세요');
          break;

        case NotificationCategory.notice:
        case NotificationCategory.important:
          if (notification.relatedId != null) {
            try {
              final announcement = await _announcementService
                  .getAnnouncement(notification.relatedId!);
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnnouncementDetailScreen(announcement: announcement),
                  ),
                );
              }
            } catch (e) {
              if (mounted) AppToast.error(context, '공지사항을 불러올 수 없습니다');
            }
          } else {
            if (mounted) AppToast.show(context, '공지사항 탭에서 확인해주세요');
          }
          break;

        case NotificationCategory.custom:
          if (mounted) _showCustomMessageSheet(notification);
          break;

        case NotificationCategory.pastoralCare:
          if (mounted) AppToast.show(context, '심방 신청 화면에서 확인해주세요');
          break;

        case NotificationCategory.schedule:
        case NotificationCategory.attendance:
          break;

        default:
          break;
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 화면 이동 실패 - $e');
      if (mounted) AppToast.error(context, '화면 이동에 실패했습니다');
    }
  }

  String _getCategoryTitle(String tableName) {
    switch (tableName) {
      case 'community_sharing':
        return '무료나눔/물품판매';
      case 'community_requests':
        return '물품 요청';
      case 'music_team_recruit':
        return '행사팀 모집';
      case 'music_seekers':
        return '행사팀 지원';
      case 'church_news':
        return '행사 소식';
      default:
        return '커뮤니티';
    }
  }

  // 관리자 커스텀 메시지 시트 — AppInfoSheet 헬퍼 사용
  void _showCustomMessageSheet(NotificationModel notification) {
    AppInfoSheet.show(
      context: context,
      title: '교회 메시지',
      icon: LucideIcons.megaphone,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.title.isNotEmpty) ...[
            Text(
              notification.title,
              style: TextStyle(
                color: NewAppColor.textStrong,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
                height: 1.4,
              ),
            ),
            SizedBox(height: 10.h),
          ],
          Text(
            notification.message,
            style: TextStyle(
              color: NewAppColor.textBody,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              height: 1.65,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            notification.timeAgo,
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '알림',
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          material.IconButton(
            icon: Icon(LucideIcons.ellipsis,
                color: NewAppColor.textStrong, size: 22.sp),
            onPressed: _showDeleteMenu,
          ),
          material.IconButton(
            icon: Icon(LucideIcons.settings,
                color: NewAppColor.textStrong, size: 20.sp),
            onPressed: _goToNotificationSettings,
          ),
          SizedBox(width: 4.w),
        ],
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: NewAppColor.skyPrimary),
            )
          : notifications.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: NewAppColor.skyPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200.h,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.bell,
                    size: 56.sp, color: NewAppColor.iconFaint),
                SizedBox(height: 14.h),
                Text(
                  '알림이 없습니다',
                  style: FigmaTextStyles().subtitle2.copyWith(
                        color: NewAppColor.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: NewAppColor.skyPrimary,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => SizedBox(height: 6.h),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Slidable(
            key: Key('notification_${notification.id}'),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                SlidableAction(
                  onPressed: (_) => _confirmDeleteOne(notification),
                  backgroundColor: NewAppColor.danger700,
                  foregroundColor: Colors.white,
                  icon: LucideIcons.trash2,
                  label: '삭제',
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
            child: _NotificationTile(
              notification: notification,
              onTap: () async {
                if (!notification.isRead) {
                  try {
                    await _notificationService
                        .markNotificationAsRead(notification.id);
                    setState(() {
                      final i = notifications
                          .indexWhere((n) => n.id == notification.id);
                      if (i != -1) {
                        notifications[i] =
                            notification.copyWith(isRead: true);
                      }
                    });
                    BadgeService.instance.updateBadge().catchError((e) {
                      print('❌ NOTIFICATION_CENTER: 배지 업데이트 실패 - $e');
                    });
                  } catch (e) {
                    print('❌ NOTIFICATION_CENTER: 읽음 처리 실패 - $e');
                  }
                }
                await _navigateToNotificationTarget(notification);
              },
            ),
          );
        },
      ),
    );
  }
}

/// 1.2.0 알림 카드 — 좌측 톤별 아이콘 타일 + 카테고리/시간 + 제목·메시지 + 미읽음 도트
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.notice:
        return LucideIcons.megaphone;
      case NotificationCategory.important:
        return LucideIcons.circleAlert;
      case NotificationCategory.schedule:
        return LucideIcons.calendar;
      case NotificationCategory.attendance:
        return LucideIcons.clipboardCheck;
      case NotificationCategory.message:
        return LucideIcons.messageCircle;
      case NotificationCategory.like:
        return LucideIcons.heart;
      case NotificationCategory.comment:
        return LucideIcons.messageSquare;
      case NotificationCategory.custom:
        return LucideIcons.megaphone;
      case NotificationCategory.pastoralCare:
        return LucideIcons.house;
      case NotificationCategory.all:
        return LucideIcons.bell;
    }
  }

  // 카테고리별 톤 — 시안에 맞춘 매핑
  ({Color bg, Color fg}) _toneFor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.important:
        return (bg: NewAppColor.dangerBg, fg: NewAppColor.danger700);
      case NotificationCategory.attendance:
      case NotificationCategory.pastoralCare:
        return (bg: NewAppColor.successBg, fg: NewAppColor.success700);
      case NotificationCategory.notice:
      case NotificationCategory.schedule:
        return (bg: NewAppColor.warningBg, fg: NewAppColor.warning700);
      case NotificationCategory.message:
      case NotificationCategory.comment:
        return (bg: NewAppColor.borderSoft, fg: NewAppColor.textSecondary);
      case NotificationCategory.all:
      case NotificationCategory.like:
      case NotificationCategory.custom:
        return (bg: NewAppColor.skyTint, fg: NewAppColor.skyDeep);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(notification.category);
    final isUnread = !notification.isRead;
    final body = _cleanBody(notification.displayMessage);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Material(
        color: isUnread ? NewAppColor.skyTint : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 13.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: tone.bg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _getCategoryIcon(notification.category),
                    color: tone.fg,
                    size: 19.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        body,
                        style: TextStyle(
                          color: NewAppColor.textStrong,
                          fontSize: 13.5.sp,
                          fontWeight:
                              isUnread ? FontWeight.w700 : FontWeight.w600,
                          fontFamily: 'Pretendard',
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          color: NewAppColor.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnread) ...[
                  SizedBox(width: 8.w),
                  Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(
                      color: NewAppColor.skyPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 본문 끝에 ": general"/": urgent" 같은 raw category 꼬리 제거
  String _cleanBody(String body) {
    final trimmed = body.trim();
    final match = RegExp(r':\s*[a-zA-Z_]+$').firstMatch(trimmed);
    if (match != null) {
      return trimmed.substring(0, match.start).trim();
    }
    return trimmed;
  }
}
