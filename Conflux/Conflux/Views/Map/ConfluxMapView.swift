import SwiftUI
import MapKit

struct ConfluxMapView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var events: [Event] = []
    @State private var selectedEvent: Event?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var sourceFilter: SourceFilter = .all
    @State private var severityFilter: SeverityFilter = .all
    @State private var showFilters = false
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 15),
            span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
        )
    )

    var filteredEvents: [Event] {
        events.filter { event in
            let src = sourceFilter.apiValue.map { event.source == $0 } ?? true
            let sev = severityFilter.apiValue.map { event.severity == $0 } ?? true
            return src && sev
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Map
            Map(position: $position) {
                ForEach(filteredEvents) { event in
                    Annotation("", coordinate: event.coordinate, anchor: .center) {
                        EventPinView(event: event)
                            .onTapGesture { selectedEvent = event }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .all)

            // Top overlay
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 0))

                Spacer()

                // Stats banner
                if !events.isEmpty {
                    statsBanner
                        .padding(.bottom, 90) // above tab bar
                }
            }

            // Loading overlay
            if isLoading {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading events…")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.7))
                    .cornerRadius(20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task { await loadEvents() }
        .onChange(of: sourceFilter) { _, _ in Task { await loadEvents() } }
        .onChange(of: severityFilter) { _, _ in Task { await loadEvents() } }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 0) {
            // Source filter row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SourceFilter.allCases) { filter in
                        SourceChip(filter: filter, isSelected: sourceFilter == filter) {
                            sourceFilter = filter
                        }
                    }

                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)

                    // Severity filter inline
                    ForEach(SeverityFilter.allCases) { filter in
                        SeverityChip(filter: filter, isSelected: severityFilter == filter) {
                            severityFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Stats Banner

    private var statsBanner: some View {
        HStack(spacing: 16) {
            StatBadge(count: filteredEvents.filter { $0.severity == "critical" }.count,
                      label: "Critical", color: .red)
            StatBadge(count: filteredEvents.filter { $0.severity == "high" }.count,
                      label: "High", color: .orange)
            StatBadge(count: filteredEvents.filter { $0.severity == "medium" }.count,
                      label: "Medium", color: Color(red: 0.9, green: 0.75, blue: 0))
            StatBadge(count: filteredEvents.filter { $0.source == "user_report" }.count,
                      label: "User", color: .purple)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    // MARK: - Data Loading

    private func loadEvents() async {
        guard let token = authManager.token else { return }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIService.shared.getEvents(
                source: sourceFilter.apiValue,
                severity: severityFilter.apiValue,
                limit: 200,
                token: token
            )
            events = result.data
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Event Pin

struct EventPinView: View {
    let event: Event
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(event.severityColor.opacity(0.25))
                .frame(width: 36, height: 36)

            Circle()
                .fill(event.severityColor)
                .frame(width: 20, height: 20)
                .shadow(color: event.severityColor.opacity(0.6), radius: 6)

            // Source indicator dot
            Circle()
                .fill(event.source == "user_report" ? Color.purple : Color.blue)
                .frame(width: 6, height: 6)
                .offset(x: 7, y: -7)
        }
        .scaleEffect(isPressed ? 1.3 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
    }
}

// MARK: - Filter Chips

struct SourceChip: View {
    let filter: SourceFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct SeverityChip: View {
    let filter: SeverityFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if filter != .all {
                    Circle()
                        .fill(filter.color)
                        .frame(width: 7, height: 7)
                }
                Text(filter.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? filter.color.opacity(0.2) : Color.gray.opacity(0.12))
            .foregroundStyle(isSelected ? filter.color : .secondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? filter.color : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Stats Badge

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ConfluxMapView()
        .environment(AuthManager())
}
