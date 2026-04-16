import SwiftUI

struct DailySummaryView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var summary: DailySummary?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedDate: Date = Date()
    @State private var dates: [Date] = []

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date picker strip
                DatePickerStrip(
                    dates: dates,
                    selectedDate: $selectedDate,
                    onChange: { date in
                        Task { await loadSummary(for: date) }
                    }
                )
                .background(Color.cxBackgroundPure)

                Rectangle()
                    .fill(Color.cxBorder)
                    .frame(height: 1)

                // Content
                Group {
                    if isLoading && summary == nil {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.cxAccent)
                            Text("LOADING BRIEFING")
                                .font(.cxData)
                                .foregroundStyle(.cxTextSecondary)
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = errorMessage, summary == nil {
                        ContentUnavailableView {
                            Label("Briefing Unavailable", systemImage: "doc.text.magnifyingglass")
                                .foregroundStyle(.cxAccent)
                        } description: {
                            Text(error)
                                .foregroundStyle(.cxTextSecondary)
                        } actions: {
                            Button("Retry") {
                                Task { await loadSummary(for: selectedDate) }
                            }
                            .foregroundStyle(.cxAccent)
                        }
                    } else if let summary {
                        summaryContent(summary)
                    }
                }
            }
            .background(Color.cxBackground)
            .navigationTitle("INTEL BRIEFING")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.cxAccent)
            .task {
                buildDates()
                await loadSummary(for: selectedDate)
            }
        }
    }

    // MARK: - Summary Content

    private func summaryContent(_ summary: DailySummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Date + Event Count bar
                SummaryDateBar(summary: summary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Severity breakdown bar
                SeverityBarView(breakdown: summary.severityBreakdown)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // Headline
                Text(summary.title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.cxText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                // Article body
                Text(summary.content)
                    .font(.system(.body, design: .default))
                    .foregroundStyle(.cxText.opacity(0.9))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Top Events
                if let topEvents = summary.topEvents, !topEvents.isEmpty {
                    sectionHeader("TOP EVENTS", icon: "flame.fill")
                        .padding(.top, 24)

                    VStack(spacing: 6) {
                        ForEach(topEvents) { event in
                            TopEventCard(event: event)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // Footer metadata
                summaryFooter(summary)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
            }
        }
        .refreshable { await loadSummary(for: selectedDate) }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.cxAccent)
            Text(title)
                .font(.cxLabel)
                .foregroundStyle(.cxTextTertiary)
                .tracking(1.5)
            Rectangle()
                .fill(Color.cxBorder)
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Footer

    private func summaryFooter(_ summary: DailySummary) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 9))
                Text("GENERATED \(summary.formattedGeneratedTime)")
                    .font(.cxData)
            }
            .foregroundStyle(.cxTextTertiary)

            Spacer()

            if let model = summary.model {
                Text(model.uppercased())
                    .font(.cxData)
                    .foregroundStyle(.cxTextTertiary)
            }
        }
        .padding(CXConstants.cardPadding)
        .background(Color.cxSurface)
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
        )
    }

    // MARK: - Data

    private func buildDates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        selectedDate = today
    }

    private func loadSummary(for date: Date) async {
        guard let token = authManager.token else {
            errorMessage = "Authentication required. Please log in again."
            return
        }
        isLoading = true
        errorMessage = nil
        summary = nil

        let dateString = dateFormatter.string(from: date)
        do {
            summary = try await APIService.shared.getSummary(date: dateString, token: token)
        } catch ServiceError.notFound {
            errorMessage = "No briefing available for this date."
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Date Picker Strip

struct DatePickerStrip: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    let onChange: (Date) -> Void

    private let calendar = Calendar.current

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    private var isToday: (Date) -> Bool {
        { calendar.isDateInToday($0) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(dates.reversed(), id: \.self) { date in
                        let selected = calendar.isDate(date, inSameDayAs: selectedDate)

                        Button {
                            selectedDate = date
                            onChange(date)
                        } label: {
                            VStack(spacing: 2) {
                                Text(weekdayFormatter.string(from: date).uppercased())
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(selected ? .cxAccent : .cxTextTertiary)
                                    .tracking(0.5)

                                Text(dayFormatter.string(from: date))
                                    .font(.cxMono)
                                    .foregroundStyle(selected ? .cxAccent : .cxText)

                                Text(monthFormatter.string(from: date).uppercased())
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(selected ? .cxAccent : .cxTextTertiary)
                                    .tracking(0.5)
                            }
                            .frame(width: 44, height: 52)
                            .background(selected ? Color.cxAccent.opacity(0.12) : Color.cxSurface)
                            .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                                    .stroke(
                                        selected ? Color.cxAccent.opacity(0.5) : Color.cxBorder,
                                        lineWidth: selected ? 1.5 : CXConstants.borderWidth
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .id(date)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onAppear {
                proxy.scrollTo(selectedDate, anchor: .trailing)
            }
        }
    }
}

// MARK: - Date Bar

struct SummaryDateBar: View {
    let summary: DailySummary

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                    .foregroundStyle(.cxAccent)
                Text(summary.formattedDate)
                    .font(.cxMono)
                    .foregroundStyle(.cxText)
            }

            Rectangle()
                .fill(Color.cxBorder)
                .frame(height: 1)

            HStack(spacing: 4) {
                Text("\(summary.eventCount)")
                    .font(.cxMono)
                    .foregroundStyle(.cxAccent)
                Text("EVENTS")
                    .font(.cxLabel)
                    .foregroundStyle(.cxTextTertiary)
                    .tracking(1)
            }

            if let incidents = summary.incidentCount {
                Rectangle()
                    .fill(Color.cxBorder)
                    .frame(width: 1, height: 12)

                HStack(spacing: 4) {
                    Text("\(incidents)")
                        .font(.cxMono)
                        .foregroundStyle(.cxAccent)
                    Text("INCIDENTS")
                        .font(.cxLabel)
                        .foregroundStyle(.cxTextTertiary)
                        .tracking(1)
                }
            }
        }
    }
}

// MARK: - Severity Breakdown Bar

struct SeverityBarView: View {
    let breakdown: SeverityBreakdown

    var body: some View {
        VStack(spacing: 6) {
            // Stacked bar
            GeometryReader { geo in
                let total = max(breakdown.total, 1)
                let w = geo.size.width

                HStack(spacing: 1) {
                    barSegment(width: w * CGFloat(breakdown.critical) / CGFloat(total), color: .cxCritical)
                    barSegment(width: w * CGFloat(breakdown.high) / CGFloat(total), color: .cxHigh)
                    barSegment(width: w * CGFloat(breakdown.medium) / CGFloat(total), color: .cxMedium)
                    barSegment(width: w * CGFloat(breakdown.low) / CGFloat(total), color: .cxLow)
                }
            }
            .frame(height: 6)
            .clipShape(RoundedRectangle(cornerRadius: 1))

            // Labels
            HStack(spacing: 0) {
                severityLabel("\(breakdown.critical)", "CRIT", .cxCritical)
                Spacer()
                severityLabel("\(breakdown.high)", "HIGH", .cxHigh)
                Spacer()
                severityLabel("\(breakdown.medium)", "MED", .cxMedium)
                Spacer()
                severityLabel("\(breakdown.low)", "LOW", .cxLow)
            }
        }
        .padding(CXConstants.cardPadding)
        .background(Color.cxSurface)
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
        )
    }

    private func barSegment(width: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(width, 0))
    }

    private func severityLabel(_ count: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(count)
                .font(.cxMono)
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.cxTextTertiary)
                .tracking(0.5)
        }
    }
}

// MARK: - Top Event Card

struct TopEventCard: View {
    let event: TopEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Severity bar
            RoundedRectangle(cornerRadius: 1)
                .fill(event.severityColor)
                .frame(width: 3)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.severityLabel)
                        .font(.cxData)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(event.severityColor.opacity(0.1))
                        .foregroundStyle(event.severityColor)
                        .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                    Text(event.country)
                        .font(.cxMono)
                        .foregroundStyle(.cxAccent)

                    Text(event.location)
                        .font(.cxData)
                        .foregroundStyle(.cxTextSecondary)
                        .lineLimit(1)

                    Spacer()
                }

                Text(event.title)
                    .font(.cxBody)
                    .fontWeight(.semibold)
                    .foregroundStyle(.cxText)
                    .lineLimit(1)

                Text(event.description)
                    .font(.cxData)
                    .foregroundStyle(.cxTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.cxSurface)
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
        )
    }
}

#Preview {
    DailySummaryView()
        .environment(AuthManager())
}
