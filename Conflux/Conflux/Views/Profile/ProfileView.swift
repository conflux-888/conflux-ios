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
                                .fill(Color.cxSurface)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.cxAccent.opacity(0.5), lineWidth: 1)
                                )
                                .cxGlow(.cxAccent, radius: 12)

                            Text(user?.displayName.prefix(1).uppercased() ?? "?")
                                .font(.cxHeading)
                                .foregroundStyle(.cxAccent)
                        }

                        VStack(spacing: 4) {
                            if let user {
                                Text(user.displayName)
                                    .font(.cxTitle)
                                    .foregroundStyle(.cxText)
                                Text(user.email)
                                    .font(.cxData)
                                    .foregroundStyle(.cxTextSecondary)
                            } else {
                                ProgressView()
                                    .tint(.cxAccent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowBackground(Color.clear)
                }

                // Edit profile
                Section {
                    if isEditingName {
                        HStack {
                            TextField("Display name", text: $newDisplayName)
                                .textContentType(.name)
                                .font(.system(.body, design: .monospaced))
                            if isSaving {
                                ProgressView()
                                    .tint(.cxAccent)
                                    .scaleEffect(0.8)
                            } else {
                                Button("Save") {
                                    Task { await saveName() }
                                }
                                .foregroundStyle(.cxAccent)
                                .fontWeight(.semibold)
                                .disabled(newDisplayName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            Button("Cancel") {
                                isEditingName = false
                            }
                            .foregroundStyle(.cxTextTertiary)
                        }
                        .listRowBackground(Color.cxSurface)
                    } else {
                        Button {
                            newDisplayName = user?.displayName ?? ""
                            isEditingName = true
                        } label: {
                            Label("Edit Display Name", systemImage: "pencil")
                                .foregroundStyle(.cxAccent)
                        }
                        .listRowBackground(Color.cxSurface)
                    }

                    if let error = errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.cxCritical)
                            .font(.cxData)
                            .listRowBackground(Color.cxSurface)
                    }
                } header: {
                    Text("ACCOUNT")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1.5)
                }

                // My Reports
                Section {
                    NavigationLink {
                        MyReportsView()
                    } label: {
                        Label("My Reports", systemImage: "square.and.pencil.circle.fill")
                            .foregroundStyle(.cxText)
                    }
                    .listRowBackground(Color.cxSurface)
                } header: {
                    Text("MY ACTIVITY")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1.5)
                }

                // Appearance note
                Section {
                    HStack {
                        Label("Theme", systemImage: "moon.fill")
                            .foregroundStyle(.cxText)
                        Spacer()
                        Text("DARK MODE")
                            .font(.cxData)
                            .foregroundStyle(.cxAccent)
                    }
                    .listRowBackground(Color.cxSurface)
                } header: {
                    Text("APPEARANCE")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1.5)
                }

                // About
                Section {
                    aboutRow(icon: "newspaper.fill", label: "Data Sources", value: "GDELT + USER REPORTS")
                    aboutRow(icon: "clock.fill", label: "Update Interval", value: "EVERY 15 MIN")
                    aboutRow(icon: "globe", label: "Coverage", value: "GLOBAL")
                    aboutRow(icon: "exclamationmark.triangle.fill", label: "Event Types", value: "CONFLICT, FORCE, UNREST")
                } header: {
                    Text("ABOUT CONFLUX")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1.5)
                }

                // Severity legend
                Section {
                    ForEach(SeverityFilter.allCases.dropFirst()) { severity in
                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(severity.color)
                                .frame(width: 3, height: 18)

                            Text(severity.rawValue.uppercased())
                                .font(.cxData)
                                .foregroundStyle(.cxText)

                            Spacer()

                            Text(severityDescription(severity))
                                .font(.cxData)
                                .foregroundStyle(.cxTextSecondary)
                        }
                        .listRowBackground(Color.cxSurface)
                    }
                } header: {
                    Text("SEVERITY LEVELS")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1.5)
                }

                // Logout
                Section {
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("SIGN OUT")
                                .font(.cxData)
                                .foregroundStyle(.cxCritical)
                                .tracking(1)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.cxSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                            .stroke(Color.cxCritical.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.cxBackground)
            .navigationTitle("PROFILE")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.cxAccent)
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

    private func aboutRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.cxText)
            Spacer()
            Text(value)
                .font(.cxData)
                .foregroundStyle(.cxTextSecondary)
        }
        .listRowBackground(Color.cxSurface)
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
