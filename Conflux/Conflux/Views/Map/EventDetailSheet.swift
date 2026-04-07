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
                            Label(event.severityLabel, systemImage: event.severityIcon)
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(event.severityColor.opacity(0.15))
                                .foregroundStyle(event.severityColor)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(event.severityColor.opacity(0.4), lineWidth: 1)
                                )

                            // Source badge
                            Label(event.sourceDisplayName, systemImage: event.sourceIcon)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(event.sourceColor.opacity(0.1))
                                .foregroundStyle(event.sourceColor)
                                .cornerRadius(20)

                            Spacer()
                        }

                        Text(event.title)
                            .font(.title3.bold())
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Meta info grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetaCard(icon: "calendar", label: "Date", value: event.formattedDate)
                        MetaCard(icon: "flag.fill", label: "Country", value: event.country)
                        if let locName = event.locationName, !locName.isEmpty {
                            MetaCard(icon: "mappin.circle.fill", label: "Location", value: locName)
                        }
                        MetaCard(icon: "exclamationmark.triangle.fill", label: "Type", value: event.eventTypeDisplayName)
                        if let sources = event.numSources, sources > 0 {
                            MetaCard(icon: "newspaper.fill", label: "Sources", value: "\(sources)")
                        }
                        if let articles = event.numArticles, articles > 0 {
                            MetaCard(icon: "doc.text.fill", label: "Articles", value: "\(articles)")
                        }
                    }
                    .padding(.horizontal)

                    // Actors
                    if let actors = event.actors, !actors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Actors", systemImage: "person.2.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(actors, id: \.self) { actor in
                                        Text(actor)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(.gray.opacity(0.12))
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Description
                    if let desc = event.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Details", systemImage: "text.alignleft")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            if desc.hasPrefix("http") {
                                Link(destination: URL(string: desc) ?? URL(string: "https://gdeltproject.org")!) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text("View Source Article")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .font(.subheadline)
                                    .padding()
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .cornerRadius(12)
                                }
                            } else {
                                Text(desc)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Mini map
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Location", systemImage: "map.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
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
                                        .fill(event.severityColor.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: event.severityIcon)
                                        .foregroundStyle(event.severityColor)
                                        .font(.title3.bold())
                                }
                            }
                        }
                        .frame(height: 180)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Coordinates
                    HStack {
                        Spacer()
                        Text(String(format: "%.4f°N, %.4f°E",
                                    event.location.coordinates[1],
                                    event.location.coordinates[0]))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    // Event ID for debugging
                    Text("ID: \(event.id)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle(event.relativeDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.08))
        .cornerRadius(12)
    }
}
