import Foundation

// MARK: - NotificationAction

/// What happens when a notification is tapped.
enum NotificationAction: Equatable {
    case none
    /// A gathering: a new one, or one a connection joined.
    case openEvent(Event.ID)
    /// The question and answer section of a gathering.
    case openEventQuestions(Event.ID)
    /// A connection request was accepted: open the chat with them.
    case openChat(Parent.ID)
    /// Someone wants to connect. The row has Accept and Decline.
    case connectionRequest(Parent.ID)
}

// MARK: - AppNotification

struct AppNotification: Identifiable {
    let id = UUID()
    var symbol: String
    var title: String
    var detail: String
    var time: String
    var isNew = false
    var action: NotificationAction = .none
}

// MARK: - AppPopup

/// A message that appears over the app, such as "The host answered your question".
struct AppPopup: Identifiable {
    let id = UUID()
    var title: String
    /// The bold line in the lavender box.
    var headline: String
    var detail: String
    var message: String
    var buttonTitle: String
    var action: NotificationAction
}
