import SwiftUI

enum LaunchStage { case onboarding, login, setup, main }

@MainActor
@Observable
final class AppState {
    var stage: LaunchStage = .onboarding
    /// The family's home area. "Near you" in Gather and the Community list use it.
    var homeLocation: Place = .potheri {
        didSet { storedHomeLocation = Self.encode(homeLocation) }
    }
    /// When on, the home area follows the phone's approximate location. When off, the family picks a city.
    var usesLiveLocation: Bool {
        get { access(keyPath: \.usesLiveLocation); return storedUsesLiveLocation }
        set { withMutation(keyPath: \.usesLiveLocation) { storedUsesLiveLocation = newValue } }
    }
    let locationService = LocationService()

    var communityRadiusKm: Int {
        get { access(keyPath: \.communityRadiusKm); return storedCommunityRadiusKm }
        set { withMutation(keyPath: \.communityRadiusKm) { storedCommunityRadiusKm = newValue } }
    }

    /// All conversations.
    let chats = ChatStore()

    /// The parent who is signed in.
    var account: Account? = AccountStore.current

    /// Every child in the family. The first one is created during setup.
    var children: [Child] = [Child.empty] {
        didSet { saveChildren() }
    }
    var selectedChildID = UUID() {
        didSet { storedSelectedChildID = selectedChildID.uuidString }
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

    // MARK: Persistence
    // `@AppStorage` replaces direct `UserDefaults.standard` calls. `@Observable` classes need
    // `@ObservationIgnored` on property wrappers, so observed properties above either mirror
    // into these (`didSet`) or wrap them with `access`/`withMutation` (the scalar settings).
    @ObservationIgnored @AppStorage("stage") private var storedStage: String?
    @ObservationIgnored @AppStorage("hasSeenFirstHome") private var storedHasSeenFirstHome: Bool?
    @ObservationIgnored @AppStorage("usesLiveLocation") private var storedUsesLiveLocation = false
    @ObservationIgnored @AppStorage("communityRadiusKm") private var storedCommunityRadiusKm = 5
    @ObservationIgnored @AppStorage("selectedChildID") private var storedSelectedChildID = ""
    @ObservationIgnored @AppStorage("children") private var storedChildren = Data()
    @ObservationIgnored @AppStorage("homeLocation") private var storedHomeLocation = Data()
    @ObservationIgnored @AppStorage("savedRegistrant") private var storedRegistrant = Data()
    @ObservationIgnored @AppStorage("bookmarkedEvents") private var storedBookmarks = Data()

    private static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        data.isEmpty ? nil : try? JSONDecoder().decode(type, from: data)
    }

    init() {
        if storedStage == "main" {
            stage = .main
        }
        // Saved children only count once setup was finished.
        if stage == .main,
           let saved = Self.decode([Child].self, from: storedChildren), !saved.isEmpty {
            children = saved
            let savedID = UUID(uuidString: storedSelectedChildID)
            selectedChildID = saved.contains { $0.id == savedID } ? (savedID ?? saved[0].id) : saved[0].id
        } else {
            selectedChildID = children[0].id
        }
        if let saved = Self.decode(Place.self, from: storedHomeLocation) {
            homeLocation = saved
        }
        // Families who were already inside the app before this screen existed skip it.
        hasSeenFirstHome = storedHasSeenFirstHome ?? (stage == .main)
        savedRegistrant = Self.decode(Registrant.self, from: storedRegistrant)
        bookmarkedKeys = Set(Self.decode([String].self, from: storedBookmarks) ?? [])

        // Sample data: the events already marked as registered get a sample registration.
        let sample = Registrant(parentName: "Asha Patel", email: "asha.patel@example.com",
                                mobile: "+91 98765 43210", childName: "Maya", childAge: "10", notes: "")
        for event in events where event.isRegistered {
            registrations[event.id] = Registration(eventID: event.id, registrant: sample,
                                                   registeredAt: Date.now.addingTimeInterval(-3 * 86_400),
                                                   amountPaid: event.price)
        }
    }

    func advance(to newStage: LaunchStage) {
        stage = newStage
        if newStage == .main {
            storedStage = "main"
        }
    }

    /// Called after login. A new account sees the first-time Home, a returning one goes straight to the regular Home.
    func setReturningUser(_ returning: Bool) {
        hasSeenFirstHome = returning
        storedHasSeenFirstHome = returning
        // A new account starts with no conversations. A returning one gets the sample chats.
        chats.reload(withSamples: returning)
    }

    /// Called when the family leaves Home for the first time.
    func markFirstHomeSeen() {
        guard !hasSeenFirstHome else { return }
        hasSeenFirstHome = true
        storedHasSeenFirstHome = true
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

    // MARK: Location

    func setLiveLocation(_ on: Bool) {
        usesLiveLocation = on
        guard on else { return }
        refreshLiveLocation()
    }

    /// Looks up the approximate area again. Does nothing unless the live location switch is on.
    func refreshLiveLocation() {
        guard usesLiveLocation else { return }
        locationService.onPlace = { [weak self] place in self?.homeLocation = place }
        locationService.request()
    }

    // MARK: Profile completeness

    /// What is still missing before someone can host: the parent's name and mobile, and each child's name, level and birth date.
    var missingProfileItems: [String] {
        var missing: [String] = []
        if (account?.name ?? "").trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your name") }
        if (account?.mobile ?? "").trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your mobile number") }
        for child in children {
            let label = child.name.trimmingCharacters(in: .whitespaces).isEmpty ? "your child" : child.name
            if child.name.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your child’s name") }
            if child.level.isEmpty { missing.append("NIOS level for \(label)") }
            if child.birthDate == nil { missing.append("Date of birth for \(label)") }
        }
        return missing
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
        storedChildren = Self.encode(children)
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

    func register(_ event: Event, as registrant: Registrant, accompanying: Bool = true, places: Int = 1) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index].isRegistered = true
        registrations[event.id] = Registration(eventID: event.id, registrant: registrant,
                                               registeredAt: .now,
                                               amountPaid: event.price.map { $0 * places },
                                               accompanying: accompanying, places: places)

        savedRegistrant = registrant
        storedRegistrant = Self.encode(registrant)
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

    /// Parents I sent a connection request to.
    var requestedParents: Set<Parent.ID> = []

    func sendRequest(to parent: Parent) {
        requestedParents.insert(parent.id)
    }

    /// The host answers a family's question. With `publish`, it also joins the event's public FAQs.
    func answerQuestion(_ questionID: EventQuestion.ID, on eventID: Event.ID, answer: String, publish: Bool) {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let e = events.firstIndex(where: { $0.id == eventID }),
              let q = events[e].questions.firstIndex(where: { $0.id == questionID }) else { return }
        events[e].questions[q].answer = trimmed
        if publish {
            events[e].faqs.append(EventFAQ(question: events[e].questions[q].text, answer: trimmed))
        }
    }

    /// Events I host that still have questions waiting for an answer.
    var hostedEventsWithQuestions: [Event] {
        events.filter { $0.isHostedByMe && $0.unansweredCount > 0 }
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
        storedBookmarks = Self.encode(bookmarkedKeys.sorted())
    }

    func resetOnboarding() {
        storedStage = nil
        children = [Child.empty]
        selectedChildID = children[0].id
        stage = .onboarding
    }
}
