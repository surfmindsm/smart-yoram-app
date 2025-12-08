import '../models/user.dart' as app_user;
import '../models/member.dart';
import '../models/church.dart';
import '../models/daily_verse.dart';
import '../models/api_response.dart';
import 'cache_service.dart';
import 'user_service.dart';
import 'member_service.dart';
import 'church_service.dart';
import 'daily_verse_service.dart';

class HomeDataService {
  static final HomeDataService _instance = HomeDataService._internal();
  factory HomeDataService() => _instance;
  HomeDataService._internal();

  final CacheService _cacheService = CacheService();
  final UserService _userService = UserService();
  final MemberService _memberService = MemberService();
  final ChurchService _churchService = ChurchService();
  final DailyVerseService _dailyVerseService = DailyVerseService();

  /// 🚀 홈화면 필수 데이터만 빠르게 로드
  Future<HomeEssentialData> loadEssentialData() async {
    print('🏠 HOME_DATA: 필수 데이터 로드 시작');

    // 멤버 캐시 무효화 (디버깅용)
    await _cacheService.invalidateCache('current_member');
    print('🧹 HOME_DATA: current_member 캐시 무효화');

    try {
      final futures = await Future.wait([
        _loadCurrentUser(),
        _loadCurrentMember(),
        _loadChurchInfo(),
      ]);

      final user = futures[0] as app_user.User?;
      final member = futures[1] as Member?;
      final church = futures[2] as Church?;

      print('🏠 HOME_DATA: 필수 데이터 로드 완료');
      return HomeEssentialData(
        user: user,
        member: member,
        church: church,
      );
    } catch (e) {
      print('❌ HOME_DATA: 필수 데이터 로드 실패 - $e');
      return HomeEssentialData();
    }
  }

  /// 📖 오늘의 말씀 로드 (별도로 처리) - 오프라인 우선 전략
  Future<DailyVerse?> loadTodaysVerse() async {
    try {
      print('📖 HOME_DATA: 오늘의 말씀 로드 시작');

      // 캐시 확인 (오래된 캐시라도 즉시 반환)
      final cached = await _cacheService.getCachedData<DailyVerse>(
        'daily_verse',
        fromJson: (json) => DailyVerse.fromJson(json),
      );

      if (cached != null) {
        print('📖 HOME_DATA: 캐시된 오늘의 말씀 즉시 사용 (오프라인 우선)');

        // 백그라운드에서 새 데이터 로드 시도 (fire-and-forget)
        _refreshVerseInBackground();

        return cached;
      }

      // 캐시가 없으면 API에서 로드 (3초 타임아웃)
      final verse = await _dailyVerseService.getRandomVerse();

      if (verse != null) {
        // 캐시에 저장 (24시간 - 하루 동안 유지)
        await _cacheService.cacheData(
          'daily_verse',
          verse.toJson(),
          cacheMinutes: 1440, // 24시간
          persistToDisk: true,
        );

        print('📖 HOME_DATA: 새로운 오늘의 말씀 로드 완료');
      }

      return verse;
    } catch (e) {
      print('❌ HOME_DATA: 오늘의 말씀 로드 실패 - $e');
      return null;
    }
  }

  /// 🔄 백그라운드에서 오늘의 말씀 새로고침 (fire-and-forget)
  void _refreshVerseInBackground() {
    Future.microtask(() async {
      try {
        print('🔄 HOME_DATA: 백그라운드에서 오늘의 말씀 갱신 시작');

        final verse = await _dailyVerseService.getRandomVerse();

        if (verse != null) {
          await _cacheService.cacheData(
            'daily_verse',
            verse.toJson(),
            cacheMinutes: 1440,
            persistToDisk: true,
          );
          print('✅ HOME_DATA: 백그라운드 갱신 완료');
        }
      } catch (e) {
        print('⚠️ HOME_DATA: 백그라운드 갱신 실패 (무시) - $e');
      }
    });
  }

  /// 👤 현재 사용자 정보 로드 (캐시 우선)
  Future<app_user.User?> _loadCurrentUser() async {
    try {
      // 🧪 테스트를 위해 캐시 무시하고 새로 로드
      print('🧪 HOME_DATA: 테스트를 위해 캐시 무시하고 사용자 정보 새로 로드');

      /*
      final cached = await _cacheService.getCachedData<app_user.User>(
        'user_data',
        fromJson: (json) => app_user.User.fromJson(json),
      );

      if (cached != null) {
        print('👤 HOME_DATA: 캐시된 사용자 정보 사용');
        return cached;
      }
      */

      final userResponse = await _userService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        await _cacheService.cacheData(
          'user_data',
          userResponse.data!.toJson(),
          cacheMinutes: 60,
          persistToDisk: true,
        );
        return userResponse.data;
      }
      return null;
    } catch (e) {
      print('❌ HOME_DATA: 사용자 정보 로드 실패 - $e');
      return null;
    }
  }

  /// 👥 현재 교인 정보 로드 (user_id로 직접 조회)
  Future<Member?> _loadCurrentMember() async {
    try {
      print('👥 HOME_DATA: 교인 정보 로드 시작');

      // 현재 사용자 정보 필요
      final user = await _loadCurrentUser();
      if (user == null) {
        print('❌ HOME_DATA: 사용자 정보가 없음');
        return null;
      }

      print('👥 HOME_DATA: 현재 사용자 ID: ${user.id}, 이메일: ${user.email}');

      // members 테이블에서 user_id로 직접 조회
      final memberResponse = await _memberService.getMemberByUserId(user.id);

      if (memberResponse.success && memberResponse.data != null) {
        final member = memberResponse.data!;

        print('✅ HOME_DATA: 교인 정보 조회 성공');
        print('  - 이름: ${member.name}');
        print('  - 이메일: ${member.email}');
        print('  - 프로필 이미지 URL: ${member.profilePhotoUrl}');
        print('  - Full 프로필 이미지 URL: ${member.fullProfilePhotoUrl}');

        // 캐시에 저장 (30분)
        await _cacheService.cacheData(
          'current_member',
          member.toJson(),
          cacheMinutes: 30,
          persistToDisk: true,
        );

        return member;
      } else {
        print('❌ HOME_DATA: user_id로 교인 정보를 찾지 못함 - ${memberResponse.message}');

        // fallback: 이메일로 검색
        print('🔄 HOME_DATA: 이메일로 재시도 - ${user.email}');
        final membersResponse = await _memberService.getMembers(limit: 100);

        if (membersResponse.success && membersResponse.data != null) {
          final members = membersResponse.data!;

          final memberByEmail = members.where((m) => m.email == user.email).firstOrNull;

          if (memberByEmail != null) {
            print('✅ HOME_DATA: 이메일로 교인 정보 찾음 - ${memberByEmail.name}');

            // 캐시에 저장
            await _cacheService.cacheData(
              'current_member',
              memberByEmail.toJson(),
              cacheMinutes: 30,
              persistToDisk: true,
            );

            return memberByEmail;
          }
        }

        print('❌ HOME_DATA: 교인 정보를 찾을 수 없음');
        return null;
      }
    } catch (e) {
      print('❌ HOME_DATA: 교인 정보 로드 실패 - $e');
      return null;
    }
  }

  /// 🏛️ 교회 정보 로드 (캐시 무시하고 항상 새로 로드)
  Future<Church?> _loadChurchInfo() async {
    try {
      // 🧪 테스트를 위해 캐시 무시하고 새로 로드
      print('🧪 HOME_DATA: 캐시 무시하고 교회 정보 새로 로드');

      /*
      final cached = await _cacheService.getCachedData<Church>(
        'church_data',
        fromJson: (json) => Church.fromJson(json),
      );

      if (cached != null) {
        print('🏛️ HOME_DATA: 캐시된 교회 정보 사용');
        return cached;
      }
      */

      final churchResponse = await _churchService.getMyChurch();
      if (churchResponse.success && churchResponse.data != null) {
        print('✅ HOME_DATA: 교회 정보 API 로드 성공');
        print('  - 교회명: ${churchResponse.data!.name}');
        print('  - 전화번호: ${churchResponse.data!.phone}');

        await _cacheService.cacheData(
          'church_data',
          churchResponse.data!.toJson(),
          cacheMinutes: 120, // 2시간 (교회 정보는 자주 변경되지 않음)
          persistToDisk: true,
        );
        return churchResponse.data;
      }
      return null;
    } catch (e) {
      print('❌ HOME_DATA: 교회 정보 로드 실패 - $e');
      return null;
    }
  }

  /// 오늘의 말씀이 오늘 것인지 확인
  bool _isTodaysVerse(DailyVerse verse) {
    // 간단한 날짜 체크 (실제로는 더 정교한 로직 필요)
    return true; // 일단 항상 true로 설정
  }

  /// 캐시 무효화
  Future<void> invalidateCache() async {
    await _cacheService.invalidateCache('user_data');
    await _cacheService.invalidateCache('current_member');
    await _cacheService.invalidateCache('church_data');
    await _cacheService.invalidateCache('daily_verse');
    print('🧹 HOME_DATA: 모든 캐시 무효화 완료');
  }
}

/// 홈화면 필수 데이터 클래스
class HomeEssentialData {
  final app_user.User? user;
  final Member? member;
  final Church? church;

  HomeEssentialData({
    this.user,
    this.member,
    this.church,
  });

  bool get hasAllData => user != null && member != null && church != null;
  bool get hasUserData => user != null;
}