import UIKit
import UserNotifications
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var pushManager: PushManager?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("[AppDelegate] APNs token: \(hex)")
        pushManager?.handleAPNsToken(hex)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] APNs registration failed: \(error.localizedDescription)")
    }

    // Foreground presentation: show banner + sound + badge while app open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    // Tap handling: post a NotificationCenter event for views to deeplink off of.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: .pushNotificationTapped, object: nil, userInfo: info)
        completionHandler()
    }
}

extension Notification.Name {
    static let pushNotificationTapped = Notification.Name("conflux.pushNotificationTapped")
}
