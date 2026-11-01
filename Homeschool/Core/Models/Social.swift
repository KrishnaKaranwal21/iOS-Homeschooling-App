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
    /// Not shown any more. Kept so older sample data still builds.
    var note = "Happy to share."
    /// The area they live in, such as "Potheri". Only the area is ever shown, never a distance.
    var place = ""

    var firstName: String { name.components(separatedBy: " ")[0] }

    /// Name of an optional photo in the asset catalog. Without it the card shows the initial.
    var photoName: String { "Parent-\(firstName)" }

    var searchText: String {
        ([name, role, tags, about, place] + interests + lookingFor).joined(separator: " ")
    }
}

struct RoadmapStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
}

/// What happens when a notification is tapped.
enum NotificationAction: Equatable {
    case none
    /// A gathering: a new one, or one a connection joined.
    case openEvent(Event.ID)
    /// The question and answer section of a gathering.
    case openEventQuestions(Event.ID)
    /// A connection request was accepted: open the chat with them.
    case openChat(Parent.ID)
    /// Someone wants to connect. The row has Accept and Decline.
    case connectionRequest(Parent.ID)
}

struct AppNotification: Identifiable {
    let id = UUID()
    var symbol: String
    var title: String
    var detail: String
    var time: String
    var isNew = false
    var action: NotificationAction = .none
}

/// A message that appears over the app, such as "The host answered your question".
struct AppPopup: Identifiable {
    let id = UUID()
    var title: String
    /// The bold line in the lavender box.
    var headline: String
    var detail: String
    var message: String
    var buttonTitle: String
    var action: NotificationAction
}

/// Choices on the community profile. Interests use the same names as child setup.
enum CommunityOptions {
    /// "Near you" means within this many kilometres, the same as on the Gatherings page.
    static let nearKm = 10.0
    static let interests = ["Coding", "Animals", "Art", "Music", "Space", "Nature", "Sports", "Reading"]
    static let lookingFor = ["Learning groups", "Weekend outings", "Playdates", "Swapping ideas"]
}
