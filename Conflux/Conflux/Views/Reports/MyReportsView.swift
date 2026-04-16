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
                ProgressView("Loading your reports...")
                    .tint(.cxAccent)
                    .foregroundStyle(.cxTextSecondary)
            } else if let error = errorMessage, reports.isEmpty {
                ContentUnavailableView {
                    Label("Failed to Load", systemImage: "wifi.slash")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await load() } }
                        .foregroundStyle(.cxAccent)
                }
            } else if reports.isEmpty {
                ContentUnavailableView {
                    Label("No Reports Yet", systemImage: "square.and.pencil")
                        .foregroundStyle(.cxAccent)
                } description: {
                    Text("Submit your first report from the Report tab to help others stay informed.")
                        .foregroundStyle(.cxTextSecondary)
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
                        .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await load() }
            }
        }
        .background(Color.cxBackground)
        .navigationTitle("MY REPORTS")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.cxBackground)
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
            HStack(spacing: 6) {
                Label(report.severityLabel.uppercased(), systemImage: report.severityIcon)
                    .font(.cxData)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(report.severityColor.opacity(0.1))
                    .foregroundStyle(report.severityColor)
                    .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                Label(report.eventTypeDisplayName.uppercased(), systemImage: "tag.fill")
                    .font(.cxData)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cxSourceUser.opacity(0.1))
                    .foregroundStyle(.cxSourceUser)
                    .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                Spacer(minLength: 4)

                Text(report.relativeDate)
                    .font(.cxMono)
                    .foregroundStyle(.cxTextTertiary)
                    .lineLimit(1)
                    .layoutPriority(-1)
            }

            Text(report.title)
                .font(.cxBody)
                .fontWeight(.semibold)
                .foregroundStyle(.cxText)
                .lineLimit(2)

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.cxTextTertiary)
                Text([report.locationName, report.country]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " // "))
                    .font(.cxData)
                    .foregroundStyle(.cxTextSecondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.cxSurface)
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
        )
    }
}
