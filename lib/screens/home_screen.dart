import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
import 'package:smart_yoram_app/resource/text_style.dart';
import '../widget/widgets.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/member_service.dart';
import '../services/church_service.dart';
import '../services/announcement_service.dart';
import '../services/daily_verse_service.dart';

import '../models/user.dart' as app_user;
import '../models/member.dart';
import '../models/church.dart';
import '../models/announcement.dart';
import '../models/daily_verse.dart';

import 'calendar_screen.dart';
import 'prayer_screen.dart';
import 'settings_screen.dart';
import 'qr_scan_screen.dart';
import 'notice_detail_screen.dart';
import 'notification_center_screen.dart';
import 'staff_directory_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final MemberService _memberService = MemberService();
  final ChurchService _churchService = ChurchService();
  final AnnouncementService _announcementService = AnnouncementService();
  final DailyVerseService _dailyVerseService = DailyVerseService();

  app_user.User? currentUser;
  Member? currentMember;
  Church? currentChurch;
  Map<String, dynamic>? churchInfo;
  Map<String, dynamic>? userStats;
  bool isLoading = true;
  bool _isChurchCardExpanded = true; // 교회 카드 펼침 상태

  // 최근 공지사항 관련 상태 변수
  List<Announcement> recentAnnouncements = [];
  bool _isLoadingAnnouncements = false;

  // 오늘의 말씀 관련 상태 변수
  DailyVerse? _currentVerse;
  bool _isRefreshingVerse = false;
  bool _isLoadingVerse = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadTodaysVerse();
  }

  Future<void> _loadDashboardData() async {
    try {
      // 현재 사용자 정보 로드
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        currentUser = userResponse.data!;

        // 현재 사용자의 교인 정보 조회
        final membersResponse = await _memberService.getMembers(limit: 1000);
        if (membersResponse.success && membersResponse.data != null) {
          // 현재 사용자의 email과 일치하는 교인 찾기
          final members = membersResponse.data!;
          currentMember = members.firstWhere(
            (member) => member.email == currentUser!.email,
            orElse: () => Member(
              id: 0,
              name: currentUser!.fullName,
              email: currentUser!.email,
              gender: '',
              phone: '',
              churchId: currentUser!.churchId,
              memberStatus: 'active',
              createdAt: DateTime.now(),
            ),
          );
        }
      }

      // 교회 정보 로드
      final churchResponse = await _churchService.getMyChurch();
      if (churchResponse.success && churchResponse.data != null) {
        currentChurch = churchResponse.data!;
        print('🏦 HOME_SCREEN: 교회 정보 로드 성공: ${currentChurch!.name}');
      } else {
        print('🏦 HOME_SCREEN: 교회 정보 로드 실패, 샘플 데이터 사용');
      }

      // 사용자 개인 통계 로드 (임시 데이터, 추후 실제 통계 API 연동)
      userStats = {
        'myAttendanceRate': 85,
        'monthlyAttendance': 12,
        'upcomingBirthdays': 3,
        'unreadNotices': 2,
      };

      // 최근 공지사항 로드 (최대 5개)
      await _loadRecentAnnouncements();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  // 최근 공지사항 로드 (5개)
  Future<void> _loadRecentAnnouncements() async {
    try {
      setState(() {
        _isLoadingAnnouncements = true;
      });

      final announcements =
          await _announcementService.getAnnouncements(limit: 5);
      setState(() {
        recentAnnouncements = announcements;
        _isLoadingAnnouncements = false;
      });
      print('📰 HOME_SCREEN: 최근 공지사항 로드 성공: ${recentAnnouncements.length}개');
    } catch (e) {
      setState(() {
        recentAnnouncements = [];
        _isLoadingAnnouncements = false;
      });
      print('📰 HOME_SCREEN: 최근 공지사항 로드 오류: $e');
    }
  }

  /// 오늘의 말씀 로드
  Future<void> _loadTodaysVerse() async {
    try {
      setState(() {
        _isLoadingVerse = true;
      });

      final verse = await _dailyVerseService.getRandomVerse();
      setState(() {
        _currentVerse = verse;
        _isLoadingVerse = false;
      });
      print('🙏 HOME_SCREEN: 오늘의 말씀 로드 성공: ${verse?.reference}');
    } catch (e) {
      setState(() {
        _currentVerse = null;
        _isLoadingVerse = false;
      });
      print('🙏 HOME_SCREEN: 오늘의 말씀 로드 오류: $e');
    }
  }

  // 헤더 위젯 빌드
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColor.secondary01, // 파란색 배경
        borderRadius: BorderRadius.all(Radius.circular(20.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안녕하세요',
                style: AppTextStyle(
                  color: AppColor.secondary06,
                ).b4(),
              ),
              Text(
                '${currentMember?.name ?? currentUser?.fullName ?? '사용자'}님!',
                style: AppTextStyle(
                  color: AppColor.secondary07,
                ).h1(),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColor.primary900.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const NotificationCenterScreen()),
                    );
                  },
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 안전 영역 추가
              SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

              // 헤더 영역
              _buildHeader(),
              const SizedBox(height: 24),

              // 본문 내용
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 교회 정보 카드
                    _buildChurchInfoCard(),
                    const SizedBox(height: 24),

                    // 오늘의 말씀
                    _buildTodaysVerse(),
                    const SizedBox(height: 24),

                    // 최근 공지사항
                    _buildRecentAnnouncements(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChurchInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16.r),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     spreadRadius: 1,
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 교회 아이콘과 교회명 + 화살표 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _isChurchCardExpanded = !_isChurchCardExpanded;
              });
            },
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColor.blue100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColor.primary600,
                          AppColor.primary8,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      Icons.church,
                      color: AppColor.white,
                      size: 14.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentChurch?.name ?? '성암교회',
                        style: AppTextStyle(
                          color: AppColor.secondary07,
                        ).h2(),
                      ),
                      Text(
                        currentChurch?.englishName ?? 'Community Church',
                        style: AppTextStyle(
                          color: AppColor.secondary04,
                        ).b4(),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isChurchCardExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColor.secondary04,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // 교회 세부 정보 (접고 펼치기 가능)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isChurchCardExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                SizedBox(height: 16.h),
                // 담임목사 정보
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColor.blue200,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColor.primary600,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '담임목사',
                              style: AppTextStyle(
                                color: AppColor.secondary04,
                              ).c1(),
                            ),
                            Text(
                              currentChurch?.pastorName ?? '안영목 목사',
                              style: AppTextStyle(
                                color: AppColor.secondary07,
                              ).b2(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                // 전화번호와 위치 (2열 그리드)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColor.background,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: AppColor.green200,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.phone,
                                color: AppColor.green600,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '전화',
                                    style: AppTextStyle(
                                      color: AppColor.secondary04,
                                    ).c1(),
                                  ),
                                  Text(
                                    currentChurch?.phone ?? '031-563-5210',
                                    style: AppTextStyle(
                                      color: AppColor.secondary07,
                                    ).b3(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColor.background,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: AppColor.orange200,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: AppColor.orange600,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '위치',
                                    style: AppTextStyle(
                                      color: AppColor.secondary04,
                                    ).c1(),
                                  ),
                                  Text(
                                    currentChurch?.city ?? '구리시',
                                    style: AppTextStyle(
                                      color: AppColor.secondary07,
                                    ).b3(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // 교회 주소 (파란색 배경)
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.circular(12.r),
                    // border: Border.all(
                    //   color: AppColor.blue200,
                    //   width: 1,
                    // ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Icon(
                          Icons.location_on,
                          color: AppColor.primary600,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '교회 주소',
                              style: AppTextStyle(
                                color: AppColor.primary600,
                              ).c1(),
                            ),
                            SizedBox(height: 4.h),
                            RichText(
                              text: TextSpan(
                                style: AppTextStyle(
                                  color: AppColor.secondary06,
                                ).b3(),
                                children: [
                                  TextSpan(
                                    text: currentChurch?.address ??
                                        '경기도 구리시 검배로 136번길 32\n',
                                  ),
                                  if (currentChurch?.district != null)
                                    TextSpan(
                                      text: '(${currentChurch!.district})',
                                      style: AppTextStyle(
                                        color: AppColor.secondary04,
                                      ).b4(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12), // 패딩 약간 줄임
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // 필요한 최소 공간만 사용
          children: [
            Icon(icon, size: 28, color: color), // 아이콘 크기 약간 줄임
            const SizedBox(height: 6), // 간격 약간 줄임
            Flexible(
              // 텍스트 오버플로우 방지
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18, // 폰트 크기 약간 줄임
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              // 텍스트 오버플로우 방지
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11, // 폰트 크기 약간 줄임
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '빠른 메뉴'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            QuickMenuItem(
              title: '출석체크',
              icon: Icons.check_circle,
              onTap: () {
                Navigator.pushNamed(context, '/attendance');
              },
            ),
            QuickMenuItem(
              title: '일정',
              icon: Icons.calendar_today,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CalendarScreen()),
                );
              },
            ),
            QuickMenuItem(
              title: '기도요청',
              icon: Icons.favorite,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrayerScreen()),
                );
              },
            ),
            QuickMenuItem(
              title: 'QR체크',
              icon: Icons.qr_code,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScanScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoreFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '더 많은 기능'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FeatureCard(
                title: '교회 소식',
                icon: Icons.announcement,
                description: '공지사항과 교회 소식을 확인하세요',
                onTap: () {
                  Navigator.pushNamed(context, '/notices');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FeatureCard(
                title: '교인 명단',
                icon: Icons.people,
                description: '교인들의 연락처를 찾아보세요',
                onTap: () {
                  Navigator.pushNamed(context, '/members');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FeatureCard(
                title: '주보',
                icon: Icons.book,
                description: '이번 주 주보를 확인하세요',
                onTap: () {
                  Navigator.pushNamed(context, '/bulletin');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FeatureCard(
                title: '교역자 명단',
                icon: Icons.people,
                description: '교역자와 임직자 연락처를 확인하세요',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StaffDirectoryScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FeatureCard(
                title: '관리자',
                icon: Icons.admin_panel_settings,
                description: '교회 관리 및 시스템 설정',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FeatureCard(
                title: '설정',
                icon: Icons.settings,
                description: '앱 설정과 개인정보를 관리하세요',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 최근 공지사항 위젯
  Widget _buildRecentAnnouncements() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.forum,
                      size: 20.r,
                      color: AppColor.primary900,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '교회 소식',
                      style: AppTextStyle(
                        color: AppColor.secondary07,
                      ).h2(),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/notices');
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    child: Text(
                      '더보기',
                      style: AppTextStyle(
                        color: AppColor.primary900,
                      ).buttonSmall(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 컨텐츠
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: _isLoadingAnnouncements
                ? Container(
                    height: 100.h,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[500]!,
                        ),
                      ),
                    ),
                  )
                : recentAnnouncements.isEmpty
                    ? Container(
                        height: 100.h,
                        child: Center(
                          child: Text(
                            '공지사항이 없습니다',
                            style: AppTextStyle(
                              color: Colors.grey[600]!,
                            ).b2(),
                          ),
                        ),
                      )
                    : Column(
                        children: recentAnnouncements
                            .map(
                              (announcement) => InkWell(
                                onTap: () {
                                  _navigateToAnnouncementDetail(announcement);
                                },
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  padding: EdgeInsets.all(12.r),
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      // 왼쪽: 새 알림 표시 및 제목
                                      Expanded(
                                        child: Row(
                                          children: [
                                            // 새 알림 표시
                                            if (announcement.isPinned)
                                              Container(
                                                width: 8.r,
                                                height: 8.r,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[500],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            if (announcement.isPinned)
                                              SizedBox(width: 8.w),
                                            // 제목
                                            Expanded(
                                              child: Text(
                                                announcement.title,
                                                style: AppTextStyle(
                                                  color: AppColor.secondary07,
                                                ).b2(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 오른쪽: 시간 및 화살표
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 12.r,
                                            color: Colors.grey[500],
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            announcement.formattedDate,
                                            style: AppTextStyle(
                                              color: Colors.grey[500]!,
                                            ).b3(),
                                          ),
                                          SizedBox(width: 8.w),
                                          Icon(
                                            Icons.chevron_right,
                                            size: 16.r,
                                            color: Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
          ),
        ],
      ),
    );
  }

  // 공지사항 상세 화면으로 이동
  void _navigateToAnnouncementDetail(Announcement announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(
          announcement: announcement,
        ),
      ),
    );
  }

  // 개발용 로그아웃 다이얼로그
  void _showDevLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개발용 로그아웃'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('로그인 화면 테스트를 위한 개발용 기능입니다.'),
            SizedBox(height: 8),
            Text('선택하신 옵션:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logoutOnly();
            },
            child: const Text('로그아웃만'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logoutAndDisableAutoLogin();
            },
            child: const Text('로그아웃 + 자동로그인 비활성화'),
          ),
        ],
      ),
    );
  }

  // 로그아웃만 수행
  Future<void> _logoutOnly() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다. 다음 앱 시작 시 자동 로그인됩니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 로그아웃 + 자동 로그인 비활성화
  Future<void> _logoutAndDisableAutoLogin() async {
    try {
      await _authService.logout();
      await _authService.setAutoLoginEnabled(false);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었고 자동 로그인이 비활성화되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 말씀 새로고침 기능
  Future<void> _refreshVerse() async {
    if (_isRefreshingVerse) return;

    setState(() {
      _isRefreshingVerse = true;
    });

    try {
      // 새로운 랜덤 말씀 가져오기
      final verse = await _dailyVerseService.getRandomVerse();
      setState(() {
        _currentVerse = verse;
        _isRefreshingVerse = false;
      });
      print('🔄 HOME_SCREEN: 말씀 새로고침 성공: ${verse?.reference}');
    } catch (e) {
      setState(() {
        _isRefreshingVerse = false;
      });
      print('🔄 HOME_SCREEN: 말씀 새로고침 오류: $e');
    }
  }

  // 말씀 공유하기 기능
  void _shareVerse() {
    if (_currentVerse != null) {
      final shareText =
          '${_currentVerse!.content}\n\n${_currentVerse!.reference}\n\n공유: 스마트 교회요람 앱';

      Share.share(
        shareText,
        subject: '오늘의 말씀',
      );
    }
  }

  // 오늘의 말씀 섹션
  Widget _buildTodaysVerse() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 230, 238, 249), // blue-50
            Color.fromARGB(255, 235, 216, 255), // purple-50
          ],
        ),
        border: Border.all(
          color: const Color(0xFFDEEEFF), // blue-100
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽: 아이콘과 제목
                Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      color: AppColor.primary900,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '오늘의 말씀',
                      style: AppTextStyle(
                        color: AppColor.secondary07,
                      ).h2(),
                    ),
                  ],
                ),
                // 오른쪽: 버튼들
                Row(
                  children: [
                    // 새로고침 버튼
                    InkWell(
                      onTap: _refreshVerse,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        child: AnimatedRotation(
                          turns: _isRefreshingVerse ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 800),
                          child: Icon(
                            Icons.refresh,
                            color: AppColor.secondary04,
                            size: 20.r,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    // 공유하기 버튼
                    InkWell(
                      onTap: _shareVerse,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        child: Icon(
                          Icons.share,
                          color: AppColor.secondary04,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // 말씀 내용
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isLoadingVerse
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColor.primary600,
                            ),
                          ),
                        )
                      : _currentVerse != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  child: Text(
                                    _currentVerse!.verse,
                                    key: ValueKey(_currentVerse!.id),
                                    style: AppTextStyle(
                                            color: AppColor.secondary06)
                                        .b2()
                                        .copyWith(),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 600),
                                  child: Text(
                                    _currentVerse!.reference,
                                    key: ValueKey('${_currentVerse!.id}_ref'),
                                    style: AppTextStyle(
                                            color: AppColor.secondary06)
                                        .b4(),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '말씀을 불러오는 중입니다...',
                              style: AppTextStyle(color: AppColor.secondary04)
                                  .b3(),
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
