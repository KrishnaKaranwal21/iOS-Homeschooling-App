import Foundation

/// What a parent types into the registration form. The last one used is remembered
/// on this device, so the next registration starts filled in.
struct Registrant: Codable, Equatable {
    var parentName = ""
    var email = ""
    var mobile = ""
    var childName = ""
    var childAge = ""
    var notes = ""
}

/// One confirmed place at one event.
struct Registration: Identifiable {
    let id = UUID()
    let eventID: Event.ID
    let registrant: Registrant
    let registeredAt: Date
    /// Rupees paid at registration. `nil` for free events.
    var amountPaid: Int? = nil
    /// Whether the parent or guardian stays with the child. `false` means drop-off.
    var accompanying = true
    /// How many children this registration covers. Paid events charge one price per place.
    var places = 1

    /// Paid places cannot be cancelled and are never refunded, even if the family does not attend.
    var isPaid: Bool { amountPaid != nil }

    /// Short reference shown on the confirmation, e.g. "HS-3F9A21".
    var code: String { "HS-" + id.uuidString.prefix(6).uppercased() }
}
