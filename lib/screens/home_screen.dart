import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// // import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import 'notices_screen.dart';
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
import 'settings_screen.dart';

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
  bool _isChurchCardExpanded = true; // 교회 카드 펼침 상태 (초기값: 펼침)
  bool _isWorshipScheduleExpanded = false; // 예배시간 카드 펼침 상태 (초기값: 닫힘)
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러
  final GlobalKey _worshipKey = GlobalKey(); // 예배시간안내 위젯 키
  final GlobalKey<_ProfileAlertState> _profileAlertKey = GlobalKey<_ProfileAlertState>(); // ProfileAlert 위젯 키

  // 최근 공지사항 관련 상태 변수
  List<Announcement> recentAnnouncements = [];
  bool _isLoadingAnnouncements = false;

  // 오늘의 말씀 관련 상태 변수
  DailyVerse? _currentVerse;
  bool _isRefreshingVerse = false;
  bool _isLoadingVerse = false; // 초기 로딩 상태를 false로 변경 (샘플 데이터를 즉시 표시)

  // 예배 서비스 데이터 (실제 API 데이터)
  List<WorshipService> worshipServices = [];
  bool _isLoadingWorshipServices = false;

  @override
  void initState() {
    super.initState();

    // 초기에 샘플 말씀을 즉시 표시 (로딩 대기 시간 제거)
    _setInitialSampleVerse();

    _loadEssentialDataFast();
    _initializeFCMInBackground();

    // 공지사항 직접 로드 (우회 방법)
    Future.delayed(Duration(seconds: 2), () {
      _loadAnnouncementsDirectly();
    });
  }

  /// 📖 초기 샘플 말씀 설정 (즉시 표시)
  void _setInitialSampleVerse() {
    _currentVerse = DailyVerse(
      id: 0,
      verse: '여호와는 나의 목자시니 내게 부족함이 없으리로다',
      reference: '시편 23:1',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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

        // 교회 정보 로그
        print('🏦 HOME: === 교회 정보 로드 완료 ===');
        if (currentChurch != null) {
          print('🏦 HOME: 교회명: ${currentChurch!.name}');
          print('🏦 HOME: 전화번호: ${currentChurch!.phone}');
          print('🏦 HOME: 주소: ${currentChurch!.address}');
        } else {
          print('❌ HOME: currentChurch가 null입니다');
        }

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

  // 📖 오늘의 말씀 비동기 로드 (로딩 스피너 없이 조용히 업데이트)
  Future<void> _loadTodaysVerseAsync() async {
    if (!mounted) return;

    // 로딩 상태를 설정하지 않음 - 샘플 데이터가 이미 표시되어 있음

    try {
      final verse = await _homeDataService.loadTodaysVerse();

      if (mounted && verse != null) {
        setState(() {
          _currentVerse = verse;
        });
        print('✅ HOME: 오늘의 말씀 업데이트 완료 (${verse.reference})');
      }
    } catch (e) {
      // 오류가 발생해도 샘플 데이터를 그대로 유지
      print('⚠️ HOME: 오늘의 말씀 로드 실패, 샘플 데이터 유지 - $e');
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

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      final churchId = userResponse.data?.churchId;

      final announcements =
          await _announcementService.getAnnouncements(
            limit: 5,
            churchId: churchId,
          );

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

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      final churchId = userResponse.data?.churchId;

      final announcements =
          await _announcementService.getAnnouncements(
            limit: 5,
            churchId: churchId,
          );

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
  // 테스트용 메서드 - 실제 운영에서는 사용하지 않음
  // void _setTestProfileImage() {
  //   print('🧪 HOME: 테스트 프로필 이미지 설정 시작');
  //
  //   if (!mounted) return;
  //
  //   // "사진테스트" 멤버의 프로필 이미지 URL 사용
  //   const testImageUrl =
  //       'https://adzhdsajdamrflvybhxq.supabase.co/storage/v1/object/public/member-photos/6/480_20250906_020147_a427da05.png';
  //
  //   setState(() {
  //     if (currentMember != null) {
  //       // 기존 멤버 정보를 유지하면서 프로필 이미지만 변경
  //       currentMember = Member(
  //         id: currentMember!.id,
  //         name: currentMember!.name,
  //         email: currentMember!.email,
  //         gender: currentMember!.gender,
  //         phone: currentMember!.phone,
  //         churchId: currentMember!.churchId,
  //         memberStatus: currentMember!.memberStatus,
  //         createdAt: currentMember!.createdAt,
  //         profilePhotoUrl: testImageUrl, // 테스트 이미지 URL 설정
  //       );
  //     }
  //   });
  //
  //   print('🧪 HOME: 테스트 프로필 이미지 설정 완료');
  //   print('🖼️ HOME: 설정된 이미지 URL: $testImageUrl');
  //   print(
  //       '👤 HOME: currentMember.fullProfilePhotoUrl: ${currentMember?.fullProfilePhotoUrl}');
  // }

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

      // ProfileAlert 새로고침 (알림 배지 업데이트)
      _profileAlertKey.currentState?.refreshNotifications();

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

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      final churchId = userResponse.data?.churchId;

      final announcements =
          await _announcementService.getAnnouncements(
            limit: 5,
            churchId: churchId,
          );
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
        key: _profileAlertKey,  // GlobalKey 사용
        userName: currentMember?.name ?? currentUser?.fullName,
        profileImageUrl: currentMember?.fullProfilePhotoUrl ??
            currentMember?.profilePhotoUrl,
        onNotificationTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationCenterScreen(),
            ),
          );
        },
        onSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
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
                    // 1. 교회 소개
                    _buildChurchInfoCard(),
                    const SizedBox(height: 24),

                    // 2. 교회 소식 (공지사항)
                    _buildRecentAnnouncements(),
                    const SizedBox(height: 24),

                    // 3. 주요 기능 (심방신청, 중보기도)
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // 4. 예배시간 안내
                    Container(
                      key: _worshipKey,
                      child: _buildWorshipSchedule(),
                    ),
                    const SizedBox(height: 24),

                    // 5. 바로가기 (홈페이지, 유튜브)
                    _buildQuickLinks(),
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
        variant: CardVariant.filled,
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
        variant: CardVariant.filled,
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
                      size: 24.sp,
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
                  // 전화번호
                  InkWell(
                    onTap: () {
                      print('📞 HOME: 전화 섹션 클릭됨!');
                      // 전화번호 유효성 검사 (최소 9자리 이상, 숫자와 하이픈만 포함)
                      String phone = currentChurch?.phone ?? '031-563-5210';
                      if (phone.replaceAll(RegExp(r'[^\d]'), '').length < 9) {
                        print('⚠️ HOME: 유효하지 않은 전화번호, fallback 사용');
                        phone = '031-563-5210';
                      }
                      _makePhoneCall(phone);
                    },
                    borderRadius: BorderRadius.circular(12.r),
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
                  SizedBox(height: 12.h),
                  // 교회 주소 (파란색 배경)
                  GestureDetector(
                    onTap: () {
                      final address = currentChurch?.address ?? '경기도 구리시 검배로 136번길 32';
                      _openNaverMap(address);
                    },
                    child: Container(
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
                  ),
                  // 교회 헌금 계좌 (account가 있을 경우에만 표시)
                  if (currentChurch?.account != null && currentChurch!.account!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: () => _copyToClipboard(currentChurch!.account!),
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: NewAppColor.neutral100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Icon(
                                Icons.account_balance,
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
                                    '교회 헌금 계좌',
                                    style: const FigmaTextStyles().body3.copyWith(
                                          color: NewAppColor.neutral600,
                                        ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    currentChurch!.account!,
                                    style: const FigmaTextStyles().body2.copyWith(
                                          color: NewAppColor.neutral900,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Icon(
                                Icons.copy,
                                color: NewAppColor.neutral500,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
        variant: CardVariant.filled,
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
        variant: CardVariant.filled,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NoticesScreen(showAppBar: true),
                      ),
                    );
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
                                                _formatDate(announcement.createdAt),
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
                                            size: 24.sp,
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
                          size: 24.sp,
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
                child: _isLoadingWorshipServices
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              NewAppColor.neutral400,
                            ),
                          ),
                        ),
                      )
                    : Column(
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
    // API에서 가져온 실제 예배 서비스 데이터 사용
    if (worshipServices.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: Text(
              '등록된 예배 시간이 없습니다',
              style: FigmaTextStyles().body3.copyWith(
                color: NewAppColor.neutral400,
              ),
            ),
          ),
        ),
      ];
    }

    return worshipServices.asMap().entries.map((entry) {
      final index = entry.key;
      final service = entry.value;
      final isLast = index == worshipServices.length - 1;

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
                service.name,
                style: FigmaTextStyles().body3.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: Text(
                service.location,
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
                    service.dayOfWeekShort,
                    textAlign: TextAlign.right,
                    style: FigmaTextStyles().caption3.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    service.formattedStartTime,
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

  // 교회 홈페이지 & 유튜브 채널 바로가기
  Widget _buildQuickLinks() {
    // 둘 다 없으면 위젯을 표시하지 않음
    if ((currentChurch?.homepageUrl == null || currentChurch!.homepageUrl!.isEmpty) &&
        (currentChurch?.youtubeChannel == null || currentChurch!.youtubeChannel!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: AppCard(
        backgroundColor: Colors.white,
        borderRadius: 16.r,
        variant: CardVariant.filled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: NewAppColor.warning200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.link,
                    color: NewAppColor.warning600,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '바로가기',
                        style: const FigmaTextStyles().headline4.copyWith(
                              color: NewAppColor.neutral900,
                            ),
                      ),
                      Text(
                        'Quick Links',
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
            // 버튼들
            Row(
              children: [
                // 교회 홈페이지 버튼
                if (currentChurch?.homepageUrl != null && currentChurch!.homepageUrl!.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchUrl(currentChurch!.homepageUrl!),
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
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.language,
                                color: NewAppColor.primary400,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              '교회',
                              style: const FigmaTextStyles().headline5.copyWith(
                                    color: NewAppColor.neutral900,
                                  ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '홈페이지',
                              style: const FigmaTextStyles().body1.copyWith(
                                    color: NewAppColor.neutral600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 간격
                if (currentChurch?.homepageUrl != null &&
                    currentChurch!.homepageUrl!.isNotEmpty &&
                    currentChurch?.youtubeChannel != null &&
                    currentChurch!.youtubeChannel!.isNotEmpty)
                  SizedBox(width: 12.w),

                // 유튜브 채널 버튼
                if (currentChurch?.youtubeChannel != null && currentChurch!.youtubeChannel!.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchUrl(currentChurch!.youtubeChannel!),
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
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: const Color(0xFFFF0000),
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              '유튜브',
                              style: const FigmaTextStyles().headline5.copyWith(
                                    color: NewAppColor.neutral900,
                                  ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '채널',
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

  // URL 실행 메서드
  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('링크를 열 수 없습니다: $urlString'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('링크 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 한국 전화번호 포맷팅 (하이픈 추가)
  String _formatPhoneNumber(String phoneNumber) {
    // 숫자만 추출
    String digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    print('📞 HOME: 원본 전화번호: $phoneNumber');
    print('📞 HOME: 숫자만 추출: $digits');

    // 이미 하이픈이 있는 경우 그대로 반환
    if (phoneNumber.contains('-')) {
      print('📞 HOME: 하이픈이 이미 포함됨, 그대로 사용');
      return phoneNumber;
    }

    // 한국 전화번호 형식에 맞게 하이픈 추가
    if (digits.length == 10) {
      // 10자리: 지역번호(3자리) + 중간(3자리) + 끝(4자리)
      // 예: 0638566240 -> 063-856-6240
      final formatted = '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
      print('📞 HOME: 10자리 포맷팅: $formatted');
      return formatted;
    } else if (digits.length == 11) {
      // 11자리: 010-XXXX-XXXX
      final formatted = '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
      print('📞 HOME: 11자리 포맷팅: $formatted');
      return formatted;
    } else if (digits.length == 9) {
      // 9자리: 02-XXX-XXXX (서울)
      final formatted = '${digits.substring(0, 2)}-${digits.substring(2, 5)}-${digits.substring(5)}';
      print('📞 HOME: 9자리 포맷팅: $formatted');
      return formatted;
    }

    // 기타 경우는 그대로 반환
    print('📞 HOME: 알 수 없는 형식, 원본 사용');
    return phoneNumber;
  }

  // 전화 걸기 메서드
  Future<void> _makePhoneCall(String phoneNumber) async {
    print('📞 HOME: _makePhoneCall 호출됨 - 전화번호: $phoneNumber');

    // 전화번호 포맷팅 (하이픈 추가)
    final formattedNumber = _formatPhoneNumber(phoneNumber);
    print('📞 HOME: 포맷팅 완료: $formattedNumber');

    final Uri phoneUri = Uri(scheme: 'tel', path: formattedNumber);
    print('📞 HOME: tel URI 생성 완료: $phoneUri');

    if (await canLaunchUrl(phoneUri)) {
      print('📞 HOME: canLaunchUrl = true, 전화 앱 실행 중...');
      await launchUrl(phoneUri);
    } else {
      print('📞 HOME: canLaunchUrl = false, 전화를 걸 수 없음');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화를 걸 수 없습니다')),
        );
      }
    }
  }

  // 날짜 포맷팅 메서드
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 네이버 지도 열기 메서드
  Future<void> _openNaverMap(String address) async {
    try {
      // 네이버 지도 앱 URL scheme
      final appUri = Uri.parse('nmap://search?query=${Uri.encodeComponent(address)}&appname=com.example.smart_yoram_app');

      // 네이버 지도 웹 URL (앱이 없을 경우 폴백)
      final webUri = Uri.parse('https://map.naver.com/v5/search/${Uri.encodeComponent(address)}');

      // 먼저 앱으로 열기 시도
      bool launched = false;
      try {
        if (await canLaunchUrl(appUri)) {
          launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('네이버 지도 앱 실행 실패: $e');
      }

      // 앱으로 열기에 실패하면 웹으로 열기
      if (!launched) {
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('지도를 열 수 없습니다'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('지도 연결 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 클립보드에 복사하기 메서드
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계좌번호가 복사되었습니다'),
            backgroundColor: NewAppColor.success600,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복사 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ProfileAlert extends StatefulWidget {
  final String? userName;
  final String? profileImageUrl;
  final Future<void> Function()? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const ProfileAlert({
    super.key,
    this.userName,
    this.profileImageUrl,
    this.onNotificationTap,
    this.onSettingsTap,
  });

  @override
  State<ProfileAlert> createState() => _ProfileAlertState();
}

class _ProfileAlertState extends State<ProfileAlert> {
  int unreadCount = 0;
  RealtimeChannel? _notificationChannel;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    print('🔔 PROFILE_ALERT: initState 호출됨!');
    _loadUnreadCount();
    _setupRealtimeSubscription();
  }

  // 외부에서 호출 가능한 새로고침 메서드
  void refreshNotifications() {
    print('🔄 PROFILE_ALERT: refreshNotifications() 호출됨');
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    print('🔔 PROFILE_ALERT: 미확인 알림 개수 로드 시작');
    try {
      final response = await NotificationService.instance.getMyNotifications(
        limit: 100,
        isRead: false,
      );

      print('🔔 PROFILE_ALERT: API 응답 - success: ${response.success}, data 개수: ${response.data?.length ?? 0}');

      if (response.success && response.data != null && mounted) {
        setState(() {
          unreadCount = response.data!.length;
        });
        print('✅ PROFILE_ALERT: 미확인 알림 개수 업데이트 완료 - $unreadCount개');
      } else {
        print('⚠️ PROFILE_ALERT: 응답은 받았지만 데이터가 없거나 실패');
      }
    } catch (e) {
      print('❌ PROFILE_ALERT: 미확인 알림 개수 로드 실패 - $e');
    }
  }

  Future<void> _setupRealtimeSubscription() async {
    try {
      // 현재 사용자 ID 가져오기
      final authService = AuthService();
      final userResponse = await authService.getCurrentUser();

      if (!userResponse.success || userResponse.data == null) {
        print('❌ PROFILE_ALERT: 사용자 정보를 가져올 수 없습니다');
        return;
      }

      final userId = userResponse.data!.id;
      print('🔔 PROFILE_ALERT: 실시간 알림 구독 시작 - User ID: $userId');

      // Realtime 채널 생성 및 구독
      _notificationChannel = _supabaseService.client
          .channel('notifications:user_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              print('🔔 PROFILE_ALERT: 새 알림 수신 - ${payload.newRecord}');

              // 새 알림이 is_read = false인지 확인
              final isRead = payload.newRecord['is_read'] as bool? ?? false;

              if (!isRead && mounted) {
                setState(() {
                  unreadCount++;
                });
                print('✅ PROFILE_ALERT: 미확인 알림 개수 업데이트 - $unreadCount');
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              print('🔔 PROFILE_ALERT: 알림 업데이트 수신 - ${payload.newRecord}');

              // 알림이 읽음 처리되었는지 확인
              final oldIsRead = payload.oldRecord['is_read'] as bool? ?? false;
              final newIsRead = payload.newRecord['is_read'] as bool? ?? false;

              // 읽지 않은 알림이 읽음으로 변경된 경우
              if (!oldIsRead && newIsRead && mounted) {
                setState(() {
                  if (unreadCount > 0) unreadCount--;
                });
                print('✅ PROFILE_ALERT: 알림 읽음 처리 - 미확인 개수: $unreadCount');
              }
            },
          )
          .subscribe();

      print('✅ PROFILE_ALERT: 실시간 알림 구독 완료');
    } catch (e) {
      print('❌ PROFILE_ALERT: 실시간 알림 구독 설정 실패 - $e');
    }
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    print('🔔 PROFILE_ALERT: 실시간 알림 구독 해제');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ProfileAlert 렌더링 시 로그
    print('🎨 PROFILE_ALERT: 렌더링 시작');
    print('🎨 PROFILE_ALERT: userName = ${widget.userName}');
    print('🎨 PROFILE_ALERT: profileImageUrl = ${widget.profileImageUrl}');
    print('🔔 PROFILE_ALERT: 현재 unreadCount = $unreadCount');

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
                widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
                    ? (() {
                        print(
                            '🖼️ CIRCLE_AVATAR: NetworkImage 생성 - URL: ${widget.profileImageUrl}');
                        return NetworkImage(widget.profileImageUrl!) as ImageProvider;
                      })()
                    : (() {
                        print('🖼️ CIRCLE_AVATAR: 이미지 없음 - 기본 아이콘 표시');
                        return null;
                      })(),
            backgroundColor: Colors.grey[300],
            child: (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty)
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
                  '${widget.userName ?? '사용자'} 님',
                  style: FigmaTextStyles().headline5.copyWith(
                        color: NewAppColor.neutral900, // Neutral_900
                      ),
                ),
              ],
            ),
          ),
          // 알림 버튼 (배지 포함)
          InkWell(
            onTap: () async {
              // 알림 화면으로 이동
              await widget.onNotificationTap?.call();
              // 알림 화면에서 돌아왔을 때 카운트 새로고침
              if (mounted) {
                _loadUnreadCount();
              }
            },
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                Container(
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
                // 미확인 알림 배지 (작은 동그라미)
                if (unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: NewAppColor.danger600,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: NewAppColor.primary200,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: widget.onSettingsTap,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: NewAppColor.neutral500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Icon(
                Icons.settings,
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
