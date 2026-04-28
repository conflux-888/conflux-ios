import Foundation
import UIKit
import UserNotifications
import Observation

@Observable
class PushManager {
    var apnsTokenHex: String?
    var registeredToken: String?
    var authStatus: UNAuthorizationStatus = .notDetermined

    private var pendingAuthToken: String?

    func bind(_ delegate: AppDelegate) {
        delegate.pushManager = self
    }

    /// Call after login (or on app launch with stored auth token) to request OS permission and register with APNs.
    @MainActor
    func requestPermissionAndRegister(authToken: String) async {
        pendingAuthToken = authToken
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authStatus = settings.authorizationStatus
            guard granted else {
                print("[PushManager] permission denied")
                return
            }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            print("[PushManager] permission error: \(error)")
        }
    }

    /// Call on logout to drop the token from the backend.
    func clearOnLogout() {
        guard let token = registeredToken, let auth = pendingAuthToken else {
            pendingAuthToken = nil
            return
        }
        let authCopy = auth
        Task {
            do {
                try await APIService.shared.unregisterDeviceToken(token: token, authToken: authCopy)
            } catch {
                print("[PushManager] unregister error: \(error)")
            }
        }
        pendingAuthToken = nil
        registeredToken = nil
    }

    /// Called by AppDelegate when iOS hands us the device token.
    func handleAPNsToken(_ hex: String) {
        apnsTokenHex = hex
        guard let auth = pendingAuthToken else { return }
        let authCopy = auth
        Task { await self.send(apnsToken: hex, authToken: authCopy) }
    }

    private func send(apnsToken: String, authToken: String) async {
        let env: String
        #if DEBUG
        env = "sandbox"
        #else
        env = "production"
        #endif
        let bundle = Bundle.main.bundleIdentifier ?? "com.conflux.app"
        do {
            try await APIService.shared.registerDeviceToken(
                token: apnsToken,
                env: env,
                bundleID: bundle,
                authToken: authToken
            )
            registeredToken = apnsToken
            print("[PushManager] device token registered (env=\(env))")
        } catch {
            print("[PushManager] register error: \(error)")
        }
    }
}
