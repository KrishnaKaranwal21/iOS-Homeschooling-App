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
    let eventLocations = EventLocationStore()

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
    var weeklyPlans: [String: WeeklyPlan] = [:] {
        didSet { storedWeeklyPlans = Self.encode(weeklyPlans) }
    }

    func saveWeek(_ plan: WeeklyPlan, for childID: Child.ID) {
        weeklyPlans[childID.uuidString] = plan
        if let child = children.first(where: { $0.id == childID }) {
            Task { await WeekReminders.sync(plan: plan, child: child) }
        }
    }

    var dailyWrapUp: DayLearningSummary?

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
    @ObservationIgnored @AppStorage("weeklyPlans") private var storedWeeklyPlans = Data()
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
        weeklyPlans = Self.decode([String: WeeklyPlan].self, from: storedWeeklyPlans) ?? [:]
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

    /// Saves what other parents see on the community profile.
    func updateCommunityProfile(bio: String? = nil, lookingFor: [String]? = nil) {
        guard var current = account else { return }
        if let bio { current.bio = bio }
        if let lookingFor { current.lookingFor = lookingFor }
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
        events[index].updateRegistration(true)
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
              let index = events.firstIndex(where: { $0.id == event.id }), events[index].isRegistered else { return false }
        events[index].updateRegistration(false)
        registrations[event.id] = nil
        return true
    }

    /// Pages that cover the tab bar (an open chat) count themselves in here, so the bottom bar used on
    /// iPad can hide too. The system tab bar on iPhone hides itself.
    var tabBarHideCount = 0
    var hidesTabBar: Bool { tabBarHideCount > 0 }

    /// Parents I sent a connection request to.
    var requestedParents: Set<Parent.ID> = []
    /// Parents I am connected with, so I can message them.
    var connectedParents: Set<Parent.ID> = MockData.initiallyConnected

    func sendRequest(to parent: Parent) {
        requestedParents.insert(parent.id)
    }

    // MARK: Notifications and pop-ups

    var notifications: [AppNotification] = MockData.notifications
    /// A message over the app, such as "The host answered your question".
    var popup: AppPopup?
    /// The Gatherings page's stack of pages, so a notification can open an event straight away.
    var gatherPath = NavigationPath()
    /// Set when an event should open scrolled to its questions.
    var scrollEventToQuestions = false
    private let incomingQuestionTexts = ["Is there parking near the entrance?", "Can my 6 year old join?", "Do we need to bring anything?"]

    var unreadNotificationCount: Int { notifications.filter(\.isNew).count }

    func markRead(_ id: AppNotification.ID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }), notifications[index].isNew else { return }
        notifications[index].isNew = false
    }

    func addNotification(_ item: AppNotification) {
        notifications.insert(item, at: 0)
    }

    /// Accepts a connection request. Returns the chat to open.
    @discardableResult
    func acceptRequest(from parentID: Parent.ID) -> ChatThread.ID? {
        guard let parent = MockData.parents.first(where: { $0.id == parentID }) else { return nil }
        connectedParents.insert(parentID)
        notifications.removeAll { $0.action == .connectionRequest(parentID) }
        addNotification(AppNotification(symbol: "bubble.left", title: "You and \(parent.firstName) are connected",
                                        detail: "Say hello.", time: "Just now", isNew: false,
                                        action: .openChat(parentID)))
        return chats.startChat(with: parent)
    }

    func declineRequest(from parentID: Parent.ID) {
        notifications.removeAll { $0.action == .connectionRequest(parentID) }
    }

    /// Does what a notification or pop-up points to: open an event, its questions or a chat.
    func open(_ action: NotificationAction, openTab: (AppTab) -> Void) {
        switch action {
        case .none, .connectionRequest:
            break
        case .openEvent(let id):
            showEvent(id, questions: false, openTab: openTab)
        case .openEventQuestions(let id):
            showEvent(id, questions: true, openTab: openTab)
        case .openChat(let parentID):
            guard let parent = MockData.parents.first(where: { $0.id == parentID }) else { return }
            chats.pendingOpenID = chats.startChat(with: parent)
            openTab(.chats)
        }
    }

    private func showEvent(_ id: Event.ID, questions: Bool, openTab: (AppTab) -> Void) {
        guard let event = events.first(where: { $0.id == id }) else { return }
        scrollEventToQuestions = questions
        gatherPath = NavigationPath([event])
        openTab(.gather)
    }

    // MARK: Questions to a host

    /// A parent asks an event's host a question. It is kept on the event page, not in Chats.
    func askHost(of eventID: Event.ID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        let question = EventQuestion(asker: account?.name ?? "You", text: trimmed, date: .now, askedByMe: true)
        events[index].questions.append(question)
        simulateHostAnswer(eventID: eventID, questionID: question.id)
    }

    /// A family asks the signed-in host a question. Shows a pop-up and a notification.
    func receiveQuestion(eventID: Event.ID, from asker: String, text: String) {
        guard let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        events[index].questions.append(EventQuestion(asker: asker, text: text, date: .now))
        let title = events[index].title
        addNotification(AppNotification(symbol: "bubble.left.and.text.bubble.right",
                                        title: "New question on \(title)", detail: "\(asker): “\(text)”",
                                        time: "Just now", isNew: true, action: .openEventQuestions(eventID)))
        guard stage == .main else { return }
        popup = AppPopup(title: "A new question", headline: "\(asker) asked about “\(title)”",
                         detail: "\(events[index].unansweredCount) waiting for your answer",
                         message: "Families like quick replies. Answer when you have a moment.",
                         buttonTitle: "View question", action: .openEventQuestions(eventID))
    }

    /// The host's answer to a question I asked. Shows a pop-up and a notification.
    func receiveAnswer(eventID: Event.ID, questionID: EventQuestion.ID, answer: String) {
        guard let e = events.firstIndex(where: { $0.id == eventID }),
              let q = events[e].questions.firstIndex(where: { $0.id == questionID }) else { return }
        events[e].questions[q].answer = answer
        let title = events[e].title
        let host = events[e].host
        addNotification(AppNotification(symbol: "checkmark.bubble", title: "\(host) answered your question",
                                        detail: "About “\(title)”", time: "Just now", isNew: true,
                                        action: .openEventQuestions(eventID)))
        guard stage == .main else { return }
        popup = AppPopup(title: "You got an answer", headline: "\(host) replied",
                         detail: "About “\(title)”",
                         message: "See the answer on the event page.",
                         buttonTitle: "View answer", action: .openEventQuestions(eventID))
    }

    // PROTOTYPE ONLY: there is no server yet, so a host's answer and a family's question are made up here
    // a few seconds after the real action. Replace these with the real updates when the server exists.
    private func simulateHostAnswer(eventID: Event.ID, questionID: EventQuestion.ID) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            self?.receiveAnswer(eventID: eventID, questionID: questionID,
                                answer: "Thanks for asking! Yes, that works. Message us here if you need anything else.")
        }
    }

    private func simulateIncomingQuestion(for eventID: Event.ID) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(15))
            guard let self else { return }
            let asker = MockData.parents.randomElement()?.firstName ?? "A parent"
            self.receiveQuestion(eventID: eventID, from: asker, text: self.incomingQuestionTexts.randomElement() ?? "Is this open to everyone?")
        }
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
        // PROTOTYPE ONLY: a family asks the new host a question a little later.
        if event.isHostedByMe { simulateIncomingQuestion(for: event.id) }
    }

    // MARK: Bookmarks

    var savedEvents: [Event] {
        events.filter { isBookmarked($0) }
    }

    func isBookmarked(_ event: Event) -> Bool {
        bookmarkedKeys.contains(event.storageKey)
    }

    func clearSavedEvents() {
        bookmarkedKeys = []
        storedBookmarks = Self.encode([String]())
    }

    func toggleBookmark(_ event: Event) {
        if !bookmarkedKeys.insert(event.storageKey).inserted {
            bookmarkedKeys.remove(event.storageKey)
        }
        storedBookmarks = Self.encode(bookmarkedKeys.sorted())
    }

    // MARK: Several accounts on one device

    /// What one account keeps: its children, the saved events and the last registration details.
    private struct FamilySnapshot: Codable {
        var children: Data
        var selectedChildID: String
        var bookmarks: Data
        var registrant: Data
    }

    @ObservationIgnored @AppStorage("accountSnapshots") private var storedSnapshots = Data()

    private var snapshots: [String: FamilySnapshot] {
        get { Self.decode([String: FamilySnapshot].self, from: storedSnapshots) ?? [:] }
        set { storedSnapshots = Self.encode(newValue) }
    }

    private func saveSnapshot() {
        guard let email = account?.email else { return }
        snapshots[AccountStore.normalized(email)] = FamilySnapshot(
            children: Self.encode(children),
            selectedChildID: selectedChildID.uuidString,
            bookmarks: Self.encode(bookmarkedKeys.sorted()),
            registrant: savedRegistrant.map { Self.encode($0) } ?? Data())
    }

    /// Loads an account's own family details. Returns false when it has none yet.
    @discardableResult
    private func restoreSnapshot(for email: String) -> Bool {
        guard let snapshot = snapshots[AccountStore.normalized(email)],
              let saved = Self.decode([Child].self, from: snapshot.children), !saved.isEmpty else {
            clearFamily()
            return false
        }
        children = saved
        let savedID = UUID(uuidString: snapshot.selectedChildID)
        selectedChildID = saved.contains { $0.id == savedID } ? (savedID ?? saved[0].id) : saved[0].id
        bookmarkedKeys = Set(Self.decode([String].self, from: snapshot.bookmarks) ?? [])
        storedBookmarks = Self.encode(bookmarkedKeys.sorted())
        savedRegistrant = Self.decode(Registrant.self, from: snapshot.registrant)
        storedRegistrant = snapshot.registrant
        return true
    }

    /// Empties the family details, for a different account that starts from scratch.
    private func clearFamily() {
        children = [Child.empty]
        selectedChildID = children[0].id
        bookmarkedKeys = []
        savedRegistrant = nil
        storedBookmarks = Data()
        storedRegistrant = Data()
        registrations = [:]
    }

    /// Called after a successful login. An account that already has family details goes straight to Home.
    func finishLogin(returning: Bool) {
        refreshAccount()
        let hadFamily = account.map { restoreSnapshot(for: $0.email) } ?? false
        setReturningUser(returning)
        advance(to: hadFamily ? .main : .setup)
    }

    /// Other accounts saved on this device.
    var otherAccounts: [Account] {
        let current = AccountStore.normalized(account?.email ?? "")
        return AccountStore.savedAccounts.filter { AccountStore.normalized($0.email) != current }
    }

    /// Switches to another saved account without signing in again.
    func switchAccount(to email: String) {
        saveSnapshot()
        AccountStore.switchTo(email)
        finishLogin(returning: true)
    }

    /// Signs out and goes back to the login page. The family's details are kept with the account.
    func signOut() {
        saveSnapshot()
        clearFamily()
        AccountStore.signOut()
        account = nil
        storedStage = nil
        stage = .login
    }

    /// Removes the account and everything saved on this device, then starts again from onboarding.
    func deleteAccount() {
        if let email = account?.email {
            snapshots.removeValue(forKey: AccountStore.normalized(email))
            AccountStore.delete(email)
        }
        account = nil
        storedChildren = Data()
        storedRegistrant = Data()
        storedBookmarks = Data()
        savedRegistrant = nil
        bookmarkedKeys = []
        registrations = [:]
        chats.reload(withSamples: false)
        resetOnboarding()
    }

    func resetOnboarding() {
        storedStage = nil
        children = [Child.empty]
        selectedChildID = children[0].id
        stage = .onboarding
    }
}
