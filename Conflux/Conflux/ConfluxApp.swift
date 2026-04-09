import SwiftUI
import Firebase
import FirebaseInAppMessaging

@main
struct ConfluxApp: App {
    @State private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .preferredColorScheme(authManager.appColorScheme.colorScheme)
        }
    }
}
