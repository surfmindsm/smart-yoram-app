import Flutter
import UIKit
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Flutter 플러그인 등록을 먼저 수행
    GeneratedPluginRegistrant.register(with: self)
    
    // Firebase 초기화를 더 안전하게 처리
    configureFirebase()
    
    // FCM 설정 (Firebase 초기화 성공 시에만)
    if FirebaseApp.app() != nil {
      setupNotifications(application)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupNotifications(_ application: UIApplication) {
    if #available(iOS 10.0, *) {
      // UNUserNotificationCenter 델리게이트를 AppDelegate로 설정
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if let error = error {
            print("❌ Notification authorization error: \(error.localizedDescription)")
          } else {
            print("✅ Notification authorization granted: \(granted)")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    DispatchQueue.main.async {
      application.registerForRemoteNotifications()
      print("✅ Remote notifications registered")
    }
  }
  
  private func configureFirebase() {
    // GoogleService-Info.plist 파일 유효성 검사
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let projectId = plist["PROJECT_ID"] as? String,
          let googleAppId = plist["GOOGLE_APP_ID"] as? String,
          !projectId.isEmpty,
          !googleAppId.isEmpty,
          !googleAppId.contains("example") && !googleAppId.contains("test") else {
      print("⚠️ GoogleService-Info.plist 파일이 올바르지 않거나 더미 데이터입니다. Firebase 기능을 비활성화합니다.")
      return
    }

    // Firebase 초기화 시도
    if FirebaseApp.app() == nil {
      do {
        FirebaseApp.configure()
        print("✅ Firebase가 성공적으로 초기화되었습니다.")
      } catch {
        print("❌ Firebase 초기화 실패: \(error.localizedDescription)")
      }
    } else {
      print("ℹ️ Firebase가 이미 초기화되어 있습니다.")
    }
  }

  // 포어그라운드에서도 알림 표시
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("🔔🔔🔔 iOS: willPresent notification called 🔔🔔🔔")
    print("🔔 Title: \(notification.request.content.title)")
    print("🔔 Body: \(notification.request.content.body)")

    if #available(iOS 14.0, *) {
      // iOS 14+: 배너, 사운드, 배지 모두 표시
      print("✅ iOS 14+: Showing banner, sound, badge, list")
      completionHandler([.banner, .sound, .badge, .list])
    } else {
      // iOS 13 이하: alert, 사운드, 배지 표시
      print("✅ iOS 13: Showing alert, sound, badge")
      completionHandler([.alert, .sound, .badge])
    }
  }
}
