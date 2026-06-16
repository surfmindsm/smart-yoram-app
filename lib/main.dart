import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import.*lucide_icons.*;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/naver_map_config.dart';
import 'firebase_options.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
import 'screens/members_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/bulletin_screen.dart';
import 'screens/notices_screen.dart';
import 'screens/member_card_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/admin/admin_member_management_screen.dart';
import 'screens/admin/admin_pastoral_care_list_screen.dart';
import 'screens/admin/admin_notice_list_screen.dart';
import 'screens/signup/signup_selection_screen.dart';
import 'screens/signup/church_signup_screen.dart';
import 'screens/signup/community_signup_screen.dart';
import 'screens/signup/signup_success_screen.dart';
import 'screens/lottie_test_screen.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/font_settings_service.dart';
import 'services/app_version_service.dart';
import 'services/presence_service.dart';
import 'widgets/update_dialog.dart';

/// 전역 네비게이터 키 (FCM 알림 탭 처리용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  print('🚀 MAIN: 앱 시작');
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 MAIN: WidgetsFlutterBinding 초기화 완료');

  // 즉시 앱 실행 (스플래시 화면 표시)
  print('🚀 MAIN: runApp() 호출 시작');
  runApp(
    ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (context) => FontSettingsService(),
        child: const MyApp(),
      ),
    ),
  );
  print('🚀 MAIN: runApp() 호출 완료');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return provider.Consumer<FontSettingsService>(
      builder: (context, fontSettings, child) {
        return ScreenUtilInit(
          designSize: const Size(390, 844), // iPhone 12 기준 사이즈
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            // MediaQuery를 사용하여 전체 앱에 글꼴 크기 적용
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: fontSettings.textScaleFactor,
              ),
              child: MaterialApp(
                navigatorKey: navigatorKey,
                title: 'Smart Yoram App',
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('ko', 'KR'),
                  Locale('en', 'US'),
                ],
                locale: const Locale('ko', 'KR'),
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.light,
                  ),
                  useMaterial3: true,
                  fontFamily: 'Pretendard',
                  // 1.2.0: 흰 AppBar에서 status bar 아이콘 진하게 보이도록
                  appBarTheme: const AppBarTheme(
                    systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.dark,
                      statusBarBrightness: Brightness.light,
                    ),
                  ),
                ),
                home: const AuthWrapper(),
                routes: {
                  '/login': (context) => const LoginScreen(),
                  '/home': (context) => const MainNavigation(),
                  '/members': (context) => const MembersScreen(),
                  '/attendance': (context) => const AttendanceScreen(),
                  '/bulletin': (context) => const BulletinScreen(),
                  '/notices': (context) => const NoticesScreen(),
                  '/member-card': (context) => const MemberCardScreen(),
                  '/calendar': (context) => const CalendarScreen(),
                  '/prayer': (context) => const PrayerScreen(),
                  '/settings': (context) => const SettingsScreen(),
                  '/chat': (context) => const ChatListScreen(),
                  // Signup routes
                  '/signup/selection': (context) =>
                      const SignupSelectionScreen(),
                  '/signup/church': (context) => const ChurchSignupScreen(),
                  '/signup/community': (context) =>
                      const CommunitySignupScreen(),
                  '/signup/success': (context) => const SignupSuccessScreen(),
                  // Admin routes
                  '/admin/members': (context) =>
                      const AdminMemberManagementScreen(),
                  '/admin/pastoral-care': (context) =>
                      const AdminPastoralCareListScreen(),
                  '/admin/notices': (context) => const AdminNoticeListScreen(),
                  // Test routes
                  '/lottie-test': (context) => const LottieTestScreen(),
                },
              ),
            );
          },
        );
      },
    );
  }
}

// 인증 상태를 확인하여 로그인 화면 또는 메인 화면으로 이동
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isLoggedIn = false;
  final AuthService _authService = AuthService();
  final PresenceService _presenceService = PresenceService();
  AppVersionService? _versionService; // Supabase 초기화 후 생성

  @override
  void initState() {
    super.initState();
    print('🔧 AUTH_WRAPPER: initState() 시작');
    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
    // 바로 초기화 시작 (네이티브 스플래시가 계속 표시됨)
    _initializeApp();
  }

  @override
  void dispose() {
    // 앱 생명주기 관찰자 제거 및 Presence 중지
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.stopTracking();
    super.dispose();
  }

  /// 앱 생명주기 상태 변경 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isLoggedIn && _authService.currentUser != null) {
      if (state == AppLifecycleState.resumed) {
        // 앱이 포그라운드로 돌아오면 Presence 재시작
        print('📱 LIFECYCLE: 앱이 포그라운드로 전환됨 - Presence 재시작');
        _presenceService.startTracking();
      } else if (state == AppLifecycleState.paused) {
        // 앱이 백그라운드로 가면 Presence 중지
        print('📱 LIFECYCLE: 앱이 백그라운드로 전환됨 - Presence 중지');
        _presenceService.stopTracking();
      }
    }
  }

  /// 앱 초기화: 최소한만 하고 빠르게 화면 표시
  Future<void> _initializeApp() async {
    print('⏱️ AUTH_WRAPPER: _initializeApp() 시작');

    // 1. 화면 방향 설정 (빠름)
    print('📱 AUTH_WRAPPER: 화면 방향 설정');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 2. Supabase 초기화를 백그라운드로 이동
    _initializeSupabase();

    // 3. Flutter 스플래시를 충분히 보여주기 (2초)
    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Supabase 및 기타 서비스 초기화 (백그라운드)
  Future<void> _initializeSupabase() async {
    try {
      print('🔄 AUTH_WRAPPER: Supabase 초기화 시작 (백그라운드)');
      await Supabase.initialize(
        url: 'https://adzhdsajdamrflvybhxq.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkemhkc2FqZGFtcmZsdnliaHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NDg5ODEsImV4cCI6MjA2OTQyNDk4MX0.pgn6M5_ihDFt3ojQmCoc3Qf8pc7LzRvQEIDT7g1nW3c',
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Supabase 초기화 타임아웃');
          throw TimeoutException('Supabase initialization timeout');
        },
      );
      print('✅ Supabase 초기화 완료');

      // AppVersionService 생성
      _versionService = AppVersionService();

      // 인증 상태 확인
      await _checkAuthStatus();

      // 백그라운드 서비스 초기화
      _initializeBackgroundServices();
    } catch (e) {
      print('⚠️ Supabase 초기화 중 오류: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
        });
      }
    }
  }

  /// 백그라운드 서비스 초기화 (앱 시작을 방해하지 않음)
  void _initializeBackgroundServices() {
    // Firebase, FCM, 글꼴, 네이버 지도, 버전 체크를 병렬로 비동기 실행
    Future.wait([
      initializeFirebase(),
      FontSettingsService().initialize(),
      NaverMapSdk.instance.initialize(clientId: NaverMapConfig.clientId),
      _checkAppVersion(),
    ]).then((_) {
      print('✅ 백그라운드 서비스 초기화 완료');
    }).catchError((error) {
      print('⚠️ 백그라운드 서비스 초기화 중 일부 실패: $error');
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      // 자동 로그인이 비활성화되어 있으면 로그인 화면으로 이동
      final isAutoLoginDisabled = await _authService.isAutoLoginDisabled;
      if (isAutoLoginDisabled) {
        print('AuthWrapper: 자동 로그인이 비활성화되어 있어 로그인 화면을 표시합니다.');
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
          });
        }
        return;
      }

      final hasStoredAuth = await _authService.loadStoredAuth();
      if (mounted) {
        setState(() {
          _isLoggedIn = hasStoredAuth;
        });

        // 로그인 성공 시 Presence 추적 시작
        if (hasStoredAuth) {
          print('✅ AUTH_WRAPPER: 로그인 성공 - Presence 추적 시작');
          _presenceService.startTracking();
        }
      }
    } catch (e) {
      print('인증 상태 확인 실패: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
        });
      }
    }
  }

  Future<void> _checkAppVersion() async {
    if (!mounted || _versionService == null) return;

    try {
      print('🔍 AUTH_WRAPPER: Checking app version...');
      final versionCheckResult = await _versionService!.checkVersion();

      if (!mounted) return;

      // 화면이 빌드된 후 다이얼로그 표시
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showUpdateDialogIfNeeded(context, versionCheckResult);
      });
    } catch (e) {
      print('❌ AUTH_WRAPPER: Version check failed: $e');
      // 버전 체크 실패는 앱 실행을 막지 않음
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 중에는 스플래시 화면 표시
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 (네이티브 스플래시와 동일한 크기)
              Image.asset(
                'assets/images/logo_type3_white.png',
                width: 200.w,
                height: 80.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40.h),
              // 로딩 인디케이터
              SizedBox(
                width: 32.w,
                height: 32.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 초기화 완료 후 로그인 또는 메인 화면으로 이동
    return _isLoggedIn ? const MainNavigation() : const LoginScreen();
  }
}

/// Firebase 초기화를 안전하게 처리하는 함수
Future<void> initializeFirebase() async {
  try {
    // Firebase 초기화 시도 (options 추가)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase가 성공적으로 초기화되었습니다.');

    // FCM 서비스 초기화 (Firebase 초기화 성공 시에만)
    try {
      await FCMService.instance.initialize();
      print('✅ FCM 서비스가 성공적으로 초기화되었습니다.');
    } catch (fcmError) {
      print('⚠️ FCM 초기화 실패: $fcmError');
      print('ℹ️ 푸시 알림 기능이 비활성화되지만 앱은 정상 작동합니다.');
    }
  } catch (firebaseError) {
    print('⚠️ Firebase 초기화 실패: $firebaseError');
    print('ℹ️ Firebase 관련 기능이 비활성화되지만 앱은 정상 작동합니다.');

    // Firebase 관련 기능들을 비활성화 상태로 설정
    // 필요시 여기에 fallback 로직 추가
  }
}
