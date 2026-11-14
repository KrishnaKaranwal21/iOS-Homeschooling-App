import Foundation

/// Compile with the app sources except HomeschoolApp.swift; run in an isolated simulator process.
@main struct FunctionalStateChecks {
    @MainActor static func main() {
        var checks = 0
        func expect(_ condition: Bool, _ message: String) { precondition(condition, message); checks += 1 }
        let savedEvents = LocalArchive.load([Event].self, category: "events", account: "local-family")
        let savedChats = LocalArchive.load([ChatThread].self, category: "chats", account: "local-family")
        let keys = ["stage", "children", "selectedChildID", "weeklyPlans", "pref.notifyChats", "pref.notifyCommunity", "pref.notifyGatherings", "pref.showProfile"]
        let old = keys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
        defer {
            for (key, value) in old { UserDefaults.standard.set(value, forKey: key) }
            if let savedEvents { LocalArchive.save(savedEvents, category: "events", account: "local-family") }
            else { LocalArchive.remove("events", account: "local-family") }
            if let savedChats { LocalArchive.save(savedChats, category: "chats", account: "local-family") }
            else { LocalArchive.remove("chats", account: "local-family") }
        }
        let state = AppState()
        var first = Child.empty
        first.name = "Learner One"
        var second = first
        second.id = UUID()
        second.name = "Learner Two"
        state.children = [first, second]
        state.selectedChildID = first.id
        let currentDate = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 9))!
        let oldDate = Calendar.current.date(byAdding: .day, value: -7, to: currentDate)!
        let current = WeeklyPlan(weekStart: currentDate, days: ["Mon"], hoursPerDay: 1,
            activities: [WeekActivity(title: "Current task", subject: "English", date: currentDate, minutes: 60)])
        let archived = WeeklyPlan(weekStart: oldDate, days: ["Mon"], hoursPerDay: 1,
            activities: [WeekActivity(title: "Earlier task", subject: "English", date: oldDate, minutes: 30)])
        let archiveKey = "history|\(first.id.uuidString)|\(Int(oldDate.timeIntervalSince1970))"
        state.weeklyPlans = [first.id.uuidString: current, archiveKey: archived, second.id.uuidString: current]
        expect(state.learningPlans(for: first.id).count == 2, "Current child receives current and archived weeks")
        expect(state.learningPlans(for: second.id).count == 1, "Other child's archives stay separate")
        let updated = state.toggleLearningActivity(archived.activities[0].id, for: first.id)!
        expect(updated.activities[0].isDone, "Historical completion can be changed")
        expect(state.weeklyPlans[first.id.uuidString] == current, "Historical changes cannot replace the active week")
        expect(state.weeklyPlans[second.id.uuidString] == current, "Changes cannot leak into another child's plan")
        let month = ProgressTimeline(plans: state.learningPlans(for: first.id), range: .month, selectedDate: currentDate)
        expect(month.plannedMinutes == 90 && month.loggedMinutes == 30, "Dashboard state includes both weeks in monthly totals")
        state.preferences.showProfile = true
        state.preferences.notifyCommunity = true
        state.preferences.notifyChats = true
        state.preferences.notifyGatherings = true
        state.notifications = [
            AppNotification(symbol: "person", title: "Request", detail: "", time: "", action: .connectionRequest(UUID())),
            AppNotification(symbol: "bubble.left", title: "Chat", detail: "", time: "", action: .openChat(UUID())),
            AppNotification(symbol: "calendar", title: "Event", detail: "", time: "", action: .openEvent(UUID()))]
        expect(state.visibleNotifications.count == 3, "Enabled preferences show every category")
        state.preferences.notifyChats = false
        expect(state.visibleNotifications.count == 2, "Chat switch hides chat alerts")
        state.preferences.notifyCommunity = false
        expect(state.visibleNotifications.count == 1, "Community switch hides request alerts")
        state.preferences.notifyGatherings = false
        expect(state.visibleNotifications.isEmpty, "Gathering switch hides event alerts")
        state.preferences.notifyCommunity = true
        state.preferences.showProfile = false
        expect(state.visibleNotifications.isEmpty, "Hidden profiles do not receive new request alerts")
        let parent = MockData.parents[0]
        expect(PlaceCatalog.matchesCommunity(parent, home: .potheri), "Nearby fixture appears in its home region")
        let mumbai = Place(name: "Mumbai", detail: "India", country: "India", kind: .city)
        expect(!PlaceCatalog.matchesCommunity(parent, home: mumbai), "Changing city removes unrelated static profiles")
        let chennai = Place(name: "Chennai", detail: "India", country: "India", kind: .city)
        expect(PlaceCatalog.matchesCommunity(parent, home: chennai), "Choosing the parent city includes its nearby areas")
        print("Passed \(checks) shared-state, historical-progress, notification and location checks")
    }
}
