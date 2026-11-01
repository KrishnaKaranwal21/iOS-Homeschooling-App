import SwiftUI
import MapKit

struct ResolvedEventPlace {
    let coordinate: EventCoordinate
    let isVenue: Bool
    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

/// Shared lookups keep the feed's distance and the detail map in agreement.
@MainActor @Observable
final class EventLocationStore {
    private(set) var places: [String: ResolvedEventPlace] = [:]
    private var pending: [String: Task<ResolvedEventPlace?, Never>] = [:]

    func place(for event: Event) -> ResolvedEventPlace? {
        if let coordinate = event.venueCoordinate { return ResolvedEventPlace(coordinate: coordinate, isVenue: true) }
        return places[key(event)]
    }

    func resolve(_ event: Event) async -> ResolvedEventPlace? {
        guard event.mode == .inPerson else { return nil }
        if let cached = place(for: event) { return cached }
        let id = key(event)
        if let task = pending[id] { return await task.value }
        let task = Task { await Self.lookup(event) }
        pending[id] = task
        let result = await task.value
        pending[id] = nil
        if let result { places[id] = result }
        return result
    }

    func distanceText(for event: Event, from origin: CLLocation?) -> String? {
        guard event.mode == .inPerson, let origin, let place = place(for: event), place.isVenue else { return nil }
        let target = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        let kilometers = origin.distance(from: target) / 1000
        return kilometers < 0.1 ? "< 0.1 km" : "\(kilometers.formatted(.number.precision(.fractionLength(1)))) km"
    }

    private func key(_ event: Event) -> String { "\(event.storageKey)|\(event.location)|\(event.locality)|\(event.country)" }

    private static func lookup(_ event: Event) async -> ResolvedEventPlace? {
        let areaQuery = "\(event.locality), \(event.country)"
        guard let area = await search(areaQuery, region: nil, types: .address) else { return nil }
        let areaCoordinate = coordinate(of: area)
        let region = MKCoordinateRegion(center: areaCoordinate, latitudinalMeters: 20000, longitudinalMeters: 20000)
        let query = "\(event.location.replacingOccurrences(of: "\n", with: ", ")), \(areaQuery)"
        if let venue = await search(query, region: region, types: [.address, .pointOfInterest]),
           normalized(venue.name ?? "").contains(normalized(event.locationLines.title)),
           normalized(event.locationLines.title).count > 5 {
            let location = coordinate(of: venue)
            let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
                .distance(from: CLLocation(latitude: areaCoordinate.latitude, longitude: areaCoordinate.longitude))
            if distance <= 15000 {
                return ResolvedEventPlace(coordinate: EventCoordinate(latitude: location.latitude, longitude: location.longitude), isVenue: true)
            }
        }
        return ResolvedEventPlace(coordinate: EventCoordinate(latitude: areaCoordinate.latitude, longitude: areaCoordinate.longitude), isVenue: false)
    }

    private static func search(_ query: String, region: MKCoordinateRegion?, types: MKLocalSearch.ResultType) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = types
        if let region { request.region = region }
        do { return try await MKLocalSearch(request: request).start().mapItems.first }
        catch { return nil }
    }

    private static func coordinate(of item: MKMapItem) -> CLLocationCoordinate2D {
        if #available(iOS 26, macOS 26, *) {
            return item.location.coordinate
        } else {
            return item.placemark.coordinate
        }
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
}
