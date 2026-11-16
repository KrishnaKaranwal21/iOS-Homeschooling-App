import Foundation
import UserNotifications

// MARK: - ExamReminders

/// Local reminders that the NIOS exam form is about to close, for children who aren't registered yet.
/// The last date comes from `ExamCalendar`, according to the child's level.
enum ExamReminders {
    /// Days before the last date that a reminder is sent. 0 is the last day itself.
    static let offsets = [30, 14, 7, 3, 1, 0]
    private static let prefix = "exam-deadline-"

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Replaces all pending exam reminders with ones that match the children as they are now.
    static func sync(children: [Child]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let calendar = Calendar.current
        for child in children where child.examRemindersOn && !child.isExamRegistered {
            guard let window = child.examWindow else { continue }
            let deadline = window.lastDate
            let deadlineDay = calendar.startOfDay(for: deadline)

            for offset in offsets {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: deadlineDay),
                      let fireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day),
                      fireDate > .now else { continue }

                let content = UNMutableNotificationContent()
                content.title = offset == 0 ? "Last day for the NIOS exam form"
                                            : "NIOS exam form: \(offset) \(offset == 1 ? "day" : "days") left"
                content.body = "\(child.displayName) isn’t registered for the \(window.session) yet. "
                    + "Last date: \(deadline.formatted(date: .abbreviated, time: .omitted))."
                content.sound = .default

                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                let request = UNNotificationRequest(identifier: "\(prefix)\(child.id.uuidString)-\(offset)",
                                                    content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }
}

// MARK: - GatheringReminders

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

// MARK: - WeekReminders

/// Keeps task reminders in sync with saved weekly edits and completion.
@MainActor enum WeekReminders {
    private static var jobs: [Child.ID: Task<Void, Never>] = [:]

    static func sync(plan: WeeklyPlan, child: Child) async {
        let previous = jobs[child.id]
        previous?.cancel()
        let job = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            await replace(plan: plan, child: child)
        }
        jobs[child.id] = job
        await job.value
    }

    private static func replace(plan: WeeklyPlan, child: Child) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "week-task-\(child.id.uuidString)-"
        let pending = await center.pendingNotificationRequests()
        guard !Task.isCancelled else { return }
        center.removePendingNotificationRequests(withIdentifiers:
            pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        let status = await center.notificationSettings().authorizationStatus
        guard !Task.isCancelled, status == .authorized || status == .provisional else { return }
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
            guard !Task.isCancelled else { return }
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
