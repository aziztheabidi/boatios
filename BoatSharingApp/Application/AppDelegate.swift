import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    var window : UIWindow?
    private let preferences: PreferenceStoring
    private let tokenStore: TokenStoring
    private let deviceIdentifierStore: DeviceIdentifierStoring

    init(
        preferences: PreferenceStoring = AppDependencies.live.preferences,
        tokenStore: TokenStoring = AppDependencies.live.tokenStore,
        deviceIdentifierStore: DeviceIdentifierStoring = AppDependencies.live.deviceIdentifierStore
    ) {
        self.preferences = preferences
        self.tokenStore = tokenStore
        self.deviceIdentifierStore = deviceIdentifierStore
        super.init()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // Stripe publishable key is set in AppServices.configure() from Info.plist (STRIPE_PUBLISHABLE_KEY).

        // Register for push notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                Task { @MainActor in
                    application.registerForRemoteNotifications()
                }
            }
        }

        Messaging.messaging().delegate = self

        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        tokenStore.deviceToken = tokenString
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        NotificationCenter.default.post(name: .didReceivePushNotification, object: userInfo)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        completionHandler()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let token = fcmToken ?? "Failed to get token"
        // FCM token is a public push identifier — store in PreferenceStore (not Keychain)
        deviceIdentifierStore.fcmToken = token
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        NotificationCenter.default.post(name: .didReceiveFCMToken, object: token)
    }
}

extension Notification.Name {
    static let didReceivePushNotification = Notification.Name("didReceivePushNotification")
    static let didReceiveFCMToken = Notification.Name("didReceiveFCMToken")
}

