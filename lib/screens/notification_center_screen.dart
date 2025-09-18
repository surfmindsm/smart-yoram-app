import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/notification.dart';
import '../resource/text_style_new.dart';
import '../resource/color_style_new.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  NotificationCategory selectedCategory = NotificationCategory.all;
  List<NotificationModel> notifications = [];
  List<NotificationModel> filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadDemoData();
  }

  void _loadDemoData() {
    // 데모 데이터 생성
    notifications = [
      NotificationModel(
        id: 1,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.important,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        isImportant: true,
      ),
      NotificationModel(
        id: 2,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.notice,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 3,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.attendance,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 4,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.schedule,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 5,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.important,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        isImportant: true,
      ),
      NotificationModel(
        id: 6,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.notice,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 7,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.attendance,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 8,
        title: '주일예배 안내',
        message: '이번 주 주일예배는 오전 11시에 시작됩니다. 와다다다다다다다다다다다다다다',
        category: NotificationCategory.schedule,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
    ];
    _filterNotifications();
  }

  void _filterNotifications() {
    if (selectedCategory == NotificationCategory.all) {
      filteredNotifications = notifications;
    } else {
      filteredNotifications = notifications.where((notification) {
        return notification.category == selectedCategory;
      }).toList();
    }
    setState(() {});
  }

  void _onCategorySelected(NotificationCategory category) {
    selectedCategory = category;
    _filterNotifications();
  }

  void _markAllAsRead() {
    setState(() {
      notifications = notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
    });
    _filterNotifications();
  }

  int get unreadCount {
    return notifications.where((notification) => !notification.isRead).length;
  }

  void _showNotificationMenu(BuildContext context) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      elevation: 8,
      items: [
        PopupMenuItem(
          value: 'settings',
          height: 32.h,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context, 'settings'),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
              child: Container(
                width: 96.w,
                height: 32.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.r),
                    topRight: Radius.circular(8.r),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: NewAppColor.neutral100),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '알림 설정',
                    style: const FigmaTextStyles()
                        .caption1
                        .copyWith(color: NewAppColor.neutral800),
                  ),
                ),
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'delete_all',
          height: 32.h,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context, 'delete_all'),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
              ),
              child: Container(
                width: 96.w,
                height: 32.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8.r),
                    bottomRight: Radius.circular(8.r),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '모든 알림 삭제',
                    style: const FigmaTextStyles()
                        .caption1
                        .copyWith(color: NewAppColor.neutral800),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'settings') {
        // 알림 설정 화면으로 이동
      } else if (value == 'delete_all') {
        _deleteAllNotifications();
      }
    });
  }

  void _deleteAllNotifications() {
    setState(() {
      notifications.clear();
    });
    _filterNotifications();
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

            // 카테고리 필터
            _buildCategoryFilter(),

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '알림센터',
                  style: const FigmaTextStyles()
                      .headline4
                      .copyWith(color: Colors.white),
                ),
                SizedBox(width: 8.w),
              ],
            ),
          ),
          // 모두 읽음 버튼
          Positioned(
            right: 45.w,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _markAllAsRead,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: NewAppColor.neutral100),
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    '모두 읽음',
                    style: const FigmaTextStyles()
                        .caption1
                        .copyWith(color: NewAppColor.neutral100),
                  ),
                ),
              ),
            ),
          ),

          // 메뉴 버튼
          Positioned(
            right: 20.w,
            top: 16.h,
            child: Builder(
              builder: (BuildContext menuContext) => GestureDetector(
                onTap: () {
                  _showNotificationMenu(menuContext);
                },
                child: Container(
                  width: 24.w,
                  height: 24.h,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20.w,
                  ),
                ),
              ),
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

  Widget _buildCategoryFilter() {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NewAppColor.neutral200),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: NotificationCategory.values.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final category = NotificationCategory.values[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: Container(
              height: 36.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? NewAppColor.primary600
                    : NewAppColor.neutral100,
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Center(
                child: Text(
                  category.displayName,
                  style: const FigmaTextStyles().caption1.copyWith(
                        color:
                            isSelected ? Colors.white : NewAppColor.neutral800,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList() {
    if (filteredNotifications.isEmpty) {
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
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return NotificationItem(
          notification: notification,
          onTap: () {
            // 알림 상세 보기 또는 읽음 처리
            if (!notification.isRead) {
              setState(() {
                final notificationIndex =
                    notifications.indexWhere((n) => n.id == notification.id);
                if (notificationIndex != -1) {
                  notifications[notificationIndex] =
                      notification.copyWith(isRead: true);
                }
              });
              _filterNotifications();
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
