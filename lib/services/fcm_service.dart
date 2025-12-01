import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/fcm_config.dart';
import '../models/push_notification.dart';
import '../models/push_notification_enhanced.dart';
import 'notification_service.dart';
import 'notification_service_enhanced.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import '../screens/chat/chat_room_screen.dart';

/// FCM 백그라운드 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log('백그라운드 메시지 수신: ${message.messageId}', name: 'FCM_BG');
  
  // 백그라운드에서도 로컬 알림 표시
  await FCMService.instance._showLocalNotification(message);
}

/// Firebase Cloud Messaging 서비스 클래스
class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._internal();

  FCMService._internal();

  late FirebaseMessaging _messaging;
  late FlutterLocalNotificationsPlugin _localNotifications;
  String? _currentToken;
  bool _initialMessageHandled = false; // 앱 종료 상태 알림 중복 처리 방지
  
  /// FCM 초기화 (안전 모드)
  Future<void> initialize() async {
    try {
      // Firebase 앱 상태 확인
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase가 초기화되지 않았습니다.');
      }
      
      // Firebase Messaging 인스턴스 초기화
      _messaging = FirebaseMessaging.instance;
      
      // 로컬 알림 플러그인 초기화
      await _initializeLocalNotifications();
      
      // 알림 권한 요청
      await _requestPermissions();
      
      // FCM 토큰 가져오기
      await _getToken();
      
      // 메시지 리스너 설정
      _setupMessageHandlers();
      
      // 백그라운드 메시지 핸들러 설정
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      developer.log('FCM 초기화 완료', name: 'FCM');
    } catch (e) {
      developer.log('FCM 초기화 실패: $e', name: 'FCM_ERROR');
      rethrow;
    }
  }
  
  /// 로컬 알림 플러그인 초기화
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    
    // Android 초기화 설정
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 초기화 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Android 알림 채널 생성
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }
  
  /// Android 알림 채널 생성
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // 기본 채널 생성
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          FCMConfig.defaultChannelId,
          FCMConfig.defaultChannelName,
          description: FCMConfig.defaultChannelDescription,
          importance: Importance.high,
        ),
      );
      
      // 타입별 채널 생성
      for (final channelConfig in FCMConfig.channels.values) {
        await androidPlugin.createNotificationChannel(
          channelConfig.toAndroidChannel(),
        );
      }
      
      developer.log('Android 알림 채널 생성 완료', name: 'FCM');
    }
  }
  
  /// 알림 권한 요청
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    
    developer.log('알림 권한 상태: ${settings.authorizationStatus}', name: 'FCM');
    
    // iOS에서 로컬 알림 권한도 요청
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }
  
  /// FCM 토큰 가져오기
  Future<String?> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      developer.log('FCM 토큰: $_currentToken', name: 'FCM');
      
      // 토큰이 변경될 때마다 백엔드에 등록
      if (_currentToken != null) {
        await _registerTokenToBackend(_currentToken!);
      }
      
      return _currentToken;
    } catch (e) {
      developer.log('FCM 토큰 가져오기 실패: $e', name: 'FCM_ERROR');
      return null;
    }
  }
  
  /// 토큰을 백엔드에 등록 (새로운 API 사용)
  Future<void> _registerTokenToBackend(String token) async {
    try {
      // 1. Supabase device_tokens 테이블에 저장 (P2P 채팅 푸시 알림용)
      await _saveTokenToSupabase(token);

      // 2. 기존 REST API에도 등록 (기존 시스템 호환성)
      final result = await NotificationServiceEnhanced.instance.registerDevice(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
        deviceId: await _getDeviceId(),
        appVersion: await _getAppVersion(),
      );

      if (result.isSuccess) {
        developer.log('✅ 디바이스 토큰 등록 성공 (REST API)', name: 'FCM');
      } else {
        developer.log('❌ 디바이스 토큰 등록 실패 (REST API): ${result.message}', name: 'FCM_ERROR');
      }

      // 3. 새로운 API를 사용한 기기 등록
      try {
        final deviceResult = await NotificationService.instance.registerDevice(token);
        if (deviceResult.isSuccess) {
          developer.log('✅ 새로운 API 기기 등록 성공', name: 'FCM');
        } else {
          developer.log('❌ 새로운 API 기기 등록 실패: ${deviceResult.message}', name: 'FCM_ERROR');
        }
      } catch (apiError) {
        developer.log('❌ 새로운 API 등록 오류: $apiError', name: 'FCM_ERROR');
      }

    } catch (e) {
      developer.log('❌ 토큰 백엔드 등록 중 오류: $e', name: 'FCM_ERROR');
    }
  }

  /// Supabase device_tokens 테이블에 FCM 토큰 저장
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      print('🔄 FCM: Supabase 토큰 저장 시도 시작...');

      final authService = AuthService();
      final userResponse = await authService.getCurrentUser();

      print('👤 FCM: getCurrentUser() 결과: ${userResponse.data != null ? "사용자 존재 (ID: ${userResponse.data!.id})" : "null"}');

      if (userResponse.data == null) {
        print('⚠️ FCM: 로그인되지 않아 Supabase에 토큰 저장 생략');
        return;
      }

      final userId = userResponse.data!.id;
      final platform = Platform.isIOS ? 'ios' : 'android';
      final deviceId = await _getDeviceId();
      final appVersion = await _getAppVersion();

      print('📝 FCM: 저장할 토큰 정보: userId=$userId, platform=$platform, token=${token.substring(0, 20)}...');

      // Supabase client 가져오기
      final supabase = Supabase.instance.client;

      // upsert로 중복 방지 (user_id + fcm_token 조합은 UNIQUE)
      final result = await supabase.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'device_id': deviceId,
        'app_version': appVersion,
        'is_active': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,fcm_token');

      print('✅ FCM: Supabase device_tokens 테이블에 토큰 저장 완료 (result: $result)');
    } catch (e, stackTrace) {
      print('❌ FCM: Supabase 토큰 저장 실패: $e');
      print('❌ FCM: 스택 트레이스: $stackTrace');
    }
  }

  /// 로그인 후 토큰 재등록 (외부에서 호출 가능)
  Future<void> refreshTokenRegistration() async {
    print('🔄 FCM: refreshTokenRegistration() 호출됨');
    print('🔄 FCM: _currentToken = ${_currentToken != null ? "존재 (${_currentToken!.substring(0, 20)}...)" : "null"}');

    if (_currentToken != null) {
      print('🔄 FCM: 로그인 완료 - FCM 토큰 재등록 시작');
      await _saveTokenToSupabase(_currentToken!);
    } else {
      print('⚠️ FCM: FCM 토큰이 없어서 재등록 불가');
      print('⚠️ FCM: Firebase 초기화 상태를 확인하세요');
    }
  }
  
  /// 메시지 핸들러 설정
  void _setupMessageHandlers() {
    // 1. 앱이 포어그라운드에 있을 때 메시지 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('포어그라운드 메시지 수신: ${message.messageId}', name: 'FCM');
      _handleForegroundMessage(message);
    });

    // 2. 앱이 백그라운드에서 알림 탭으로 열릴 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('백그라운드에서 알림 탭으로 앱 열림: ${message.messageId}', name: 'FCM');
      _handleNotificationTap(message);
    });

    // 3. 앱이 완전히 종료된 상태에서 알림 탭으로 실행될 때
    _checkInitialMessage();

    // 4. 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((String token) {
      developer.log('FCM 토큰 갱신: $token', name: 'FCM');
      _currentToken = token;
      _registerTokenToBackend(token);
    });
  }

  /// 앱 종료 상태에서 알림 탭으로 실행되었는지 확인
  Future<void> _checkInitialMessage() async {
    try {
      // getInitialMessage는 앱이 종료된 상태에서 알림을 탭하고 실행했을 때만 메시지를 반환
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null && !_initialMessageHandled) {
        developer.log('앱 종료 상태에서 알림 탭으로 실행: ${initialMessage.messageId}', name: 'FCM');
        _initialMessageHandled = true;

        // 약간의 지연 후 처리 (앱 초기화 완료 대기)
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage);
        });
      }
    } catch (e) {
      developer.log('초기 메시지 확인 실패: $e', name: 'FCM_ERROR');
    }
  }
  
  /// 포어그라운드에서 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // 로컬 알림으로 표시
    await _showLocalNotification(message);
    
    // 앱 내 알림 처리 (예: 스낵바, 다이얼로그 등)
    _showInAppNotification(message);
  }
  
  /// 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = PushNotificationModel.fromFirebaseMessage(message);
      
      // 알림 타입에 따른 채널 설정
      final channelId = notification.type?.channelId ?? FCMConfig.defaultChannelId;
      final channelConfig = FCMConfig.channels[notification.type?.name] ?? 
          FCMConfig.channels['custom']!;
      
      // 채팅 알림인 경우 BigTextStyle 사용 (2줄 표시)
      final isChatNotification = message.data['type'] == 'chat_message';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelConfig.name,
        channelDescription: channelConfig.description,
        importance: channelConfig.importance,
        priority: Priority.high,
        icon: 'ic_notification',
        color: const Color(0xFF1976D2),
        enableVibration: true,
        playSound: true,
        // 채팅 알림인 경우 BigTextStyle 사용
        styleInformation: isChatNotification
            ? BigTextStyleInformation(
                notification.body ?? '',
                contentTitle: notification.title,
                summaryText: '',
                htmlFormatContentTitle: false,
                htmlFormatContent: false,
              )
            : null,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        notification.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(notification.toJson()),
      );
      
      developer.log('로컬 알림 표시 완료: ${notification.title}', name: 'FCM');
    } catch (e) {
      developer.log('로컬 알림 표시 실패: $e', name: 'FCM_ERROR');
    }
  }
  
  /// 앱 내 알림 표시
  void _showInAppNotification(RemoteMessage message) {
    // 전역 네비게이터를 통해 스낵바 표시
    // 실제 구현에서는 Riverpod 상태 관리나 이벤트 버스 사용 권장
    developer.log('앱 내 알림 표시: ${message.notification?.title}', name: 'FCM');
  }
  
  /// 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    final notification = PushNotificationModel.fromFirebaseMessage(message);
    developer.log('알림 탭 처리: ${notification.title}', name: 'FCM');

    // 알림 타입에 따른 화면 이동
    _navigateToRelevantScreen(notification, message.data);
  }
  
  /// 로컬 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final json = jsonDecode(response.payload!);
        final notification = PushNotificationModel.fromJson(json);
        final data = json['data'] as Map<String, dynamic>?;
        developer.log('로컬 알림 탭: ${notification.title}', name: 'FCM');

        _navigateToRelevantScreen(notification, data ?? {});
      } catch (e) {
        developer.log('로컬 알림 탭 처리 실패: $e', name: 'FCM_ERROR');
      }
    }
  }
  
  /// 알림 타입에 따른 화면 이동
  void _navigateToRelevantScreen(
    PushNotificationModel notification,
    Map<String, dynamic> data,
  ) {
    try {
      // data에서 알림 타입 확인
      final type = data['type'] as String?;

      developer.log('화면 이동: type=$type, data=$data', name: 'FCM');

      // 채팅 메시지 알림
      if (type == 'chat_message') {
        final roomId = int.tryParse(data['room_id']?.toString() ?? '');
        if (roomId != null) {
          _navigateToChatRoom(roomId, data);
          return;
        }
      }

      // 다른 알림 타입 처리 (추후 확장 가능)
      switch (notification.type?.name) {
        case 'announcement':
          developer.log('공지사항 화면으로 이동 예정', name: 'FCM');
          // TODO: 공지사항 화면 이동
          break;
        case 'worship_reminder':
          developer.log('예배 화면으로 이동 예정', name: 'FCM');
          // TODO: 예배 화면 이동
          break;
        default:
          developer.log('기본 알림 처리: ${notification.type?.displayName ?? 'custom'}', name: 'FCM');
      }
    } catch (e) {
      developer.log('화면 이동 실패: $e', name: 'FCM_ERROR');
    }
  }

  /// 채팅방으로 이동
  Future<void> _navigateToChatRoom(int roomId, Map<String, dynamic> data) async {
    try {
      // WidgetsBinding을 통해 현재 BuildContext에서 Navigator 찾기
      final context = WidgetsBinding.instance.rootElement;
      if (context == null) {
        developer.log('❌ BuildContext를 찾을 수 없습니다', name: 'FCM_ERROR');
        return;
      }

      final navigator = Navigator.of(context);

      // ChatService를 통해 채팅방 정보 조회
      final chatService = ChatService();
      final chatRooms = await chatService.getChatRooms();

      if (chatRooms.isEmpty) {
        developer.log('❌ 채팅방 목록이 비어있습니다', name: 'FCM_ERROR');
        return;
      }

      // roomId에 해당하는 채팅방 찾기
      final chatRoom = chatRooms.firstWhere(
        (room) => room.id == roomId,
        orElse: () => throw Exception('채팅방을 찾을 수 없습니다'),
      );

      // 채팅방 화면으로 직접 이동
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
        ),
      );

      developer.log('✅ 채팅방으로 이동: room_id=$roomId', name: 'FCM');
    } catch (e) {
      developer.log('❌ 채팅방 이동 실패: $e', name: 'FCM_ERROR');
    }
  }
  
  /// 디바이스 ID 가져오기
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isIOS) {
        return 'ios_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        return 'android_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      developer.log('디바이스 ID 생성 실패: $e', name: 'FCM_WARNING');
      return 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// 앱 버전 가져오기
  Future<String> _getAppVersion() async {
    try {
      // TODO: package_info_plus 패키지를 사용하여 실제 버전 가져오기
      return '1.0.0';
    } catch (e) {
      developer.log('앱 버전 가져오기 실패: $e', name: 'FCM_WARNING');
      return '1.0.0';
    }
  }
  
  /// 현재 FCM 토큰 반환
  String? get currentToken => _currentToken;
  
  /// 토큰 갱신
  Future<String?> refreshToken() async {
    try {
      await _messaging.deleteToken();
      return await _getToken();
    } catch (e) {
      developer.log('토큰 갱신 실패: $e', name: 'FCM_ERROR');
      return null;
    }
  }

  /// 로그아웃 시 토큰 비활성화
  Future<void> deactivateToken() async {
    try {
      print('🔄 FCM: 토큰 비활성화 시도');

      final authService = AuthService();
      final userResponse = await authService.getCurrentUser();

      if (userResponse.data == null) {
        print('⚠️ FCM: 로그인된 사용자가 없어 토큰 비활성화 생략');
        return;
      }

      if (_currentToken == null) {
        print('⚠️ FCM: 저장된 토큰이 없어 비활성화 생략');
        return;
      }

      final userId = userResponse.data!.id;
      final supabase = Supabase.instance.client;

      // device_tokens 테이블에서 해당 토큰 비활성화
      await supabase
          .from('device_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('fcm_token', _currentToken!);

      print('✅ FCM: 토큰 비활성화 완료 (user_id: $userId)');
    } catch (e, stackTrace) {
      print('❌ FCM: 토큰 비활성화 실패: $e');
      print('❌ FCM: 스택 트레이스: $stackTrace');
    }
  }

  /// FCM 서비스 정리
  Future<void> dispose() async {
    // 필요시 리소스 정리
  }
}
