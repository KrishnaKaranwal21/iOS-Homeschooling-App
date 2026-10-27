import CoreLocation

/// Finds the family's approximate area. It asks for "while using the app" access and only needs a rough position.
/// The app needs a "Privacy - Location When In Use Usage Description" in its Info settings.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum Status { case idle, locating, denied, failed }

    private(set) var status: Status = .idle
    /// Called with the area that was found.
    var onPlace: ((Place) -> Void)?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            status = .locating
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            status = .locating
            manager.requestLocation()
        default:
            status = .denied
        }
    }

    private func authorizationChanged() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if status == .locating { manager.requestLocation() }
        case .denied, .restricted:
            status = .denied
        default:
            break
        }
    }

    private func resolve(latitude: Double, longitude: Double) async {
        do {
            let marks = try await geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude))
            guard let mark = marks.first else { status = .failed; return }
            let area = mark.subLocality ?? mark.locality ?? mark.administrativeArea ?? "Your area"
            let detail = [mark.locality, mark.administrativeArea]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            let place = Place(name: area, detail: detail, country: mark.country ?? "",
                              kind: mark.subLocality != nil ? .area : .city)
            status = .idle
            onPlace?(place)
        } catch {
            status = .failed
        }
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.authorizationChanged() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let latitude = last.coordinate.latitude
        let longitude = last.coordinate.longitude
        Task { @MainActor in await self.resolve(latitude: latitude, longitude: longitude) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.status = .failed }
    }
}
