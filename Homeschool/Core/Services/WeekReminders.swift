import Foundation
import UserNotifications

/// Reminders are scheduled only when the family saves their weekly draft.
enum WeekReminders {
    static func sync(plan: WeeklyPlan, child: Child) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "week-task-\(child.id.uuidString)-"
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers:
            pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }
        let calendar = Calendar.current
        let scheduled = plan.activities.compactMap { activity -> (WeekActivity, Date)? in
            guard activity.reminder, !activity.isDone, let time = activity.time else { return nil }
            let parts = calendar.dateComponents([.hour, .minute], from: time)
            guard let date = calendar.date(bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0,
                                           second: 0, of: activity.date), date > .now else { return nil }
            return (activity, date)
        }.sorted { $0.1 < $1.1 }
        // iOS limits pending notifications across the app, including exam reminders.
        let otherCount = pending.filter { !$0.identifier.hasPrefix(prefix) }.count
        for (activity, date) in scheduled.prefix(max(0, 64 - otherCount)) {
            let content = UNMutableNotificationContent()
            content.title = "\(child.displayName)’s learning time"
            content.body = "\(activity.title) · \(activity.minutes) min"
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let request = UNNotificationRequest(identifier: prefix + activity.id.uuidString,
                content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            try? await center.add(request)
        }
    }
}
