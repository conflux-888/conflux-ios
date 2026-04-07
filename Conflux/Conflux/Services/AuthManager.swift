import Foundation
import SwiftUI
import Observation

enum AppColorScheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@Observable
class AuthManager {
    var token: String?
    var currentUser: User?
    var isLoggedIn: Bool { token != nil }
    var appColorScheme: AppColorScheme = .system

    private let tokenKey = "conflux_token"
    private let colorSchemeKey = "conflux_color_scheme"

    init() {
        token = UserDefaults.standard.string(forKey: tokenKey)
        if let saved = UserDefaults.standard.string(forKey: colorSchemeKey),
           let scheme = AppColorScheme(rawValue: saved) {
            appColorScheme = scheme
        }
    }

    func setColorScheme(_ scheme: AppColorScheme) {
        appColorScheme = scheme
        UserDefaults.standard.set(scheme.rawValue, forKey: colorSchemeKey)
    }

    func saveToken(_ newToken: String) {
        token = newToken
        UserDefaults.standard.set(newToken, forKey: tokenKey)
    }

    func logout() {
        token = nil
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }

    func fetchCurrentUser() async {
        guard let token else { return }
        do {
            currentUser = try await APIService.shared.getMe(token: token)
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
}
