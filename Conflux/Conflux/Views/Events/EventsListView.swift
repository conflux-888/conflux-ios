import SwiftUI

struct EventsListView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var totalEvents = 0
    @State private var sourceFilter: SourceFilter = .all
    @State private var severityFilter: SeverityFilter = .all
    @State private var selectedEvent: Event?
    @State private var searchText = ""
    @State private var errorMessage: String?

    private let pageSize = 30

    var hasMore: Bool { events.count < totalEvents }

    var filteredEvents: [Event] {
        guard !searchText.isEmpty else { return events }
        let q = searchText.lowercased()
        return events.filter {
            $0.title.lowercased().contains(q) ||
            $0.country.lowercased().contains(q) ||
            ($0.locationName?.lowercased().contains(q) ?? false) ||
            $0.eventType.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                    .background(Color.cxBackgroundPure)

                // Content
                if isLoading && events.isEmpty {
                    Spacer()
                    ProgressView("Loading events...")
                        .tint(.cxAccent)
                        .foregroundStyle(.cxTextSecondary)
                    Spacer()
                } else if let error = errorMessage, events.isEmpty {
                    Spacer()
                    ContentUnavailableView {
                        Label("Failed to Load", systemImage: "wifi.slash")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { Task { await refresh() } }
                            .foregroundStyle(.cxAccent)
                    }
                    Spacer()
                } else if filteredEvents.isEmpty {
                    Spacer()
                    ContentUnavailableView.search
                    Spacer()
                } else {
                    List {
                        ForEach(filteredEvents) { event in
                            Button {
                                selectedEvent = event
                            } label: {
                                EventRowView(event: event)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                            .listRowSeparator(.hidden)
                        }

                        if hasMore && searchText.isEmpty {
                            HStack {
                                Spacer()
                                if isLoadingMore {
                                    ProgressView()
                                        .tint(.cxAccent)
                                } else {
                                    Button("LOAD MORE") {
                                        Task { await loadMore() }
                                    }
                                    .font(.cxData)
                                    .foregroundStyle(.cxAccent)
                                    .tracking(1)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                                            .stroke(Color.cxAccent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onAppear {
                                Task { await loadMore() }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await refresh() }
                }
            }
            .background(Color.cxBackground)
            .navigationTitle("EVENTS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NotificationBellView()
                }
            }
            .searchable(text: $searchText, prompt: "Search events, countries...")
            .tint(.cxAccent)
            .sheet(item: $selectedEvent) { event in
                EventDetailSheet(event: event)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.cxBackground)
            }
            .task { await refresh() }
            .onChange(of: sourceFilter) { _, _ in Task { await refresh() } }
            .onChange(of: severityFilter) { _, _ in Task { await refresh() } }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 0) {
            // Source row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("SOURCE")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1)
                    ForEach(SourceFilter.allCases) { filter in
                        SourceChip(filter: filter, isSelected: sourceFilter == filter) {
                            sourceFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Rectangle()
                .fill(Color.cxBorder)
                .frame(height: 1)

            // Severity row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("SEVERITY")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1)
                    ForEach(SeverityFilter.allCases) { filter in
                        SeverityChip(filter: filter, isSelected: severityFilter == filter) {
                            severityFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Data

    private func refresh() async {
        guard let token = authManager.token else { return }
        isLoading = true
        currentPage = 1
        do {
            let result = try await APIService.shared.getEvents(
                source: sourceFilter.apiValue,
                severity: severityFilter.apiValue,
                page: 1,
                limit: pageSize,
                token: token
            )
            events = result.data
            totalEvents = result.pagination?.total ?? result.data.count
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoadingMore, hasMore, let token = authManager.token else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let result = try await APIService.shared.getEvents(
                source: sourceFilter.apiValue,
                severity: severityFilter.apiValue,
                page: nextPage,
                limit: pageSize,
                token: token
            )
            let newIDs = Set(events.map(\.id))
            let newEvents = result.data.filter { !newIDs.contains($0.id) }
            events.append(contentsOf: newEvents)
            currentPage = nextPage
            totalEvents = result.pagination?.total ?? events.count
        } catch {
            print("Load more failed: \(error)")
        }
        isLoadingMore = false
    }
}

// MARK: - Event Row

struct EventRowView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                // Severity indicator bar
                RoundedRectangle(cornerRadius: 1)
                    .fill(event.severityColor)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    // Tags row
                    HStack(spacing: 6) {
                        // Severity
                        Label(event.severityLabel.uppercased(), systemImage: event.severityIcon)
                            .font(.cxData)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(event.severityColor.opacity(0.1))
                            .foregroundStyle(event.severityColor)
                            .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                        // Source
                        Text(event.sourceDisplayName.uppercased())
                            .font(.cxData)
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(event.sourceColor.opacity(0.1))
                            .foregroundStyle(event.sourceColor)
                            .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                        Spacer(minLength: 4)

                        Text(event.relativeDate)
                            .font(.cxMono)
                            .foregroundStyle(.cxTextTertiary)
                            .lineLimit(1)
                            .layoutPriority(-1)
                    }

                    // Title
                    Text(event.title)
                        .font(.cxBody)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundStyle(.cxText)

                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.cxTextTertiary)
                        Text([event.locationName, event.country]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                            .joined(separator: ", "))
                            .font(.cxData)
                            .foregroundStyle(.cxTextSecondary)
                            .lineLimit(1)
                    }
                }
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

#Preview {
    EventsListView()
        .environment(AuthManager())
}
