import Foundation

// MARK: - ParentChild

struct ParentChild: Hashable {
    let name: String
    let age: Int
    let level: String
    /// This child's own interests (names from child setup).
    var interests: [String] = []
}

// MARK: - Parent

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
    /// Not shown any more. Kept so older sample data still builds.
    var note = "Happy to share."
    /// The area they live in, such as "Potheri". Only the area is ever shown, never a distance.
    var place = ""
    /// The city the area belongs to, such as "Chennai". Used so searching or choosing a city finds people.
    var city = "Chennai"
    var country = "India"

    var firstName: String { name.components(separatedBy: " ")[0] }

    /// Name of an optional photo in the asset catalog. Without it the card shows the initial.
    var photoName: String { "Parent-\(firstName)" }

    var searchText: String {
        ([name, role, tags, about, place, city] + interests + lookingFor).joined(separator: " ")
    }
}

// MARK: - CommunityOptions

/// Choices on the community profile. Interests use the same names as child setup.
enum CommunityOptions {
    /// "Near you" means within this many kilometres, the same as on the Gatherings page.
    static let nearKm = 10.0
    static let interests = ["Coding", "Animals", "Art", "Music", "Space", "Nature", "Sports", "Reading"]
    static let lookingFor = ["Learning groups", "Weekend outings", "Playdates", "Swapping ideas"]
}
