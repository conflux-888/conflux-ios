import SwiftUI

struct NotificationSettingsView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var notificationsEnabled = true
    @State private var minSeverity = "critical"
    @State private var radiusKm: Double = 50
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var hasChanges = false

    // Original values to detect changes
    @State private var originalEnabled = true
    @State private var originalSeverity = "critical"
    @State private var originalRadius: Double = 50

    private let severityOptions = ["critical", "high", "medium", "low"]

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                // Enable toggle
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Enable Notifications", systemImage: "bell.fill")
                            .foregroundStyle(.cxText)
                    }
                    .tint(.cxAccent)
                    .listRowBackground(Color.cxSurface)
                    .onChange(of: notificationsEnabled) { _, _ in checkChanges() }
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
                                    checkChanges()
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
                            .onChange(of: radiusKm) { _, _ in checkChanges() }

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

                // Spacer for save button
                if hasChanges {
                    Color.clear.frame(height: 60)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.cxBackground)

            // Save button
            if hasChanges {
                Button {
                    Task { await saveAll() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("SAVE CHANGES")
                            .font(.cxTitle)
                            .tracking(1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cxAccent)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .disabled(isSaving)
            }
        }
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

    private func checkChanges() {
        hasChanges = notificationsEnabled != originalEnabled
            || minSeverity != originalSeverity
            || Int(radiusKm) != Int(originalRadius)
    }

    private func loadPreferences() async {
        guard let token = authManager.token else { return }
        isLoading = true
        do {
            let prefs = try await APIService.shared.getPreferences(token: token)
            notificationsEnabled = prefs.notificationsEnabled
            minSeverity = prefs.minSeverity
            radiusKm = prefs.radiusKm
            // Store originals
            originalEnabled = prefs.notificationsEnabled
            originalSeverity = prefs.minSeverity
            originalRadius = prefs.radiusKm
            hasChanges = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func saveAll() async {
        guard let token = authManager.token else { return }
        isSaving = true
        errorMessage = nil
        do {
            let req = UpdatePreferencesRequest(
                notificationsEnabled: notificationsEnabled,
                minSeverity: minSeverity,
                radiusKm: radiusKm
            )
            _ = try await APIService.shared.updatePreferences(req, token: token)
            // Update originals after save
            originalEnabled = notificationsEnabled
            originalSeverity = minSeverity
            originalRadius = radiusKm
            hasChanges = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
