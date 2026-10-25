import Foundation
import UserNotifications

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
