// Coordinates shared family data, saved weekly plans, event bookings, account switching, and local prototype interactions.
// Imports SwiftUI views, state and environment wrappers, Observation support, and UI drawing types used in this file.
import SwiftUI

// Lists the four root-screen stages used by RootView to decide which flow is visible.
enum LaunchStage { case onboarding, login, setup, main }

// Isolates this shared UI-facing type to the main actor so its state is accessed through the same actor context.
@MainActor
// Generates observation tracking so views update when the properties they actually read change; this does not itself persist data.
@Observable
// Keeps one shared observable family state so Home, First Week, Progress, Gather, Community, and Chats use consistent data.
final class AppState {
    // Starts a fresh app session at onboarding until init restores a completed launch stage.
    var stage: LaunchStage = .onboarding
    /// The family's home area. "Near you" in Gather and the Community list use it.
    var homeLocation: Place = .potheri {
        // Encodes the new home area whenever it changes so Gather and Community can restore it after relaunch.
        didSet { storedHomeLocation = Self.encode(homeLocation) }
    }
    /// When on, the home area follows the phone's approximate location. When off, the family picks a city.
    var usesLiveLocation: Bool {
        // Registers an observable read manually before returning the UserDefaults-backed live-location preference.
        get { access(keyPath: \.usesLiveLocation); return storedUsesLiveLocation }
        // Wraps the saved preference mutation in Observation tracking so views reading usesLiveLocation update.
        set { withMutation(keyPath: \.usesLiveLocation) { storedUsesLiveLocation = newValue } }
    }
    // Owns the shared location service responsible for permission, coordinates, and approximate place callbacks.
    let locationService = LocationService()
    // Owns one cached event-location resolver so Gather feed distances and detail maps agree.
    let eventLocations = EventLocationStore()

    // Exposes the persisted Community distance preference as an observable integer measured in kilometres.
    var communityRadiusKm: Int {
        // Registers an observable read before retrieving the stored Community radius.
        get { access(keyPath: \.communityRadiusKm); return storedCommunityRadiusKm }
        // Notifies Observation while writing the new Community radius to local storage.
        set { withMutation(keyPath: \.communityRadiusKm) { storedCommunityRadiusKm = newValue } }
    }

    /// All conversations.
    let chats = ChatStore()
    let preferences = AppPreferences()
    private let gatheringReminders = GatheringReminders()
    @ObservationIgnored private var restoringEvents = true
    @ObservationIgnored private var eventArchiveAccount = "local-family"

    /// The parent who is signed in.
    var account: Account? = AccountStore.current

    /// Every child in the family. The first one is created during setup.
    var children: [Child] = [Child.empty] {
        // Saves the child array and refreshes exam reminders whenever a profile is added or changed.
        didSet { saveChildren() }
    }
    // Identifies the active child without creating a separate AppState for each learner.
    var selectedChildID = UUID() {
        // Saves the selected UUID as a string so the same child can be selected after relaunch.
        didSet { storedSelectedChildID = selectedChildID.uuidString }
    }

    /// The child whose plan is on screen. Reading and writing go to the matching entry in `children`.
    var child: Child {
        // Returns the child matching selectedChildID, with the first profile as the fallback.
        get { children.first { $0.id == selectedChildID } ?? children[0] }
        // Writes a bound child edit back into the existing family array rather than keeping an unrelated copy.
        set {
            // Finds the array position of the child represented by the incoming value.
            if let index = children.firstIndex(where: { $0.id == newValue.id }) {
                // Replaces that child profile, triggering the children persistence observer.
                children[index] = newValue
            }
        }
    }
    // Maps child UUID strings to the WeeklyPlan shared by FirstWeekView and ProgressDashboardView.
    var weeklyPlans: [String: WeeklyPlan] = [:] {
        // JSON-encodes changed plans into AppStorage so learning completion survives app restarts.
        didSet { storedWeeklyPlans = Self.encode(weeklyPlans) }
    }

    /// An added day becomes part of this child's routine; its activities are planned separately.
    @discardableResult
    func addLearningDay(_ day: String, for childID: Child.ID) -> Date? {
        guard let index = children.firstIndex(where: { $0.id == childID }) else { return nil }
        var plan = weeklyPlans[childID.uuidString] ?? .firstWeek(for: children[index])
        guard plan.includeLearningDay(day) else { return nil }
        children[index].learningDays.insert(day)
        saveWeek(plan, for: childID)
        return plan.date(for: day)
    }

    // Saves shared planner edits and asynchronously resynchronises that child's learning reminders.
    func saveWeek(_ plan: WeeklyPlan, for childID: Child.ID) {
        // Stores First Week or Progress edits under the same child key that Progress later reads to rebuild its chart and totals.
        weeklyPlans[childID.uuidString] = plan
        // Finds the corresponding child profile before scheduling that plan notifications.
        if let child = children.first(where: { $0.id == childID }) {
            // Starts asynchronous notification synchronisation after saving; await can suspend without blocking the main thread while waiting.
            Task { await WeekReminders.sync(plan: plan, child: child) }
        }
    }

    /// Keeps Home, First Week, and Progress on the current calendar week without discarding the previous saved week.
    func prepareHomeWeek(for childID: Child.ID, today: Date = .now) {
        guard let child = children.first(where: { $0.id == childID }) else { return }
        let key = childID.uuidString
        let previous = weeklyPlans[key]
        let current = WeeklyPlan.homeWeek(for: child, savedPlan: previous, now: today)
        guard current != previous else { return }
        if let previous {
            let archiveKey = "history|\(key)|\(Int(previous.weekStart.timeIntervalSince1970))"
            weeklyPlans[archiveKey] = previous
        }
        saveWeek(current, for: childID)
    }

    /// Current occurrences take precedence over any older archived copies.
    func learningPlans(for childID: Child.ID) -> [WeeklyPlan] {
        let key = childID.uuidString
        let history = weeklyPlans.filter { $0.key.hasPrefix("history|\(key)|") }
            .map(\.value).sorted { $0.weekStart > $1.weekStart }
        return weeklyPlans[key].map { [$0] + history } ?? history
    }

    /// Completion from a historical chart updates that saved week without replacing the current plan.
    @discardableResult
    func toggleLearningActivity(_ id: WeekActivity.ID, for childID: Child.ID) -> WeeklyPlan? {
        let childKey = childID.uuidString
        let keys = [childKey] + weeklyPlans.keys.filter { $0.hasPrefix("history|\(childKey)|") }.sorted()
        for key in keys {
            guard var plan = weeklyPlans[key], let index = plan.activities.firstIndex(where: { $0.id == id }) else { continue }
            plan.activities[index].setCompleted(!plan.activities[index].isDone)
            if key == childKey { saveWeek(plan, for: childID) }
            else { weeklyPlans[key] = plan }
            return plan
        }
        return nil
    }

    // Holds the frozen daily completion summary shown by MainTabView as a wrap-up overlay.
    var dailyWrapUp: DayLearningSummary?

    // Starts the separate simple Home task list from prototype data; Progress uses WeeklyPlan activities instead.
    var tasks: [TaskItem] = MockData.tasks
    // Loads prototype Gather events in start-date order rather than fetching them from a server.
    var events: [Event] = MockData.events.sorted { $0.start < $1.start } {
        didSet {
            guard !restoringEvents else { return }
            LocalArchive.save(events, category: "events", account: eventArchiveAccount)
            syncGatheringReminders()
        }
    }


    private func restoreEvents() {
        restoringEvents = true

        eventArchiveAccount = account.map {
            AccountStore.normalized($0.email)
        } ?? "local-family"

        let mockEvents = MockData.events.sorted { $0.start < $1.start }

        let savedEvents = LocalArchive.load(
            [Event].self,
            category: "events",
            account: eventArchiveAccount
        ) ?? mockEvents

        events = savedEvents.map { savedEvent in
            var updatedEvent = savedEvent

            if savedEvent.title == "Pond Life Walk",
               let mockEvent = mockEvents.first(where: {
                   $0.storageKey == savedEvent.storageKey
               }) {
                updatedEvent.coverName = mockEvent.coverName
            }

            return updatedEvent
        }

        restoringEvents = false

        // Persist the updated cover without resetting other event data.
        LocalArchive.save(
            events,
            category: "events",
            account: eventArchiveAccount
        )

        notifications = MockData.notifications.map { notification in
            var item = notification

            switch item.action {
            case .openEvent(let id), .openEventQuestions(let id):
                if let old = MockData.events.first(where: { $0.id == id }),
                   let restored = events.first(where: {
                       $0.storageKey == old.storageKey
                   }) {
                    if case .openEventQuestions = item.action {
                        item.action = .openEventQuestions(restored.id)
                    } else {
                        item.action = .openEvent(restored.id)
                    }
                }
            default:
                break
            }

            return item
        }
    }


    func syncGatheringReminders() {
        gatheringReminders.sync(events: events.filter { $0.isRegistered || bookmarkedKeys.contains($0.storageKey) },
                                enabled: preferences.notifyGatherings && stage == .main)
    }

    /// Details from the last registration, used to pre-fill the next one.
    var savedRegistrant: Registrant?
    // Maps current event UUIDs to the active account local registrations for confirmation and ticket screens.
    var registrations: [Event.ID: Registration] = [:]
    // Keeps unique stable event keys for liked events because catalogue UUIDs can change across launches.
    private var bookmarkedKeys: Set<String> = [] {
        didSet { syncGatheringReminders() }
    }

    /// false until the family has seen the first-time Home and moved on to another tab.
    var hasSeenFirstHome = false

    /// Login/relaunch determines this flag; simply switching tabs during a first session does not replace the first-time Home.
    var isReturningSession = false

    // MARK: Persistence
    // `@AppStorage` replaces direct `UserDefaults.standard` calls. `@Observable` classes need
    // `@ObservationIgnored` on property wrappers, so observed properties above either mirror
    // into these (`didSet`) or wrap them with `access`/`withMutation` (the scalar settings).
    @ObservationIgnored @AppStorage("stage") private var storedStage: String?
    // Persists "hasSeenFirstHome" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("hasSeenFirstHome") private var storedHasSeenFirstHome: Bool?
    // Persists "usesLiveLocation" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("usesLiveLocation") private var storedUsesLiveLocation = false
    // Persists "communityRadiusKm" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("communityRadiusKm") private var storedCommunityRadiusKm = 5
    // Persists "selectedChildID" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("selectedChildID") private var storedSelectedChildID = ""
    // Persists "weeklyPlans" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("weeklyPlans") private var storedWeeklyPlans = Data()
    // Persists "children" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("children") private var storedChildren = Data()
    // Persists "homeLocation" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("homeLocation") private var storedHomeLocation = Data()
    // Persists "savedRegistrant" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("savedRegistrant") private var storedRegistrant = Data()
    // Persists "bookmarkedEvents" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("bookmarkedEvents") private var storedBookmarks = Data()
    // Persists "eventBookingsByAccount" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("eventBookingsByAccount") private var storedBookings = Data()

    // Encodes any Encodable model to Data for the UserDefaults-backed storage fields.
    private static func encode<T: Encodable>(_ value: T) -> Data {
        // Uses JSONEncoder and returns empty Data if encoding fails instead of throwing from a property observer.
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    // Decodes a requested Decodable type from its saved JSON Data without throwing to the caller.
    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        // Treats empty or invalid saved data as nil so each caller can choose a suitable default.
        data.isEmpty ? nil : try? JSONDecoder().decode(type, from: data)
    }

    // Restores saved launch, family, location, plan, bookmark, and booking state when the shared store is created.
    init() {
        // Checks whether a previous session completed setup and reached the main app.
        if storedStage == "main" {
            if account == nil, let recovered = AccountStore.recoverLegacySession() {
                account = recovered
                let key = AccountStore.normalized(recovered.email)
                // Keep content created while the older build had lost its account selection.
                if LocalArchive.load([Event].self, category: "events", account: key) == nil,
                   let legacy = LocalArchive.load([Event].self, category: "events", account: "local-family") {
                    LocalArchive.save(legacy, category: "events", account: key)
                }
                if LocalArchive.load([ChatThread].self, category: "chats", account: key) == nil,
                   let legacy = LocalArchive.load([ChatThread].self, category: "chats", account: "local-family") {
                    LocalArchive.save(legacy, category: "chats", account: key)
                }
                if bookingsByAccount[key] == nil, let legacy = bookingsByAccount["local-family"] {
                    bookingsByAccount[key] = legacy
                }
                chats.reload(withSamples: false, account: key)
            }
            // Restores the main launch stage instead of showing onboarding again.
            stage = .main
            isReturningSession = true
        }
        // Saved children only count once setup was finished.
        if stage == .main,
           // Decodes a nonempty saved child list before replacing the initial blank family.
           let saved = Self.decode([Child].self, from: storedChildren), !saved.isEmpty {
            // Loads the restored child array; its didSet keeps the encoded family storage in sync.
            children = saved
            // Parses the persisted selected-child string back into a UUID.
            let savedID = UUID(uuidString: storedSelectedChildID)
            // Restores the selected child only if it still exists, otherwise falling back to the first restored child.
            selectedChildID = saved.contains { $0.id == savedID } ? (savedID ?? saved[0].id) : saved[0].id
        } else {
            // Selects the first child so the computed child property points to an existing profile.
            selectedChildID = children[0].id
        }
        // Attempts to reconstruct the previously selected home area from encoded storage.
        if let saved = Self.decode(Place.self, from: storedHomeLocation) {
            // Publishes the restored home area to Gather and Community consumers.
            homeLocation = saved
        }
        // Families who were already inside the app before this screen existed skip it.
        hasSeenFirstHome = storedHasSeenFirstHome ?? (stage == .main)
        // Restores plans by child ID so Progress can recall the same activities that First Week saved in an earlier session.
        weeklyPlans = Self.decode([String: WeeklyPlan].self, from: storedWeeklyPlans) ?? [:]
        // Restores the last registration form details to prefill the next event registration.
        savedRegistrant = Self.decode(Registrant.self, from: storedRegistrant)
        // Restores stable bookmark keys into a set for fast membership checks and duplicate prevention.
        bookmarkedKeys = Set(Self.decode([String].self, from: storedBookmarks) ?? [])

        restoreEvents()
        restoreBookings()
        preferences.onGatheringChange = { [weak self] in self?.syncGatheringReminders() }
        chats.onIncomingMessage = { [weak self] thread in
            guard let self, self.preferences.notifyChats else { return }
            self.addNotification(AppNotification(symbol: "bubble.left", title: thread.title,
                detail: thread.preview, time: "Just now", isNew: true))
        }
    }

    // Changes the root launch stage and remembers when onboarding and setup have reached the main app.
    func advance(to newStage: LaunchStage) {
        // Changes the observable launch stage that RootView switches over to choose its content.
        stage = newStage
        // Persists the stage only when the family has entered the main app.
        if newStage == .main {
            // Records completed setup so the next app launch can restore the main stage.
            storedStage = "main"
            syncGatheringReminders()
        }
    }

    /// Called after login. A new account sees the first-time Home, a returning one goes straight to the regular Home.
    func setReturningUser(_ returning: Bool) {
        isReturningSession = returning
        // Updates the in-memory returning-family flag used by first-home bookkeeping.
        hasSeenFirstHome = returning
        // Saves the returning-family flag for the next launch.
        storedHasSeenFirstHome = returning
        // A new account starts with no conversations. A returning one gets the sample chats.
        chats.reload(withSamples: returning)
    }

    /// Called when the family leaves Home for the first time.
    func markFirstHomeSeen() {
        // Exits when the first-home flag is already set, avoiding a redundant write.
        guard !hasSeenFirstHome else { return }
        // Marks the family as having moved beyond its first Home visit.
        hasSeenFirstHome = true
        // Persists the first-home flag even if the app closes before another screen action.
        storedHasSeenFirstHome = true
    }

    // MARK: Parent account

    // Reloads the active account from the local AccountStore into observable app state.
    func refreshAccount() {
        // Refreshes the observable parent account from the locally selected AccountStore record.
        account = AccountStore.current
    }

    // Trims and saves the active parent name and mobile number, then updates observable account data.
    @discardableResult
    func updateAccount(name: String, mobile: String) -> Bool {
        // Stops if there is no signed-in parent account to edit and otherwise creates a mutable copy.
        guard var current = account ?? AccountStore.current else { return false }
        // Removes surrounding whitespace before storing the parent name.
        current.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Removes surrounding whitespace before storing the parent contact number.
        current.mobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        // Writes the updated parent account to the local account store.
        AccountStore.update(current)
        // Replaces the observed account so dependent profile and community views refresh.
        account = current
        return true
    }

    /// Saves what other parents see on the community profile.
    func updateCommunityProfile(bio: String? = nil, lookingFor: [String]? = nil) {
        // Stops if there is no signed-in parent account to edit and otherwise creates a mutable copy.
        guard var current = account else { return }
        // Changes the biography only when a caller supplies a new value.
        if let bio { current.bio = bio }
        // Changes the connection-purpose list only when a caller supplies it.
        if let lookingFor { current.lookingFor = lookingFor }
        // Writes the updated parent account to the local account store.
        AccountStore.update(current)
        // Replaces the observed account so dependent profile and community views refresh.
        account = current
    }

    // MARK: Location

    // Saves the live-location preference and starts a location refresh only when it is enabled.
    func setLiveLocation(_ on: Bool) {
        // Writes the requested live-location preference through its observable persisted accessor.
        usesLiveLocation = on
        // Skips location access when the user has turned the preference off.
        guard on else { return }
        // Requests an updated approximate area after enabling live location.
        refreshLiveLocation()
    }

    /// Looks up the approximate area again. Does nothing unless the live location switch is on.
    func refreshLiveLocation() {
        // Avoids requesting location when the saved preference is disabled.
        guard usesLiveLocation else { return }
        // Installs a weakly captured callback that updates the shared home area without retaining AppState through the service.
        locationService.onPlace = { [weak self] place in self?.homeLocation = place }
        // Starts the location-service permission and coordinate request flow.
        locationService.request()
    }

    // MARK: Profile completeness

    /// What is still missing before someone can host: the parent's name and mobile, and each child's name, level and birth date.
    var missingProfileItems: [String] {
        // Accumulates human-readable missing profile fields for the hosting prerequisite screen.
        var missing: [String] = []
        // Adds the parent-name requirement when the current name is absent or blank.
        if (account?.name ?? "").trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your name") }
        // Adds the parent-mobile requirement when the current phone number is absent or blank.
        if (account?.mobile ?? "").trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your mobile number") }
        // Checks every learner because hosting prerequisites include the whole family profile.
        for child in children {
            // Chooses a readable child name for missing-field messages, falling back to your child.
            let label = child.name.trimmingCharacters(in: .whitespaces).isEmpty ? "your child" : child.name
            // Adds a missing-name message for a blank child profile.
            if child.name.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your child’s name") }
            // Adds a level-selection message for a child with no curriculum level.
            if child.level.isEmpty { missing.append("NIOS level for \(label)") }
            // Adds a birth-date message when that child has no saved date of birth.
            if child.birthDate == nil { missing.append("Date of birth for \(label)") }
        }
        // Returns all missing requirements so the UI can explain what to complete.
        return missing
    }

    // MARK: Children

    // Selects an existing child by ID so all tabs derive their data from that family member.
    func selectChild(_ id: Child.ID) {
        // Rejects a selection ID that does not belong to the current family.
        guard children.contains(where: { $0.id == id }) else { return }
        // Changes the shared selected child, letting every tab derive the correct learner data.
        selectedChildID = id
    }

    /// Adds a child and switches to them.
    func addChild(_ newChild: Child) {
        // Adds the new profile to the family and triggers automatic child persistence.
        children.append(newChild)
        // Switches all child-dependent screens to the newly created learner.
        selectedChildID = newChild.id
    }

    /// Removes a child and everything saved for them. The last remaining child can't be removed.
    func removeChild(_ id: Child.ID) {
        guard children.count > 1, children.contains(where: { $0.id == id }) else { return }
        let key = id.uuidString
        weeklyPlans = weeklyPlans.filter { k, _ in k != key && !k.hasPrefix("history|\(key)|") }
        children.removeAll { $0.id == id }
        if selectedChildID == id, let first = children.first { selectedChildID = first.id }
    }

    /// Switches a child's NIOS level. Subjects depend on the level, so they are cleared and chosen again.
    @discardableResult
    // Changes a child level and clears level-dependent subject choices before saving the profile.
    func changeLevel(of id: Child.ID, to level: String) -> Child? {
        // Requires an existing child and a genuinely different level before making any change.
        guard var changed = children.first(where: { $0.id == id }), changed.level != level else { return nil }
        // Stores the newly chosen level on a mutable child copy.
        changed.level = level
        // Remembers that the parent chose this level so later date-of-birth edits do not automatically override it.
        changed.levelChosenManually = true
        // Clears subjects selected under the previous level because the new level may have different options and limits.
        changed.selectedSubjects = []
        // Replaces the saved child through the shared update method.
        updateChild(changed)
        // Returns the changed child for callers that need to continue the setup flow with the updated profile.
        return changed
    }

    // Replaces the matching child in the observable array so profile persistence and dependent screens update.
    func updateChild(_ updated: Child) {
        // Finds the child being edited and safely exits if that ID is no longer present.
        guard let index = children.firstIndex(where: { $0.id == updated.id }) else { return }
        let previous = children[index]
        // Replaces the matching array entry, triggering persistence and observable updates.
        children[index] = updated
        // Learning days, hours per day and subjects shape the saved week, so Home, the planner and Progress must follow.
        if previous.learningDays != updated.learningDays
            || previous.hoursPerDay != updated.hoursPerDay
            || previous.selectedSubjects != updated.selectedSubjects {
            syncWeek(with: updated)
        }
    }

    /// Re-applies a child's current rhythm and subjects to their saved week.
    /// Without a saved week there is nothing to update: screens build the week from the profile directly.
    private func syncWeek(with child: Child) {
        let key = child.id.uuidString
        guard weeklyPlans[key] != nil else { return }
        // A saved week from an earlier calendar week is archived and rebuilt from the updated profile.
        prepareHomeWeek(for: child.id)
        guard let saved = weeklyPlans[key] else { return }
        let updated = saved.reconciled(with: child)
        if updated != saved { saveWeek(updated, for: child.id) }
    }

    // Encodes all child profiles locally and refreshes their exam-deadline notification schedule.
    private func saveChildren() {
        // Encodes the whole family child list into its AppStorage-backed Data field.
        storedChildren = Self.encode(children)
        // Re-evaluates local exam notifications after a child profile changes.
        syncExamReminders()
    }

    /// Re-plans the "exam form closes soon" notifications for every child who isn't registered.
    func syncExamReminders() {
        // Avoids presenting or scheduling this main-app-only behaviour while onboarding, login, or setup is active.
        guard stage == .main else { return }
        // Captures the current children before starting asynchronous reminder synchronisation.
        let snapshot = children
        // Starts the asynchronous exam notification update without making the calling profile edit asynchronous.
        Task { await ExamReminders.sync(children: snapshot) }
    }

    // Finds and reverses the completion flag of a simple Home TaskItem, independently of weekly learning activities.
    func toggle(_ task: TaskItem) {
        // Finds the simple Home task by equality and exits if it is absent.
        guard let i = tasks.firstIndex(of: task) else { return }
        // Reverses that Home task completion flag; this does not edit a dated WeekActivity.
        tasks[i].isDone.toggle()
    }

    // MARK: Events

    // Creates a local event booking, updates its attending flag, and persists registrant and booking data; no payment gateway is called.
    func register(_ event: Event, as registrant: Registrant, accompanying: Bool = true, places: Int = 1) {
        // Requires the event to exist in the current catalogue before creating a booking.
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        // Prevents a second local registration for an event that already has one.
        guard registrations[event.id] == nil else { return }
        // Marks the current family as registered and adjusts the event family count only if the flag changes.
        events[index].updateRegistration(true)
        // Creates the stable booking record used by confirmation and ticket views.
        registrations[event.id] = Registration(eventID: event.id, registrant: registrant,
                                               // Stores the local registration creation time.
                                               registeredAt: .now,
                                               // Calculates the recorded price from the event fee and place count; no real payment transaction occurs here.
                                               amountPaid: event.price.map { $0 * places },
                                               // Stores whether an adult stays and how many child places this booking covers.
                                               accompanying: accompanying, places: places)

        // Keeps the form details in observed memory for the next registration.
        savedRegistrant = registrant
        // Encodes the last form details so prefill also works after relaunch.
        storedRegistrant = Self.encode(registrant)
        // Persists the account booking map after this registration change.
        saveBookings()
    }

    /// Free registrations can be cancelled at any time. Paid ones cannot, and are not refunded.
    func canCancel(_ event: Event) -> Bool {
        // Rejects cancellation checks for an event the family has not registered for.
        guard event.isRegistered else { return false }
        // Uses the booking paid flag, or event-price fallback, to permit only free cancellations.
        return !(registrations[event.id]?.isPaid ?? !event.isFree)
    }

    // Allows callers to ignore this method return value when they only need its state-changing side effect.
    @discardableResult
    // Removes an eligible free booking, updates the event count, and saves the changed booking collection.
    func cancelRegistration(for event: Event) -> Bool {
        // Checks the cancellation policy before mutating a registration.
        guard canCancel(event),
              // Requires both an existing event and an active registration, otherwise reports cancellation failure.
              let index = events.firstIndex(where: { $0.id == event.id }), events[index].isRegistered else { return false }
        // Clears the current-family attending flag and keeps the displayed count consistent.
        events[index].updateRegistration(false)
        // Removes the booking from the active registration dictionary by assigning nil.
        registrations[event.id] = nil
        // Persists the account booking map after this registration change.
        saveBookings()
        // Reports that the requested state change or restoration completed successfully.
        return true
    }

    // Derives the account namespace used to separate locally stored event bookings.
    private var bookingAccountKey: String {
        // Uses the normalised parent email as the booking key, with a local-family fallback when no account is active.
        account.map { AccountStore.normalized($0.email) } ?? "local-family"
    }

    // Exposes the encoded account-to-event booking map through a typed computed property.
    private var bookingsByAccount: [String: [String: Registration]] {
        // Decodes the nested booking dictionary or returns an empty map when storage is missing or invalid.
        get { Self.decode([String: [String: Registration]].self, from: storedBookings) ?? [:] }
        // Re-encodes the nested booking dictionary whenever a caller changes it.
        set { storedBookings = Self.encode(newValue) }
    }

    // Stores current event bookings under stable event keys and the active account while retaining out-of-catalogue bookings.
    private func saveBookings() {
        // Retain bookings for events outside the current catalog as well.
        var saved = bookingsByAccount[bookingAccountKey] ?? [:]
        // Visits each currently known event while preserving saved entries for events outside this catalogue.
        for event in events {
            // Stores or removes the event booking using its stable title-and-start key rather than its regenerated UUID.
            saved[event.storageKey] = registrations[event.id]
        }
        // Writes the updated event map back under the active account key.
        bookingsByAccount[bookingAccountKey] = saved
    }

    // Loads the active account bookings, remaps regenerated event UUIDs, and restores event attendance flags.

    private func restoreBookings() {
        registrations = [:]

        let saved = bookingsByAccount[bookingAccountKey] ?? [:]

        let demoEventTitles: Set<String> = [
            "Mini Science Fair",
            "Creative Art & Craft Day",
            "Nature Discovery Walk"
        ]

        let sampleRegistrant = Registrant(
            parentName: "Asha Patel",
            email: "asha.patel@example.com",
            mobile: "+91 98765 43210",
            childName: "Maya",
            childAge: "10",
            notes: ""
        )
        for index in events.indices {
            let event = events[index]
            if var booking = saved[event.storageKey] {
                booking = booking.forEvent(event.id)
                registrations[event.id] = booking
                events[index].updateRegistration(true)
            } else if demoEventTitles.contains(event.title) {
                let booking = Registration(
                    eventID: event.id,
                    registrant: sampleRegistrant,
                    registeredAt: event.start,
                    amountPaid: event.price
                )
                registrations[event.id] = booking
                events[index].updateRegistration(true)
            } else {
                events[index].updateRegistration(false)
            }
        }
        saveBookings()
    }

    /// Pages that cover the tab bar (an open chat) count themselves in here, so the bottom bar used on
    /// iPad can hide too. The system tab bar on iPhone hides itself.
    var tabBarHideCount = 0
    // Hides the native tab bar while one or more covering pages have requested it.
    var hidesTabBar: Bool { tabBarHideCount > 0 }

    /// Parents I sent a connection request to.
    var requestedParents: Set<Parent.ID> = []
    /// Parents I am connected with, so I can message them.
    var connectedParents: Set<Parent.ID> = MockData.initiallyConnected

    // Records a pending community connection locally by parent ID; this does not send a server request.
    func sendRequest(to parent: Parent) {
        // Adds the parent ID to the local pending-connection set without sending a network request.
        requestedParents.insert(parent.id)
    }
    
    func withdrawRequest(to parent: Parent) {
        requestedParents.remove(parent.id)
    }

    // MARK: Notifications and pop-ups

    // Initialises the notification feed from prototype sample data.
    var notifications: [AppNotification] = MockData.notifications
    /// A message over the app, such as "The host answered your question".
    var popup: AppPopup?
    /// The Gatherings page's stack of pages, so a notification can open an event straight away.
    var gatherPath = NavigationPath()
    /// Set when an event should open scrolled to its questions.
    var scrollEventToQuestions = false
    // Provides the small canned-question pool used only by the delayed prototype host interaction.
    private let incomingQuestionTexts = ["Is there parking near the entrance?", "Can my 6 year old join?", "Do we need to bring anything?"]

    // Counts notification rows still marked new for the unread indicator.
    var visibleNotifications: [AppNotification] {
        notifications.filter { item in
            switch item.action {
            case .connectionRequest: return preferences.notifyCommunity && preferences.showProfile
            case .openChat: return preferences.notifyChats
            case .openEvent, .openEventQuestions: return preferences.notifyGatherings
            case .none: return item.symbol == "bubble.left" ? preferences.notifyChats : true
            }
        }
    }
    var unreadNotificationCount: Int { visibleNotifications.filter(\.isNew).count }

    // Clears the unread flag of the matching in-app notification if it is currently new.
    func markRead(_ id: AppNotification.ID) {
        // Finds an unread notification and exits when it is missing or already read.
        guard let index = notifications.firstIndex(where: { $0.id == id }), notifications[index].isNew else { return }
        // Clears that notification unread flag so counts and row appearance update.
        notifications[index].isNew = false
    }

    // Prepends a notification so the newest local update appears first.
    func addNotification(_ item: AppNotification) {
        // Inserts the newest notification at the beginning of the feed.
        notifications.insert(item, at: 0)
    }

    /// Accepts a connection request. Returns the chat to open.
    @discardableResult
    // Accepts a local connection request, updates notifications, and returns a chat ID for navigation.
    func acceptRequest(from parentID: Parent.ID) -> ChatThread.ID? {
        // Looks up the sample community parent before accepting a connection.
        guard let parent = MockData.parents.first(where: { $0.id == parentID }) else { return nil }
        // Adds the parent to the active local connection set so messaging becomes available.
        connectedParents.insert(parentID)
        // Removes the matching request notification after it has been accepted or declined.
        notifications.removeAll { $0.action == .connectionRequest(parentID) }
        // Creates a local notification confirming the new connection.
        addNotification(AppNotification(symbol: "bubble.left", title: "You and \(parent.firstName) are connected",
                                        // Supplies the greeting prompt and marks this confirmation notification already read.
                                        detail: "Say hello.", time: "Just now", isNew: false,
                                        // Associates the confirmation with the connected parent chat destination.
                                        action: .openChat(parentID)))
        // Finds or creates the parent conversation and returns its ID to the caller.
        return chats.startChat(with: parent)
    }

    // Removes the matching connection-request notification from the local list.
    func declineRequest(from parentID: Parent.ID) {
        // Removes the matching request notification after it has been accepted or declined.
        notifications.removeAll { $0.action == .connectionRequest(parentID) }
    }

    /// Does what a notification or pop-up points to: open an event, its questions or a chat.
    func open(_ action: NotificationAction, openTab: (AppTab) -> Void) {
        // Chooses navigation behaviour from the data-only notification action enum.
        switch action {
        // Handles actions that have no direct destination or use separate Accept and Decline controls.
        case .none, .connectionRequest:
            // Leaves navigation unchanged for this action branch.
            break
        // Extracts the event ID from a normal event-opening action.
        case .openEvent(let id):
            // Opens the event detail without requesting a jump to its questions.
            showEvent(id, questions: false, openTab: openTab)
        // Extracts the event ID from a question-specific notification action.
        case .openEventQuestions(let id):
            // Opens the event detail and requests its question section.
            showEvent(id, questions: true, openTab: openTab)
        // Extracts the community parent ID from a chat-opening notification.
        case .openChat(let parentID):
            // Requires a matching sample parent before preparing a conversation destination.
            guard let parent = MockData.parents.first(where: { $0.id == parentID }) else { return }
            // Sets the pending conversation ID that the Chats screen will open.
            chats.pendingOpenID = chats.startChat(with: parent)
            // Requests selection of the Chats tab through the caller-supplied navigation closure.
            openTab(.chats)
        }
    }

    // Places an event on the shared Gather navigation path and optionally requests scrolling to its questions.
    private func showEvent(_ id: Event.ID, questions: Bool, openTab: (AppTab) -> Void) {
        // Finds the event before constructing a Gather navigation path.
        guard let event = events.first(where: { $0.id == id }) else { return }
        // Records whether EventDetailView should scroll to its question section after opening.
        scrollEventToQuestions = questions
        // Replaces the shared Gather stack with the target event so typed navigation opens its details.
        gatherPath = NavigationPath([event])
        // Requests selection of the Gather tab so the prepared event destination is visible.
        openTab(.gather)
    }

    // MARK: Questions to a host

    /// A parent asks an event's host a question. It is kept on the event page, not in Chats.
    func askHost(of eventID: Event.ID, text: String) {
        // Trims spaces and line breaks from the submitted host question.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Rejects blank text or a missing event before creating a local question.
        guard !trimmed.isEmpty, let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        // Creates an unanswered question attributed to the signed-in parent and marks it as asked by this account.
        let question = EventQuestion(asker: account?.name ?? "You", text: trimmed, date: .now, askedByMe: true)
        // Appends the question to the matching event so its question section updates.
        events[index].questions.append(question)
        // Schedules a canned reply for demonstration because the prototype has no host-messaging backend.
        simulateHostAnswer(eventID: eventID, questionID: question.id)
    }

    /// A family asks the signed-in host a question. Shows a pop-up and a notification.
    func receiveQuestion(eventID: Event.ID, from asker: String, text: String) {
        // Requires the target event to exist before adding a simulated incoming question.
        guard let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        // Appends an incoming family question to the hosted event local data.
        events[index].questions.append(EventQuestion(asker: asker, text: text, date: .now))
        // Reads the event title used in the related notification and popup.
        let title = events[index].title
        // Creates a notification with a question-and-answer icon for the new host question.
        addNotification(AppNotification(symbol: "bubble.left.and.text.bubble.right",
                                        // Includes the event title, asking parent, and question preview in the notification.
                                        title: "New question on \(title)", detail: "\(asker): “\(text)”",
                                        // Marks the notification new and routes a tap to this event question section.
                                        time: "Just now", isNew: true, action: .openEventQuestions(eventID)))
        // Avoids presenting or scheduling this main-app-only behaviour while onboarding, login, or setup is active.
        guard stage == .main, preferences.notifyGatherings else { return }
        // Builds the popup heading from the asking parent and hosted event title.
        popup = AppPopup(title: "A new question", headline: "\(asker) asked about “\(title)”",
                         // Displays the updated number of unanswered questions awaiting the host.
                         detail: "\(events[index].unansweredCount) waiting for your answer",
                         // Supplies the supporting message encouraging the host to answer when available.
                         message: "Families like quick replies. Answer when you have a moment.",
                         // Labels the popup action and routes it to the event questions.
                         buttonTitle: "View question", action: .openEventQuestions(eventID))
    }

    /// The host's answer to a question I asked. Shows a pop-up and a notification.
    func receiveAnswer(eventID: Event.ID, questionID: EventQuestion.ID, answer: String) {
        // Finds the event index before accessing its questions.
        guard let e = events.firstIndex(where: { $0.id == eventID }),
              // Finds the question index and exits safely if either the event or question is missing.
              let q = events[e].questions.firstIndex(where: { $0.id == questionID }) else { return }
        // Stores the received answer on the exact event question.
        events[e].questions[q].answer = answer
        // Reads the event title used in the related notification and popup.
        let title = events[e].title
        // Reads the host name used to attribute the answer notification.
        let host = events[e].host
        // Creates the local notification announcing that the host replied.
        addNotification(AppNotification(symbol: "checkmark.bubble", title: "\(host) answered your question",
                                        // Supplies the event context and marks the answer notification unread.
                                        detail: "About “\(title)”", time: "Just now", isNew: true,
                                        // Routes a tap on the answer notification to the event question section.
                                        action: .openEventQuestions(eventID)))
        // Avoids presenting or scheduling this main-app-only behaviour while onboarding, login, or setup is active.
        guard stage == .main, preferences.notifyGatherings else { return }
        // Creates the popup headline naming the host who replied.
        popup = AppPopup(title: "You got an answer", headline: "\(host) replied",
                         // Displays which event the reply concerns.
                         detail: "About “\(title)”",
                         // Directs the parent to read the actual answer on the event page.
                         message: "See the answer on the event page.",
                         // Labels and routes the popup action to the relevant event questions.
                         buttonTitle: "View answer", action: .openEventQuestions(eventID))
    }

    // PROTOTYPE ONLY: there is no server yet, so a host's answer and a family's question are made up here
    // a few seconds after the real action. Replace these with the real updates when the server exists.
    private func simulateHostAnswer(eventID: Event.ID, questionID: EventQuestion.ID) {
        // Starts an unstructured task with a weak AppState capture; it inherits the surrounding main-actor context.
        Task { [weak self] in
            // Suspends the task for eight seconds before generating a prototype answer; it does not block a thread while waiting.
            try? await Task.sleep(for: .seconds(8))
            // Delivers the simulated answer only if the shared store still exists.
            self?.receiveAnswer(eventID: eventID, questionID: questionID,
                                // Supplies the canned answer text used for the prototype rather than an actual host reply.
                                answer: "Thanks for asking! Yes, that works. Message us here if you need anything else.")
        }
    }

    // Waits asynchronously before creating a random prototype family question for a hosted event.
    private func simulateIncomingQuestion(for eventID: Event.ID) {
        // Starts an unstructured task with a weak AppState capture; it inherits the surrounding main-actor context.
        Task { [weak self] in
            // Suspends for fifteen seconds before generating the prototype incoming question.
            try? await Task.sleep(for: .seconds(15))
            // Requires the weakly captured AppState to still exist before updating it.
            guard let self else { return }
            // Chooses a sample parent name for the demonstration question, with a readable fallback.
            let asker = MockData.parents.randomElement()?.firstName ?? "A parent"
            // Creates a locally simulated incoming question using the canned question pool and selected sample parent.
            self.receiveQuestion(eventID: eventID, from: asker, text: self.incomingQuestionTexts.randomElement() ?? "Is this open to everyone?")
        }
    }

    /// The host answers a family's question. With `publish`, it also joins the event's public FAQs.
    func answerQuestion(_ questionID: EventQuestion.ID, on eventID: Event.ID, answer: String, publish: Bool) {
        // Trims the host answer before validating and saving it.
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        // Rejects an empty host answer before changing question data.
        guard !trimmed.isEmpty,
              // Finds the event index before accessing its questions.
              let e = events.firstIndex(where: { $0.id == eventID }),
              // Finds the question index and exits safely if either the event or question is missing.
              let q = events[e].questions.firstIndex(where: { $0.id == questionID }) else { return }
        // Stores the trimmed reply on the matched event question.
        events[e].questions[q].answer = trimmed
        // Checks whether the host also wants this reply visible as a public FAQ.
        if publish {
            // Copies the question and reply into the public FAQ collection while preserving the original conversation.
            events[e].faqs.append(EventFAQ(question: events[e].questions[q].text, answer: trimmed))
        }
    }

    /// Events I host that still have questions waiting for an answer.
    var hostedEventsWithQuestions: [Event] {
        // Returns only events hosted by this account that still contain unanswered questions.
        events.filter { $0.isHostedByMe && $0.unansweredCount > 0 }
    }

    // Adds a hosted or supplied event to the local Gather catalogue and preserves chronological ordering.
    func add(_ event: Event) {
        // Appends the newly created event to the shared catalogue used by Gather views.
        events.append(event)
        // Sorts events by their start date so the next event appears first.
        events.sort { $0.start < $1.start }
        // PROTOTYPE ONLY: a family asks the new host a question a little later.
        if event.isHostedByMe { simulateIncomingQuestion(for: event.id) }
    }

    // MARK: Bookmarks

    // Derives the saved-event list from the current catalogue and bookmark set instead of storing duplicate event objects.
    var savedEvents: [Event] {
        // Filters the catalogue using each event stable bookmark key.
        events.filter { isBookmarked($0) }
    }

    // Checks a stable event key against the shared saved-event set.
    func isBookmarked(_ event: Event) -> Bool {
        // Checks whether the event stable key is present in the saved-event set.
        bookmarkedKeys.contains(event.storageKey)
    }

    // Clears both the observable bookmark set and its locally encoded storage.
    func clearSavedEvents() {
        // Empties the active set of liked event keys.
        bookmarkedKeys = []
        // Persists an empty bookmark array after clearing liked events.
        storedBookmarks = Self.encode([String]())
    }

    // Adds or removes the stable event key and saves the sorted bookmark keys for future launches.
    func toggleBookmark(_ event: Event) {
        // Attempts insertion and detects when the event was already bookmarked.
        if !bookmarkedKeys.insert(event.storageKey).inserted {
            // Removes an existing bookmark so the same heart action toggles between liked and unliked.
            bookmarkedKeys.remove(event.storageKey)
        }
        // Encodes sorted bookmark keys for deterministic local persistence.
        storedBookmarks = Self.encode(bookmarkedKeys.sorted())
    }

    // MARK: Several accounts on one device

    /// What one account keeps: its children, the saved events and the last registration details.
    private struct FamilySnapshot: Codable {
        // Stores the account child profiles as encoded Data inside its family snapshot.
        var children: Data
        // Stores the selected child UUID string within the account-specific snapshot.
        var selectedChildID: String
        // Stores the account liked event keys as encoded Data within its snapshot.
        var bookmarks: Data
        // Stores the last account registrant as encoded Data for later form prefilling.
        var registrant: Data
    }

    // Persists "accountSnapshots" in local UserDefaults; ObservationIgnored prevents the Observable macro from rewriting this wrapped storage.
    @ObservationIgnored @AppStorage("accountSnapshots") private var storedSnapshots = Data()

    // Exposes all local family snapshots keyed by normalised account email.
    private var snapshots: [String: FamilySnapshot] {
        // Decodes saved family snapshots or starts an empty account map when no valid data exists.
        get { Self.decode([String: FamilySnapshot].self, from: storedSnapshots) ?? [:] }
        // Encodes the updated snapshot map back into its AppStorage field.
        set { storedSnapshots = Self.encode(newValue) }
    }

    // Saves the current account family profile, selected child, bookmarks, and registrant under its normalised email.
    private func saveSnapshot() {
        // Requires an active account email before saving an account-specific family snapshot.
        guard let email = account?.email else { return }
        // Creates or replaces the snapshot under a case-normalised account email.
        snapshots[AccountStore.normalized(email)] = FamilySnapshot(
            // Encodes the current family child profiles into the snapshot.
            children: Self.encode(children),
            // Records the active child UUID so switching back restores the correct learner.
            selectedChildID: selectedChildID.uuidString,
            // Encodes stable bookmark keys in sorted order for this account snapshot.
            bookmarks: Self.encode(bookmarkedKeys.sorted()),
            // Encodes registrant details when present and otherwise stores empty Data.
            registrant: savedRegistrant.map { Self.encode($0) } ?? Data())
    }

    /// Loads an account's own family details. Returns false when it has none yet.
    @discardableResult
    // Restores an account family snapshot and validates its selected child, or starts an empty family if no valid snapshot exists.
    private func restoreSnapshot(for email: String) -> Bool {
        // Looks up the requested account snapshot using its normalised email.
        guard let snapshot = snapshots[AccountStore.normalized(email)],
              // Requires a decodable nonempty child array before treating the account as an existing family.
              let saved = Self.decode([Child].self, from: snapshot.children), !saved.isEmpty else {
            // Clears the active family view of data while preserving stored account snapshots for future login.
            clearFamily()
            // Reports that the account had no valid family snapshot and needs setup.
            return false
        }
        // Loads the restored child array; its didSet keeps the encoded family storage in sync.
        children = saved
        // Converts the snapshot selected-child string back into a UUID.
        let savedID = UUID(uuidString: snapshot.selectedChildID)
        // Restores the selected child only if it still exists, otherwise falling back to the first restored child.
        selectedChildID = saved.contains { $0.id == savedID } ? (savedID ?? saved[0].id) : saved[0].id
        // Restores the account bookmark keys to the active set.
        bookmarkedKeys = Set(Self.decode([String].self, from: snapshot.bookmarks) ?? [])
        // Encodes sorted bookmark keys for deterministic local persistence.
        storedBookmarks = Self.encode(bookmarkedKeys.sorted())
        // Restores the last registrant from this account snapshot for future event form prefilling.
        savedRegistrant = Self.decode(Registrant.self, from: snapshot.registrant)
        // Copies the snapshot registrant payload into the active local storage field.
        storedRegistrant = snapshot.registrant
        // Reports that the requested state change or restoration completed successfully.
        return true
    }

    /// Empties the family details, for a different account that starts from scratch.
    private func clearFamily() {
        // Creates a new empty child profile with a fresh UUID for the next setup flow.
        children = [Child.empty]
        // Selects the first child so the computed child property points to an existing profile.
        selectedChildID = children[0].id
        // Empties the active set of liked event keys.
        bookmarkedKeys = []
        // Clears the last registrant from active memory.
        savedRegistrant = nil
        // Clears the active encoded bookmark field without deleting other saved account snapshots.
        storedBookmarks = Data()
        // Clears the active encoded registrant field.
        storedRegistrant = Data()
        // Clears the active in-memory booking lookup before rebuilding or changing account state.
        registrations = [:]
        // Resets current-catalogue event registration flags when changing family context.
        for index in events.indices { events[index].updateRegistration(false) }
    }

    /// Called after a successful login. An account that already has family details goes straight to Home.
    func finishLogin(returning: Bool) {
        // Loads the account selected by the completed login or account-switch action.
        refreshAccount()
        restoreEvents()
        // Attempts to restore that account family and remembers whether setup was already completed.
        let hadFamily = account.map { restoreSnapshot(for: $0.email) } ?? false
        // Rebuilds the active account registrations and event attendance flags from saved booking data.
        restoreBookings()
        // Applies returning-user bookkeeping and chooses whether to load prototype sample chats.
        setReturningUser(returning)
        // Opens the main tabs for a restored family or child setup for an account without saved family data.
        advance(to: hadFamily ? .main : .setup)
    }

    /// Other accounts saved on this device.
    var otherAccounts: [Account] {
        // Normalises the current email before comparing it with locally saved accounts.
        let current = AccountStore.normalized(account?.email ?? "")
        // Returns the other saved accounts while excluding the account already active.
        return AccountStore.savedAccounts.filter { AccountStore.normalized($0.email) != current }
    }

    /// Switches to another saved account without signing in again.
    func switchAccount(to email: String) {
        // Persists the current account family before switching or signing out.
        saveSnapshot()
        // Selects the other saved account in the local account store without a new network login.
        AccountStore.switchTo(email)
        // Runs the returning-account restoration path for the newly selected account.
        finishLogin(returning: true)
    }

    /// Signs out and goes back to the login page. The family's details are kept with the account.
    func signOut() {
        // Persists the current account family before switching or signing out.
        saveSnapshot()
        // Clears the active family view of data while preserving stored account snapshots for future login.
        clearFamily()
        // Clears the active account selection in the local AccountStore.
        AccountStore.signOut()
        // Clears the observable account so authenticated profile data is no longer active.
        account = nil
        // Clears the persisted main-stage flag so a subsequent launch does not assume setup is active.
        storedStage = nil
        // Routes RootView back to the login screen after sign-out.
        stage = .login
    }

    /// Removes the account and everything saved on this device, then starts again from onboarding.
    func deleteAccount() {
        let childKeys = Set(children.map { $0.id.uuidString })
        weeklyPlans = weeklyPlans.filter { key, _ in
            !childKeys.contains(key) && !childKeys.contains(where: { key.hasPrefix("history|\($0)|") })
        }
        chats.deleteSavedChats()
        LocalArchive.remove("events", account: eventArchiveAccount)
        restoringEvents = true
        events = MockData.events.sorted { $0.start < $1.start }
        restoringEvents = false
        // Checks whether an active account email exists before deleting account-specific records.
        if let email = account?.email {
            // Removes only this account encoded family snapshot from the snapshot dictionary.
            snapshots.removeValue(forKey: AccountStore.normalized(email))
            // Removes only this account persisted event booking map.
            bookingsByAccount.removeValue(forKey: AccountStore.normalized(email))
            // Deletes the active account from the local account store.
            AccountStore.delete(email)
        }
        // Clears the observable account so authenticated profile data is no longer active.
        account = nil
        // Clears encoded child profiles after removing their current and historical learning plans.
        storedChildren = Data()
        // Clears the active encoded registrant field.
        storedRegistrant = Data()
        // Clears the active encoded bookmark field without deleting other saved account snapshots.
        storedBookmarks = Data()
        // Clears the last registrant from active memory.
        savedRegistrant = nil
        // Empties the active set of liked event keys.
        bookmarkedKeys = []
        // Clears the active in-memory booking lookup before rebuilding or changing account state.
        registrations = [:]
        // Resets Chats to an empty prototype inbox instead of loading returning-user samples.
        chats.reload(withSamples: false)
        // Resets the launch state and blank family after account deletion.
        resetOnboarding()
    }

    // Clears the saved launch stage and creates an empty selected child before returning to onboarding.
    func resetOnboarding() {
        isReturningSession = false
        // Clears the persisted main-stage flag so a subsequent launch does not assume setup is active.
        storedStage = nil
        // Creates a new empty child profile with a fresh UUID for the next setup flow.
        children = [Child.empty]
        // Selects the first child so the computed child property points to an existing profile.
        selectedChildID = children[0].id
        // Routes the root view back to onboarding.
        stage = .onboarding
    }
}
