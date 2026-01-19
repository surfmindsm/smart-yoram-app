import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Supabase Realtime Presence를 사용하여 앱 사용자의 온라인 상태를 관리하는 서비스
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final AuthService _authService = AuthService();
  RealtimeChannel? _channel;
  bool _isTracking = false;

  /// Presence 추적 시작
  ///
  /// 웹 관리자 대시보드에서 앱 사용자의 실시간 접속 상태를 확인할 수 있도록
  /// Supabase Realtime Presence 채널에 접속 정보를 전송합니다.
  Future<void> startTracking() async {
    if (_isTracking) {
      print('ℹ️ PRESENCE: 이미 Presence 추적 중입니다.');
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('⚠️ PRESENCE: 로그인된 사용자가 없어 Presence 추적을 시작할 수 없습니다.');
        return;
      }

      final supabase = Supabase.instance.client;

      // 관리자 대시보드와 동일한 채널 사용
      _channel = supabase.channel(
        'church-online-users',
        opts: RealtimeChannelConfig(
          key: user.id.toString(),
        ),
      );

      // Presence 이벤트 리스너 (디버깅용)
      _channel!
          .onPresenceSync((payload) {
            final state = _channel!.presenceState();
            print('📡 PRESENCE: 동기화 완료 - ${state.length}명 온라인');
          })
          .onPresenceJoin((payload) {
            print('👋 PRESENCE: 새 사용자 접속 - ${payload.newPresences}');
          })
          .onPresenceLeave((payload) {
            print('👋 PRESENCE: 사용자 종료 - ${payload.leftPresences}');
          });

      // 채널 구독
      await _channel!.subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          print('✅ PRESENCE: 채널 구독 성공');

          // 자신의 presence 상태 전송
          await _channel!.track({
            'user_id': user.id.toString(),
            'user_name': user.fullName.isNotEmpty ? user.fullName : user.username,
            'user_type': 'member', // 앱 사용자 구분 (웹 관리자와 구분)
            'church_id': user.churchId,
            'online_at': DateTime.now().toIso8601String(),
            'platform': 'flutter', // 플랫폼 정보
          });

          _isTracking = true;
          print('✅ PRESENCE: 추적 시작됨 - ${user.fullName} (ID: ${user.id})');
        } else if (error != null) {
          print('❌ PRESENCE: 구독 오류 - $error');
        }
      });
    } catch (e) {
      print('❌ PRESENCE: 초기화 오류 - $e');
    }
  }

  /// Presence 추적 중지
  ///
  /// 앱 종료 또는 백그라운드 전환 시 호출되어
  /// 관리자 대시보드에서 사용자가 오프라인 상태로 표시되도록 합니다.
  Future<void> stopTracking() async {
    if (_channel != null && _isTracking) {
      try {
        await _channel!.untrack();
        await _channel!.unsubscribe();
        _channel = null;
        _isTracking = false;
        print('✅ PRESENCE: 추적 중지됨');
      } catch (e) {
        print('❌ PRESENCE: 중지 오류 - $e');
      }
    }
  }

  /// 현재 온라인 사용자 목록 가져오기 (옵션)
  ///
  /// 앱에서 직접 사용하지는 않지만, 필요 시 현재 접속 중인 사용자 목록을 가져올 수 있습니다.
  List<Map<String, dynamic>> getOnlineUsers() {
    if (_channel == null) return [];

    final presenceState = _channel!.presenceState();
    final List<Map<String, dynamic>> users = [];

    // presenceState는 List<SinglePresenceState>
    // 각 SinglePresenceState는 List<Presence> presences를 가짐
    // 각 Presence는 Map<String, dynamic> payload를 가짐
    for (var singlePresence in presenceState) {
      for (var presence in singlePresence.presences) {
        users.add(Map<String, dynamic>.from(presence.payload));
      }
    }

    return users;
  }

  /// 현재 추적 중인지 여부
  bool get isTracking => _isTracking;
}
