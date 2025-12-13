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
        
        // Set up comprehensive notification categories with actions
        var categories: [UNNotificationCategory] = []
        
        // Contest Updates Category
        let enterAction = UNNotificationAction(
            identifier: "enter_contest",
            title: "🎯 Enter Now",
            options: .foreground
        )
        let saveAction = UNNotificationAction(
            identifier: "save_contest",
            title: "💾 Save",
            options: []
        )
        let shareAction = UNNotificationAction(
            identifier: "share_contest",
            title: "📱 Share",
            options: []
        )
        
        let contestCategory = UNNotificationCategory(
            identifier: "contest_actions",
            actions: [enterAction, saveAction, shareAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        categories.append(contestCategory)
        
        // Social Activity Category
        let viewProfileAction = UNNotificationAction(
            identifier: "view_profile",
            title: "👤 View Profile",
            options: .foreground
        )
        let replyAction = UNTextInputNotificationAction(
            identifier: "reply",
            title: "💬 Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a reply..."
        )
        
        let socialCategory = UNNotificationCategory(
            identifier: "social_actions",
            actions: [viewProfileAction, replyAction],
            intentIdentifiers: [],
            options: []
        )
        categories.append(socialCategory)
        
        // High Priority Category
        let viewNowAction = UNNotificationAction(
            identifier: "view_now",
            title: "View Now",
            options: [.foreground, .destructive]
        )
        
        let criticalCategory = UNNotificationCategory(
            identifier: "critical_actions",
            actions: [viewNowAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        categories.append(criticalCategory)
        
        // Default Category
        let defaultCategory = UNNotificationCategory(
            identifier: "default_actions",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        categories.append(defaultCategory)
        
        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
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