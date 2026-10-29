import Foundation

struct WeekActivity: Identifiable, Codable, Equatable {
    var id = UUID()
    var title = ""
    var subject = "Coding"
    var date: Date
    var time: Date? = nil
    var minutes = 45
    var helpMinutes = 15
    var repeatRule: ActivityRepeat = .never
    var reminder = false
    var smallSteps = ""
    var notes = ""
    var isDone = false
}

enum ActivityRepeat: String, Codable, CaseIterable {
    case never = "Does not repeat"
    case learningDays = "Every learning day"
    case daily = "Every day"
}

/// A saved week belongs to one child. Task edits are drafts; daily completion and removal save immediately.
struct WeeklyPlan: Codable, Equatable {
    static let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    static let fullDayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var weekStart: Date
    var days: [String]
    var hoursPerDay: Int
    var activities: [WeekActivity]
    var startTimes: [String: Date] = [:]

    var weekEnd: Date { Calendar.current.date(byAdding: .day, value: 6, to: weekStart)! }

    func date(for day: String) -> Date {
        Calendar.current.date(byAdding: .day, value: Self.dayNames.firstIndex(of: day) ?? 0, to: weekStart)!
    }

    func day(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return Self.dayNames[(weekday + 5) % 7]
    }

    func activities(on day: String) -> [WeekActivity] {
        activities.filter { Calendar.current.isDate($0.date, inSameDayAs: date(for: day)) }
            .sorted { left, right in
                switch (left.time, right.time) {
                case let (a?, b?):
                    let calendar = Calendar.current
                    let leftMinute = calendar.component(.hour, from: a) * 60 + calendar.component(.minute, from: a)
                    let rightMinute = calendar.component(.hour, from: b) * 60 + calendar.component(.minute, from: b)
                    return leftMinute < rightMinute
                case (_?, nil): return true
                default: return false
                }
            }
    }

    func remainingActivities(on day: String) -> [WeekActivity] {
        activities(on: day).filter { !$0.isDone }
    }

    func completedActivities(on day: String) -> [WeekActivity] {
        activities(on: day).filter(\.isDone)
    }

    func learningSummary(on day: String, childName: String) -> DayLearningSummary {
        let completed = completedActivities(on: day)
        return DayLearningSummary(day: day, childName: childName,
                                  minutes: completed.reduce(0) { $0 + $1.minutes },
                                  activityCount: completed.count)
    }

    /// Completion keeps the activity in the learning log while the pending list hides it.
    @discardableResult
    mutating func complete(_ id: WeekActivity.ID) -> Bool {
        guard let index = activities.firstIndex(where: { $0.id == id }), !activities[index].isDone else { return false }
        activities[index].isDone = true
        return true
    }

    /// Repeated activities have separate IDs, so removing this occurrence leaves other days alone.
    @discardableResult
    mutating func removeForDay(_ id: WeekActivity.ID) -> WeekActivity? {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return nil }
        return activities.remove(at: index)
    }

    func minutes(on day: String) -> Int {
        activities(on: day).reduce(0) { $0 + $1.minutes }
    }

    mutating func add(_ activity: WeekActivity) {
        var dates = [activity.date]
        if activity.repeatRule != .never {
            dates += Self.dayNames.compactMap { day in
                let date = date(for: day)
                guard date > activity.date,
                      activity.repeatRule == .daily || days.contains(day) else { return nil }
                return date
            }
        }
        for date in dates {
            var copy = activity
            copy.id = UUID()
            copy.date = date
            activities.append(copy)
            let day = day(for: date)
            if !days.contains(day) { days.append(day) }
        }
        days.sort { Self.dayNames.firstIndex(of: $0)! < Self.dayNames.firstIndex(of: $1)! }
    }

    static func firstWeek(for child: Child, now: Date = .now) -> WeeklyPlan {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let mondayOffset = (calendar.component(.weekday, from: today) + 5) % 7
        let start = calendar.date(byAdding: .day, value: -mondayOffset, to: today)!
        let days = dayNames.filter { child.learningDays.contains($0) }
        var plan = WeeklyPlan(weekStart: start, days: days, hoursPerDay: child.hoursPerDay, activities: [])
        let subjects = child.subjectNames.isEmpty
            ? ["Maths", "English", "Science", "Computer skills", "Art & craft"] : child.subjectNames
        let ideas = [
            "maths": "Fractions in practice", "mathematics": "Fractions in practice",
            "english": "Explain an idea", "science": "Observe and predict",
            "computer skills": "Explore Python data types", "coding": "Explore Python data types",
            "art & craft": "Create a repeating pattern", "art": "Create a repeating pattern"
        ]
        for day in days {
            let total = child.hoursPerDay * 60
            let count = min(subjects.count, max(1, total / 15))
            let chosen = Array(subjects.prefix(count))
            let weights = chosen.indices.map { $0 == 0 ? 4 : 3 }
            let weightTotal = weights.reduce(0, +)
            var remaining = total
            for (index, subject) in chosen.enumerated() {
                let minutes = index == chosen.count - 1 ? remaining : max(5, (total * weights[index] / weightTotal / 5) * 5)
                remaining -= minutes
                plan.activities.append(WeekActivity(
                    title: ideas[subject.lowercased()] ?? "Explore \(subject.lowercased())",
                    subject: subject, date: plan.date(for: day), minutes: minutes,
                    helpMinutes: min(15, minutes)))
            }
        }
        return plan
    }
}

/// Snapshot the totals before presenting, so switching children or days cannot change an open card.
struct DayLearningSummary: Identifiable, Equatable {
    let id = UUID()
    let day: String
    let childName: String
    let minutes: Int
    let activityCount: Int
}
