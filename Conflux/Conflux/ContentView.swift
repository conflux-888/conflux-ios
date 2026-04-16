import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(NotificationManager.self) private var notifManager

    var body: some View {
        ZStack(alignment: .top) {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }

            // In-app notification banner
            if let banner = notifManager.newBanner {
                NotificationBannerView(
                    notification: banner,
                    onTap: { notifManager.dismissBanner() },
                    onDismiss: { notifManager.dismissBanner() }
                )
                .padding(.top, 50)
                .zIndex(100)
                .animation(.easeOut(duration: 0.3), value: notifManager.newBanner?.id)
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                ConfluxMapView()
            }

            Tab("Events", systemImage: "list.bullet.rectangle") {
                EventsListView()
            }

            Tab("Report", systemImage: "plus.app") {
                ReportFormView()
            }

            Tab("Intel", systemImage: "doc.text") {
                DailySummaryView()
            }

            Tab("Profile", systemImage: "person") {
                ProfileView()
            }
        }
        .tint(Color.cxAccent)
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .environment(NotificationManager())
}
