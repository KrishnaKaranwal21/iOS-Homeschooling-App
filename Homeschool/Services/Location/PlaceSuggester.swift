import SwiftUI
import MapKit

/// Wraps MapKit's completer so typing "mumbai" or "paris" finds real places beyond the built-in list.
@Observable
final class PlaceSuggester: NSObject, MKLocalSearchCompleterDelegate {
    var suggestions: [Place] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func update(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.count < 2 {
            suggestions = []
            completer.queryFragment = ""
        } else {
            completer.queryFragment = trimmed
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let places = completer.results.prefix(8).map { result -> Place in
            let parts = result.subtitle.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let country = parts.last ?? ""
            return Place(name: result.title,
                         detail: result.subtitle.isEmpty ? "Place" : result.subtitle,
                         country: country, kind: .city)
        }
        suggestions = Array(places)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
