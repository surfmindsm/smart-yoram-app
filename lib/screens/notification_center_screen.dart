import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/notification.dart';
import '../models/push_notification.dart';
import '../models/api_response.dart';
import '../resource/text_style_new.dart';
import '../resource/color_style_new.dart';
import '../services/notification_service.dart';
import 'notification_settings_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // 실제 알림 데이터 로드
  Future<void> _loadNotifications() async {
    print('📱 NOTIFICATION_CENTER: 알림 로드 시작');
    final startTime = DateTime.now();

    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      print('📱 NOTIFICATION_CENTER: API 호출 중...');
      final response = await _notificationService.getMyNotifications(
        limit: 100,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ NOTIFICATION_CENTER: API 타임아웃 (10초)');
          return ApiResponse.error('타임아웃');
        },
      );

      if (!mounted) return;

      final duration = DateTime.now().difference(startTime);
      print('📱 NOTIFICATION_CENTER: API 응답 완료 (${duration.inSeconds}초)');

      if (response.success && response.data != null) {
        print('✅ NOTIFICATION_CENTER: 알림 ${response.data!.length}개 로드 성공');
        setState(() {
          notifications = response.data!
              .map((myNotification) => _convertToNotificationModel(myNotification))
              .toList();
        });
      } else {
        print('❌ NOTIFICATION_CENTER: API 응답 실패 - ${response.message}');
        // 실패 시 빈 리스트 표시
        setState(() {
          notifications = [];
        });
      }
    } catch (e) {
      if (!mounted) return;

      final duration = DateTime.now().difference(startTime);
      print('❌ NOTIFICATION_CENTER: 알림 로드 실패 (${duration.inSeconds}초) - $e');
      // 에러 시 빈 리스트 표시
      setState(() {
        notifications = [];
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      final totalDuration = DateTime.now().difference(startTime);
      print('📱 NOTIFICATION_CENTER: 로딩 완료 (총 ${totalDuration.inSeconds}초)');
    }
  }

  // MyNotification을 NotificationModel로 변환
  NotificationModel _convertToNotificationModel(MyNotification myNotification) {
    // type 문자열을 NotificationCategory로 매핑
    NotificationCategory category;
    switch (myNotification.type.toLowerCase()) {
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
      default:
        category = NotificationCategory.notice;
    }

    return NotificationModel(
      id: myNotification.id,
      title: myNotification.title,
      message: myNotification.body,
      category: category,
      createdAt: myNotification.createdAt,
      isRead: myNotification.isRead,
      isImportant: myNotification.type.toLowerCase() == 'important',
      userId: myNotification.userId,
      relatedId: myNotification.data?['related_id'] as int?,
      relatedType: myNotification.data?['related_type'] as String?,
      data: myNotification.data,
    );
  }


  Future<void> _markAllAsRead() async {
    try {
      // 읽지 않은 알림들을 API를 통해 읽음 처리
      final unreadNotifications = notifications.where((n) => !n.isRead).toList();

      for (final notification in unreadNotifications) {
        await _notificationService.markNotificationAsRead(notification.id);
      }

      // 로컬 상태 업데이트
      setState(() {
        notifications = notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 알림을 읽음 처리했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 모든 알림 읽음 처리 실패 - $e');
    }
  }

  int get unreadCount {
    return notifications.where((notification) => !notification.isRead).length;
  }

  // 삭제 메뉴 표시
  void _showDeleteMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              // 핸들
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: NewAppColor.neutral300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              // 전체 읽기
              ListTile(
                leading: Icon(
                  Icons.done_all,
                  color: NewAppColor.neutral800,
                ),
                title: Text(
                  '전체 읽기',
                  style: FigmaTextStyles().body2,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _markAllAsRead();
                },
              ),
              Divider(height: 1, color: NewAppColor.neutral200),
              // 전체 삭제
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: NewAppColor.danger600,
                ),
                title: Text(
                  '전체 삭제',
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.danger600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAllNotifications();
                },
              ),
              Divider(height: 1, color: NewAppColor.neutral200),
              // 닫기
              ListTile(
                leading: Icon(
                  Icons.close,
                  color: NewAppColor.neutral800,
                ),
                title: Text(
                  '닫기',
                  style: FigmaTextStyles().body2,
                ),
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // 알림 설정 화면으로 이동
  void _goToNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  Future<void> _deleteAllNotifications() async {
    // 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 삭제'),
        content: const Text('모든 알림을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 알림 삭제는 백엔드 API에서 지원하지 않으므로 로컬에서만 처리
      setState(() {
        notifications.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 알림을 삭제했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 모든 알림 삭제 실패 - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 읽지 않은 알림 배너
            if (unreadCount > 0) _buildUnreadBanner(),

            // 알림 리스트
            Expanded(
              child: _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56.h,
      color: NewAppColor.primary600,
      child: Stack(
        children: [
          // 뒤로가기 버튼
          Positioned(
            left: 20.w,
            top: 14.h,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 28.w,
                height: 28.h,
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
            ),
          ),

          // 제목
          Center(
            child: Text(
              '알림센터',
              style: const FigmaTextStyles()
                  .headline4
                  .copyWith(color: Colors.white),
            ),
          ),

          // 우측 버튼들
          Positioned(
            right: 20.w,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                // 삭제 아이콘
                GestureDetector(
                  onTap: _showDeleteMenu,
                  child: Container(
                    width: 28.w,
                    height: 28.h,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // 설정 아이콘
                GestureDetector(
                  onTap: _goToNotificationSettings,
                  child: Container(
                    width: 28.w,
                    height: 28.h,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: NewAppColor.primary200,
        border: Border.all(color: NewAppColor.primary400),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: NewAppColor.primary600,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.notifications,
              color: Colors.white,
              size: 14.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              '읽지 않은 알림 $unreadCount개',
              style: const FigmaTextStyles()
                  .title4
                  .copyWith(color: NewAppColor.primary600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            NewAppColor.primary600,
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64.w,
              color: NewAppColor.neutral500,
            ),
            SizedBox(height: 16.h),
            Text(
              '알림이 없습니다',
              style: const FigmaTextStyles()
                  .bodyText2
                  .copyWith(color: NewAppColor.neutral500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationItem(
          notification: notification,
          onTap: () async {
            // 알림 상세 보기 또는 읽음 처리
            if (!notification.isRead) {
              try {
                // API를 통해 읽음 처리
                await _notificationService.markNotificationAsRead(notification.id);

                // 로컬 상태 업데이트
                setState(() {
                  final notificationIndex =
                      notifications.indexWhere((n) => n.id == notification.id);
                  if (notificationIndex != -1) {
                    notifications[notificationIndex] =
                        notification.copyWith(isRead: true);
                  }
                });
              } catch (e) {
                print('❌ NOTIFICATION_CENTER: 알림 읽음 처리 실패 - $e');
              }
            }
          },
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryStyle = notification.category.style;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: NewAppColor.neutral200),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 카테고리 뱃지와 메타 정보
                  Row(
                    children: [
                      // 카테고리 뱃지
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Color(categoryStyle.backgroundColor),
                          border: Border.all(
                              color: Color(categoryStyle.borderColor)),
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Text(
                          notification.category.displayName,
                          style: const FigmaTextStyles()
                              .caption2
                              .copyWith(color: Color(categoryStyle.textColor)),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // 제목
                      Text(
                        notification.title,
                        style: const FigmaTextStyles()
                            .body3
                            .copyWith(color: NewAppColor.neutral500),
                      ),

                      SizedBox(width: 4.w),

                      // 구분점
                      Text(
                        '•',
                        style: const FigmaTextStyles()
                            .caption2
                            .copyWith(color: NewAppColor.neutral500),
                      ),

                      SizedBox(width: 4.w),

                      // 시간
                      Text(
                        notification.timeAgo,
                        style: const FigmaTextStyles()
                            .caption2
                            .copyWith(color: NewAppColor.neutral500),
                      ),

                      // 읽지 않음 표시
                      if (!notification.isRead) ...[
                        SizedBox(width: 4.w),
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: NewAppColor.danger600,
                            borderRadius: BorderRadius.circular(3.5.r),
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // 메시지 내용
                  Text(
                    notification.message,
                    style: const FigmaTextStyles()
                        .bodyText2
                        .copyWith(color: NewAppColor.neutral800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // // 더보기 버튼
            // GestureDetector(
            //   onTap: () {
            //     // 알림 상세 또는 메뉴 액션
            //   },
            //   child: Container(
            //     width: 24.w,
            //     height: 24.h,
            //     alignment: Alignment.center,
            //     child: Icon(
            //       Icons.more_horiz,
            //       color: NewAppColor.neutral500,
            //       size: 20.w,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
