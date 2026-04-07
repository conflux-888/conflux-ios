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
                    .background(.bar)

                // Content
                if isLoading && events.isEmpty {
                    Spacer()
                    ProgressView("Loading events…")
                    Spacer()
                } else if let error = errorMessage, events.isEmpty {
                    Spacer()
                    ContentUnavailableView {
                        Label("Failed to Load", systemImage: "wifi.slash")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { Task { await refresh() } }
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
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }

                        if hasMore && searchText.isEmpty {
                            HStack {
                                Spacer()
                                if isLoadingMore {
                                    ProgressView()
                                } else {
                                    Button("Load More") {
                                        Task { await loadMore() }
                                    }
                                    .font(.subheadline)
                                }
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                            .onAppear {
                                Task { await loadMore() }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await refresh() }
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search events, countries…")
            .sheet(item: $selectedEvent) { event in
                EventDetailSheet(event: event)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .task { await refresh() }
            .onChange(of: sourceFilter) { _, _ in Task { await refresh() } }
            .onChange(of: severityFilter) { _, _ in Task { await refresh() } }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SourceFilter.allCases) { filter in
                    SourceChip(filter: filter, isSelected: sourceFilter == filter) {
                        sourceFilter = filter
                    }
                }

                Divider().frame(height: 20)

                ForEach(SeverityFilter.allCases) { filter in
                    SeverityChip(filter: filter, isSelected: severityFilter == filter) {
                        severityFilter = filter
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
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
                // Severity indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.severityColor)
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    // Tags row
                    HStack(spacing: 6) {
                        // Severity
                        Label(event.severityLabel, systemImage: event.severityIcon)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(event.severityColor.opacity(0.15))
                            .foregroundStyle(event.severityColor)
                            .cornerRadius(10)

                        // Source
                        Text(event.sourceDisplayName)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(event.sourceColor.opacity(0.1))
                            .foregroundStyle(event.sourceColor)
                            .cornerRadius(10)

                        Spacer()

                        Text(event.relativeDate)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Title
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text([event.locationName, event.country]
                            .compactMap { $0 }
                            .filter { !$0.isEmpty }
                            .joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.gray.opacity(0.06))
        .cornerRadius(14)
    }
}

#Preview {
    EventsListView()
        .environment(AuthManager())
}
