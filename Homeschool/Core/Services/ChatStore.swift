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
    /// A recorded voice note.
    var audioData: Data? = nil
    var audioDuration: TimeInterval = 0
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
    var isFavourite = false
    /// Ids of the custom labels on this chat.
    var labelIDs: Set<String> = []

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
        let body: String
        if last.audioData != nil {
            body = "Voice message (\(ChatFormat.duration(last.audioDuration)))"
        } else {
            body = last.imageData != nil && last.text.isEmpty ? "Photo" : last.text
        }
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

    /// 0:07, 1:32
    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return "\(total / 60):\(String(format: "%02d", total % 60))"
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
    var threads: [ChatThread]

    /// The chips above the chat list, in order. `All` is always first.
    var labels: [ChatLabel] {
        didSet { saveLabels() }
    }

    /// The chip that is selected. Kept here, not in the view, so it survives switching tabs and relaunching.
    var selectedLabelID: String {
        didSet { UserDefaults.standard.set(selectedLabelID, forKey: Keys.selected) }
    }

    private enum Keys {
        static let labels = "chat.labels"
        static let selected = "chat.selectedLabel"
        static let tags = "chat.tagsByTitle"
        static let favourites = "chat.favourites"
        static let seedSamples = "chat.seedSamples"
    }

    init() {
        let defaults = UserDefaults.standard
        var loaded = ChatLabel.defaultBar
        if let data = defaults.data(forKey: Keys.labels),
           let saved = try? JSONDecoder().decode([ChatLabel].self, from: data), !saved.isEmpty {
            loaded = saved
        }
        if !loaded.contains(where: { $0.id == ChatLabel.allID }) { loaded.insert(.all, at: 0) }
        labels = loaded

        let savedSelection = defaults.string(forKey: Keys.selected) ?? ChatLabel.allID
        selectedLabelID = loaded.contains { $0.id == savedSelection } ? savedSelection : ChatLabel.allID

        // A new account has no conversations. Sample chats only exist for a returning login.
        threads = defaults.bool(forKey: Keys.seedSamples) ? ChatStore.savedSample() : []
    }

    /// Starts from an empty inbox, or from the sample conversations.
    func reload(withSamples: Bool) {
        UserDefaults.standard.set(withSamples, forKey: Keys.seedSamples)
        threads = withSamples ? ChatStore.savedSample() : []
    }

    /// Sample chats with the labels and favourites the family saved earlier (matched by name).
    private static func savedSample() -> [ChatThread] {
        let defaults = UserDefaults.standard
        var sample = ChatStore.sample()
        let tags = (defaults.dictionary(forKey: Keys.tags) as? [String: [String]]) ?? [:]
        let favourites = Set(defaults.stringArray(forKey: Keys.favourites) ?? [])
        for index in sample.indices {
            sample[index].labelIDs = Set(tags[sample[index].title] ?? [])
            sample[index].isFavourite = favourites.contains(sample[index].title)
        }
        return sample
    }

    var sortedThreads: [ChatThread] {
        threads.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.lastDate > $1.lastDate
        }
    }

    /// How many chats have something unread (not how many messages). Muted chats aren't counted.
    var unreadChatCount: Int {
        threads.filter { $0.hasUnread && !$0.isMuted }.count
    }

    /// A chat to open as soon as the Chats tab appears, for example after messaging an event host.
    var pendingOpenID: ChatThread.ID?

    func thread(_ id: ChatThread.ID) -> ChatThread? {
        threads.first { $0.id == id }
    }

    private func update(_ id: ChatThread.ID, _ change: (inout ChatThread) -> Void) {
        guard let index = threads.firstIndex(where: { $0.id == id }) else { return }
        change(&threads[index])
    }

    // MARK: Labels

    var selectedLabel: ChatLabel {
        labels.first { $0.id == selectedLabelID } ?? .all
    }

    func matches(_ thread: ChatThread, label: ChatLabel) -> Bool {
        switch label.id {
        case "all":        return true
        case "unread":     return thread.hasUnread
        case "groups":     return thread.isGroup
        case "direct":     return !thread.isGroup
        case "muted":      return thread.isMuted
        case "favourites": return thread.isFavourite
        default:           return thread.labelIDs.contains(label.id)
        }
    }

    func threads(for label: ChatLabel) -> [ChatThread] {
        sortedThreads.filter { matches($0, label: label) }
    }

    /// Built-in labels that are not on the bar right now.
    var removedBuiltIns: [ChatLabel] {
        ChatLabel.builtIns.filter { builtIn in !labels.contains { $0.id == builtIn.id } }
    }

    var customLabels: [ChatLabel] { labels.filter { !$0.isBuiltIn } }

    func select(_ id: String) { selectedLabelID = id }

    func addBuiltIn(_ label: ChatLabel) {
        guard !labels.contains(where: { $0.id == label.id }) else { return }
        labels.append(label)
    }

    @discardableResult
    func addCustomLabel(name: String, colorIndex: Int) -> ChatLabel? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !labels.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return nil }
        let label = ChatLabel(id: UUID().uuidString, name: trimmed, colorIndex: colorIndex)
        labels.append(label)
        return label
    }

    func updateLabel(_ id: String, name: String, colorIndex: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let index = labels.firstIndex(where: { $0.id == id }) else { return }
        labels[index].name = trimmed
        labels[index].colorIndex = colorIndex
    }

    /// Moves a chip one place left (-1) or right (+1). `All` stays first.
    func moveLabel(_ id: String, by offset: Int) {
        guard id != ChatLabel.allID,
              let index = labels.firstIndex(where: { $0.id == id }) else { return }
        let target = index + offset
        guard target >= 1, target < labels.count else { return }
        labels.swapAt(index, target)
    }

    /// Custom labels are deleted and removed from every chat. Built-in ones only leave the bar.
    func removeLabel(_ id: String) {
        guard id != ChatLabel.allID else { return }
        let wasCustom = !(labels.first { $0.id == id }?.isBuiltIn ?? true)
        labels.removeAll { $0.id == id }
        if wasCustom {
            for index in threads.indices { threads[index].labelIDs.remove(id) }
            saveTags()
        }
        if selectedLabelID == id { selectedLabelID = ChatLabel.allID }
    }

    func toggleLabel(_ labelID: String, on threadID: ChatThread.ID) {
        update(threadID) { thread in
            if thread.labelIDs.contains(labelID) { thread.labelIDs.remove(labelID) }
            else { thread.labelIDs.insert(labelID) }
        }
        saveTags()
    }

    func toggleFavourite(_ id: ChatThread.ID) {
        update(id) { $0.isFavourite.toggle() }
        saveTags()
    }

    private func saveLabels() {
        if let data = try? JSONEncoder().encode(labels) {
            UserDefaults.standard.set(data, forKey: Keys.labels)
        }
    }

    private func saveTags() {
        var tags: [String: [String]] = [:]
        for thread in threads where !thread.labelIDs.isEmpty { tags[thread.title] = Array(thread.labelIDs) }
        UserDefaults.standard.set(tags, forKey: Keys.tags)
        UserDefaults.standard.set(threads.filter(\.isFavourite).map(\.title), forKey: Keys.favourites)
    }

    /// Sends the same message to every chat under a label, one by one. Blocked chats are skipped.
    @discardableResult
    func broadcast(_ text: String, to labelID: String) -> (sent: Int, skipped: Int) {
        guard let label = labels.first(where: { $0.id == labelID }) else { return (0, 0) }
        var sent = 0, skipped = 0
        for thread in threads(for: label) {
            if thread.isBlocked { skipped += 1 } else {
                send(text: text, in: thread.id)
                sent += 1
            }
        }
        return (sent, skipped)
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
        deliver(ChatMessage(text: trimmed, date: .now, isMine: true, status: .sent, imageData: imageData), in: id)
    }

    func sendVoiceNote(_ data: Data, duration: TimeInterval, in id: ChatThread.ID) {
        deliver(ChatMessage(text: "", date: .now, isMine: true, status: .sent,
                            audioData: data, audioDuration: duration), in: id)
    }

    private func deliver(_ message: ChatMessage, in id: ChatThread.ID) {
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

    /// Opens the chat with an event host, creating it the first time.
    func startChat(withHost name: String, role: String) -> ChatThread.ID {
        if let existing = threads.first(where: { !$0.isGroup && $0.title == name }) { return existing.id }
        let thread = ChatThread(title: name, about: role)
        threads.append(thread)
        return thread.id
    }

    // PROTOTYPE ONLY: adds a message from the other person so the received-message style can be seen.
    // Remove this together with the "Show incoming message" button in ChatDetailView.
    func simulateIncoming(in id: ChatThread.ID) {
        let samples = [
            "Thanks for getting in touch! Happy to help.",
            "Sounds great. See you there!",
            "Of course. Let me check and get back to you shortly.",
            "Yes, that works for us too."
        ]
        update(id) { thread in
            let sender = thread.isGroup ? thread.members.randomElement() : nil
            thread.messages.append(ChatMessage(text: samples.randomElement() ?? samples[0], date: .now,
                                               isMine: false, sender: sender))
        }
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
