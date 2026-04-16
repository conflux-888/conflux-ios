import SwiftUI
import MapKit

struct EventDetailSheet: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            // Severity badge
                            Label(event.severityLabel.uppercased(), systemImage: event.severityIcon)
                                .font(.cxData)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(event.severityColor.opacity(0.1))
                                .foregroundStyle(event.severityColor)
                                .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius)
                                        .stroke(event.severityColor.opacity(0.4), lineWidth: 1)
                                )

                            // Source badge
                            Label(event.sourceDisplayName.uppercased(), systemImage: event.sourceIcon)
                                .font(.cxData)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(event.sourceColor.opacity(0.1))
                                .foregroundStyle(event.sourceColor)
                                .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                            Spacer()
                        }

                        Text(event.title)
                            .font(.cxTitle)
                            .foregroundStyle(.cxText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)

                    Rectangle()
                        .fill(Color.cxBorder)
                        .frame(height: 1)

                    // Meta info grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        MetaCard(icon: "calendar", label: "DATE", value: event.formattedDate)
                        MetaCard(icon: "flag.fill", label: "COUNTRY", value: event.country)
                        if let locName = event.locationName, !locName.isEmpty {
                            MetaCard(icon: "mappin.circle.fill", label: "LOCATION", value: locName)
                        }
                        MetaCard(icon: "exclamationmark.triangle.fill", label: "TYPE", value: event.eventTypeDisplayName)
                        if let sources = event.numSources, sources > 0 {
                            MetaCard(icon: "newspaper.fill", label: "SOURCES", value: "\(sources)")
                        }
                        if let articles = event.numArticles, articles > 0 {
                            MetaCard(icon: "doc.text.fill", label: "ARTICLES", value: "\(articles)")
                        }
                    }
                    .padding(.horizontal)

                    // Actors
                    if let actors = event.actors, !actors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("ACTORS", systemImage: "person.2.fill")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextTertiary)
                                .tracking(1)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(actors, id: \.self) { actor in
                                        Text(actor)
                                            .font(.cxData)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.cxSurface)
                                            .foregroundStyle(.cxText)
                                            .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius)
                                                    .stroke(Color.cxBorder, lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Description
                    if let desc = event.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("DETAILS", systemImage: "text.alignleft")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextTertiary)
                                .tracking(1)

                            if desc.hasPrefix("http") {
                                Link(destination: URL(string: desc) ?? URL(string: "https://gdeltproject.org")!) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text("VIEW SOURCE ARTICLE")
                                            .font(.cxData)
                                            .tracking(0.5)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .padding()
                                    .background(Color.cxSurface)
                                    .foregroundStyle(.cxAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                                            .stroke(Color.cxAccent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            } else {
                                Text(desc)
                                    .font(.cxBody)
                                    .foregroundStyle(.cxText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Mini map
                    VStack(alignment: .leading, spacing: 8) {
                        Label("LOCATION", systemImage: "map")
                            .font(.cxLabel)
                            .foregroundStyle(.cxTextTertiary)
                            .tracking(1)
                            .padding(.horizontal)

                        Map(initialPosition: .region(
                            MKCoordinateRegion(
                                center: event.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                            )
                        )) {
                            Annotation("", coordinate: event.coordinate, anchor: .center) {
                                ZStack {
                                    Circle()
                                        .fill(event.severityColor.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: event.severityIcon)
                                        .foregroundStyle(event.severityColor)
                                        .font(.title3.bold())
                                }
                            }
                        }
                        .mapStyle(.imagery(elevation: .flat))
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                                .stroke(Color.cxBorder, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Coordinates
                    HStack {
                        Spacer()
                        Text(String(format: "%.4f\u{00B0}N, %.4f\u{00B0}E",
                                    event.location.coordinates[1],
                                    event.location.coordinates[0]))
                            .font(.cxData)
                            .foregroundStyle(.cxAccent)
                        Spacer()
                    }

                    // Event ID
                    Text("EVT-ID: \(event.id)")
                        .font(.cxData)
                        .foregroundStyle(.cxTextTertiary)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                .padding(.top)
            }
            .background(Color.cxBackground)
            .navigationTitle(event.relativeDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.cxAccent)
                }
            }
        }
    }
}

// MARK: - Meta Card

struct MetaCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.cxLabel)
                .foregroundStyle(.cxTextTertiary)
                .tracking(0.5)
            Text(value)
                .font(.cxData)
                .foregroundStyle(.cxText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CXConstants.cardPadding)
        .background(Color.cxSurface)
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxBorder, lineWidth: CXConstants.borderWidth)
        )
    }
}
