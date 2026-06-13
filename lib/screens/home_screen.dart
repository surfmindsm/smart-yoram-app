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
import '../screens/offering_history_screen.dart';
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
  bool _isWorshipScheduleExpanded = false; // 1.2.0: 카드는 항상 보이고, 이 플래그는 4개 이상일 때 '더보기' 확장 여부만 제어
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

    // 1.2.0: 다크 그라데이션 헤더 위에 상태바 아이콘이 흰색으로 보이도록 명시 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android: 라이트(흰) 아이콘
        statusBarBrightness: Brightness.dark, // iOS: 다크 배경 가정 → 흰 아이콘
      ),
    );

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
  // 1.2.0 C 방향: 스카이 그라데이션 헤더 밴드 (SafeArea 위까지 확장)
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: 16.w,
        right: 16.w,
        // 본문이 -32px 위로 올라오므로 그라데이션 바닥 여유분
        bottom: 44.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NewAppColor.skyPrimary,
            NewAppColor.primary800,
          ],
        ),
      ),
      child: ProfileAlert(
        key: _profileAlertKey,
        userName: currentMember?.name ?? currentUser?.fullName,
        // 1.2.0: "안녕하세요 · {교회명}" 부제 표시용
        churchName: currentChurch?.name,
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 1.2.0: 다크 그라데이션 헤더 위에 상태바 아이콘이 흰색으로 그려지도록
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS — 다크 배경에 라이트 아이콘
      ),
      child: Scaffold(
      // 1.2.0 C 방향: 그라데이션 헤더가 상단 SafeArea까지 차오르도록 extendBodyBehindAppBar 효과
      backgroundColor: NewAppColor.canvas,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 영역 (그라데이션 밴드, SafeArea + 하단 여유 포함)
              _buildHeader(),

              // 본문 — 그라데이션 위로 -32px 오버랩
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 교회 소개
                      _buildChurchInfoCard(),
                      const SizedBox(height: 14),

                      // 2. 주요 기능 (심방신청, 중보기도, 헌금내역) — 목업 §180 기준 교회 카드 바로 아래
                      _buildQuickActions(),
                      const SizedBox(height: 18),

                      // 3. 교회 소식 (공지사항)
                      _buildRecentAnnouncements(),
                      const SizedBox(height: 18),

                      // 4. 예배시간 안내
                      Container(
                        key: _worshipKey,
                        child: _buildWorshipSchedule(),
                      ),
                      const SizedBox(height: 18),

                      // 5. 바로가기 (홈페이지, 유튜브)
                      _buildQuickLinks(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // 1.2.0 C 방향: 가로 스크롤 칩 row (심방 신청 · 중보 기도 · 헌금 내역)
  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // 카드/그라데이션 영역과 시각적으로 살짝 들여쓰기
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          _buildQuickActionChip(
            icon: Icons.home_outlined,
            label: '심방 신청',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PastoralCareRequestScreen(),
                ),
              );
            },
          ),
          SizedBox(width: 9.w),
          _buildQuickActionChip(
            icon: Icons.favorite_outline,
            label: '중보 기도',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrayerRequestScreen(),
                ),
              );
            },
          ),
          SizedBox(width: 9.w),
          _buildQuickActionChip(
            icon: Icons.account_balance_wallet_outlined,
            label: '헌금 내역',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfferingHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 흰 배경 · 1px borderStrong · 라운드 999px · skyDeep 아이콘 (목업 §181-183)
  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: NewAppColor.borderStrong, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: NewAppColor.skyDeep, size: 16.sp),
              SizedBox(width: 7.w),
              Text(
                label,
                style: FigmaTextStyles().caption1.copyWith(
                      color: NewAppColor.neutral700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5.sp,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1.2.0 C 방향: 헤더(교회명 + 담임/전화 부제) + 주소·계좌 2행 압축 카드
  Widget _buildChurchInfoCard() {
    final pastorName = currentChurch?.pastorName ?? '안영목 목사';
    final phone = currentChurch?.phone ?? '031-563-5210';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: AppCard(
        backgroundColor: Colors.white,
        borderRadius: 16.r,
        variant: CardVariant.filled,
        // 카드 패딩을 목업(15px)에 맞춰 자체 Padding으로 제어
        padding: EdgeInsets.all(15.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 교회 아이콘 + 교회명 + (담임 · 전화 부제) + 펼침 화살표
            GestureDetector(
              onTap: () {
                setState(() {
                  _isChurchCardExpanded = !_isChurchCardExpanded;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  // 사각 라운드 11px 스카이 타일
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: NewAppColor.skyTint,
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(
                      Icons.church_outlined,
                      color: NewAppColor.skyDeep,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentChurch?.name ?? '성암교회',
                          style: FigmaTextStyles().cardTitleSm.copyWith(
                                color: NewAppColor.textStrong,
                              ),
                        ),
                        SizedBox(height: 2.h),
                        // 담임목사 · 전화 통합 부제. 전화번호는 InkWell로 감싸 전화걸기 유지
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pastorName,
                                style: FigmaTextStyles().caption2.copyWith(
                                      color: NewAppColor.textTertiary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ' · ',
                              style: FigmaTextStyles().caption2.copyWith(
                                    color: NewAppColor.textTertiary,
                                  ),
                            ),
                            InkWell(
                              onTap: () {
                                String p = phone;
                                if (p.replaceAll(RegExp(r'[^\d]'), '').length < 9) {
                                  p = '031-563-5210';
                                }
                                _makePhoneCall(p);
                              },
                              child: Text(
                                phone,
                                style: FigmaTextStyles().caption2.copyWith(
                                      color: NewAppColor.textTertiary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isChurchCardExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: NewAppColor.iconFaint,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
            // 펼침 영역: 주소 + 계좌 2행만
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isChurchCardExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  SizedBox(height: 11.h),
                  // 교회 주소
                  _buildChurchInfoRow(
                    icon: Icons.location_on_outlined,
                    text: () {
                      final addr = currentChurch?.address ?? '경기도 구리시 검배로 136번길 32';
                      final district = currentChurch?.district;
                      return district != null && district.isNotEmpty
                          ? '$addr ($district)'
                          : addr;
                    }(),
                    onTap: () {
                      final address = currentChurch?.address ?? '경기도 구리시 검배로 136번길 32';
                      _openNaverMap(address);
                    },
                  ),
                  // 교회 헌금 계좌
                  if (currentChurch?.account != null && currentChurch!.account!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _buildChurchInfoRow(
                      icon: Icons.account_balance_outlined,
                      label: '교회 헌금 계좌',
                      text: currentChurch!.account!,
                      trailingIcon: Icons.copy_outlined,
                      onTap: () => _copyToClipboard(currentChurch!.account!),
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

  // 1.2.0 C 방향: 주소/계좌 등 정보 행 (#F8FAFC 배경, skyDeep 아이콘)
  Widget _buildChurchInfoRow({
    required IconData icon,
    required String text,
    String? label,
    IconData? trailingIcon,
    VoidCallback? onTap,
  }) {
    // leading 아이콘은 텍스트 상단에 자연스럽게 붙고, trailing(복사 등)은 행 전체 가운데 정렬
    final row = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            // 본문이 2줄(label+text)일 때 leading 아이콘은 첫 줄에 맞춰 살짝 위로
            padding: EdgeInsets.only(top: label != null ? 2.h : 1.h),
            child: Align(
              alignment: Alignment.topLeft,
              child: Icon(
                icon,
                color: NewAppColor.skyDeep,
                size: 15.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) ...[
                  Text(
                    label,
                    style: FigmaTextStyles().caption3.copyWith(
                          color: NewAppColor.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 2.h),
                ],
                Text(
                  text,
                  style: FigmaTextStyles().caption1.copyWith(
                        color: label != null
                            ? NewAppColor.neutral700
                            : NewAppColor.textSecondary,
                        fontWeight:
                            label != null ? FontWeight.w600 : FontWeight.w500,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: 8.w),
            Icon(
              trailingIcon,
              color: NewAppColor.textTertiary,
              size: 15.sp,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11.r),
      child: row,
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

  // 1.2.0 C 방향: 외부 섹션 헤더 + 흰 카드 + dot bullet 행 (목업 §186-192)
  Widget _buildRecentAnnouncements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더 — 카드 외부
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '교회 소식',
                style: FigmaTextStyles().cardTitleSm.copyWith(
                      color: NewAppColor.textStrong,
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NoticesScreen(showAppBar: true),
                    ),
                  );
                },
                child: Text(
                  '더보기',
                  style: FigmaTextStyles().caption2.copyWith(
                        color: NewAppColor.skyDeep,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        // 카드
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF020817).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _isLoadingAnnouncements
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Column(
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
                  ),
                )
              : recentAnnouncements.isEmpty
                  ? Container(
                      height: 100.h,
                      alignment: Alignment.center,
                      child: Text(
                        '공지사항이 없습니다',
                        style: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.textMuted,
                            ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: recentAnnouncements
                          .asMap()
                          .entries
                          .map((entry) {
                        final i = entry.key;
                        final a = entry.value;
                        final isLast = i == recentAnnouncements.length - 1;
                        // 마지막 행 dot은 회색 처리 (목업 §191)
                        final dotColor = isLast
                            ? NewAppColor.borderStrong
                            : NewAppColor.skyPrimary;
                        return InkWell(
                          onTap: () => _navigateToAnnouncementDetail(a),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        width: 1,
                                        color: NewAppColor.borderSoft,
                                      ),
                                    ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 11.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        a.title,
                                        style: FigmaTextStyles()
                                            .body3
                                            .copyWith(
                                              color: NewAppColor.textBody,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _formatDate(a.createdAt),
                                        style: FigmaTextStyles()
                                            .caption3
                                            .copyWith(
                                              color:
                                                  NewAppColor.textTertiary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16.sp,
                                  color: NewAppColor.iconFaint,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ),
      ],
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

  // 1.2.0 C 방향: 외부 섹션 헤더 + 흰 카드 + sun/moon 타일 행 (목업 §195-200)
  Widget _buildWorshipSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더 — 단순 라벨 (펼침/접힘은 카드 마지막 행 더보기로 제어)
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
          child: Text(
            '예배시간안내',
            style: FigmaTextStyles().cardTitleSm.copyWith(
                  color: NewAppColor.textStrong,
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        // 카드 — 항상 노출, 4개 이상이면 카드 마지막 행에 '더보기/접기' 행 표시
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF020817).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _isLoadingWorshipServices
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        NewAppColor.skyPrimary,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _buildWorshipServiceRows(),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildWorshipServiceRows() {
    if (worshipServices.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: Text(
              '등록된 예배 시간이 없습니다',
              style: FigmaTextStyles().body3.copyWith(
                    color: NewAppColor.textTertiary,
                  ),
            ),
          ),
        ),
      ];
    }

    const previewCount = 3;
    final total = worshipServices.length;
    final hasMore = total > previewCount;
    final visible = (hasMore && !_isWorshipScheduleExpanded)
        ? worshipServices.take(previewCount).toList()
        : worshipServices;

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      final service = visible[i];
      // 행 구분선: 다음 요소(더보기 행 포함)가 있으면 표시
      final hasNextRow = i < visible.length - 1 || hasMore;
      // 수요예배·저녁예배 등 야간 예배는 moon 아이콘, 그 외 sun
      final isEvening = service.name.contains('수요') ||
          service.name.contains('저녁') ||
          service.name.contains('밤');
      rows.add(Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: hasNextRow
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: NewAppColor.borderSoft,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            // sun/moon 라운드 9px 타일
            Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(9.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                isEvening ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                color: NewAppColor.skyDeep,
                size: 15.sp,
              ),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Text(
                service.name,
                style: FigmaTextStyles().body3.copyWith(
                      color: NewAppColor.neutral700,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '${service.dayOfWeekShort} ${service.formattedStartTime}',
              style: FigmaTextStyles().body3.copyWith(
                    color: NewAppColor.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ));
    }

    // 4개 이상일 때만 더보기/접기 행 표시
    if (hasMore) {
      final hiddenCount = total - previewCount;
      rows.add(
        InkWell(
          onTap: () {
            setState(() {
              _isWorshipScheduleExpanded = !_isWorshipScheduleExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isWorshipScheduleExpanded
                      ? '접기'
                      : '더보기 (+$hiddenCount)',
                  style: FigmaTextStyles().caption2.copyWith(
                        color: NewAppColor.skyDeep,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(width: 4.w),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isWorshipScheduleExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16.sp,
                    color: NewAppColor.skyDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return rows;
  }

  // 1.2.0 C 방향: 외부 섹션 헤더 + 2열 흰 카드 (목업 §203-207)
  Widget _buildQuickLinks() {
    final hasHomepage =
        currentChurch?.homepageUrl != null && currentChurch!.homepageUrl!.isNotEmpty;
    final hasYoutube =
        currentChurch?.youtubeChannel != null && currentChurch!.youtubeChannel!.isNotEmpty;

    if (!hasHomepage && !hasYoutube) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 10.h),
          child: Text(
            '바로가기',
            style: FigmaTextStyles().cardTitleSm.copyWith(
                  color: NewAppColor.textStrong,
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        // 2열 그리드 (둘 중 하나만 있어도 동일한 폭 유지)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              if (hasHomepage)
                Expanded(
                  child: _buildQuickLinkCard(
                    icon: Icons.language,
                    label: '홈페이지',
                    onTap: () => _launchUrl(currentChurch!.homepageUrl!),
                  ),
                ),
              if (hasHomepage && hasYoutube) SizedBox(width: 10.w),
              if (hasYoutube)
                Expanded(
                  child: _buildQuickLinkCard(
                    icon: Icons.play_arrow,
                    label: '유튜브',
                    onTap: () => _launchUrl(currentChurch!.youtubeChannel!),
                  ),
                ),
              // 한쪽만 있을 때 카드가 너무 넓어지지 않도록 빈 공간 채움
              if (hasHomepage ^ hasYoutube) ...[
                SizedBox(width: 10.w),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 바로가기 카드 (흰 배경, skyTint 라운드 10px 타일 + skyDeep 아이콘 + 라벨)
  Widget _buildQuickLinkCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(13.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF020817).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: NewAppColor.skyTint,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: NewAppColor.skyDeep,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: FigmaTextStyles().body3.copyWith(
                        color: NewAppColor.neutral700,
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
        _showAppToast('계좌번호가 복사되었습니다');
      }
    } catch (e) {
      if (mounted) {
        _showAppToast('복사 실패: $e', isError: true);
      }
    }
  }

  // 1.2.0 C 방향: floating 다크 토스트 (디자인 정책 §3 바텀시트 톤)
  void _showAppToast(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    // 직전 토스트가 남아있으면 즉시 제거 (겹치지 않게)
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          // 하단 탭바와 자연스럽게 떨어지도록
          bottom: 16.h,
        ),
        duration: Duration(milliseconds: isError ? 2800 : 2000),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: NewAppColor.textStrong, // #0F172A 다크
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF020817).withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: isError
                    ? NewAppColor.danger300
                    : NewAppColor.success300,
                size: 18.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: FigmaTextStyles().body3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ProfileAlert extends StatefulWidget {
  final String? userName;
  final String? churchName; // 1.2.0: 헤더 부제에 표시
  final String? profileImageUrl;
  final Future<void> Function()? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const ProfileAlert({
    super.key,
    this.userName,
    this.churchName,
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

    // 1.2.0 C 방향: 그라데이션 헤더 밴드 위에 올라가는 투명 컨테이너 + 흰색 텍스트
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 프로필 아바타 — 라운드 사각 (목업 §161). 사진이 있으면 풀-사이즈, 없으면 흰 반투명 플레이스홀더
          (widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    widget.profileImageUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                  ),
                )
              : _avatarPlaceholder(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1.2.0: "안녕하세요 · {교회명}" 형식 (교회명 없으면 "안녕하세요"만)
                Text(
                  widget.churchName != null && widget.churchName!.isNotEmpty
                      ? '안녕하세요 · ${widget.churchName}'
                      : '안녕하세요',
                  style: FigmaTextStyles().caption1.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.userName ?? '사용자'} 님',
                  style: FigmaTextStyles().subtitle1.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          // 알림 버튼 (배지 포함) — 흰색 아이콘
          InkWell(
            onTap: () async {
              await widget.onNotificationTap?.call();
              if (mounted) {
                _loadUnreadCount();
              }
            },
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: NewAppColor.danger700,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NewAppColor.skyDeep,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: widget.onSettingsTap,
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 사진 없거나 로드 실패 시 흰 반투명 라운드 사각 플레이스홀더
  Widget _avatarPlaceholder() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: 24,
        color: Colors.white.withOpacity(0.85),
      ),
    );
  }
}
