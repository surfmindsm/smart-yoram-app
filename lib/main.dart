import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/bulletin_screen.dart';
import 'screens/notices_screen.dart';
import 'screens/member_card_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 12 기준 사이즈
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Smart Yoram App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Pretendard', // Google Fonts로 나중에 설정 가능
          ),
          home: const MainNavigation(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const MainNavigation(),
            '/members': (context) => const ProfileScreen(),
            '/attendance': (context) => const AttendanceScreen(),
            '/bulletin': (context) => const BulletinScreen(),
            '/notices': (context) => const NoticesScreen(),
            '/member-card': (context) => const MemberCardScreen(),
            '/contacts': (context) => const ContactsScreen(),
            '/calendar': (context) => const CalendarScreen(),
            '/prayer': (context) => const PrayerScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}


