import SwiftUI
import MapKit
import CoreLocation

struct ReportFormView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var eventType: ReportEventType = .armedConflict
    @State private var severity: ReportSeverity = .high
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var locationName = ""
    @State private var country = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 20, longitude: 15)
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 15),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
        )
    )
    @State private var isSubmitting = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var step = 1

    var formValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !country.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if step == 1 {
                    // Step 1: Location
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Tap the map to pin the event location", systemImage: "hand.tap.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ZStack {
                                Map(position: $mapPosition) {
                                    Annotation("Event", coordinate: selectedCoordinate, anchor: .bottom) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.red)
                                            .shadow(radius: 4)
                                    }
                                }
                                .frame(height: 240)
                                .cornerRadius(14)
                                .onMapCameraChange { context in
                                    selectedCoordinate = context.region.center
                                }

                                // Crosshair for center-based selection
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                            }

                            Text("Pan the map — crosshair marks the selected point")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Select Location")
                    }

                    Section {
                        HStack {
                            Label("Lat", systemImage: "location")
                            Spacer()
                            Text(String(format: "%.4f", selectedCoordinate.latitude))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("Lng", systemImage: "location")
                            Spacer()
                            Text(String(format: "%.4f", selectedCoordinate.longitude))
                                .foregroundStyle(.secondary)
                        }
                        TextField("Location name (optional)", text: $locationName)
                        TextField("Country code (e.g. TH, US, IR)", text: $country)
                            .autocapitalization(.allCharacters)
                    } header: {
                        Text("Location Details")
                    }

                } else {
                    // Step 2: Event details
                    Section {
                        Picker("Event Type", selection: $eventType) {
                            ForEach(ReportEventType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.navigationLink)

                        Picker("Severity", selection: $severity) {
                            ForEach(ReportSeverity.allCases) { s in
                                HStack {
                                    Circle()
                                        .fill(s.color)
                                        .frame(width: 10, height: 10)
                                    Text(s.displayName)
                                }
                                .tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Event Classification")
                    }

                    Section {
                        TextField("Short title describing the event", text: $title, axis: .vertical)
                            .lineLimit(2, reservesSpace: true)

                        ZStack(alignment: .topLeading) {
                            if descriptionText.isEmpty {
                                Text("Describe what you witnessed (optional)…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                            }
                            TextEditor(text: $descriptionText)
                                .frame(minHeight: 100)
                        }
                    } header: {
                        Text("Event Description")
                    }

                    // Preview card
                    if !title.isEmpty {
                        Section {
                            EventPreviewCard(
                                eventType: eventType,
                                severity: severity,
                                title: title,
                                country: country,
                                coordinate: selectedCoordinate
                            )
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        } header: {
                            Text("Preview")
                        }
                    }
                }

                // Error message
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Report Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == 2 {
                        Button("Back") { step = 1 }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if step == 1 {
                        Button("Next") {
                            if !country.isEmpty {
                                step = 2
                            } else {
                                errorMessage = "Please enter the country code"
                            }
                        }
                    } else {
                        Button {
                            Task { await submit() }
                        } label: {
                            if isSubmitting {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Text("Submit")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(isSubmitting || !formValid)
                    }
                }
            }
            .alert("Report Submitted", isPresented: $showSuccess) {
                Button("OK") {
                    resetForm()
                }
            } message: {
                Text("Your report has been submitted and will be reviewed.")
            }
        }
    }

    private func submit() async {
        guard let token = authManager.token else { return }
        isSubmitting = true
        errorMessage = nil

        let report = APIService.CreateReportRequest(
            event_type: eventType.rawValue,
            severity: severity.rawValue,
            title: title.trimmingCharacters(in: .whitespaces),
            description: descriptionText.isEmpty ? nil : descriptionText,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            location_name: locationName.isEmpty ? nil : locationName,
            country: country.uppercased()
        )

        do {
            _ = try await APIService.shared.createReport(report, token: token)
            showSuccess = true
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    private func resetForm() {
        title = ""
        descriptionText = ""
        locationName = ""
        country = ""
        eventType = .armedConflict
        severity = .high
        step = 1
    }
}

// MARK: - Event Preview Card

struct EventPreviewCard: View {
    let eventType: ReportEventType
    let severity: ReportSeverity
    let title: String
    let country: String
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(severity.displayName, systemImage: "flame.fill")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severity.color.opacity(0.15))
                    .foregroundStyle(severity.color)
                    .cornerRadius(10)

                Label("User Report", systemImage: "person.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .cornerRadius(10)

                Spacer()
            }

            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack {
                Image(systemName: eventType.icon)
                    .font(.caption)
                Text(eventType.displayName)
                    .font(.caption)
                Spacer()
                Image(systemName: "flag.fill")
                    .font(.caption)
                Text(country.uppercased())
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.gray.opacity(0.08))
        .cornerRadius(14)
    }
}

#Preview {
    ReportFormView()
        .environment(AuthManager())
}
