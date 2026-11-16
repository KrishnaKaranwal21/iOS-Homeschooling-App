import SwiftUI

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

enum PlaceCatalog {
    /// Closest areas first. These are shown at the top of the list.
    static let nearby: [Place] = [
        .potheri,
        Place(name: "Guduvanchery", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Urapakkam", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Chengalpattu", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Maraimalai Nagar", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Tambaram", detail: "Chennai area, India", country: "India", kind: .area),
        Place(name: "Kattankulathur", detail: "Chennai area, India", country: "India", kind: .area)
    ]

    /// Areas in Mumbai that have families or events.
    static let mumbaiAreas: [Place] = [
        Place(name: "Kharghar", detail: "Mumbai area, India", country: "India", kind: .area),
        Place(name: "Navi Mumbai", detail: "Mumbai area, India", country: "India", kind: .area)
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

    static var all: [Place] { nearby + mumbaiAreas + india + worldCountries + worldCities }

    /// Areas that belong to a city, so choosing "Chennai" also shows events in Potheri and nearby.
    private static let areasByCity: [String: Set<String>] = [
        "Chennai": Set(nearby.map(\.name)),
        "Mumbai": Set(mumbaiAreas.map(\.name)),
        "Thane": Set(mumbaiAreas.map(\.name))
    ]

    /// Whether an event is relevant to the place chosen in the filter.
    /// Area names that count as "near" a home location.
    static func nearbyNames(around home: Place) -> Set<String> {
        if nearby.contains(where: { $0.name == home.name }) { return Set(nearby.map(\.name)) }
        if mumbaiAreas.contains(where: { $0.name == home.name }) { return Set(mumbaiAreas.map(\.name)) }
        if let areas = areasByCity[home.name] { return areas.union([home.name]) }
        return [home.name]
    }

    /// Static profiles follow the chosen area/city rather than retaining the original demo location.
    static func matchesCommunity(_ parent: Parent, home: Place) -> Bool {
        guard parent.distanceKm <= CommunityOptions.nearKm else { return false }
        // The whole country, or a city or area named in the profile, also counts.
        if home.kind == .country || home.kind == .world {
            return home.kind == .world || home.country.isEmpty
                || parent.country.localizedCaseInsensitiveCompare(home.country) == .orderedSame
        }
        if home.name.localizedCaseInsensitiveCompare(parent.city) == .orderedSame { return true }
        return nearbyNames(around: home).contains { $0.localizedCaseInsensitiveCompare(parent.place) == .orderedSame }
    }

    /// Community filter for the place chosen in the picker. "Near you" keeps the 10 km rule;
    /// any other choice lists the parents who live in that area, city or country.
    static func matchesCommunity(_ parent: Parent, selection: Place, home: Place) -> Bool {
        func same(_ a: String, _ b: String) -> Bool { a.localizedCaseInsensitiveCompare(b) == .orderedSame }
        switch selection.kind {
        case .nearby:
            return matchesCommunity(parent, home: home)
        case .world:
            return true
        case .country:
            return same(parent.country, selection.country) || same(parent.country, selection.name)
        case .area:
            return same(parent.place, selection.name)
        case .city:
            if same(parent.city, selection.name) || same(parent.place, selection.name) { return true }
            if areasByCity[selection.name]?.contains(parent.place) ?? false { return true }
            // Places found through map search can come back as "Panaji, Goa" style names.
            return !selection.name.isEmpty
                && (parent.city.localizedCaseInsensitiveContains(selection.name)
                    || selection.name.localizedCaseInsensitiveContains(parent.city)
                    || selection.name.localizedCaseInsensitiveContains(parent.place))
        }
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
