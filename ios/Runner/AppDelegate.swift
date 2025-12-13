import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    
    // Set up Firebase Messaging delegate
    Messaging.messaging().delegate = self
    
    // Set up notification center delegate
    UNUserNotificationCenter.current().delegate = self
    
    // Request notification permissions (iOS 10+)
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - APNs Token Handling
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Forward APNs token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    
    // Also forward to Flutter if needed
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    
    // Send token to Flutter via method channel if needed
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "sweepfeed/apns_token",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onTokenReceived", arguments: token)
    }
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  // MARK: - Notification Handling (iOS 10+)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground (iOS 14+)
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge, .list])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    // Handle notification tap
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "sweepfeed/notification_tap",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onNotificationTap", arguments: userInfo)
    }
    
    completionHandler()
  }
  
  // MARK: - Universal Links / Associated Domains
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Handle universal links
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      // Forward to Flutter for handling
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "sweepfeed/universal_link",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("onUniversalLink", arguments: url.absoluteString)
      }
      return true
    }
    return false
  }
  
  // MARK: - URL Scheme Handling
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Handle custom URL schemes (e.g., sweepfeed://)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "sweepfeed/deep_link",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
    }
    return true
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let token = fcmToken else { return }
    
    print("Firebase registration token: \(token)")
    
    // Forward FCM token to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "sweepfeed/fcm_token",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("onTokenReceived", arguments: token)
    }
  }
}

