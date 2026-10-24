import Foundation

struct Event: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case gathering = "Gathering"
        case workshop = "Workshop"
        var id: String { rawValue }
    }

    enum Mode: String, CaseIterable, Identifiable {
        case inPerson = "In person"
        case online = "Online"
        var id: String { rawValue }
    }

    /// What the host expects of parents and guardians at the event.
    enum ParentPresence: String, CaseIterable, Identifiable {
        case required   = "Parent/guardian required to stay"
        case optional   = "Parent/guardian optional"
        case notAllowed = "Drop-off only (Kids only)"
        var id: String { rawValue }

        var shortTitle: String {
            switch self {
            case .required:   return "Parent stays"
            case .optional:   return "Parent optional"
            case .notAllowed: return "Drop-off only"
            }
        }

        var detail: String {
            switch self {
            case .required:   return "An adult must remain present throughout the session."
            case .optional:   return "Feel free to stay or drop off your child."
            case .notAllowed: return "Designed for children only; parent/guardian drop-off and pick-up."
            }
        }

        var symbol: String {
            switch self {
            case .required:   return "person.2.fill"
            case .optional:   return "person.crop.circle.badge.questionmark"
            case .notAllowed: return "figure.walk.departure"
            }
        }
    }

    let id = UUID()
    var title: String
    /// Science, Habit, Art, Coding, Nature, or Community for events parents host.
    var category: String
    var kind: Kind = .gathering
    var start: Date
    var end: Date
    var host: String
    var hostRole = "Parent host"
    var locality = "Potheri"
    /// Country of the locality, used when filtering by country.
    var country = "India"
    /// First line is the venue, an optional second line is the area or address.
    var location: String
    var mode: Mode = .inPerson
    var ages: String
    var parentPresence: ParentPresence = .required
    var about: String
    /// Price in rupees. `nil` means free.
    var price: Int? = nil
    var symbol: String
    /// Name of an image in the asset catalog. The cover falls back to a colour when it is missing.
    var coverName: String? = nil
    /// Photo picked by a parent when hosting.
    var coverData: Data? = nil
    var isRegistered = false
}

extension Event {
    /// Categories a host can choose from. The Gather page adds "All" in front.
    static let categories = ["Science", "Habit", "Art", "Coding", "Nature"]

    static func symbol(for category: String) -> String {
        switch category {
        case "Science": return "flask"
        case "Habit":   return "repeat"
        case "Art":     return "paintpalette"
        case "Coding":  return "chevron.left.forwardslash.chevron.right"
        case "Nature":  return "leaf"
        default:        return "person.2.fill"
        }
    }

    var day: Int { Calendar.current.component(.day, from: start) }
    var month: String { start.formatted(.dateTime.month(.abbreviated)).uppercased() }
    var weekday: String { start.formatted(.dateTime.weekday(.abbreviated)).uppercased() }
    var time: String { start.formatted(date: .omitted, time: .shortened) }

    /// "9 AM" on the hour, "9:30 AM" otherwise.
    var shortTime: String {
        Calendar.current.component(.minute, from: start) == 0
            ? start.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
            : time
    }

    /// "Thu, 12 Nov · 9 AM"
    var shortDateText: String {
        let weekday = start.formatted(.dateTime.weekday(.abbreviated))
        let date = start.formatted(.dateTime.day().month(.abbreviated))
        return "\(weekday), \(date) · \(shortTime)"
    }

    /// Stays the same between launches (ids do not), so bookmarks can be remembered.
    var storageKey: String { "\(title)|\(Int(start.timeIntervalSince1970))" }

    var isFree: Bool { price == nil }

    var priceText: String {
        guard let price else { return "Free" }
        return price.formatted(.currency(code: "INR").precision(.fractionLength(0)))
    }

    var locationLines: (title: String, detail: String?) {
        let lines = location.split(separator: "\n", maxSplits: 1).map(String.init)
        return (lines.first ?? location, lines.count > 1 ? lines[1] : nil)
    }
}
