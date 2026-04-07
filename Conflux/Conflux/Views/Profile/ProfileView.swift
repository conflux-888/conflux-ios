import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var isEditingName = false
    @State private var newDisplayName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showLogoutConfirm = false

    var user: User? { authManager.currentUser }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)

                            Text(user?.displayName.prefix(1).uppercased() ?? "?")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 4) {
                            if let user {
                                Text(user.displayName)
                                    .font(.title2.bold())
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ProgressView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowBackground(Color.clear)
                }

                // Edit profile
                Section("Account") {
                    if isEditingName {
                        HStack {
                            TextField("Display name", text: $newDisplayName)
                                .textContentType(.name)
                            if isSaving {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Button("Save") {
                                    Task { await saveName() }
                                }
                                .fontWeight(.semibold)
                                .disabled(newDisplayName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            Button("Cancel") {
                                isEditingName = false
                            }
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            newDisplayName = user?.displayName ?? ""
                            isEditingName = true
                        } label: {
                            Label("Edit Display Name", systemImage: "pencil")
                        }
                    }

                    if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                // My Reports
                Section("My Activity") {
                    NavigationLink {
                        MyReportsView()
                    } label: {
                        Label("My Reports", systemImage: "square.and.pencil.circle.fill")
                    }
                }

                // Appearance
                Section("Appearance") {
                    Picker(selection: Binding(
                        get: { authManager.appColorScheme },
                        set: { authManager.setColorScheme($0) }
                    )) {
                        ForEach(AppColorScheme.allCases) { scheme in
                            Label(scheme.rawValue, systemImage: scheme.icon).tag(scheme)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush.fill")
                    }
                    .pickerStyle(.menu)
                }

                // About
                Section("About Conflux") {
                    HStack {
                        Label("Data Sources", systemImage: "newspaper.fill")
                        Spacer()
                        Text("GDELT + User Reports")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Update Interval", systemImage: "clock.fill")
                        Spacer()
                        Text("Every 15 minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Coverage", systemImage: "globe")
                        Spacer()
                        Text("Global")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Event Types", systemImage: "exclamationmark.triangle.fill")
                        Spacer()
                        Text("Armed conflict, force, unrest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Severity legend
                Section("Severity Levels") {
                    ForEach(SeverityFilter.allCases.dropFirst()) { severity in
                        HStack {
                            Circle()
                                .fill(severity.color)
                                .frame(width: 12, height: 12)
                            Text(severity.rawValue)
                            Spacer()
                            Text(severityDescription(severity))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Sign Out", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to sign in again to access the app.")
            }
            .task {
                if authManager.currentUser == nil {
                    await authManager.fetchCurrentUser()
                }
            }
        }
    }

    private func saveName() async {
        guard let token = authManager.token else { return }
        let name = newDisplayName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        do {
            authManager.currentUser = try await APIService.shared.updateDisplayName(name, token: token)
            isEditingName = false
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func severityDescription(_ severity: SeverityFilter) -> String {
        switch severity {
        case .critical: return "Mass casualties, major attacks"
        case .high: return "Significant armed incidents"
        case .medium: return "Localized conflicts"
        case .low: return "Minor incidents, alerts"
        default: return ""
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager())
}
