import Foundation
import CoreLocation
import Observation

@Observable
class AppLocationManager: NSObject, CLLocationManagerDelegate {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var lastLocation: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private var token: String?

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startMonitoring(token: String) {
        self.token = token
        manager.startMonitoringSignificantLocationChanges()
    }

    func stopMonitoring() {
        manager.stopMonitoringSignificantLocationChanges()
        token = nil
    }

    func updateLocationNow() {
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, let token else { return }
        lastLocation = location.coordinate
        Task {
            try? await APIService.shared.updateLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                token: token
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent — location is optional
    }
}
