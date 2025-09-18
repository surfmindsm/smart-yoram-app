import 'package:flutter/material.dart';
// // import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import '../widget/widgets.dart';
import '../components/index.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/member_service.dart';
import '../services/church_service.dart';
import '../services/announcement_service.dart';
import '../services/daily_verse_service.dart';
import '../services/worship_service.dart';
import '../services/fcm_service.dart';
import '../services/home_data_service.dart';
import '../models/user.dart' as app_user;
import '../models/member.dart';
import '../models/church.dart';
import '../models/announcement.dart';
import '../models/daily_verse.dart';
import '../models/worship_service.dart';

import 'notice_detail_screen.dart';
import 'notification_center_screen.dart';
import '../screens/pastoral_care_request_screen.dart';
import '../screens/prayer_request_screen.dart';

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
  final WorshipServiceApi _worshipServiceApi = WorshipServiceApi();
  final HomeDataService _homeDataService = HomeDataService();

  app_user.User? currentUser;
  Member? currentMember;
  Church? currentChurch;
  Map<String, dynamic>? churchInfo;
  Map<String, dynamic>? userStats;
  bool isLoading = true;
  bool _isChurchCardExpanded = true; // 교회 카드 펼침 상태
  bool _isWorshipScheduleExpanded = true; // 예배시간 카드 펼침 상태
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러
  final GlobalKey _worshipKey = GlobalKey(); // 예배시간안내 위젯 키

  // 최근 공지사항 관련 상태 변수
  List<Announcement> recentAnnouncements = [];
  bool _isLoadingAnnouncements = false;

  // 오늘의 말씀 관련 상태 변수
  DailyVerse? _currentVerse;
  bool _isRefreshingVerse = false;
  bool _isLoadingVerse = true;

  // 예배 서비스 데이터 (실제 API 데이터)
  List<WorshipService> worshipServices = [];
  bool _isLoadingWorshipServices = false;

  @override
  void initState() {
    super.initState();
    _loadEssentialDataFast();
    _initializeFCMInBackground();

    // 공지사항 직접 로드 (우회 방법)
    Future.delayed(Duration(seconds: 2), () {
      _loadAnnouncementsDirectly();
    });

    // 프로필 이미지 테스트를 위해 임시 이미지 설정
    Future.delayed(Duration(seconds: 3), () {
      _setTestProfileImage();
    });
  }

  // 🚀 필수 데이터 빠른 로드
  Future<void> _loadEssentialDataFast() async {
    try {
      print('🚀 HOME: 필수 데이터 빠른 로드 시작');

      final essentialData = await _homeDataService.loadEssentialData();

      if (mounted) {
        setState(() {
          currentUser = essentialData.user;
          currentMember = essentialData.member;
          currentChurch = essentialData.church;
          isLoading = false; // 로딩 완료
        });

        // 프로필 이미지 디버깅 로그
        print('📸 PROFILE_IMAGE: === 프로필 이미지 로그 시작 ===');
        if (currentMember != null) {
          print('👤 PROFILE_IMAGE: Member data loaded');
          print('👤 PROFILE_IMAGE: - name: ${currentMember!.name}');
          print('👤 PROFILE_IMAGE: - email: ${currentMember!.email}');
          print('👤 PROFILE_IMAGE: - id: ${currentMember!.id}');
          print(
              '👤 PROFILE_IMAGE: - profilePhotoUrl (원본): ${currentMember!.profilePhotoUrl}');
          print(
              '👤 PROFILE_IMAGE: - fullProfilePhotoUrl (변환됨): ${currentMember!.fullProfilePhotoUrl}');
          print('👤 PROFILE_IMAGE: - photo getter: ${currentMember!.photo}');

          // URL 유효성 체크
          final finalUrl = currentMember!.fullProfilePhotoUrl ??
              currentMember!.profilePhotoUrl;
          if (finalUrl != null && finalUrl.isNotEmpty) {
            print('✅ PROFILE_IMAGE: 최종 사용할 URL: $finalUrl');
            if (finalUrl.startsWith('http')) {
              print('✅ PROFILE_IMAGE: URL이 http로 시작함 (올바름)');
            } else {
              print('❌ PROFILE_IMAGE: URL이 http로 시작하지 않음 (상대경로?)');
            }
          } else {
            print('❌ PROFILE_IMAGE: 프로필 이미지 URL이 null 또는 비어있음');
          }
        } else {
          print('❌ PROFILE_IMAGE: currentMember가 null입니다');
        }

        if (currentUser != null) {
          print('👤 PROFILE_IMAGE: User data loaded');
          print('👤 PROFILE_IMAGE: - fullName: ${currentUser!.fullName}');
          print('👤 PROFILE_IMAGE: - email: ${currentUser!.email}');
        } else {
          print('❌ PROFILE_IMAGE: currentUser가 null입니다');
        }
        print('📸 PROFILE_IMAGE: === 프로필 이미지 로그 끝 ===');
      }

      print('🚀 HOME: 필수 데이터 로드 완료');

      // 오늘의 말씀은 별도로 로드 (UI 블로킹 방지)
      print('🔄 HOME: _loadTodaysVerseAsync() 호출 예정');
      _loadTodaysVerseAsync();

      // 공지사항도 백그라운드에서 로드
      print('🔄 HOME: _loadAnnouncementsInBackground() 호출 예정');
      _loadAnnouncementsInBackground();

      // 테스트: 임시 공지사항 데이터 추가
      _addTestAnnouncements();

      // 예배시간 로드 (백그라운드)
      print('🔄 HOME: _loadWorshipServices() 호출 예정');
      _loadWorshipServices();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('❌ HOME: 필수 데이터 로드 실패 - $e');
    }
  }

  // 📖 오늘의 말씀 비동기 로드
  Future<void> _loadTodaysVerseAsync() async {
    if (!mounted) return;

    setState(() {
      _isLoadingVerse = true;
    });

    try {
      final verse = await _homeDataService.loadTodaysVerse();

      if (mounted) {
        setState(() {
          _currentVerse = verse;
          _isLoadingVerse = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentVerse = null;
          _isLoadingVerse = false;
        });
      }
      print('❌ HOME: 오늘의 말씀 로드 실패 - $e');
    }
  }

  // 📢 공지사항 백그라운드 로드
  Future<void> _loadAnnouncementsInBackground() async {
    // UI 블로킹을 피하기 위해 백그라운드에서 처리
    print('📢 HOME: _loadAnnouncementsInBackground() 시작');

    if (!mounted) {
      print('❌ HOME: Widget이 mounted 상태가 아님');
      return;
    }

    try {
      print('📢 HOME: AnnouncementService.getAnnouncements() 호출 시작');

      final announcements =
          await _announcementService.getAnnouncements(limit: 5);

      print('📢 HOME: API 호출 완료 - 받은 데이터: ${announcements.length}개');

      if (announcements.isNotEmpty) {
        print('📢 HOME: 첫 번째 공지사항: ${announcements.first.title}');
      }

      if (mounted) {
        setState(() {
          recentAnnouncements = announcements;
        });
        print(
            '📢 HOME: setState 완료 - recentAnnouncements.length: ${recentAnnouncements.length}');
      }
    } catch (e, stackTrace) {
      print('❌ HOME: 공지사항 로드 실패 - $e');
      print('❌ HOME: 스택트레이스: $stackTrace');

      if (mounted) {
        setState(() {
          recentAnnouncements = [];
        });
      }
    }

    print('📢 HOME: _loadAnnouncementsInBackground() 종료');
  }

  // 🧪 테스트용 공지사항 추가
  void _addTestAnnouncements() {
    print('🧪 HOME: 테스트 공지사항 데이터 추가');

    if (mounted) {
      setState(() {
        recentAnnouncements = [
          // Announcement 객체를 생성하는 것은 복잡하므로 일단 빈 리스트로 시작
        ];
      });
      print('🧪 HOME: 테스트 공지사항 추가 완료 - 개수: ${recentAnnouncements.length}');
    }
  }

  // 📢 공지사항 직접 로드 (우회 방법)
  Future<void> _loadAnnouncementsDirectly() async {
    print('📢 HOME: _loadAnnouncementsDirectly() 시작');

    if (!mounted) {
      print('❌ HOME: Widget이 mounted 상태가 아님');
      return;
    }

    try {
      print('📢 HOME: AnnouncementService 직접 호출 시작');

      final announcements =
          await _announcementService.getAnnouncements(limit: 5);

      print('📢 HOME: 직접 호출 완료 - 받은 데이터: ${announcements.length}개');

      if (announcements.isNotEmpty) {
        print('📢 HOME: 첫 번째 공지사항: ${announcements.first.title}');
      }

      if (mounted) {
        setState(() {
          recentAnnouncements = announcements;
        });
        print(
            '📢 HOME: setState 완료 - recentAnnouncements.length: ${recentAnnouncements.length}');
      }
    } catch (e, stackTrace) {
      print('❌ HOME: 공지사항 직접 로드 실패 - $e');
      print('❌ HOME: 스택트레이스: $stackTrace');
    }

    print('📢 HOME: _loadAnnouncementsDirectly() 종료');
  }

  // 🔄 캐시 무효화 후 프로필 다시 로드
  Future<void> _reloadProfileWithCacheClear() async {
    print('🔄 HOME: 캐시 무효화 후 프로필 다시 로드 시작');

    try {
      // 캐시 무효화
      await _homeDataService.invalidateCache();
      print('🗑️ HOME: 홈 데이터 캐시 무효화 완료');

      // 새로운 데이터 로드
      final essentialData = await _homeDataService.loadEssentialData();

      if (mounted) {
        setState(() {
          currentUser = essentialData.user;
          currentMember = essentialData.member;
          currentChurch = essentialData.church;
        });

        // 프로필 이미지 로그
        print('📸 HOME: 캐시 무효화 후 프로필 이미지');
        print('👤 HOME: currentMember.name: ${currentMember?.name}');
        print('🖼️ HOME: profilePhotoUrl: ${currentMember?.profilePhotoUrl}');
        print(
            '🖼️ HOME: fullProfilePhotoUrl: ${currentMember?.fullProfilePhotoUrl}');
      }
    } catch (e) {
      print('❌ HOME: 캐시 무효화 후 재로드 실패 - $e');
    }

    print('🔄 HOME: 캐시 무효화 후 프로필 다시 로드 완료');
  }

  // 🧪 테스트용 프로필 이미지 설정
  void _setTestProfileImage() {
    print('🧪 HOME: 테스트 프로필 이미지 설정 시작');

    if (!mounted) return;

    // "사진테스트" 멤버의 프로필 이미지 URL 사용
    const testImageUrl =
        'https://adzhdsajdamrflvybhxq.supabase.co/storage/v1/object/public/member-photos/6/480_20250906_020147_a427da05.png';

    setState(() {
      if (currentMember != null) {
        // 기존 멤버 정보를 유지하면서 프로필 이미지만 변경
        currentMember = Member(
          id: currentMember!.id,
          name: currentMember!.name,
          email: currentMember!.email,
          gender: currentMember!.gender,
          phone: currentMember!.phone,
          churchId: currentMember!.churchId,
          memberStatus: currentMember!.memberStatus,
          createdAt: currentMember!.createdAt,
          profilePhotoUrl: testImageUrl, // 테스트 이미지 URL 설정
        );
      }
    });

    print('🧪 HOME: 테스트 프로필 이미지 설정 완료');
    print('🖼️ HOME: 설정된 이미지 URL: $testImageUrl');
    print(
        '👤 HOME: currentMember.fullProfilePhotoUrl: ${currentMember?.fullProfilePhotoUrl}');
  }

  // 🔄 FCM 백그라운드 초기화
  Future<void> _initializeFCMInBackground() async {
    // 백그라운드에서 FCM 초기화 (UI 블로킹 방지)
    Future.microtask(() async {
      try {
        await FCMService.instance.initialize();
        print('✅ FCM 초기화 완료');
      } catch (e) {
        print('❌ FCM 초기화 실패: $e');
      }
    });
  }

  // 기존 FCM 초기화 (호환성 유지)
  Future<void> _initializeFCM() async {
    return _initializeFCMInBackground();
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

      // 예배 서비스 로드
      await _loadWorshipServices();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // 스낵바 제거됨
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

  // 예배 서비스 로드
  Future<void> _loadWorshipServices() async {
    try {
      setState(() {
        _isLoadingWorshipServices = true;
      });

      // 활성 상태의 예배 서비스만 로드
      final services = await _worshipServiceApi.getWorshipServices(
        isActive: true,
      );

      setState(() {
        worshipServices = services;
        _isLoadingWorshipServices = false;
      });
      print('🛐 HOME_SCREEN: 예배 서비스 로드 성공: ${worshipServices.length}개');
    } catch (e) {
      setState(() {
        worshipServices = [];
        _isLoadingWorshipServices = false;
      });
      print('🛐 HOME_SCREEN: 예배 서비스 로드 오류: $e');
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
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ProfileAlert(
        userName: currentMember?.name ?? currentUser?.fullName,
        profileImageUrl: currentMember?.fullProfilePhotoUrl ??
            currentMember?.profilePhotoUrl,
        onNotificationTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationCenterScreen(),
            ),
          );
        },
      ),
    );
  }

  // 예배시간안내 섹션으로 스크롤하는 메서드
  void _scrollToWorshipSchedule() {
    final context = _worshipKey.currentContext;
    if (context != null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final scrollOffset = position.dy - 100; // 약간의 여백을 위해 100 픽셀 위로

      _scrollController.animateTo(
        _scrollController.offset + scrollOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          controller: _scrollController,
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

                    // 주요 기능 버튼들
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // 오늘의 말씀
                    _buildTodaysVerse(),
                    const SizedBox(height: 24),

                    // 최근 공지사항
                    _buildRecentAnnouncements(),
                    const SizedBox(height: 24),

                    // 예배안내
                    Container(
                      key: _worshipKey,
                      child: _buildWorshipSchedule(),
                    ),
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

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: AppCard(
        backgroundColor: Colors.white,
        borderRadius: 16.r,
        variant: CardVariant.outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: NewAppColor.success200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.folder_open_outlined,
                    color: NewAppColor.success600,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '주요 기능',
                        style: const FigmaTextStyles().headline4.copyWith(
                              color: NewAppColor.neutral900,
                            ),
                      ),
                      Text(
                        'Main Features',
                        style: const FigmaTextStyles().body3.copyWith(
                              color: NewAppColor.neutral600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PastoralCareRequestScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: NewAppColor.neutral100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.home_outlined,
                              color: NewAppColor.success400,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            '심방 신청',
                            style: const FigmaTextStyles().headline5.copyWith(
                                  color: NewAppColor.neutral900,
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '심방을 신청하세요',
                            style: const FigmaTextStyles().body1.copyWith(
                                  color: NewAppColor.neutral600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrayerRequestScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: NewAppColor.neutral100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_outline,
                              color: NewAppColor.success400,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            '중보 기도',
                            style: const FigmaTextStyles().headline5.copyWith(
                                  color: NewAppColor.neutral900,
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '함께 기도하겠습니다',
                            style: const FigmaTextStyles().body1.copyWith(
                                  color: NewAppColor.neutral600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: AppCard(
        backgroundColor: Colors.white,
        borderRadius: 16.r,
        variant: CardVariant.outlined,
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
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: NewAppColor.primary200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: NewAppColor.primary600,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentChurch?.name ?? '성암교회',
                          style: const FigmaTextStyles().headline4.copyWith(
                                color: NewAppColor.neutral900,
                              ),
                        ),
                        Text(
                          currentChurch?.englishName ?? 'Community Church',
                          style: const FigmaTextStyles().body3.copyWith(
                                color: NewAppColor.neutral600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isChurchCardExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: NewAppColor.neutral500,
                      size: 16.sp,
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
                      color: NewAppColor.neutral100,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: NewAppColor.primary300,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            Icons.person,
                            color: NewAppColor.primary600,
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
                                style: const FigmaTextStyles().body3.copyWith(
                                      color: NewAppColor.neutral600,
                                    ),
                              ),
                              Text(
                                currentChurch?.pastorName ?? '안영목 목사',
                                style: const FigmaTextStyles().title4.copyWith(
                                      color: NewAppColor.neutral900,
                                    ),
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
                            color: NewAppColor.neutral100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: NewAppColor.success200,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Icon(
                                  Icons.phone,
                                  color: NewAppColor.success600,
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
                                      style: const FigmaTextStyles()
                                          .body3
                                          .copyWith(
                                            color: NewAppColor.neutral600,
                                          ),
                                    ),
                                    Text(
                                      currentChurch?.phone ?? '031-563-5210',
                                      style: const FigmaTextStyles()
                                          .body2
                                          .copyWith(
                                            color: NewAppColor.neutral900,
                                          ),
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
                            color: NewAppColor.neutral100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: NewAppColor.warning200,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: NewAppColor.warning600,
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
                                      style: const FigmaTextStyles()
                                          .body3
                                          .copyWith(
                                            color: NewAppColor.neutral600,
                                          ),
                                    ),
                                    Text(
                                      currentChurch?.city ?? '구리시',
                                      style: const FigmaTextStyles()
                                          .body2
                                          .copyWith(
                                            color: NewAppColor.neutral900,
                                          ),
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
                      color: NewAppColor.neutral100,
                      borderRadius: BorderRadius.circular(12.r),
                      // border: Border.all(
                      //   color: NewAppColor.primary300,
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
                            color: NewAppColor.primary600,
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
                                style: const FigmaTextStyles().body3.copyWith(
                                      color: NewAppColor.neutral600,
                                    ),
                              ),
                              SizedBox(height: 4.h),
                              RichText(
                                text: TextSpan(
                                  style: const FigmaTextStyles().body2.copyWith(
                                        color: NewAppColor.neutral900,
                                      ),
                                  children: [
                                    TextSpan(
                                      text: currentChurch?.address ??
                                          '경기도 구리시 검배로 136번길 32\n',
                                    ),
                                    if (currentChurch?.district != null)
                                      TextSpan(
                                        text: '(${currentChurch!.district})',
                                        style: const FigmaTextStyles()
                                            .body2
                                            .copyWith(
                                              color: NewAppColor.neutral900,
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
                  ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
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
        // 스낵바 제거됨
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
      await _loadTodaysVerse();
    } catch (e) {
      print('😑 HOME_SCREEN: 오늘의 말씀 새로고침 오류: $e');
    } finally {
      setState(() {
        _isRefreshingVerse = false;
      });
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
      child: AppCard(
        backgroundColor: NewAppColor.secondary200,
        borderRadius: 16.r,
        variant: CardVariant.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽: 아이콘과 제목
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: NewAppColor.secondary100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book,
                          color: NewAppColor.secondary600,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘의 말씀',
                              style: const FigmaTextStyles().headline4.copyWith(
                                    color: NewAppColor.neutral900,
                                  ),
                            ),
                            Text(
                              'Daily Scripture',
                              style: const FigmaTextStyles().body3.copyWith(
                                    color: NewAppColor.neutral600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                            color: NewAppColor.neutral500,
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
                          color: NewAppColor.neutral500,
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
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: _isLoadingVerse
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NewAppColor.secondary600,
                        ),
                      ),
                    )
                  : _currentVerse != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                _currentVerse!.verse,
                                key: ValueKey(_currentVerse!.id),
                                style: const FigmaTextStyles()
                                    .body1
                                    .copyWith(color: NewAppColor.neutral800),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                _currentVerse!.reference,
                                key: ValueKey('${_currentVerse!.id}_ref'),
                                style: const FigmaTextStyles()
                                    .body3
                                    .copyWith(color: NewAppColor.neutral400),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '말씀을 불러올 수 없습니다',
                          style: const FigmaTextStyles().body3.copyWith(
                                color: NewAppColor.neutral500,
                              ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // 최근 공지사항 위젯
  Widget _buildRecentAnnouncements() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: AppCard(
        backgroundColor: Colors.white,
        borderRadius: 16.r,
        variant: CardVariant.outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: NewAppColor.primary200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.article_outlined,
                          color: NewAppColor.primary600,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '교회 소식',
                              style: const FigmaTextStyles().headline4.copyWith(
                                    color: NewAppColor.neutral900,
                                  ),
                            ),
                            Text(
                              'Church News',
                              style: const FigmaTextStyles().body3.copyWith(
                                    color: NewAppColor.neutral600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/notices');
                  },
                  child: Container(
                    width: 80.w,
                    height: 32.h,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: NewAppColor.neutral200,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 34.w,
                          child: Text(
                            '더보기',
                            textAlign: TextAlign.center,
                            style: FigmaTextStyles().caption1.copyWith(
                                  color: NewAppColor.neutral800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 컨텐츠
            Padding(
              padding: EdgeInsets.fromLTRB(0.w, 16.h, 0.w, 0),
              child: _isLoadingAnnouncements
                  ? Column(
                      children: [
                        AppListItemSkeleton(
                          showLeading: false,
                          titleLines: 1,
                          subtitleLines: 1,
                        ),
                        SizedBox(height: 8.h),
                        AppListItemSkeleton(
                          showLeading: false,
                          titleLines: 1,
                          subtitleLines: 1,
                        ),
                        SizedBox(height: 8.h),
                        AppListItemSkeleton(
                          showLeading: false,
                          titleLines: 1,
                          subtitleLines: 1,
                        ),
                      ],
                    )
                  : recentAnnouncements.isEmpty
                      ? Container(
                          height: 100.h,
                          child: Center(
                            child: Text(
                              '공지사항이 없습니다',
                              style: const FigmaTextStyles().bodyText2.copyWith(
                                    color: Colors.grey[600]!,
                                  ),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: recentAnnouncements
                              .map(
                                (announcement) => GestureDetector(
                                  onTap: () {
                                    _navigateToAnnouncementDetail(announcement);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 66.h,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 12.w),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 1,
                                          color: NewAppColor.neutral100,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                announcement.title,
                                                style: TextStyle(
                                                  color: NewAppColor.neutral900,
                                                  fontSize: 14.sp,
                                                  fontFamily:
                                                      'Pretendard Variable',
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.43,
                                                  letterSpacing: -0.35,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                announcement.formattedDate,
                                                style: TextStyle(
                                                  color: NewAppColor.neutral600,
                                                  fontSize: 13.sp,
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.38,
                                                  letterSpacing: -0.33,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 28.w,
                                          height: 28.h,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100.r),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_right,
                                            size: 16.sp,
                                            color: NewAppColor.neutral500,
                                          ),
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

  // 예배안내 위젯
  Widget _buildWorshipSchedule() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: ShapeDecoration(
        color: NewAppColor.neutral700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16.w, 16.h, 16.w, _isWorshipScheduleExpanded ? 16.h : 12.h),
        child: Column(
          children: [
            // Header
            GestureDetector(
              onTap: () {
                setState(() {
                  _isWorshipScheduleExpanded = !_isWorshipScheduleExpanded;
                });

                // 펼쳤을 때만 스크롤 포커싱
                if (_isWorshipScheduleExpanded) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _scrollToWorshipSchedule();
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.only(
                    bottom: _isWorshipScheduleExpanded ? 12.h : 0.h),
                decoration: _isWorshipScheduleExpanded
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1,
                            color: NewAppColor.neutral100,
                          ),
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '예배시간안내',
                            style: FigmaTextStyles().headline4.copyWith(
                                  color: NewAppColor.neutral100,
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Worship',
                            style: FigmaTextStyles().body3.copyWith(
                                  color: NewAppColor.neutral400,
                                ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isWorshipScheduleExpanded ? 0.5 : 0,
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: ShapeDecoration(
                          color: NewAppColor.neutral700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Service List with Animation
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isWorshipScheduleExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: Column(
                  children: _buildWorshipServiceRows(),
                ),
              ),
              secondChild: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWorshipServiceRows() {
    // Sample data - replace with actual worship service data
    final services = [
      {'name': '주일예배 1부', 'location': '예루살렘성전', 'day': '주일', 'time': '오전 9시'},
      {'name': '주일예배 2부', 'location': '예루살렘성전', 'day': '주일', 'time': '오전 11시'},
      {
        'name': '주일예배 3부',
        'location': '예루살렘성전',
        'day': '주일',
        'time': '오후 1시 30분'
      },
      {'name': '새싹부', 'location': '새싹부실', 'day': '주일', 'time': '오전 11시'},
      {'name': '어린이부', 'location': '어린이부실', 'day': '주일', 'time': '오전 11시'},
      {'name': '청소년부', 'location': '밷엘성전', 'day': '주일', 'time': '오전 11시'},
      {'name': '대학청년부', 'location': '시온성전', 'day': '주일', 'time': '오후 1시 30분'},
      {'name': '수요 예배', 'location': '예루살렘성전', 'day': '수요일', 'time': '오후 8시'},
      {
        'name': '새벽기도회(월)',
        'location': '온라인',
        'day': '월요일',
        'time': '오전 5시 30분'
      },
      {
        'name': '새벽기도회(화)',
        'location': '온라인',
        'day': '화요일',
        'time': '오전 5시 30분'
      },
      {
        'name': '새벽기도회(수)',
        'location': '온라인',
        'day': '수요일',
        'time': '오전 5시 30분'
      },
      {
        'name': '새벽기도회(목)',
        'location': '온라인',
        'day': '목요일',
        'time': '오전 5시 30분'
      },
      {
        'name': '새벽기도회(금)',
        'location': '온라인',
        'day': '금요일',
        'time': '오전 5시 30분'
      },
    ];

    return services.map((service) {
      final isLast = services.indexOf(service) == services.length - 1;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: NewAppColor.neutral600,
                  ),
                ),
              ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                service['name']!,
                style: FigmaTextStyles().body3.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: Text(
                service['location']!,
                textAlign: TextAlign.center,
                style: FigmaTextStyles().body3.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    service['day']!,
                    textAlign: TextAlign.right,
                    style: FigmaTextStyles().caption3.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    service['time']!,
                    textAlign: TextAlign.right,
                    style: FigmaTextStyles().subtitle4.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ProfileAlert extends StatelessWidget {
  final String? userName;
  final String? profileImageUrl;
  final VoidCallback? onNotificationTap;

  const ProfileAlert({
    super.key,
    this.userName,
    this.profileImageUrl,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    // ProfileAlert 렌더링 시 로그
    print('🎨 PROFILE_ALERT: 렌더링 시작');
    print('🎨 PROFILE_ALERT: userName = $userName');
    print('🎨 PROFILE_ALERT: profileImageUrl = $profileImageUrl');

    return Container(
      width: double.infinity,
      height: 84,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: NewAppColor.primary200, // Primary_200
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 21.54,
            backgroundImage:
                profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? (() {
                        print(
                            '🖼️ CIRCLE_AVATAR: NetworkImage 생성 - URL: $profileImageUrl');
                        return NetworkImage(profileImageUrl!) as ImageProvider;
                      })()
                    : (() {
                        print('🖼️ CIRCLE_AVATAR: 이미지 없음 - 기본 아이콘 표시');
                        return null;
                      })(),
            backgroundColor: Colors.grey[300],
            child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                ? Icon(
                    Icons.person,
                    size: 24,
                    color: Colors.grey[600],
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요',
                  style: FigmaTextStyles().caption1.copyWith(
                        color: NewAppColor.neutral600, // Neutral_600
                      ),
                ),
                Text(
                  '${userName ?? '사용자'} 님',
                  style: FigmaTextStyles().headline5.copyWith(
                        color: NewAppColor.neutral900, // Neutral_900
                      ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onNotificationTap,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: const Color(0xFF0078FF), // Primary_600
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
