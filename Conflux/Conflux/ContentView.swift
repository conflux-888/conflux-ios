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
            Tab("Map", systemImage: "map.fill") {
                ConfluxMapView()
            }

            Tab("Events", systemImage: "newspaper.fill") {
                EventsListView()
            }

            Tab("Report", systemImage: "plus.circle.fill") {
                ReportFormView()
            }

            Tab("Profile", systemImage: "person.fill") {
                ProfileView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
