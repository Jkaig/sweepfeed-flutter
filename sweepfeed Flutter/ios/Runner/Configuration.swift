swift
import Foundation
import Firebase
import FirebaseMessaging
import UserNotifications

class AppConfiguration {
    static let shared = AppConfiguration()
    
    // Deep linking configuration
    static let deepLinkScheme = "sweepfeed"
    static let deepLinkHost = "sweepfeed.com"
    
    // Push notification configuration
    static let pushNotificationCategory = "SWEEPSTAKES_UPDATE"
    
    private init() {}
    
    func configureDeepLinking() {
        // Register for deep links
        UNUserNotificationCenter.current().delegate = self
    }
    
    func configurePushNotifications() {
        // Request authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        // Configure Firebase Messaging
        Messaging.messaging().delegate = self
        
        // Set up notification categories
        let viewAction = UNNotificationAction(
            identifier: "VIEW_SWEEPSTAKES",
            title: "View",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: AppConfiguration.pushNotificationCategory,
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return
        }
        
        // Handle different deep link paths
        switch host {
        case "sweepstakes":
            if let id = components.queryItems?.first(where: { $0.name == "id" })?.value {
                handleSweepstakesDeepLink(id: id)
            }
        case "subscription":
            handleSubscriptionDeepLink()
        default:
            break
        }
    }
    
    private func handleSweepstakesDeepLink(id: String) {
        // Navigate to sweepstakes detail
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToSweepstakes"),
            object: nil,
            userInfo: ["id": id]
        )
    }
    
    private func handleSubscriptionDeepLink() {
        // Navigate to subscription page
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToSubscription"),
            object: nil
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppConfiguration: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let sweepstakesId = userInfo["sweepstakesId"] as? String {
            handleSweepstakesDeepLink(id: sweepstakesId)
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppConfiguration: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        // Send token to your backend
        let userDefaults = UserDefaults.standard
        userDefaults.set(token, forKey: "fcmToken")
        
        // Update token in Firestore if user is logged in
        if let userId = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(userId).updateData([
                "fcmToken": token,
                "platform": "ios",
                "lastTokenUpdate": FieldValue.serverTimestamp()
            ])
        }
    }
}