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
    @State private var showFullscreenMap = false

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
                                .font(.cxData)
                                .foregroundStyle(.cxTextSecondary)

                            ZStack {
                                Map(position: $mapPosition) {
                                    Annotation("Event", coordinate: selectedCoordinate, anchor: .bottom) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.cxAccent)
                                            .shadow(color: .cxAccent.opacity(0.5), radius: 4)
                                    }
                                }
                                .mapStyle(.imagery(elevation: .flat))
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                                        .stroke(Color.cxBorder, lineWidth: 1)
                                )
                                .onMapCameraChange { context in
                                    selectedCoordinate = context.region.center
                                }

                                // Crosshair
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.cxAccent)
                                    .shadow(color: .cxAccent.opacity(0.5), radius: 2)
                            }

                            Button {
                                showFullscreenMap = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 10))
                                    Text("EXPAND MAP")
                                        .font(.cxData)
                                        .tracking(0.5)
                                }
                                .foregroundStyle(.cxAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.cxSurface)
                                .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                                        .stroke(Color.cxAccent.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("SELECT LOCATION")
                            .font(.cxLabel)
                            .foregroundStyle(.cxTextTertiary)
                            .tracking(1.5)
                    }

                    Section {
                        HStack {
                            Label("LAT", systemImage: "location")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextSecondary)
                            Spacer()
                            Text(String(format: "%.4f", selectedCoordinate.latitude))
                                .font(.cxData)
                                .foregroundStyle(.cxAccent)
                        }
                        .listRowBackground(Color.cxSurface)
                        HStack {
                            Label("LNG", systemImage: "location")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextSecondary)
                            Spacer()
                            Text(String(format: "%.4f", selectedCoordinate.longitude))
                                .font(.cxData)
                                .foregroundStyle(.cxAccent)
                        }
                        .listRowBackground(Color.cxSurface)
                        TextField("Location name (optional)", text: $locationName)
                            .font(.system(.body, design: .monospaced))
                            .listRowBackground(Color.cxSurface)
                        TextField("Country code (e.g. TH, US, IR)", text: $country)
                            .autocapitalization(.allCharacters)
                            .font(.system(.body, design: .monospaced))
                            .listRowBackground(Color.cxSurface)
                    } header: {
                        Text("LOCATION DETAILS")
                            .font(.cxLabel)
                            .foregroundStyle(.cxTextTertiary)
                            .tracking(1.5)
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
                        .listRowBackground(Color.cxSurface)

                        // Custom severity chips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SEVERITY")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextSecondary)
                                .tracking(1)

                            HStack(spacing: 6) {
                                ForEach(ReportSeverity.allCases) { s in
                                    Button {
                                        severity = s
                                    } label: {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(s.color)
                                                .frame(width: 6, height: 6)
                                            Text(s.displayName.uppercased())
                                        }
                                        .cxChip(isSelected: severity == s, activeColor: s.color)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .listRowBackground(Color.cxSurface)
                    } header: {
                        Text("EVENT CLASSIFICATION")
                            .font(.cxLabel)
                            .foregroundStyle(.cxTextTertiary)
                            .tracking(1.5)
                    }

                    Section {
                        TextField("Short title describing the event", text: $title, axis: .vertical)
                            .lineLimit(2, reservesSpace: true)
                            .listRowBackground(Color.cxSurface)

                        ZStack(alignment: .topLeading) {
                            if descriptionText.isEmpty {
                                Text("Describe what you witnessed (optional)...")
                                    .foregroundStyle(.cxTextTertiary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                            }
                            TextEditor(text: $descriptionText)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .listRowBackground(Color.cxSurface)
                    } header: {
                        Text("EVENT DESCRIPTION")
                            .font(.cxLabel)
                            .foregroundStyle(.cxTextTertiary)
                            .tracking(1.5)
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
                            Text("PREVIEW")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextTertiary)
                                .tracking(1.5)
                        }
                    }
                }

                // Error message
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.cxCritical)
                            .font(.cxData)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.cxBackground)
            .navigationTitle("REPORT EVENT")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.cxAccent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step == 2 {
                        Button("Back") { step = 1 }
                            .foregroundStyle(.cxAccent)
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
                        .foregroundStyle(.cxAccent)
                    } else {
                        Button {
                            Task { await submit() }
                        } label: {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.cxAccent)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Submit")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.cxAccent)
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
            .fullScreenCover(isPresented: $showFullscreenMap) {
                FullscreenMapPicker(
                    coordinate: $selectedCoordinate,
                    mapPosition: $mapPosition
                )
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
            HStack(spacing: 6) {
                Label(severity.displayName.uppercased(), systemImage: "flame.fill")
                    .font(.cxData)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(severity.color.opacity(0.1))
                    .foregroundStyle(severity.color)
                    .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                Label("USER REPORT", systemImage: "person.fill")
                    .font(.cxData)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cxSourceUser.opacity(0.1))
                    .foregroundStyle(.cxSourceUser)
                    .clipShape(RoundedRectangle(cornerRadius: CXConstants.chipCornerRadius))

                Spacer()
            }

            Text(title)
                .font(.cxBody)
                .fontWeight(.semibold)
                .foregroundStyle(.cxText)

            HStack {
                Image(systemName: eventType.icon)
                    .font(.system(size: 10))
                Text(eventType.displayName.uppercased())
                    .font(.cxData)
                Spacer()
                Image(systemName: "flag.fill")
                    .font(.system(size: 10))
                Text(country.uppercased())
                    .font(.cxData)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.cxTextSecondary)
        }
        .padding(CXConstants.cardPadding)
        .background(Color.cxSurface)
        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                .stroke(Color.cxAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Fullscreen Map Picker

struct FullscreenMapPicker: View {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var mapPosition: MapCameraPosition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Map(position: $mapPosition) {
                Annotation("Event", coordinate: coordinate, anchor: .bottom) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.cxAccent)
                        .shadow(color: .cxAccent.opacity(0.5), radius: 4)
                }
            }
            .mapStyle(.imagery(elevation: .flat))
            .mapControls {
                MapCompass()
                    .mapControlVisibility(.visible)
                MapScaleView()
                    .mapControlVisibility(.visible)
            }
            .onMapCameraChange { context in
                coordinate = context.region.center
            }
            .ignoresSafeArea()

            // Crosshair
            Image(systemName: "plus")
                .font(.title)
                .foregroundStyle(.cxAccent)
                .shadow(color: .cxAccent.opacity(0.5), radius: 3)

            // Bottom bar: coordinates + confirm
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "LAT %.4f", coordinate.latitude))
                            .font(.cxMono)
                            .foregroundStyle(.cxAccent)
                        Text(String(format: "LNG %.4f", coordinate.longitude))
                            .font(.cxMono)
                            .foregroundStyle(.cxAccent)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("CONFIRM")
                            .font(.cxTitle)
                            .tracking(1)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.cxAccent)
                            .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                    }
                }
                .padding(16)
                .background(Color.cxBackgroundPure.opacity(0.85))
            }

            // Close button top-left
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.cxText)
                            .frame(width: 36, height: 36)
                            .background(Color.cxBackgroundPure.opacity(0.8))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.top, 54)
                Spacer()
            }
        }
    }
}

#Preview {
    ReportFormView()
        .environment(AuthManager())
}
