import SwiftUI

// MARK: - MessageStatus

enum MessageStatus: Codable { case sent, delivered, read }

// MARK: - ChatMessage

struct ChatMessage: Identifiable, Equatable, Codable {
    var id = UUID()
    var text: String
    var date: Date
    var isMine: Bool
    /// Who wrote it, for messages from other people in a group.
    var sender: String? = nil
    var status: MessageStatus = .read
    var image: PickedImage? = nil
    /// A recorded voice note.
    var audioData: Data? = nil
    var audioDuration: TimeInterval = 0
    /// Starred messages stay in the chat even when disappearing messages is on.
    var isStarred = false
}

// MARK: - ChatThread

struct ChatThread: Identifiable, Codable {
    var id = UUID()
    var title: String
    /// Shown under the name, like "Mum to Arya, 13".
    var about: String = ""
    var isGroup = false
    var members: [String] = []
    var messages: [ChatMessage] = []
    var unreadCount = 0
    var markedUnread = false
    var isMuted = false
    var isPinned = false
    var isBlocked = false
    var isFavourite = false
    /// Ids of the custom labels on this chat.
    var labelIDs: Set<String> = []
    /// Photos show as a placeholder and are left out of the media gallery.
    var hidesMedia = false
    /// A locked chat is hidden from the list and opens from "Locked chats" after unlocking the phone.
    var isLocked = false
    /// Messages sent after `disappearSince` are removed this many seconds after they were sent.
    var disappearAfter: TimeInterval? = nil
    var disappearSince: Date = .distantFuture

    var lastDate: Date { messages.last?.date ?? .distantPast }
    var hasUnread: Bool { unreadCount > 0 || markedUnread }

    var subtitle: String {
        isGroup ? "Group · \(members.count + 1) members" : about
    }

    var initials: String {
        let letters = title.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var avatarColor: Color { Theme.pink }

    var mediaMessages: [ChatMessage] { hidesMedia ? [] : messages.filter { $0.image != nil } }
    var starredMessages: [ChatMessage] { messages.filter(\.isStarred) }

    /// The line shown in the chat list.
    var preview: String {
        guard let last = messages.last else { return "No messages yet" }
        let body: String
        if last.audioData != nil {
            body = "Voice message (\(ChatFormat.duration(last.audioDuration)))"
        } else {
            body = last.image != nil && last.text.isEmpty ? "Photo" : last.text
        }
        if last.isMine { return "You: \(body)" }
        if isGroup, let sender = last.sender { return "\(sender): \(body)" }
        return body
    }
}

// MARK: - ChatFormat

enum ChatFormat {
    static func clock(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
    }

    /// Time on the right of a chat row: the time today, then Yesterday, a weekday, or a date.
    static func listTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return clock(date) }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: .now)).day ?? 99
        return days < 7
            ? date.formatted(.dateTime.weekday(.abbreviated))
            : date.formatted(.dateTime.day().month(.defaultDigits).year(.twoDigits))
    }

    /// 0:07, 1:32
    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }

    static func dayHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }
}

// MARK: - ChatToast

/// The short dark message at the bottom of the chat list, like "List was created".
struct ChatToast: Identifiable, Equatable {
    var id = UUID()
    var message: String
    var actionTitle: String? = nil
}

// MARK: - ChatLabel

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
        Color(hex: 0xD0C8FA), Color(hex: 0xF7C9C9), Color(hex: 0xD8EBA0),
        Color(hex: 0xFBE7A1), Color(hex: 0xFAD0B8), Color(hex: 0xBFE3F5)
    ]

    var color: Color { Self.palette[colorIndex % Self.palette.count] }
}
