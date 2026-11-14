import Foundation
import UserNotifications

/// Registered and saved gatherings get a local reminder one hour before their start.
@MainActor final class GatheringReminders {
    private var pendingSync: Task<Void, Never>?

    func sync(events: [Event], enabled: Bool) {
        let previous = pendingSync
        previous?.cancel()
        pendingSync = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            guard !Task.isCancelled else { return }
            center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("gathering-") })
            guard enabled else { return }
            let status = await center.notificationSettings().authorizationStatus
            guard !Task.isCancelled, status == .authorized || status == .provisional else { return }
            var seen: Set<String> = []
            let candidates = events.filter { seen.insert($0.storageKey).inserted && $0.start.addingTimeInterval(-3600) > .now }
                .sorted { $0.start < $1.start }
            let room = max(0, 64 - pending.filter { !$0.identifier.hasPrefix("gathering-") }.count)
            for event in candidates.prefix(room) {
                guard !Task.isCancelled else { return }
                let content = UNMutableNotificationContent()
                content.title = "Coming up: \(event.title)"
                content.body = "Starts in one hour · \(event.mode == .online ? "Online" : event.locality)"
                content.sound = .default
                let date = event.start.addingTimeInterval(-3600)
                let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let request = UNNotificationRequest(identifier: "gathering-" + event.id.uuidString, content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
                try? await center.add(request)
            }
        }
    }
}
