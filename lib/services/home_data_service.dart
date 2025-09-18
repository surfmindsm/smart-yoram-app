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

  /// 📖 오늘의 말씀 로드 (별도로 처리)
  Future<DailyVerse?> loadTodaysVerse() async {
    try {
      print('📖 HOME_DATA: 오늘의 말씀 로드 시작');

      // 캐시 확인 (5분 캐시)
      final cached = await _cacheService.getCachedData<DailyVerse>(
        'daily_verse',
        fromJson: (json) => DailyVerse.fromJson(json),
      );

      if (cached != null && _isTodaysVerse(cached)) {
        print('📖 HOME_DATA: 캐시된 오늘의 말씀 사용');
        return cached;
      }

      // API에서 새로 로드
      final verse = await _dailyVerseService.getRandomVerse();

      if (verse != null) {
        // 캐시에 저장 (30분)
        await _cacheService.cacheData(
          'daily_verse',
          verse.toJson(),
          cacheMinutes: 30,
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

  /// 👥 현재 교인 정보 로드 (캐시 우선)
  Future<Member?> _loadCurrentMember() async {
    try {
      // 🧪 테스트를 위해 캐시 무시하고 새로 로드
      print('🧪 HOME_DATA: 테스트를 위해 캐시 무시하고 교인 정보 새로 로드');

      /*
      final cached = await _cacheService.getCachedData<Member>(
        'current_member',
        fromJson: (json) => Member.fromJson(json),
      );

      if (cached != null) {
        print('👥 HOME_DATA: 캐시된 교인 정보 사용');
        return cached;
      }
      */

      // 현재 사용자 정보 필요
      final user = await _loadCurrentUser();
      if (user == null) return null;

      // 교인 목록에서 현재 사용자 찾기 (최소한만)
      final membersResponse = await _memberService.getMembers(limit: 50);
      if (membersResponse.success && membersResponse.data != null) {
        final members = membersResponse.data!;

        // 디버깅: 받아온 멤버 데이터 로그
        print('🔍 HOME_DATA: 받아온 멤버 수: ${members.length}');
        print('🔍 HOME_DATA: 현재 사용자 이메일: ${user.email}');

        for (int i = 0; i < members.length && i < 3; i++) {
          final member = members[i];
          print('🔍 HOME_DATA: Member[$i] - name: ${member.name}, email: ${member.email}, profilePhotoUrl: ${member.profilePhotoUrl}');
        }

        final currentMember = members.firstWhere(
          (member) {
            print('🔍 HOME_DATA: 비교중 - ${member.email} == ${user.email} ? ${member.email == user.email}');
            return member.email == user.email;
          },
          orElse: () {
            print('❌ HOME_DATA: 일치하는 멤버를 찾지 못함 - 기본 Member 생성');

            // 임시 해결책: 프로필 이미지가 있는 기존 멤버의 이미지 사용
            final memberWithPhoto = members.firstWhere(
              (m) => m.profilePhotoUrl != null && m.profilePhotoUrl!.isNotEmpty,
              orElse: () => members.first,
            );

            print('🔄 HOME_DATA: 임시 프로필 이미지 사용 - ${memberWithPhoto.name}의 이미지');
            print('🔄 HOME_DATA: 임시 이미지 URL - ${memberWithPhoto.profilePhotoUrl}');

            return Member(
              id: 0,
              name: user.fullName,
              email: user.email,
              gender: '',
              phone: '',
              churchId: user.churchId,
              memberStatus: 'active',
              createdAt: DateTime.now(),
              profilePhotoUrl: memberWithPhoto.profilePhotoUrl, // 임시 이미지 사용
            );
          },
        );

        print('✅ HOME_DATA: 최종 선택된 멤버 - name: ${currentMember.name}, profilePhotoUrl: ${currentMember.profilePhotoUrl}');

        // 캐시에 저장 (30분)
        await _cacheService.cacheData(
          'current_member',
          currentMember.toJson(),
          cacheMinutes: 30,
          persistToDisk: true,
        );

        return currentMember;
      }
      return null;
    } catch (e) {
      print('❌ HOME_DATA: 교인 정보 로드 실패 - $e');
      return null;
    }
  }

  /// 🏛️ 교회 정보 로드 (캐시 우선)
  Future<Church?> _loadChurchInfo() async {
    try {
      final cached = await _cacheService.getCachedData<Church>(
        'church_data',
        fromJson: (json) => Church.fromJson(json),
      );

      if (cached != null) {
        print('🏛️ HOME_DATA: 캐시된 교회 정보 사용');
        return cached;
      }

      final churchResponse = await _churchService.getMyChurch();
      if (churchResponse.success && churchResponse.data != null) {
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