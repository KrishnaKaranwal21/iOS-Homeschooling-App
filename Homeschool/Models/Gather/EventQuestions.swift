import SwiftUI

/// A question and answer the host adds to their event.
struct EventFAQ: Identifiable, Hashable, Codable {
    var id = UUID()
    var question: String
    var answer: String
}

/// A question a family asked the host. The host answers it, and can add it to the event's public FAQs.
struct EventQuestion: Identifiable, Hashable, Codable {
    var id = UUID()
    var asker: String
    var text: String
    var date: Date
    var answer: String? = nil
    /// True when the signed-in parent asked it (to a host). Otherwise a family asked the signed-in host.
    var askedByMe = false

    var isAnswered: Bool { answer != nil }
}
