import SwiftUI

/// A filter chip above the chat list. Built-in ones filter by chat type; custom ones are tags the parent creates.
struct ChatLabel: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    /// Index into `ChatLabel.palette`. Only custom labels show their colour.
    var colorIndex = 0

    static let allID = "all"

    static let all        = ChatLabel(id: "all", name: "All")
    static let unread     = ChatLabel(id: "unread", name: "Unread")
    static let groups     = ChatLabel(id: "groups", name: "Groups")
    static let favourites = ChatLabel(id: "favourites", name: "Favourites")
    static let direct     = ChatLabel(id: "direct", name: "Direct")
    static let muted      = ChatLabel(id: "muted", name: "Muted")

    /// Every built-in label. `all` always stays first and can't be removed.
    static let builtIns: [ChatLabel] = [.all, .unread, .groups, .favourites, .direct, .muted]
    /// What the bar shows the first time.
    static let defaultBar: [ChatLabel] = [.all, .unread, .groups, .favourites]

    var isBuiltIn: Bool { Self.builtIns.contains { $0.id == id } }

    static let palette: [Color] = [
        Color.adaptive(0xD0C8FA, 0x3B3059), Color.adaptive(0xF7C9C9, 0x482D38), Color.adaptive(0xD8EBA0, 0x36402A),
        Color.adaptive(0xFBE7A1, 0x443B23), Color.adaptive(0xFAD0B8, 0x4B332D), Color.adaptive(0xBFE3F5, 0x263D49)
    ]

    var color: Color { Self.palette[colorIndex % Self.palette.count] }
}
