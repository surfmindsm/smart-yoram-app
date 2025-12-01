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
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/font_settings_service.dart';

/// 전역 네비게이터 키 (FCM 알림 탭 처리용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 기본 화면 방향을 세로 모드로 설정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase 초기화를 더 안전하게 처리
  await initializeFirebase();

  // 글꼴 설정 서비스 초기화
  await FontSettingsService().initialize();

  // Supabase 초기화 (실제 설정 사용)
  await Supabase.initialize(
    url: 'https://adzhdsajdamrflvybhxq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkemhkc2FqZGFtcmZsdnliaHhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NDg5ODEsImV4cCI6MjA2OTQyNDk4MX0.pgn6M5_ihDFt3ojQmCoc3Qf8pc7LzRvQEIDT7g1nW3c',
  );

  // 네이버 지도 SDK 초기화
  await NaverMapSdk.instance.initialize(clientId: NaverMapConfig.clientId);

  runApp(
    ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (context) => FontSettingsService(),
        child: const MyApp(),
      ),
    ),
  );
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
                  fontFamily: 'Pretendard', // Google Fonts로 나중에 설정 가능
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
                  '/signup/selection': (context) => const SignupSelectionScreen(),
                  '/signup/church': (context) => const ChurchSignupScreen(),
                  '/signup/community': (context) => const CommunitySignupScreen(),
                  '/signup/success': (context) => const SignupSuccessScreen(),
                  // Admin routes
                  '/admin/members': (context) => const AdminMemberManagementScreen(),
                  '/admin/pastoral-care': (context) => const AdminPastoralCareListScreen(),
                  '/admin/notices': (context) => const AdminNoticeListScreen(),
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

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
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
            _isLoading = false;
          });
        }
        return;
      }

      final hasStoredAuth = await _authService.loadStoredAuth();
      if (mounted) {
        setState(() {
          _isLoggedIn = hasStoredAuth;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('인증 상태 확인 실패: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.church,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '스마트 교회요람',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                '로딩 중...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? const MainNavigation() : const LoginScreen();
  }
}

/// Firebase 초기화를 안전하게 처리하는 함수
Future<void> initializeFirebase() async {
  try {
    // Firebase 초기화 시도
    await Firebase.initializeApp();
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
