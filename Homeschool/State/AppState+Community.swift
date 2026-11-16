import SwiftUI

/// Connection requests, in-app notifications and notification navigation.
extension AppState {
    /// Records a pending community connection locally by parent ID; this does not send a server request.
    @discardableResult
    func sendRequest(to parent: Parent, note: String = "") -> Bool {
        guard !requestedParents.contains(parent.id), !connectedParents.contains(parent.id) else { return false }
        requestedParents.insert(parent.id)
        requestIntroductions[parent.id] = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(300))
        return true
    }

    /// Cancels a pending connection request.
    func withdrawRequest(to parent: Parent) {
        requestedParents.remove(parent.id)
        requestIntroductions.removeValue(forKey: parent.id)
    }

    /// Notifications that match the family's notification settings.
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

    /// How many visible notifications are still marked new.
    var unreadNotificationCount: Int { visibleNotifications.filter(\.isNew).count }

    /// Clears the unread flag of the matching in-app notification if it is currently new.
    func markRead(_ id: AppNotification.ID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }), notifications[index].isNew else { return }
        notifications[index].isNew = false
    }

    /// Prepends a notification so the newest local update appears first.
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

    /// Removes the matching connection-request notification from the local list.
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

    /// Places an event on the shared Gather navigation path and optionally requests scrolling to its questions.
    func showEvent(_ id: Event.ID, questions: Bool, openTab: (AppTab) -> Void) {
        guard let event = events.first(where: { $0.id == id }) else { return }
        scrollEventToQuestions = questions
        gatherPath = NavigationPath([event])
        openTab(.gather)
    }
}
