import SwiftUI

/// The four root-screen stages `RootView` switches between.
enum LaunchStage { case onboarding, login, setup, main }

/// Single source of truth for the signed-in family: profiles, weekly plans, events, connections and
/// notifications. Views read it from the environment; behaviour is grouped into the `AppState+*.swift`
/// extensions (account, children, planning, events, host questions, community).
///
/// Stored properties must live in this declaration because `@Observable` cannot synthesise
/// observation for properties declared in extensions.
@MainActor
@Observable
final class AppState {
    /// Which root flow is showing. Starts at onboarding until `init` restores a finished setup.
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

    /// Permission, coordinates and approximate-place lookups.
    let locationService = LocationService()

    /// One cached event-location resolver, so Gather distances and detail maps agree.
    let eventLocations = EventLocationStore()

    /// How far (in kilometres) "Near you" reaches in Community.
    var communityRadiusKm: Int {
        get { access(keyPath: \.communityRadiusKm); return storedCommunityRadiusKm }
        set { withMutation(keyPath: \.communityRadiusKm) { storedCommunityRadiusKm = newValue } }
    }

    /// All conversations.
    let chats = ChatStore()

    /// User-controlled notification and display settings.
    let preferences = AppPreferences()

    /// Schedules local reminders for events the family joined or saved.
    let gatheringReminders = GatheringReminders()

    /// True while saved events load, so `events.didSet` does not write them straight back.
    @ObservationIgnored var restoringEvents = true

    /// Account key the event archive on this device is stored under.
    @ObservationIgnored var eventArchiveAccount = "local-family"

    /// The parent who is signed in.
    var account: Account? = AccountStore.current

    /// Every child in the family. The first one is created during setup.
    var children: [Child] = [Child.empty] {
        didSet { saveChildren() }
    }

    /// The learner whose data every tab shows.
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

    /// Weekly plans keyed by child id; archived weeks use a `history|<childID>|<timestamp>` key.
    var weeklyPlans: [String: WeeklyPlan] = [:] {
        didSet { storedWeeklyPlans = Self.encode(weeklyPlans) }
    }

    /// Frozen summary of today shown by `MainTabView` as a wrap-up overlay.
    var dailyWrapUp: DayLearningSummary?

    /// Simple Home to-dos. Progress is calculated from `WeeklyPlan` activities instead.
    var tasks: [TaskItem] = MockData.tasks

    /// Every Gather event, in start-date order. Saved per account whenever it changes.
    var events: [Event] = MockData.events.sorted { $0.start < $1.start } {
        didSet {
            guard !restoringEvents else { return }
            LocalArchive.save(events, category: "events", account: eventArchiveAccount)
            syncGatheringReminders()
        }
    }

    /// Details from the last registration, used to pre-fill the next one.
    var savedRegistrant: Registrant?

    /// Registrations of the signed-in account, keyed by the current event ids.
    var registrations: [Event.ID: Registration] = [:]

    /// Stable keys of saved events. Catalogue UUIDs change between launches, so ids are not stored.
    var bookmarkedKeys: Set<String> = [] {
        didSet { syncGatheringReminders() }
    }

    /// false until the family has seen the first-time Home and moved on to another tab.
    var hasSeenFirstHome = false

    /// Login/relaunch determines this flag; simply switching tabs during a first session does not replace the first-time Home.
    var isReturningSession = false

    /// Pages that cover the tab bar (an open chat) count themselves in here, so the bottom bar used on
    /// iPad can hide too. The system tab bar on iPhone hides itself.
    var tabBarHideCount = 0

    /// Hides the native tab bar while one or more covering pages have requested it.
    var hidesTabBar: Bool { tabBarHideCount > 0 }

    /// Parents I sent a connection request to.
    var requestedParents: Set<Parent.ID> = []

    /// The note sent along with each pending connection request.
    var requestIntroductions: [Parent.ID: String] = [:]

    /// Parents I am connected with, so I can message them.
    var connectedParents: Set<Parent.ID> = MockData.initiallyConnected

    /// The in-app notification feed (prototype sample data).
    var notifications: [AppNotification] = MockData.notifications

    /// A message shown over the app, such as "The host answered your question".
    var popup: AppPopup?

    /// The Gather tab's navigation stack, so a notification can open an event directly.
    var gatherPath = NavigationPath()

    /// Set when an event should open scrolled to its questions.
    var scrollEventToQuestions = false

    /// Provides the small canned-question pool used only by the delayed prototype host interaction.
    let incomingQuestionTexts = ["Is there parking near the entrance?", "Can my 6 year old join?", "Do we need to bring anything?"]

    // MARK: - Persistence

    /// Persisted mirrors of the state above. `@Observable` requires `@ObservationIgnored` on property wrappers,
    /// so observed properties either write into these from `didSet` or wrap them with `access`/`withMutation`.
    @ObservationIgnored @AppStorage("stage") var storedStage: String?

    @ObservationIgnored @AppStorage("hasSeenFirstHome") var storedHasSeenFirstHome: Bool?

    @ObservationIgnored @AppStorage("usesLiveLocation") var storedUsesLiveLocation = false

    @ObservationIgnored @AppStorage("communityRadiusKm") var storedCommunityRadiusKm = 5

    @ObservationIgnored @AppStorage("selectedChildID") var storedSelectedChildID = ""

    @ObservationIgnored @AppStorage("weeklyPlans") var storedWeeklyPlans = Data()

    @ObservationIgnored @AppStorage("children") var storedChildren = Data()

    @ObservationIgnored @AppStorage("homeLocation") var storedHomeLocation = Data()

    @ObservationIgnored @AppStorage("savedRegistrant") var storedRegistrant = Data()

    @ObservationIgnored @AppStorage("bookmarkedEvents") var storedBookmarks = Data()

    @ObservationIgnored @AppStorage("eventBookingsByAccount") var storedBookings = Data()

    /// Per-account family snapshots, so several parents can share one device.
    @ObservationIgnored @AppStorage("accountSnapshots") var storedSnapshots = Data()

    /// Encodes any Encodable model to Data for the UserDefaults-backed storage fields.
    static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    /// Decodes a requested Decodable type from its saved JSON Data without throwing to the caller.
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        data.isEmpty ? nil : try? JSONDecoder().decode(type, from: data)
    }

    /// Restores saved launch, family, location, plan, bookmark, and booking state when the shared store is created.
    init() {
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
            stage = .main
            isReturningSession = true
        }
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

        restoreEvents()
        restoreBookings()
        preferences.onGatheringChange = { [weak self] in self?.syncGatheringReminders() }
        chats.onIncomingMessage = { [weak self] thread in
            guard let self, self.preferences.notifyChats else { return }
            self.addNotification(AppNotification(symbol: "bubble.left", title: thread.title,
                detail: thread.preview, time: "Just now", isNew: true))
        }
    }

    /// Changes the root launch stage and remembers when onboarding and setup have reached the main app.
    func advance(to newStage: LaunchStage) {
        stage = newStage
        if newStage == .main {
            storedStage = "main"
            syncGatheringReminders()
        }
    }

    /// Called after login. A new account sees the first-time Home, a returning one goes straight to the regular Home.
    func setReturningUser(_ returning: Bool) {
        isReturningSession = returning
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

    /// Saves the live-location preference and starts a location refresh only when it is enabled.
    func setLiveLocation(_ on: Bool) {
        usesLiveLocation = on
        guard on else { return }
        refreshLiveLocation()
    }

    /// Looks up the approximate area again. Does nothing unless the live location switch is on.
    func refreshLiveLocation() {
        guard usesLiveLocation else { return }
        // Installs a weakly captured callback that updates the shared home area without retaining AppState through
        // the service.
        locationService.onPlace = { [weak self] place in self?.homeLocation = place }
        locationService.request()
    }

    /// Clears the saved launch stage and the child profile, then returns to onboarding.
    func resetOnboarding() {
        isReturningSession = false
        storedStage = nil
        children = [Child.empty]
        selectedChildID = children[0].id
        stage = .onboarding
    }
}
