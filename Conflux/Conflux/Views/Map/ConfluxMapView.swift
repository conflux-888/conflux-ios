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
            // Map - dark satellite imagery
            Map(position: $position) {
                ForEach(filteredEvents) { event in
                    Annotation("", coordinate: event.coordinate, anchor: .center) {
                        EventPinView(event: event)
                            .onTapGesture { selectedEvent = event }
                    }
                }
            }
            .mapStyle(.imagery(elevation: .flat))
            .ignoresSafeArea(edges: .all)

            // Top overlay
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                    .background(Color.cxBackgroundPure.opacity(0.85))

                Spacer()

                // Stats banner
                if !events.isEmpty {
                    statsBanner
                        .padding(.bottom, 90)
                }
            }

            // Loading overlay
            if isLoading {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.cxAccent)
                        Text("LOADING EVENTS")
                            .font(.cxData)
                            .foregroundStyle(.cxText)
                            .tracking(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.cxSurface)
                    .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                            .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
                    )
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.cxBackground)
        }
        .task { await loadEvents() }
        .onChange(of: sourceFilter) { _, _ in Task { await loadEvents() } }
        .onChange(of: severityFilter) { _, _ in Task { await loadEvents() } }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SourceFilter.allCases) { filter in
                        SourceChip(filter: filter, isSelected: sourceFilter == filter) {
                            sourceFilter = filter
                        }
                    }

                    Rectangle()
                        .fill(Color.cxBorder)
                        .frame(width: 1, height: 20)
                        .padding(.horizontal, 4)

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
                      label: "CRITICAL", color: .cxCritical)
            StatBadge(count: filteredEvents.filter { $0.severity == "high" }.count,
                      label: "HIGH", color: .cxHigh)
            StatBadge(count: filteredEvents.filter { $0.severity == "medium" }.count,
                      label: "MEDIUM", color: .cxMedium)
            StatBadge(count: filteredEvents.filter { $0.source == "user_report" }.count,
                      label: "USER", color: .cxSourceUser)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.cxBackgroundPure.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
        )
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
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(event.severityColor.opacity(0.15))
                .frame(width: 32, height: 32)
                .opacity(event.severity == "critical" && isPulsing ? 0.6 : 1)

            // Inner dot
            Circle()
                .fill(event.severityColor)
                .frame(width: 14, height: 14)
                .shadow(color: event.severityColor.opacity(0.6), radius: 6)

            // Source indicator
            Circle()
                .fill(event.source == "user_report" ? Color.cxSourceUser : Color.cxSourceGDELT)
                .frame(width: 5, height: 5)
                .offset(x: 6, y: -6)
        }
        .onAppear {
            if event.severity == "critical" {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
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
                    .font(.system(size: 10))
                Text(filter.rawValue.uppercased())
            }
            .cxChip(isSelected: isSelected)
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
                        .frame(width: 6, height: 6)
                }
                Text(filter.rawValue.uppercased())
            }
            .cxChip(isSelected: isSelected, activeColor: filter == .all ? .cxAccent : filter.color)
        }
    }
}

// MARK: - Stats Badge

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.cxMono)
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.cxTextTertiary)
                .tracking(0.5)
        }
    }
}

#Preview {
    ConfluxMapView()
        .environment(AuthManager())
}
