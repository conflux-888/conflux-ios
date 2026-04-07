import SwiftUI

struct MyReportsView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var reports: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedEvent: Event?
    @State private var reportToDelete: Event?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if isLoading && reports.isEmpty {
                ProgressView("Loading your reports…")
            } else if let error = errorMessage, reports.isEmpty {
                ContentUnavailableView {
                    Label("Failed to Load", systemImage: "wifi.slash")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await load() } }
                }
            } else if reports.isEmpty {
                ContentUnavailableView {
                    Label("No Reports Yet", systemImage: "square.and.pencil")
                } description: {
                    Text("Submit your first report from the Report tab to help others stay informed.")
                }
            } else {
                List {
                    ForEach(reports) { report in
                        Button {
                            selectedEvent = report
                        } label: {
                            UserReportRow(report: report)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                reportToDelete = report
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .refreshable { await load() }
            }
        }
        .navigationTitle("My Reports")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Delete Report",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let report = reportToDelete {
                    Task { await deleteReport(report) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .task { await load() }
    }

    private func load() async {
        guard let token = authManager.token else { return }
        isLoading = true
        do {
            let result = try await APIService.shared.getMyReports(limit: 50, token: token)
            reports = result.data
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func deleteReport(_ report: Event) async {
        guard let token = authManager.token else { return }
        do {
            try await APIService.shared.deleteReport(id: report.id, token: token)
            reports.removeAll { $0.id == report.id }
        } catch {
            print("Delete failed: \(error)")
        }
    }
}

// MARK: - User Report Row

struct UserReportRow: View {
    let report: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(report.severityLabel, systemImage: report.severityIcon)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(report.severityColor.opacity(0.15))
                    .foregroundStyle(report.severityColor)
                    .cornerRadius(10)

                Label(report.eventTypeDisplayName, systemImage: "tag.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .cornerRadius(10)

                Spacer()

                Text(report.relativeDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(report.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text([report.locationName, report.country]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.gray.opacity(0.06))
        .cornerRadius(14)
    }
}
