import SwiftUI

struct NotificationSettingsView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var notificationsEnabled = true
    @State private var minSeverity = "critical"
    @State private var radiusKm: Double = 50
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let severityOptions = ["critical", "high", "medium", "low"]

    var body: some View {
        List {
            // Enable toggle
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Enable Notifications", systemImage: "bell.fill")
                        .foregroundStyle(.cxText)
                }
                .tint(.cxAccent)
                .listRowBackground(Color.cxSurface)
                .onChange(of: notificationsEnabled) { _, newVal in
                    save(UpdatePreferencesRequest(notificationsEnabled: newVal))
                }
            } header: {
                Text("NOTIFICATIONS")
                    .font(.cxLabel).foregroundStyle(.cxTextTertiary).tracking(1.5)
            }

            // Severity filter
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Minimum severity to trigger alerts")
                        .font(.cxData)
                        .foregroundStyle(.cxTextSecondary)

                    HStack(spacing: 6) {
                        ForEach(severityOptions, id: \.self) { sev in
                            Button {
                                minSeverity = sev
                                save(UpdatePreferencesRequest(minSeverity: sev))
                            } label: {
                                Text(sev == "critical" ? "CRIT" : sev.uppercased())
                                    .cxChip(
                                        isSelected: minSeverity == sev,
                                        activeColor: colorFor(sev)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listRowBackground(Color.cxSurface)
            } header: {
                Text("MINIMUM SEVERITY")
                    .font(.cxLabel).foregroundStyle(.cxTextTertiary).tracking(1.5)
            }

            // Radius slider
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Alert when threats are within")
                            .font(.cxData)
                            .foregroundStyle(.cxTextSecondary)
                        Spacer()
                        Text("\(Int(radiusKm)) KM")
                            .font(.cxMono)
                            .foregroundStyle(.cxAccent)
                    }

                    Slider(value: $radiusKm, in: 1...500, step: 1)
                        .tint(.cxAccent)
                        .onChange(of: radiusKm) { _, _ in }
                        .onSubmit {
                            save(UpdatePreferencesRequest(radiusKm: radiusKm))
                        }

                    HStack {
                        Text("1 KM")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.cxTextTertiary)
                        Spacer()
                        Text("500 KM")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.cxTextTertiary)
                    }
                }
                .listRowBackground(Color.cxSurface)
            } header: {
                Text("ALERT RADIUS")
                    .font(.cxLabel).foregroundStyle(.cxTextTertiary).tracking(1.5)
            }

            // Error
            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.cxData)
                        .foregroundStyle(.cxCritical)
                        .listRowBackground(Color.cxSurface)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.cxBackground)
        .navigationTitle("NOTIFICATION SETTINGS")
        .navigationBarTitleDisplayMode(.inline)
        .tint(.cxAccent)
        .task { await loadPreferences() }
    }

    private func colorFor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .cxCritical
        case "high": return .cxHigh
        case "medium": return .cxMedium
        case "low": return .cxLow
        default: return .cxAccent
        }
    }

    private func loadPreferences() async {
        guard let token = authManager.token else { return }
        isLoading = true
        do {
            let prefs = try await APIService.shared.getPreferences(token: token)
            notificationsEnabled = prefs.notificationsEnabled
            minSeverity = prefs.minSeverity
            radiusKm = prefs.radiusKm
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save(_ req: UpdatePreferencesRequest) {
        guard let token = authManager.token else { return }
        Task {
            do {
                _ = try await APIService.shared.updatePreferences(req, token: token)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
