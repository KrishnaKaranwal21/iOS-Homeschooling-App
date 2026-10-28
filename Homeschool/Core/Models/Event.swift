import SwiftUI

/// A question and answer the host adds to their event.
struct EventFAQ: Identifiable, Hashable {
    let id = UUID()
    var question: String
    var answer: String
}

/// A question a family asked the host. The host answers it, and can add it to the event's public FAQs.
struct EventQuestion: Identifiable, Hashable {
    let id = UUID()
    var asker: String
    var text: String
    var date: Date
    var answer: String? = nil

    var isAnswered: Bool { answer != nil }
}

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
        case dropOffOnly = "Drop-off only (No parent/guardian)"
        var id: String { rawValue }

        var shortTitle: String {
            switch self {
            case .required:   return "Parent stays"
            case .optional:   return "Parent optional"
            case .dropOffOnly: return "Drop-off only"
            }
        }

        var detail: String {
            switch self {
            case .required:   return "An adult must remain present throughout the session."
            case .optional:   return "You are welcome to stay or drop off your child."
            case .dropOffOnly: return "Independent session for learners; drop-off and pick-up only."
            }
        }

        var symbol: String {
            switch self {
            case .required:   return "person.2.fill"
            case .optional:   return "person.crop.circle.badge.questionmark"
            case .dropOffOnly: return "figure.walk.departure"
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
    /// Questions the host answered ahead of time.
    var faqs: [EventFAQ] = []
    /// Price in rupees. `nil` means free.
    var price: Int? = nil
    var symbol: String
    /// Name of an image in the asset catalog. The cover falls back to a colour when it is missing.
    var coverName: String? = nil
    /// Photo picked by a parent when hosting.
    var coverImage: PickedImage? = nil
    var isRegistered = false
    /// True when the signed-in parent created this event. The detail page then shows the host's tools.
    var isHostedByMe = false
    /// How many families have registered (shown to the host).
    var registeredCount = 0
    /// Questions families sent to the host.
    var questions: [EventQuestion] = []
}

extension Event {
    /// Categories a host can choose from. The Gather page adds "All" in front.
    static let categories = ["Science", "Habit", "Art", "Coding", "Nature", "Others"]

    static func symbol(for category: String) -> String {
        switch category {
        case "Science": return "flask"
        case "Habit":   return "repeat"
        case "Art":     return "paintpalette"
        case "Coding":  return "chevron.left.forwardslash.chevron.right"
        case "Nature":  return "leaf"
        case "Others":  return "sparkles"
        default:        return "person.2.fill"
        }
    }

    /// The host's own answers first, then the basics every family asks about.
    var allFAQs: [EventFAQ] {
        var standard: [EventFAQ] = [
            EventFAQ(question: "Who is this for?",
                     answer: "This session is planned for \(ages.lowercased() == "all ages" ? "all ages" : ages.lowercased())."),
            EventFAQ(question: "Can I stay with my child?",
                     answer: "\(parentPresence.rawValue). \(parentPresence.detail)"),
            EventFAQ(question: "Can I cancel my place?",
                     answer: isFree
                        ? "Yes. Free places can be cancelled any time from your registration."
                        : "Paid places can’t be cancelled. The \(priceText) fee is non-refundable, even if you can’t attend.")
        ]
        standard.append(EventFAQ(question: mode == .online ? "How do we join?" : "Where do we meet?",
                                 answer: mode == .online
                                    ? "This is an online session. The host shares the meeting link in the details."
                                    : location.replacingOccurrences(of: "\n", with: ", ")))
        return faqs + standard
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

    var unansweredCount: Int { questions.filter { !$0.isAnswered }.count }

    /// Unanswered questions first, then the newest answered ones.
    var sortedQuestions: [EventQuestion] {
        questions.sorted {
            if $0.isAnswered != $1.isAnswered { return !$0.isAnswered }
            return $0.date > $1.date
        }
    }

    var priceText: String {
        guard let price else { return "Free" }
        return price.formatted(.currency(code: "INR").precision(.fractionLength(0)))
    }

    var locationLines: (title: String, detail: String?) {
        let lines = location.split(separator: "\n", maxSplits: 1).map(String.init)
        return (lines.first ?? location, lines.count > 1 ? lines[1] : nil)
    }
}

/// A photo the person picked, kept as a SwiftUI `Image` (loaded with `PhotosPickerItem.loadTransferable(type: Image.self)`).
/// `Image` is not `Hashable`/`Equatable`, so identity is the wrapper's own id.
struct PickedImage: Identifiable, Hashable {
    let id = UUID()
    let image: Image

    static func == (lhs: PickedImage, rhs: PickedImage) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
