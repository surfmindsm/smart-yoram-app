import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/fcm_config.dart';
import '../models/push_notification.dart';
import '../models/push_notification_enhanced.dart';
import 'notification_service.dart';
import 'notification_service_enhanced.dart';
import 'auth_service.dart';

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
      // 새로운 향상된 서비스 사용
      final result = await NotificationServiceEnhanced.instance.registerDevice(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
        deviceId: await _getDeviceId(),
        appVersion: await _getAppVersion(),
      );
      
      if (result.isSuccess) {
        developer.log('✅ 디바이스 토큰 등록 성공', name: 'FCM');
      } else {
        developer.log('❌ 디바이스 토큰 등록 실패: ${result.message}', name: 'FCM_ERROR');
      }
      
      // 새로운 API를 사용한 기기 등록
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
  
  /// 메시지 핸들러 설정
  void _setupMessageHandlers() {
    // 앱이 포어그라운드에 있을 때 메시지 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('포어그라운드 메시지 수신: ${message.messageId}', name: 'FCM');
      _handleForegroundMessage(message);
    });
    
    // 알림 탭으로 앱이 열릴 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('알림 탭으로 앱 열림: ${message.messageId}', name: 'FCM');
      _handleNotificationTap(message);
    });
    
    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((String token) {
      developer.log('FCM 토큰 갱신: $token', name: 'FCM');
      _currentToken = token;
      _registerTokenToBackend(token);
    });
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
    _navigateToRelevantScreen(notification);
  }
  
  /// 로컬 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final notification = PushNotificationModel.fromJson(data);
        developer.log('로컬 알림 탭: ${notification.title}', name: 'FCM');
        
        _navigateToRelevantScreen(notification);
      } catch (e) {
        developer.log('로컬 알림 탭 처리 실패: $e', name: 'FCM_ERROR');
      }
    }
  }
  
  /// 알림 타입에 따른 화면 이동
  void _navigateToRelevantScreen(PushNotificationModel notification) {
    // TODO: 실제 화면 이동 로직 구현
    // 예: Navigator.pushNamed(), context 사용 시 전역 네비게이터 키 필요
    developer.log('화면 이동: ${notification.type?.displayName ?? '기본'}', name: 'FCM');
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
  
  /// FCM 서비스 정리
  Future<void> dispose() async {
    // 필요시 리소스 정리
  }
}
