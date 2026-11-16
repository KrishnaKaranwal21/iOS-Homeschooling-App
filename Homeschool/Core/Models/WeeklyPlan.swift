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
    var completedAt: Date? = nil

    /// Older saves have no completion timestamp; retain their original scheduled-day credit.
    var creditDate: Date? { isDone ? (completedAt ?? date) : nil }

    /// A pending task the planner generated and the family has not customised. These follow the child's profile;
    /// completed and hand-made tasks never do.
    var isAutoPlanned: Bool {
        !isDone && time == nil && smallSteps.isEmpty && notes.isEmpty && !reminder
            && TaskIdeas.isStock(title: title, subject: subject)
    }

    mutating func setCompleted(_ completed: Bool, at date: Date = .now) {
        if completed && !isDone { completedAt = date }
        if !completed { completedAt = nil }
        isDone = completed
    }
}

enum ActivityRepeat: String, Codable, CaseIterable {
    case never = "Does not repeat"
    case learningDays = "Every learning day"
    case daily = "Every day"
}

/// A dated week belongs to one child; every saved edit and completion feeds Home and Progress.
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
        activities[index].setCompleted(true)
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

    var plannedMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }

    /// Adding a learning day leaves existing tasks and completion untouched.
    @discardableResult
    mutating func includeLearningDay(_ day: String) -> Bool {
        guard Self.dayNames.contains(day), !days.contains(day) else { return false }
        days = Self.dayNames.filter { days.contains($0) || $0 == day }
        return true
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
            copy.setCompleted(false)
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
        plan.activities = generatedActivities(for: child, days: days, in: plan, keeping: [], reusing: [])
        return plan
    }

    /// Starter tasks built only from the subjects the family chose: one task per subject on every learning day,
    /// sharing the child's hours per day. Task titles rotate through each subject's ideas.
    /// `kept` are activities that stay (completed or hand-made); they use up time and subjects first.
    /// `reusing` lets regenerated tasks keep their old IDs so an unchanged plan stays equal to the saved one.
    fileprivate static func generatedActivities(for child: Child, days: [String], in plan: WeeklyPlan,
                                                keeping kept: [WeekActivity],
                                                reusing old: [WeekActivity]) -> [WeekActivity] {
        let calendar = Calendar.current
        let subjects = child.subjectNames
        guard !subjects.isEmpty, !days.isEmpty else { return [] }
        let total = child.hoursPerDay * 60
        let week = calendar.component(.weekOfYear, from: plan.weekStart)
        var result: [WeekActivity] = []
        for (position, day) in days.enumerated() {
            let date = plan.date(for: day)
            let dayKept = kept.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let usedKeys = Set(dayKept.map { LearningProgress.subjectKey($0.subject) })
            let budget = total - dayKept.reduce(0) { $0 + $1.minutes }
            guard budget >= 10 else { continue }
            // Every chosen subject gets a task on every learning day; the title rotates so days differ.
            let chosen = subjects.filter { !usedKeys.contains(LearningProgress.subjectKey($0)) }
            guard !chosen.isEmpty else { continue }
            let base = max(5, (budget / chosen.count / 5) * 5)
            var remaining = budget
            for (index, subject) in chosen.enumerated() {
                let minutes = index == chosen.count - 1 ? max(5, remaining) : base
                remaining -= minutes
                var activity = WeekActivity(
                    title: TaskIdeas.title(for: subject, level: child.level, slot: week + position + index),
                    subject: subject, date: date, minutes: minutes, helpMinutes: min(15, minutes))
                if let previous = old.first(where: {
                    calendar.isDate($0.date, inSameDayAs: date)
                        && LearningProgress.subjectKey($0.subject) == LearningProgress.subjectKey(subject)
                }) {
                    activity.id = previous.id
                }
                result.append(activity)
            }
        }
        return result
    }

    /// Brings this week in line with an edited child profile (learning days, hours per day, subjects).
    /// Completed tasks and tasks the family wrote themselves stay; auto-planned pending tasks are rebuilt
    /// from the child's current subjects. Running it twice gives the same plan.
    func reconciled(with child: Child) -> WeeklyPlan {
        var plan = self
        let wanted = Self.dayNames.filter { child.learningDays.contains($0) }
        let stock = activities.filter(\.isAutoPlanned)
        let kept = activities.filter { !$0.isAutoPlanned }
        plan.hoursPerDay = child.hoursPerDay
        plan.activities = kept
        let generated = Self.generatedActivities(for: child, days: wanted, in: plan, keeping: kept, reusing: stock)
        plan.activities = kept + generated
        let calendar = Calendar.current
        plan.days = Self.dayNames.filter { name in
            wanted.contains(name) || plan.activities.contains { calendar.isDate($0.date, inSameDayAs: plan.date(for: name)) }
        }
        return plan
    }

    /// Reuses this calendar week's saved edits and completion; a new week starts from the child's current curriculum and rhythm.
    static func homeWeek(for child: Child, savedPlan: WeeklyPlan?, now: Date = .now) -> WeeklyPlan {
        let generated = firstWeek(for: child, now: now)
        if let savedPlan, Calendar.current.isDate(savedPlan.weekStart, inSameDayAs: generated.weekStart) {
            return savedPlan
        }
        return generated
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
