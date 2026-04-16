import SwiftUI
import MapKit

struct ConfluxMapView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AppLocationManager.self) private var locationManager

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
    @State private var currentSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)

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
                // Event pins
                ForEach(filteredEvents) { event in
                    Annotation("", coordinate: event.coordinate, anchor: .center) {
                        EventPinView(event: event)
                            .onTapGesture { selectedEvent = event }
                    }
                }

                // User location + alert radius
                if let userCoord = locationManager.lastLocation {
                    // Alert radius circle (50km default)
                    MapCircle(center: userCoord, radius: 50_000)
                        .foregroundStyle(Color.cxAccent.opacity(0.06))
                        .stroke(Color.cxAccent.opacity(0.25), lineWidth: 1)

                    // User location pin
                    Annotation("", coordinate: userCoord, anchor: .center) {
                        UserLocationPin()
                    }
                }
            }
            .mapStyle(.imagery(elevation: .flat))
            .onMapCameraChange { context in
                currentSpan = context.region.span
            }
            .ignoresSafeArea(edges: .all)

            // Top overlay
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                    .background(Color.cxBackgroundPure.opacity(0.85))

                Spacer()

                // Bottom controls: scale bar (left) + location button (right)
                HStack(alignment: .bottom) {
                    // Scale indicator
                    MapScaleView(position: position)

                    Spacer()

                    // My location button (Google Maps style)
                    if locationManager.lastLocation != nil {
                        Button {
                            if let coord = locationManager.lastLocation {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    position = .region(MKCoordinateRegion(
                                        center: coord,
                                        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                                    ))
                                }
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.cxAccent)
                                .frame(width: 44, height: 44)
                                .background(Color.cxSurface.opacity(0.95))
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
                                )
                                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

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
                .padding(.horizontal, 14)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
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

// MARK: - User Location Pin

struct UserLocationPin: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.cxAccent.opacity(0.3), lineWidth: 1.5)
                .frame(width: 32, height: 32)
                .scaleEffect(isPulsing ? 1.4 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)

            // Middle glow
            Circle()
                .fill(Color.cxAccent.opacity(0.15))
                .frame(width: 24, height: 24)

            // Inner dot
            Circle()
                .fill(Color.cxAccent)
                .frame(width: 10, height: 10)
                .shadow(color: .cxAccent.opacity(0.6), radius: 6)

            // Center white dot
            Circle()
                .fill(.white)
                .frame(width: 4, height: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
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

// MARK: - Map Scale View

struct MapScaleView: View {
    let position: MapCameraPosition

    private var scaleText: String {
        guard let region = position.region else { return "" }
        // 1 degree latitude ≈ 111km
        let spanKm = region.span.latitudeDelta * 111.0
        // Scale bar represents roughly 1/5 of visible area
        let barKm = spanKm / 5.0

        if barKm >= 1000 {
            let rounded = roundToNice(barKm / 1000)
            return "\(formatNumber(rounded)) km"
        } else if barKm >= 1 {
            let rounded = roundToNice(barKm)
            return "\(formatNumber(rounded)) km"
        } else {
            let meters = barKm * 1000
            let rounded = roundToNice(meters)
            return "\(formatNumber(rounded)) m"
        }
    }

    private func roundToNice(_ value: Double) -> Double {
        let steps: [Double] = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000]
        return steps.last(where: { $0 <= value }) ?? steps.first!
    }

    private func formatNumber(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Scale bar line
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.cxAccent)
                    .frame(width: 60, height: 2)
                Rectangle()
                    .fill(Color.cxAccent)
                    .frame(width: 1, height: 6)
            }

            Text(scaleText)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.cxText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.cxBackgroundPure.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
    }
}

#Preview {
    ConfluxMapView()
        .environment(AuthManager())
}
