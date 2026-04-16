import SwiftUI

@main
struct ConfluxApp: App {
    @State private var authManager = AuthManager()

    init() {
        // Palantir Gotham: force dark UIKit appearances
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.37, alpha: 1) // cxTextTertiary

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 0.039, green: 0.055, blue: 0.102, alpha: 1)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.910, green: 0.918, blue: 0.929, alpha: 1),
            .font: UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 0.910, green: 0.918, blue: 0.929, alpha: 1),
            .font: UIFont.monospacedSystemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        UITextField.appearance().tintColor = UIColor(red: 0, green: 0.898, blue: 1, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .preferredColorScheme(.dark)
        }
    }
}
