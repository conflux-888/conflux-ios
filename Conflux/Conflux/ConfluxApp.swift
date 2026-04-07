import SwiftUI

@main
struct ConfluxApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .preferredColorScheme(authManager.appColorScheme.colorScheme)
        }
    }
}
