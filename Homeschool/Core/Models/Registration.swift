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

    /// Short reference shown on the confirmation, e.g. "HS-3F9A21".
    var code: String { "HS-" + id.uuidString.prefix(6).uppercased() }
}
