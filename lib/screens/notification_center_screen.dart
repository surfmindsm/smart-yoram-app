import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/notification.dart';
import '../models/push_notification.dart';
import '../models/api_response.dart';
import '../models/announcement.dart';
import '../resource/text_style_new.dart';
import '../resource/color_style_new.dart';
import '../services/notification_service.dart';
import '../services/badge_service.dart';
import '../services/announcement_service.dart';
import 'notification_settings_screen.dart';
import 'community/community_detail_screen.dart';
import 'notice_detail_screen.dart';

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
      final response = await _notificationService
          .getMyNotifications(
        limit: 100,
      )
          .timeout(
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
              .map((myNotification) =>
                  _convertToNotificationModel(myNotification))
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

    // relatedId와 relatedType은 MyNotification의 직접 필드에서 가져옴
    print(
        '📱 NOTIFICATION_CENTER: 알림 데이터 - ID: ${myNotification.id}, relatedId: ${myNotification.relatedId}, relatedType: ${myNotification.relatedType}');

    return NotificationModel(
      id: myNotification.id,
      title: myNotification.title,
      message: myNotification.body,
      category: category,
      createdAt: myNotification.createdAt,
      isRead: myNotification.isRead,
      isImportant: myNotification.type.toLowerCase() == 'important',
      userId: myNotification.userId,
      relatedId: myNotification.relatedId,
      relatedType: myNotification.relatedType,
      data: myNotification.data,
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      // 읽지 않은 알림들을 API를 통해 읽음 처리
      final unreadNotifications =
          notifications.where((n) => !n.isRead).toList();

      for (final notification in unreadNotifications) {
        await _notificationService.markNotificationAsRead(notification.id);
      }

      // 로컬 상태 업데이트
      setState(() {
        notifications = notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();
      });

      // 배지 업데이트 (모든 알림 읽음)
      BadgeService.instance.updateBadge().catchError((e) {
        print('❌ NOTIFICATION_CENTER: 배지 업데이트 실패 - $e');
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
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
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _markAllAsRead();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: NewAppColor.primary100,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          LucideIcons.checkCheck,
                          color: NewAppColor.primary600,
                          size: 20.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        '전체 읽기',
                        style: FigmaTextStyles().body1.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: NewAppColor.neutral200, indent: 20.w, endIndent: 20.w),
              // 전체 삭제
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _deleteAllNotifications();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: NewAppColor.danger100,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          LucideIcons.trash2,
                          color: NewAppColor.danger600,
                          size: 20.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        '전체 삭제',
                        style: FigmaTextStyles().body1.copyWith(
                              color: NewAppColor.danger600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.h),
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
      // 서버에서 알림 삭제
      final response = await _notificationService.deleteAllNotifications();

      if (response.success) {
        // 로컬 상태 업데이트
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: ${response.message}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 모든 알림 삭제 실패 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 삭제 중 오류가 발생했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 개별 알림 삭제
  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      print('🗑️ NOTIFICATION_CENTER: 알림 삭제 시작 - ID: ${notification.id}');

      // 서버에서 알림 삭제
      final response =
          await _notificationService.deleteNotification(notification.id);

      if (response.success) {
        // 로컬 상태 업데이트
        setState(() {
          notifications.removeWhere((n) => n.id == notification.id);
        });

        print('✅ NOTIFICATION_CENTER: 알림 삭제 완료');
      } else {
        print('❌ NOTIFICATION_CENTER: 알림 삭제 실패 - ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: ${response.message}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 알림 삭제 예외 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 삭제 중 오류가 발생했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 알림 클릭 시 관련 화면으로 이동
  Future<void> _navigateToNotificationTarget(
      NotificationModel notification) async {
    print(
        '📱 NOTIFICATION_CENTER: 알림 클릭 - 카테고리: ${notification.category}, relatedId: ${notification.relatedId}, relatedType: ${notification.relatedType}');

    try {
      switch (notification.category) {
        case NotificationCategory.like:
        case NotificationCategory.comment:
          // 좋아요, 댓글 알림 → 커뮤니티 게시글 상세로 이동
          if (notification.relatedId == null) {
            print('⚠️ NOTIFICATION_CENTER: relatedId가 없어 이동할 수 없습니다');
            return;
          }

          final tableName = notification.relatedType ?? 'community_sharing';
          final categoryTitle = _getCategoryTitle(tableName);

          print(
              '📱 NOTIFICATION_CENTER: 커뮤니티 게시글로 이동 - postId: ${notification.relatedId}, tableName: $tableName');

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetailScreen(
                postId: notification.relatedId!,
                tableName: tableName,
                categoryTitle: categoryTitle,
              ),
            ),
          );
          break;

        case NotificationCategory.message:
          // 메시지 알림 → 채팅 목록으로 이동 (채팅방 직접 이동은 ChatRoom 객체 필요)
          print('📱 NOTIFICATION_CENTER: 채팅 알림 - 채팅 목록으로 이동');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('채팅 탭에서 확인해주세요'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;

        case NotificationCategory.notice:
        case NotificationCategory.important:
          // 공지사항 알림 → 공지사항 상세 화면으로 이동
          print(
              '📱 NOTIFICATION_CENTER: 공지사항 알림 - relatedId: ${notification.relatedId}');
          if (notification.relatedId != null) {
            try {
              // relatedId로 공지사항 상세 조회
              final announcement = await _announcementService
                  .getAnnouncement(notification.relatedId!);

              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AnnouncementDetailScreen(announcement: announcement),
                  ),
                );
              }
            } catch (e) {
              print('❌ NOTIFICATION_CENTER: 공지사항 조회 실패 - $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('공지사항을 불러올 수 없습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } else {
            print('⚠️ NOTIFICATION_CENTER: relatedId가 없어 공지사항 탭으로 이동');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('공지사항 탭에서 확인해주세요'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
          break;

        case NotificationCategory.custom:
          // 관리자 커스텀 메시지 → 다이얼로그로 표시
          print('📱 NOTIFICATION_CENTER: 커스텀 메시지 알림 - 다이얼로그 표시');
          if (mounted) {
            _showCustomMessageDialog(notification);
          }
          break;

        case NotificationCategory.pastoralCare:
          // 심방 알림 → 심방 목록 화면으로 이동
          print('📱 NOTIFICATION_CENTER: 심방 알림 - 심방 신청 화면으로 이동 안내');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('심방 신청 화면에서 확인해주세요'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;

        case NotificationCategory.schedule:
        case NotificationCategory.attendance:
          // 일정, 출석 알림 → 현재는 별도 화면 없음 (추후 추가 가능)
          print(
              '📱 NOTIFICATION_CENTER: ${notification.category} 알림 - 별도 화면 없음');
          break;

        default:
          print(
              '📱 NOTIFICATION_CENTER: 알 수 없는 알림 타입 - ${notification.category}');
      }
    } catch (e) {
      print('❌ NOTIFICATION_CENTER: 화면 이동 실패 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('화면 이동에 실패했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // tableName을 카테고리 제목으로 변환
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

  // 관리자 커스텀 메시지 다이얼로그 표시
  void _showCustomMessageDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 + 제목
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: NewAppColor.primary100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: NewAppColor.primary600,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '교회 메시지',
                      style: FigmaTextStyles().headline4.copyWith(
                            color: NewAppColor.neutral900,
                          ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // 구분선
              Divider(height: 1, color: NewAppColor.neutral200),

              SizedBox(height: 20.h),

              // 제목
              if (notification.title.isNotEmpty) ...[
                Text(
                  notification.title,
                  style: FigmaTextStyles().title3.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                ),
                SizedBox(height: 12.h),
              ],

              // 내용
              Container(
                constraints: BoxConstraints(
                  maxHeight: 300.h,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    notification.message,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral800,
                          height: 1.6,
                        ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // 작성 시간
              Text(
                notification.timeAgo,
                style: FigmaTextStyles().caption2.copyWith(
                      color: NewAppColor.neutral500,
                    ),
              ),

              SizedBox(height: 20.h),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NewAppColor.primary600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: FigmaTextStyles().button1.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            // if (unreadCount > 0) _buildUnreadBanner(),

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
      color: Colors.transparent,
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
                  LucideIcons.chevronLeft,
                  color: NewAppColor.neutral800,
                  size: 20.w,
                ),
              ),
            ),
          ),

          // 제목
          Center(
            child: Text(
              '알림',
              style: const FigmaTextStyles()
                  .headline4
                  .copyWith(color: NewAppColor.neutral800),
            ),
          ),

          // 우측 버튼들
          Positioned(
            right: 20.w,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                // 더보기 메뉴 아이콘
                GestureDetector(
                  onTap: _showDeleteMenu,
                  child: Container(
                    width: 28.w,
                    height: 28.h,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.more_vert,
                      color: NewAppColor.neutral800,
                      size: 22.w,
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
                      LucideIcons.settings,
                      color: NewAppColor.neutral800,
                      size: 22.w,
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
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        color: NewAppColor.primary600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200.h,
            child: Center(
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
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: NewAppColor.primary600,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Slidable(
          key: Key('notification_${notification.id}'),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.3,
            children: [
              SlidableAction(
                onPressed: (context) async {
                  // 삭제 확인 다이얼로그
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('알림 삭제'),
                      content: const Text('이 알림을 삭제하시겠습니까?'),
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

                  if (confirmed == true) {
                    await _deleteNotification(notification);
                  }
                },
                backgroundColor: NewAppColor.danger600,
                foregroundColor: Colors.white,
                label: '삭제',
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
          child: NotificationItem(
            notification: notification,
            onTap: () async {
              // 알림 읽음 처리
              if (!notification.isRead) {
                try {
                  // API를 통해 읽음 처리
                  await _notificationService
                      .markNotificationAsRead(notification.id);

                  // 로컬 상태 업데이트
                  setState(() {
                    final notificationIndex = notifications
                        .indexWhere((n) => n.id == notification.id);
                    if (notificationIndex != -1) {
                      notifications[notificationIndex] =
                          notification.copyWith(isRead: true);
                    }
                  });

                  // 배지 업데이트 (알림 읽음)
                  BadgeService.instance.updateBadge().catchError((e) {
                    print('❌ NOTIFICATION_CENTER: 배지 업데이트 실패 - $e');
                  });
                } catch (e) {
                  print('❌ NOTIFICATION_CENTER: 알림 읽음 처리 실패 - $e');
                }
              }

              // 관련 화면으로 이동
              await _navigateToNotificationTarget(notification);
            },
          ),
        );
        },
      ),
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

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.notice:
        return Icons.campaign_outlined;
      case NotificationCategory.important:
        return Icons.error_outline;
      case NotificationCategory.schedule:
        return Icons.event_outlined;
      case NotificationCategory.attendance:
        return Icons.fact_check_outlined;
      case NotificationCategory.message:
        return Icons.chat_bubble_outline;
      case NotificationCategory.like:
        return Icons.favorite;
      case NotificationCategory.comment:
        return Icons.mode_comment_outlined;
      case NotificationCategory.custom:
        return Icons.campaign;
      case NotificationCategory.pastoralCare:
        return Icons.home_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryStyle = notification.category.style;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : Color(categoryStyle.backgroundColor).withValues(alpha: 0.9),
          // borderRadius: BorderRadius.circular(8.r),
          // border: Border.all(
          //   color: notification.isRead
          //       ? NewAppColor.neutral200
          //       : Color(categoryStyle.borderColor).withOpacity(0.3),
          // ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측 아이콘
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Icon(
                _getCategoryIcon(notification.category),
                color: Color(categoryStyle.textColor),
                size: 16.w,
              ),
            ),

            SizedBox(width: 10.w),

            // 카드 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 분류 타이틀 + 시간
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 분류 타이틀
                      Text(
                        notification.category.displayName,
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral600,
                              // fontWeight: FontWeight.w600,
                            ),
                      ),

                      // 시간
                      Text(
                        notification.timeAgo,
                        style: const FigmaTextStyles().caption2.copyWith(
                              color: NewAppColor.neutral500,
                            ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // 알림 내용
                  Text(
                    notification.displayMessage,
                    style: const FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
