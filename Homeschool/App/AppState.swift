import SwiftUI

enum LaunchStage { case onboarding, login, setup, main }

@MainActor
@Observable
final class AppState {
    var stage: LaunchStage = .onboarding
    /// All conversations.
    let chats = ChatStore()

    /// The parent who is signed in.
    var account: Account? = AccountStore.current

    /// Every child in the family. The first one is created during setup.
    var children: [Child] = [Child.empty] {
        didSet { saveChildren() }
    }
    var selectedChildID = UUID() {
        didSet { UserDefaults.standard.set(selectedChildID.uuidString, forKey: selectedChildKey) }
    }

    /// The child whose plan is on screen. Reading and writing go to the matching entry in `children`.
    var child: Child {
        get { children.first { $0.id == selectedChildID } ?? children[0] }
        set {
            if let index = children.firstIndex(where: { $0.id == newValue.id }) {
                children[index] = newValue
            }
        }
    }
    var tasks: [TaskItem] = MockData.tasks
    var events: [Event] = MockData.events.sorted { $0.start < $1.start }

    /// Details from the last registration, used to pre-fill the next one.
    var savedRegistrant: Registrant?
    var registrations: [Event.ID: Registration] = [:]
    private var bookmarkedKeys: Set<String> = []

    /// false until the family has seen the first-time Home and moved on to another tab.
    var hasSeenFirstHome = false

    private let childrenKey = "children"
    private let selectedChildKey = "selectedChildID"
    private let stageKey = "stage"
    private let firstHomeKey = "hasSeenFirstHome"
    private let registrantKey = "savedRegistrant"
    private let bookmarkKey = "bookmarkedEvents"

    init() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: stageKey) == "main" {
            stage = .main
        }
        // Saved children only count once setup was finished.
        if stage == .main,
           let data = defaults.data(forKey: childrenKey),
           let saved = try? JSONDecoder().decode([Child].self, from: data), !saved.isEmpty {
            children = saved
            let savedID = defaults.string(forKey: selectedChildKey).flatMap(UUID.init(uuidString:))
            selectedChildID = saved.contains { $0.id == savedID } ? (savedID ?? saved[0].id) : saved[0].id
        } else {
            selectedChildID = children[0].id
        }
        // Families who were already inside the app before this screen existed skip it.
        hasSeenFirstHome = defaults.object(forKey: firstHomeKey) as? Bool ?? (stage == .main)
        if let data = defaults.data(forKey: registrantKey),
           let saved = try? JSONDecoder().decode(Registrant.self, from: data) {
            savedRegistrant = saved
        }
        bookmarkedKeys = Set(defaults.stringArray(forKey: bookmarkKey) ?? [])

        // Sample data: the events already marked as registered get a sample registration.
        let sample = Registrant(parentName: "Asha Patel", email: "asha.patel@example.com",
                                mobile: "98765 43210", childName: "Maya", childAge: "10", notes: "")
        for event in events where event.isRegistered {
            registrations[event.id] = Registration(eventID: event.id, registrant: sample,
                                                   registeredAt: Date.now.addingTimeInterval(-3 * 86_400),
                                                   amountPaid: event.price)
        }
    }

    func advance(to newStage: LaunchStage) {
        stage = newStage
        if newStage == .main {
            UserDefaults.standard.set("main", forKey: stageKey)
        }
    }

    /// Called after login. A new account sees the first-time Home, a returning one goes straight to the regular Home.
    func setReturningUser(_ returning: Bool) {
        hasSeenFirstHome = returning
        UserDefaults.standard.set(returning, forKey: firstHomeKey)
    }

    /// Called when the family leaves Home for the first time.
    func markFirstHomeSeen() {
        guard !hasSeenFirstHome else { return }
        hasSeenFirstHome = true
        UserDefaults.standard.set(true, forKey: firstHomeKey)
    }

    // MARK: Parent account

    func refreshAccount() {
        account = AccountStore.current
    }

    func updateAccount(name: String, mobile: String) {
        guard var current = account else { return }
        current.name = name.trimmingCharacters(in: .whitespaces)
        current.mobile = mobile.trimmingCharacters(in: .whitespaces)
        AccountStore.update(current)
        account = current
    }

    // MARK: Children

    func selectChild(_ id: Child.ID) {
        guard children.contains(where: { $0.id == id }) else { return }
        selectedChildID = id
    }

    /// Adds a child and switches to them.
    func addChild(_ newChild: Child) {
        children.append(newChild)
        selectedChildID = newChild.id
    }

    /// Switches a child's NIOS level. Subjects depend on the level, so they are cleared and chosen again.
    @discardableResult
    func changeLevel(of id: Child.ID, to level: String) -> Child? {
        guard var changed = children.first(where: { $0.id == id }), changed.level != level else { return nil }
        changed.level = level
        changed.levelChosenManually = true
        changed.selectedSubjects = []
        updateChild(changed)
        return changed
    }

    func updateChild(_ updated: Child) {
        guard let index = children.firstIndex(where: { $0.id == updated.id }) else { return }
        children[index] = updated
    }

    private func saveChildren() {
        if let data = try? JSONEncoder().encode(children) {
            UserDefaults.standard.set(data, forKey: childrenKey)
        }
        syncExamReminders()
    }

    /// Re-plans the "exam form closes soon" notifications for every child who isn't registered.
    func syncExamReminders() {
        guard stage == .main else { return }
        let snapshot = children
        Task { await ExamReminders.sync(children: snapshot) }
    }

    func toggle(_ task: TaskItem) {
        guard let i = tasks.firstIndex(of: task) else { return }
        tasks[i].isDone.toggle()
    }

    // MARK: Events

    func register(_ event: Event, as registrant: Registrant, accompanying: Bool = true) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index].isRegistered = true
        registrations[event.id] = Registration(eventID: event.id, registrant: registrant,
                                               registeredAt: .now, amountPaid: event.price,
                                               accompanying: accompanying)

        savedRegistrant = registrant
        if let data = try? JSONEncoder().encode(registrant) {
            UserDefaults.standard.set(data, forKey: registrantKey)
        }
    }

    /// Free registrations can be cancelled at any time. Paid ones cannot, and are not refunded.
    func canCancel(_ event: Event) -> Bool {
        guard event.isRegistered else { return false }
        return !(registrations[event.id]?.isPaid ?? !event.isFree)
    }

    @discardableResult
    func cancelRegistration(for event: Event) -> Bool {
        guard canCancel(event),
              let index = events.firstIndex(where: { $0.id == event.id }) else { return false }
        events[index].isRegistered = false
        registrations[event.id] = nil
        return true
    }

    func add(_ event: Event) {
        events.append(event)
        events.sort { $0.start < $1.start }
    }

    // MARK: Bookmarks

    var savedEvents: [Event] {
        events.filter { isBookmarked($0) }
    }

    func isBookmarked(_ event: Event) -> Bool {
        bookmarkedKeys.contains(event.storageKey)
    }

    func toggleBookmark(_ event: Event) {
        if !bookmarkedKeys.insert(event.storageKey).inserted {
            bookmarkedKeys.remove(event.storageKey)
        }
        UserDefaults.standard.set(Array(bookmarkedKeys), forKey: bookmarkKey)
    }

    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: stageKey)
        children = [Child.empty]
        selectedChildID = children[0].id
        stage = .onboarding
    }
}
