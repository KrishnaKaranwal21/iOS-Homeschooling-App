import SwiftUI

// MARK: - Models

enum MessageStatus { case sent, delivered, read }

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var date: Date
    var isMine: Bool
    /// Who wrote it, for messages from other people in a group.
    var sender: String? = nil
    var status: MessageStatus = .read
    var imageData: Data? = nil
}

struct ChatThread: Identifiable {
    let id = UUID()
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

    var lastDate: Date { messages.last?.date ?? .distantPast }
    var hasUnread: Bool { unreadCount > 0 || markedUnread }

    var subtitle: String {
        isGroup ? "Group · \(members.count + 1) members" : about
    }

    var initials: String {
        let letters = title.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var avatarColor: Color {
        let palette: [Color] = [Color(hex: 0xE6E1FF), Theme.pink, Theme.lime, Theme.yellow, Color(hex: 0xFAD9C9)]
        let seed = title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[seed % palette.count]
    }

    var mediaMessages: [ChatMessage] { messages.filter { $0.imageData != nil } }

    /// The line shown in the chat list.
    var preview: String {
        guard let last = messages.last else { return "No messages yet" }
        let body = last.imageData != nil && last.text.isEmpty ? "Photo" : last.text
        if last.isMine { return "You: \(body)" }
        if isGroup, let sender = last.sender { return "\(sender): \(body)" }
        return body
    }
}

// MARK: - Formatting

enum ChatFormat {
    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm"; return f
    }()
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMM"; return f
    }()
    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d/M/yy"; return f
    }()

    static func clock(_ date: Date) -> String { clockFormatter.string(from: date) }

    /// Time on the right of a chat row: the time today, then Yesterday, a weekday, or a date.
    static func listTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return clock(date) }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: .now)).day ?? 99
        return days < 7 ? weekdayFormatter.string(from: date) : shortFormatter.string(from: date)
    }

    static func dayHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return dayFormatter.string(from: date)
    }
}

// MARK: - Store

@MainActor
@Observable
final class ChatStore {
    var threads: [ChatThread] = ChatStore.sample()

    var sortedThreads: [ChatThread] {
        threads.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.lastDate > $1.lastDate
        }
    }

    var totalUnread: Int {
        threads.filter { !$0.isMuted }.reduce(0) { $0 + ($1.unreadCount > 0 ? $1.unreadCount : ($1.markedUnread ? 1 : 0)) }
    }

    func thread(_ id: ChatThread.ID) -> ChatThread? {
        threads.first { $0.id == id }
    }

    private func update(_ id: ChatThread.ID, _ change: (inout ChatThread) -> Void) {
        guard let index = threads.firstIndex(where: { $0.id == id }) else { return }
        change(&threads[index])
    }

    // MARK: Reading

    func markRead(_ id: ChatThread.ID) {
        update(id) { $0.unreadCount = 0; $0.markedUnread = false }
    }

    func markUnread(_ id: ChatThread.ID) {
        update(id) { $0.markedUnread = true }
    }

    // MARK: Settings

    func toggleMute(_ id: ChatThread.ID) { update(id) { $0.isMuted.toggle() } }
    func togglePin(_ id: ChatThread.ID) { update(id) { $0.isPinned.toggle() } }
    func toggleBlock(_ id: ChatThread.ID) { update(id) { $0.isBlocked.toggle() } }
    func clear(_ id: ChatThread.ID) { update(id) { $0.messages = []; $0.unreadCount = 0; $0.markedUnread = false } }

    func delete(_ id: ChatThread.ID) {
        threads.removeAll { $0.id == id }
    }

    func deleteMessage(_ messageID: ChatMessage.ID, in id: ChatThread.ID) {
        update(id) { $0.messages.removeAll { $0.id == messageID } }
    }

    // MARK: Sending

    func send(text: String, imageData: Data? = nil, in id: ChatThread.ID) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || imageData != nil else { return }
        let message = ChatMessage(text: trimmed, date: .now, isMine: true, status: .sent, imageData: imageData)
        update(id) { $0.messages.append(message) }

        // Ticks move on like in any messenger: sent, then delivered, then read.
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            self?.setStatus(.delivered, for: message.id, in: id)
            try? await Task.sleep(for: .milliseconds(1700))
            self?.setStatus(.read, for: message.id, in: id)
        }
    }

    private func setStatus(_ status: MessageStatus, for messageID: ChatMessage.ID, in id: ChatThread.ID) {
        update(id) { thread in
            if let index = thread.messages.firstIndex(where: { $0.id == messageID }) {
                thread.messages[index].status = status
            }
        }
    }

    // MARK: Creating chats

    /// Opens the chat with this parent, creating it the first time.
    func startChat(with parent: Parent) -> ChatThread.ID {
        if let existing = threads.first(where: { !$0.isGroup && $0.title == parent.name }) {
            return existing.id
        }
        let thread = ChatThread(title: parent.name, about: parent.role)
        threads.append(thread)
        return thread.id
    }

    func createGroup(title: String, members: [String]) -> ChatThread.ID {
        let thread = ChatThread(title: title, isGroup: true, members: members)
        threads.append(thread)
        return thread.id
    }

    func addMembers(_ names: [String], to id: ChatThread.ID) {
        update(id) { thread in
            for name in names where !thread.members.contains(name) { thread.members.append(name) }
        }
    }

    func removeMember(_ name: String, from id: ChatThread.ID) {
        update(id) { $0.members.removeAll { $0 == name } }
    }

    // MARK: Sample conversations

    private static func at(_ daysAgo: Int, _ hour: Int, _ minute: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: .now)) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func sample() -> [ChatThread] {
        func me(_ text: String, _ d: Date, _ status: MessageStatus = .read) -> ChatMessage {
            ChatMessage(text: text, date: d, isMine: true, status: status)
        }
        func them(_ text: String, _ d: Date, from sender: String? = nil) -> ChatMessage {
            ChatMessage(text: text, date: d, isMine: false, sender: sender)
        }

        return [
            ChatThread(title: "Sara Patel", about: "Mum to Arya, 13", messages: [
                me("Hi Sara! I’m Asha. I spotted your profile in the homeschooling community and thought I’d say hello. We’re new here – would love to connect!", at(0, 9, 8)),
                them("Hi Asha! Nice to meet you. Homeschooling can feel quiet sometimes, so it’s great to connect with someone local.", at(0, 9, 10)),
                me("Exactly! We just moved here and I’m still finding our rhythm. Do you have a favorite park or meetup spot nearby?", at(0, 9, 12)),
                them("We love the library on Fridays and the nature walk by the creek on Wednesdays. Both are super chill for kids.", at(0, 9, 14)),
                them("Arya is excited to show Maya her telescope!", at(0, 9, 33)),
                them("Shall we meet by the café at 10?", at(0, 9, 36))
            ], unreadCount: 2),

            ChatThread(title: "Oakwood homeschool circle", isGroup: true,
                       members: ["Emma", "Priya", "Daniel", "Neha", "Kiran"], messages: [
                them("Who’s up for the park on Saturday?", at(0, 9, 2), from: "Priya"),
                them("Count us in!", at(0, 9, 8), from: "Neha"),
                them("Me too. Should we plan a picnic?", at(0, 9, 14), from: "Daniel"),
                them("Yes please, the kids will love it.", at(0, 9, 19), from: "Kiran"),
                them("I’ll bring the picnic blanket!", at(0, 9, 24), from: "Emma")
            ], unreadCount: 5),

            ChatThread(title: "Curious Minds Club", isGroup: true,
                       members: ["Leo", "Mira", "Sam", "Anita"], messages: [
                them("Sharing the photos from Thursday’s session.", at(0, 8, 41), from: "Mira"),
                them("The kids loved the volcano!", at(0, 8, 49), from: "Anita"),
                them("The moon experiment was a hit", at(0, 8, 58), from: "Leo")
            ], unreadCount: 3),

            ChatThread(title: "James Wilson", about: "Dad to Noah, 9", messages: [
                me("Hi James, we have two spots left at the nature walk.", at(0, 8, 5)),
                them("Thanks! Noah can’t wait to join you.", at(0, 8, 12))
            ]),

            ChatThread(title: "Nature explorers", isGroup: true, members: ["Nina", "Rohan", "Kavya"], messages: [
                me("Meeting at the main gate at 9. Bring water!", at(1, 18, 20)),
                them("A little rain won’t stop us 🌿", at(1, 18, 45), from: "Nina")
            ], isMuted: true),

            ChatThread(title: "Amelia Chen", about: "Mum to Ivy, 6", messages: [
                them("Have you read The Wild Robot with Maya yet?", at(1, 17, 10)),
                me("That book is on our list now!", at(1, 17, 30))
            ]),

            ChatThread(title: "The Friday families", isGroup: true, members: ["Sara", "Daniel", "Preeti"], messages: [
                them("Library trip again this Friday?", at(3, 15, 5), from: "Preeti"),
                me("See you all next week!", at(3, 15, 40))
            ])
        ]
    }
}
