import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        if authManager.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
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
}
