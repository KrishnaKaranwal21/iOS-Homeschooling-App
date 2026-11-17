import SwiftUI

/// The four root-screen stages `RootView` switches between.
enum LaunchStage { case onboarding, login, setup, main }

/// Single source of truth for the signed-in family. Behaviour lives in the `AppState+*.swift` extensions;
/// stored properties must stay here because `@Observable` can't observe them from extensions.
@MainActor
@Observable
final class AppState {
    var stage: LaunchStage = .onboarding

    var homeLocation: Place = .potheri {
        didSet { storedHomeLocation = Self.encode(homeLocation) }
    }

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

    let chats = ChatStore()

    let preferences = AppPreferences()

    let gatheringReminders = GatheringReminders()

    /// True while saved events load, so `events.didSet` does not write them straight back.
    @ObservationIgnored var restoringEvents = true

    @ObservationIgnored var eventArchiveAccount = "local-family"

    var account: Account? = AccountStore.current

    var children: [Child] = [Child.empty] {
        didSet { saveChildren() }
    }

    var selectedChildID = UUID() {
        didSet { storedSelectedChildID = selectedChildID.uuidString }
    }

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

    var dailyWrapUp: DayLearningSummary?

    var tasks: [TaskItem] = MockData.tasks

    var events: [Event] = MockData.events.sorted { $0.start < $1.start } {
        didSet {
            guard !restoringEvents else { return }
            LocalArchive.save(events, category: "events", account: eventArchiveAccount)
            syncGatheringReminders()
        }
    }

    var savedRegistrant: Registrant?

    var registrations: [Event.ID: Registration] = [:]

    /// Stable keys of saved events. Catalogue UUIDs change between launches, so ids are not stored.
    var bookmarkedKeys: Set<String> = [] {
        didSet { syncGatheringReminders() }
    }

    /// Pages that cover the tab bar (an open chat) count themselves in, so the iPad bottom bar can hide too.
    var tabBarHideCount = 0

    var hidesTabBar: Bool { tabBarHideCount > 0 }

    var requestedParents: Set<Parent.ID> = []

    var requestIntroductions: [Parent.ID: String] = [:]

    var connectedParents: Set<Parent.ID> = MockData.initiallyConnected

    var notifications: [AppNotification] = MockData.notifications

    var popup: AppPopup?

    var gatherPath = NavigationPath()

    var scrollEventToQuestions = false

    let incomingQuestionTexts = ["Is there parking near the entrance?", "Can my 6 year old join?", "Do we need to bring anything?"]

    // MARK: - Persistence

    /// Persisted mirrors of the state above. `@Observable` needs `@ObservationIgnored` on property wrappers,
    /// so observed properties write into these from `didSet` or wrap them with `access`/`withMutation`.
    @ObservationIgnored @AppStorage("stage") var storedStage: String?

    @ObservationIgnored @AppStorage("usesLiveLocation") var storedUsesLiveLocation = false

    @ObservationIgnored @AppStorage("communityRadiusKm") var storedCommunityRadiusKm = 5

    @ObservationIgnored @AppStorage("selectedChildID") var storedSelectedChildID = ""

    @ObservationIgnored @AppStorage("weeklyPlans") var storedWeeklyPlans = Data()

    @ObservationIgnored @AppStorage("children") var storedChildren = Data()

    @ObservationIgnored @AppStorage("homeLocation") var storedHomeLocation = Data()

    @ObservationIgnored @AppStorage("savedRegistrant") var storedRegistrant = Data()

    @ObservationIgnored @AppStorage("bookmarkedEvents") var storedBookmarks = Data()

    @ObservationIgnored @AppStorage("eventBookingsByAccount") var storedBookings = Data()

    @ObservationIgnored @AppStorage("accountSnapshots") var storedSnapshots = Data()

    static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        data.isEmpty ? nil : try? JSONDecoder().decode(type, from: data)
    }

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

    func advance(to newStage: LaunchStage) {
        stage = newStage
        if newStage == .main {
            storedStage = "main"
            syncGatheringReminders()
        }
    }

    /// A new account starts with no chats; a returning one gets the sample chats.
    func setReturningUser(_ returning: Bool) {
        chats.reload(withSamples: returning)
    }

    func setLiveLocation(_ on: Bool) {
        usesLiveLocation = on
        guard on else { return }
        refreshLiveLocation()
    }

    func refreshLiveLocation() {
        guard usesLiveLocation else { return }
        locationService.onPlace = { [weak self] place in self?.homeLocation = place }
        locationService.request()
    }

    func resetOnboarding() {
        storedStage = nil
        children = [Child.empty]
        selectedChildID = children[0].id
        stage = .onboarding
    }
}
