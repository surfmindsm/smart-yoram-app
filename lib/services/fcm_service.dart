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
import 'notification_settings_service.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'badge_service.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/community/community_detail_screen.dart';
import '../main.dart' show navigatorKey;

/// FCM 백그라운드 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log('백그라운드 메시지 수신: ${message.messageId}', name: 'FCM_BG');

  // 백그라운드에서도 로컬 알림 표시
  await FCMService.instance._showLocalNotification(message);

  // 데이터베이스 트리거 완료 대기 (메시지 저장 및 unread_count 업데이트)
  await Future.delayed(const Duration(milliseconds: 500));

  // 배지 업데이트 (백그라운드에서도 실행)
  try {
    await BadgeService.instance.initialize();
    await BadgeService.instance.updateBadge();
    developer.log('✅ 백그라운드 배지 업데이트 완료', name: 'FCM_BG');
  } catch (e) {
    developer.log('❌ 백그라운드 배지 업데이트 실패: $e', name: 'FCM_BG_ERROR');
  }
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

      // iOS에서 포어그라운드 알림 자동 표시 설정
      if (Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        developer.log('✅ iOS 포어그라운드 알림 자동 표시 설정 완료', name: 'FCM');
      }

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

      // BadgeService 초기화
      await BadgeService.instance.initialize();

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

    // iOS 초기화 설정 - 권한 요청 활성화
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    developer.log('로컬 알림 플러그인 초기화: ${initialized == true ? "성공" : "실패"}', name: 'FCM');

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

    developer.log('🔔 FCM 알림 권한 상태: ${settings.authorizationStatus}', name: 'FCM');

    // iOS에서 로컬 알림 권한도 요청
    if (Platform.isIOS) {
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final iosGranted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        developer.log('🔔 iOS 로컬 알림 권한: ${iosGranted == true ? "허용 ✅" : "거부 ❌"}', name: 'FCM');

        // iOS 권한 상태 재확인
        final checkResult = await iosPlugin.checkPermissions();
        developer.log('🔔 iOS 권한 재확인: $checkResult', name: 'FCM');
      }
    }

    // Android 13+ 알림 권한 요청
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final androidGranted = await androidPlugin.requestNotificationsPermission();
        developer.log('🔔 Android 로컬 알림 권한: ${androidGranted == true ? "허용 ✅" : "거부 ❌"}', name: 'FCM');

        // 권한이 거부되었으면 경고
        if (androidGranted == false) {
          developer.log('⚠️ Android 알림 권한이 거부되었습니다. 시스템 설정에서 권한을 허용해주세요.', name: 'FCM');
        }
      }
    }
  }
  
  /// FCM 토큰 가져오기
  Future<String?> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      developer.log('FCM 토큰: $_currentToken', name: 'FCM');

      // 토큰이 변경될 때마다 백엔드에 등록 (백그라운드에서 실행 - await 제거)
      if (_currentToken != null) {
        // 백그라운드로 실행하여 앱 초기화를 차단하지 않음
        _registerTokenToBackend(_currentToken!).catchError((e) {
          developer.log('백그라운드 토큰 등록 실패: $e', name: 'FCM_ERROR');
        });
        developer.log('✅ FCM 토큰 백그라운드 등록 시작 (앱 초기화 차단하지 않음)', name: 'FCM');
      }

      return _currentToken;
    } catch (e) {
      developer.log('FCM 토큰 가져오기 실패: $e', name: 'FCM_ERROR');
      return null;
    }
  }
  
  /// 토큰을 백엔드에 등록 (새로운 API 사용 - 병렬 처리 + 타임아웃)
  Future<void> _registerTokenToBackend(String token) async {
    try {
      final deviceId = await _getDeviceId();
      final appVersion = await _getAppVersion();

      // 모든 API 호출을 병렬로 처리 (타임아웃 10초)
      final results = await Future.wait([
        // 1. Supabase device_tokens 테이블에 저장
        _saveTokenToSupabase(token)
            .timeout(const Duration(seconds: 10))
            .catchError((e) {
          developer.log('❌ Supabase 토큰 저장 실패: $e', name: 'FCM_ERROR');
        }),

        // 2. 기존 REST API에 등록
        NotificationServiceEnhanced.instance
            .registerDevice(
              token: token,
              platform: Platform.isIOS ? 'ios' : 'android',
              deviceId: deviceId,
              appVersion: appVersion,
            )
            .timeout(const Duration(seconds: 10))
            .then((result) {
          if (result.isSuccess) {
            developer.log('✅ 디바이스 토큰 등록 성공 (REST API)', name: 'FCM');
          } else {
            developer.log('❌ 디바이스 토큰 등록 실패 (REST API): ${result.message}', name: 'FCM_ERROR');
          }
        }).catchError((e) {
          developer.log('❌ REST API 등록 타임아웃/오류: $e', name: 'FCM_ERROR');
        }),

        // 3. 새로운 API 기기 등록
        NotificationService.instance
            .registerDevice(token)
            .timeout(const Duration(seconds: 10))
            .then((result) {
          if (result.isSuccess) {
            developer.log('✅ 새로운 API 기기 등록 성공', name: 'FCM');
          } else {
            developer.log('❌ 새로운 API 기기 등록 실패: ${result.message}', name: 'FCM_ERROR');
          }
        }).catchError((e) {
          developer.log('❌ 새로운 API 등록 타임아웃/오류: $e', name: 'FCM_ERROR');
        }),
      ], eagerError: false); // 에러가 나도 다른 Future는 계속 실행

      developer.log('✅ 백엔드 토큰 등록 완료 (병렬 처리)', name: 'FCM');
    } catch (e) {
      developer.log('❌ 토큰 백엔드 등록 중 치명적 오류: $e', name: 'FCM_ERROR');
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

  // 🚫 알림 저장은 백엔드 Edge Function에서 처리하므로 앱에서는 하지 않음
  // 중복 저장 방지를 위해 주석 처리
  /*
  /// Supabase notifications 테이블에 알림 저장
  Future<void> _saveNotificationToSupabase(RemoteMessage message) async {
    try {
      developer.log('💾 알림 Supabase 저장 시작', name: 'FCM');

      final authService = AuthService();
      final userResponse = await authService.getCurrentUser();

      if (userResponse.data == null) {
        developer.log('⚠️ 로그인되지 않아 알림 저장 생략', name: 'FCM');
        return;
      }

      final userId = userResponse.data!.id;
      final supabase = Supabase.instance.client;

      // FCM 메시지 데이터 파싱
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      final type = message.data['type'] as String? ?? 'custom';
      final relatedId = message.data['post_id'] != null
          ? int.tryParse(message.data['post_id'].toString())
          : (message.data['related_id'] != null
              ? int.tryParse(message.data['related_id'].toString())
              : null);
      final relatedType = message.data['table_name'] as String? ?? message.data['related_type'] as String?;

      developer.log('💾 저장할 알림 정보: userId=$userId, type=$type, relatedId=$relatedId, relatedType=$relatedType', name: 'FCM');

      // notifications 테이블에 insert
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'is_read': false,
        'related_id': relatedId,
        'related_type': relatedType,
        'data': message.data,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      developer.log('✅ 알림 Supabase 저장 완료', name: 'FCM');
    } catch (e, stackTrace) {
      developer.log('❌ 알림 Supabase 저장 실패: $e', name: 'FCM_ERROR');
      developer.log('스택 트레이스: $stackTrace', name: 'FCM_ERROR');
    }
  }
  */

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
      developer.log('🔥🔥🔥 포어그라운드 메시지 수신 🔥🔥🔥', name: 'FCM');
      developer.log('메시지 ID: ${message.messageId}', name: 'FCM');
      developer.log('제목: ${message.notification?.title}', name: 'FCM');
      developer.log('내용: ${message.notification?.body}', name: 'FCM');
      developer.log('데이터: ${message.data}', name: 'FCM');
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
    developer.log('🔔 포어그라운드 메시지 처리 시작: ${message.notification?.title}', name: 'FCM');

    try {
      // iOS: setForegroundNotificationPresentationOptions로 자동 표시되므로 로컬 알림 불필요
      // Android: 로컬 알림을 수동으로 표시해야 함
      if (Platform.isAndroid) {
        developer.log('📱 Android: 로컬 알림 표시 시작', name: 'FCM');
        await _showLocalNotification(message);
        developer.log('✅ Android: 로컬 알림 표시 완료', name: 'FCM');
      } else {
        developer.log('📱 iOS: Firebase가 자동으로 알림 표시 (로컬 알림 불필요)', name: 'FCM');
      }

      developer.log('✅✅✅ 포어그라운드 알림 처리 완료 ✅✅✅', name: 'FCM');

      // 배지 업데이트 (알림 받음)
      BadgeService.instance.updateBadge().catchError((e) {
        developer.log('❌ 배지 업데이트 실패: $e', name: 'FCM_ERROR');
      });
    } catch (e, stackTrace) {
      developer.log('❌ 포어그라운드 메시지 처리 중 오류: $e', name: 'FCM_ERROR');
      developer.log('스택 트레이스: $stackTrace', name: 'FCM_ERROR');
    }
  }
  
  /// 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      developer.log('📱📱📱 로컬 알림 생성 시작 📱📱📱', name: 'FCM');

      // 알림 타입 확인
      final notificationType = message.data['type'] as String?;
      developer.log('📱 알림 타입 확인: $notificationType', name: 'FCM');

      // 사용자 설정 확인 - 알림이 꺼져있으면 표시하지 않음
      final settingsService = NotificationSettingsService.instance;
      final shouldShow = await settingsService.shouldShowNotification(notificationType);

      if (!shouldShow) {
        developer.log('⚠️ 사용자가 이 알림 타입을 끔: $notificationType', name: 'FCM');
        developer.log('❌ 알림 표시 취소됨 (사용자 설정)', name: 'FCM');
        return; // 알림 표시하지 않고 종료
      }

      developer.log('✅ 알림 표시 허용됨 (사용자 설정)', name: 'FCM');

      final notification = PushNotificationModel.fromFirebaseMessage(message);

      // 알림 타입에 따른 채널 설정
      final channelId = notification.type?.channelId ?? FCMConfig.defaultChannelId;
      final channelConfig = FCMConfig.channels[notification.type?.name] ??
          FCMConfig.channels['custom']!;

      // 채팅 알림인 경우 BigTextStyle 사용 (2줄 표시)
      final isChatNotification = message.data['type'] == 'chat_message';

      developer.log('📱 알림 타입: ${isChatNotification ? "채팅" : "일반"}', name: 'FCM');
      developer.log('📱 제목: ${notification.title}, 내용: ${notification.body}', name: 'FCM');
      developer.log('📱 채널 ID: $channelId', name: 'FCM');

      // Android 알림 설정 - 최대한 강력하게
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelConfig.name,
        channelDescription: channelConfig.description,
        importance: Importance.max, // max로 변경
        priority: Priority.max, // max로 변경
        icon: 'ic_notification', // drawable의 ic_notification 사용
        color: const Color(0xFF1976D2),
        enableVibration: true,
        playSound: true,
        // 포어그라운드 알림 강제 표시
        visibility: NotificationVisibility.public,
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
        // 자동 취소
        autoCancel: true,
        // LED 표시
        enableLights: true,
        ledColor: const Color(0xFF1976D2),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // iOS 알림 설정 - 모든 옵션 활성화
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        // 중요 알림
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 고유한 알림 ID 생성 (중복 방지)
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      developer.log('📱 알림 ID: $notificationId', name: 'FCM');
      developer.log('📱 알림 표시 시작...', name: 'FCM');

      await _localNotifications.show(
        notificationId,
        notification.title ?? '새 메시지',
        notification.body ?? '',
        notificationDetails,
        payload: jsonEncode(notification.toJson()),
      );

      developer.log('✅✅✅ 로컬 알림 show() 호출 완료: ${notification.title} ✅✅✅', name: 'FCM');

      // 알림이 실제로 표시되었는지 확인 (Android)
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          final activeNotifications = await androidPlugin.getActiveNotifications();
          developer.log('📱 현재 활성 알림 개수: ${activeNotifications.length}', name: 'FCM');
        }
      }

      // iOS에서 권한 재확인
      if (Platform.isIOS) {
        final iosPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          final permissions = await iosPlugin.checkPermissions();
          developer.log('📱 iOS 현재 권한 상태: $permissions', name: 'FCM');
        }
      }
    } catch (e, stackTrace) {
      developer.log('❌❌❌ 로컬 알림 표시 실패: $e ❌❌❌', name: 'FCM_ERROR');
      developer.log('❌ 스택 트레이스: $stackTrace', name: 'FCM_ERROR');
    }
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

      // 커뮤니티 좋아요 알림
      if (type == 'community_like') {
        final postId = int.tryParse(data['post_id']?.toString() ?? '');
        final tableName = data['table_name'] as String?;
        final categoryTitle = data['category_title'] as String?;

        if (postId != null && tableName != null && categoryTitle != null) {
          _navigateToCommunityDetail(postId, tableName, categoryTitle);
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
      developer.log('🔔 채팅방 이동 시작: room_id=$roomId', name: 'FCM');

      // navigatorKey를 통해 Navigator 접근
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        developer.log('❌ Navigator를 찾을 수 없습니다', name: 'FCM_ERROR');
        return;
      }

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
        orElse: () => throw Exception('채팅방을 찾을 수 없습니다 (room_id: $roomId)'),
      );

      developer.log('✅ 채팅방 정보 조회 완료: ${chatRoom.displayTitle}', name: 'FCM');

      // 채팅방 화면으로 직접 이동
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
        ),
      );

      developer.log('✅ 채팅방으로 이동 완료: room_id=$roomId', name: 'FCM');

      // 배지 업데이트 (채팅방 나올 때 읽은 메시지 반영)
      BadgeService.instance.updateBadge().catchError((e) {
        developer.log('❌ 배지 업데이트 실패: $e', name: 'FCM_ERROR');
      });
    } catch (e, stackTrace) {
      developer.log('❌ 채팅방 이동 실패: $e', name: 'FCM_ERROR');
      developer.log('스택 트레이스: $stackTrace', name: 'FCM_ERROR');
    }
  }

  /// 커뮤니티 상세 화면으로 이동
  Future<void> _navigateToCommunityDetail(
    int postId,
    String tableName,
    String categoryTitle,
  ) async {
    try {
      developer.log('🔔 커뮤니티 상세로 이동 시작: post_id=$postId, table=$tableName', name: 'FCM');

      // navigatorKey를 통해 Navigator 접근
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        developer.log('❌ Navigator를 찾을 수 없습니다', name: 'FCM_ERROR');
        return;
      }

      // 커뮤니티 상세 화면으로 직접 이동
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => CommunityDetailScreen(
            postId: postId,
            tableName: tableName,
            categoryTitle: categoryTitle,
          ),
        ),
      );

      developer.log('✅ 커뮤니티 상세로 이동 완료: post_id=$postId', name: 'FCM');
    } catch (e, stackTrace) {
      developer.log('❌ 커뮤니티 상세 이동 실패: $e', name: 'FCM_ERROR');
      developer.log('스택 트레이스: $stackTrace', name: 'FCM_ERROR');
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
