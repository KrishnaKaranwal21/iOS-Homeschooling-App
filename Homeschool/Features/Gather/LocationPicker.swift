import SwiftUI
import MapKit

// MARK: - Place

/// A place a family can filter by or host in: a nearby area, a city, a country, or the whole world.
struct Place: Identifiable, Hashable, Codable {
    enum Kind: String, Codable { case nearby, area, city, country, world }

    var name: String
    var detail: String
    var country: String
    var kind: Kind

    var id: String { "\(kind.rawValue)|\(name)|\(country)" }

    static let nearYou = Place(name: "Near you", detail: "Potheri, Guduvanchery and nearby areas", country: "India", kind: .nearby)
    static let world = Place(name: "All over the world", detail: "Every event, anywhere", country: "", kind: .world)
    static let potheri = Place(name: "Potheri", detail: "Chennai area, India", country: "India", kind: .area)
}

// MARK: - Catalog

enum PlaceCatalog {
    /// Closest areas first. These are shown at the top of the list.
    static let nearby: [Place] = [
        .potheri,
        Place(name: "Guduvanchery", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Chengalpattu", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Maraimalai Nagar", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Tambaram", detail: "Chennai area, India", country: "India", kind: .area)
    ]

    static let india: [Place] = [
        Place(name: "India", detail: "Whole country", country: "India", kind: .country)
    ] + ["Chennai", "Mumbai", "Delhi", "Bengaluru", "Hyderabad", "Kolkata", "Pune", "Ahmedabad",
         "Jaipur", "Kochi", "Coimbatore", "Madurai", "Thane", "Goa"]
        .map { Place(name: $0, detail: "India", country: "India", kind: .city) }

    static let worldCountries: [Place] = [
        "United States", "United Kingdom", "Canada", "Australia", "Singapore", "United Arab Emirates",
        "Germany", "France", "Japan", "New Zealand", "Malaysia", "Sri Lanka", "Nepal", "South Africa"
    ].map { Place(name: $0, detail: "Country", country: $0, kind: .country) }

    static let worldCities: [Place] = [
        ("London", "United Kingdom"), ("New York", "United States"), ("San Francisco", "United States"),
        ("Toronto", "Canada"), ("Sydney", "Australia"), ("Melbourne", "Australia"),
        ("Singapore", "Singapore"), ("Dubai", "United Arab Emirates"), ("Paris", "France"),
        ("Berlin", "Germany"), ("Tokyo", "Japan"), ("Kuala Lumpur", "Malaysia"),
        ("Colombo", "Sri Lanka"), ("Kathmandu", "Nepal"), ("Auckland", "New Zealand")
    ].map { Place(name: $0.0, detail: $0.1, country: $0.1, kind: .city) }

    static var all: [Place] { nearby + india + worldCountries + worldCities }

    /// Areas that belong to a city, so choosing "Chennai" also shows events in Potheri and nearby.
    private static let areasByCity: [String: Set<String>] = [
        "Chennai": Set(nearby.map(\.name))
    ]

    /// Whether an event is relevant to the place chosen in the filter.
    /// Area names that count as "near" a home location.
    static func nearbyNames(around home: Place) -> Set<String> {
        if nearby.contains(where: { $0.name == home.name }) { return Set(nearby.map(\.name)) }
        if let areas = areasByCity[home.name] { return areas.union([home.name]) }
        return [home.name]
    }

    static func matches(_ event: Event, selection: Place, home: Place = .potheri) -> Bool {
        if event.mode == .online { return true }
        switch selection.kind {
        case .world:   return true
        case .nearby:  return nearbyNames(around: home).contains { $0.localizedCaseInsensitiveCompare(event.locality) == .orderedSame }
        case .country: return event.country.localizedCaseInsensitiveCompare(selection.country) == .orderedSame
        case .area:    return event.locality.localizedCaseInsensitiveCompare(selection.name) == .orderedSame
        case .city:
            if event.locality.localizedCaseInsensitiveCompare(selection.name) == .orderedSame { return true }
            return areasByCity[selection.name]?.contains(event.locality) ?? false
        }
    }
}

// MARK: - Live suggestions for any place on Earth

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

// MARK: - Picker sheet

/// Search box on top. With nothing typed it lists nearby areas, then India, then the rest of the world.
struct LocationPickerSheet: View {
    /// Offers "All over the world". Hosts must choose a real place, so they turn it off.
    var allowsWorld = true
    let selection: Place?
    /// The family's home area, shown under "Near you".
    var home: Place = .potheri
    let onSelect: (Place) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var suggester = PlaceSuggester()

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }
    private var isSearching: Bool { !trimmed.isEmpty }

    private var matches: [Place] {
        PlaceCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.country.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Map results that are not already in the built-in list.
    private var extraSuggestions: [Place] {
        let known = Set(matches.map { $0.name.lowercased() })
        return suggester.suggestions.filter { !known.contains($0.name.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    searchResults
                } else {
                    browseSections
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(allowsWorld ? "Choose a location" : "Where is it?")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search any city, area or country")
            .onChange(of: query) { _, newValue in suggester.update(newValue) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder private var browseSections: some View {
        if allowsWorld {
            Section {
                row(.nearYou)
                row(.world)
            }
        }
        Section("Nearby areas") { ForEach(PlaceCatalog.nearby) { row($0) } }
        Section("India") { ForEach(PlaceCatalog.india) { row($0) } }
        Section("All over the world") {
            ForEach(PlaceCatalog.worldCountries + PlaceCatalog.worldCities) { row($0) }
        }
    }

    @ViewBuilder private var searchResults: some View {
        let local = matches
        let extra = extraSuggestions

        if !local.isEmpty {
            Section("Matches") { ForEach(local) { row($0) } }
        }
        if !extra.isEmpty {
            Section("More places") { ForEach(extra) { row($0) } }
        }
        if local.isEmpty && extra.isEmpty {
            Section {
                row(Place(name: trimmed, detail: "Use exactly what you typed", country: "", kind: .city))
            }
        }
    }

    private func row(_ place: Place) -> some View {
        Button {
            onSelect(place)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon(for: place))
                    .foregroundStyle(Theme.gatherAccent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .scaledFont(16, weight: .medium, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                    Text(place.kind == .nearby ? "Around \(home.name)" : place.detail)
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }
                Spacer(minLength: 0)
                if selection?.id == place.id {
                    Image(systemName: "checkmark").foregroundStyle(Theme.gatherAccent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func icon(for place: Place) -> String {
        switch place.kind {
        case .nearby:  return "location.fill"
        case .world:   return "globe"
        case .country: return "flag"
        case .city:    return "building.2"
        case .area:    return "mappin.and.ellipse"
        }
    }
}
