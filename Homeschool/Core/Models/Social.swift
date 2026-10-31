import Foundation

struct ParentChild: Hashable {
    let name: String
    let age: Int
    let level: String
    /// This child's own interests (names from child setup).
    var interests: [String] = []
}

struct Parent: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let tags: String
    let distanceKm: Double
    /// One or two lines shown on the community card.
    let about: String
    /// Longer text shown on the profile page.
    var bio = ""
    var children: [ParentChild] = []
    /// Uses the same names as the interests picked in child setup (Space, Art, Reading ...).
    var interests: [String] = []
    var lookingFor: [String] = []
    /// Short line on the sticky note.
    var note = "Happy to share."

    var firstName: String { name.components(separatedBy: " ")[0] }

    /// Name of an optional photo in the asset catalog. Without it the card shows the initial.
    var photoName: String { "Parent-\(firstName)" }

    /// Only an approximate distance is ever shown: rounded to the nearest half kilometre.
    var approxDistance: String {
        let rounded = max(0.5, (distanceKm * 2).rounded() / 2)
        return "About \(rounded.formatted(.number.precision(.fractionLength(0...1)))) km"
    }

    var searchText: String {
        ([name, role, tags, about] + interests + lookingFor).joined(separator: " ")
    }
}

struct AppNotification: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let detail: String
    let time: String
    var isNew = false
}

struct RoadmapStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
}

/// Choices on the community profile. Interests use the same names as child setup.
enum CommunityOptions {
    static let interests = ["Coding", "Animals", "Art", "Music", "Space", "Nature", "Sports", "Reading"]
    static let lookingFor = ["Learning groups", "Weekend outings", "Playdates", "Swapping ideas"]
}
