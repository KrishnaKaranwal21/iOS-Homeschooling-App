import Foundation

/// Progress is calculated from the same saved activities used by the weekly plan.
/// Removed occurrences are absent; planned activities never count as logged learning.
struct LearningProgress {
    let plan: WeeklyPlan
    let subjects: [SubjectLearningProgress]

    init(plan: WeeklyPlan, selectedSubjects: [String], creditedActivities: [WeekActivity]? = nil) {
        self.plan = plan
        var names: [String] = []
        var keys: Set<String> = []
        for name in selectedSubjects + plan.activities.map(\.subject) + (creditedActivities ?? []).map(\.subject) {
            if keys.insert(Self.subjectKey(name)).inserted { names.append(name) }
        }
        subjects = names.map { name in
            let activities = plan.activities.filter { Self.subjectKey($0.subject) == Self.subjectKey(name) }
            return SubjectLearningProgress(name: name, activities: activities,
                creditedActivities: creditedActivities?.filter { Self.subjectKey($0.subject) == Self.subjectKey(name) })
        }
    }

    var plannedMinutes: Int { plan.activities.reduce(0) { $0 + $1.minutes } }
    var loggedMinutes: Int { plan.activities.filter(\.isDone).reduce(0) { $0 + $1.minutes } }
    var completedCount: Int { plan.activities.filter(\.isDone).count }
    var activityCount: Int { plan.activities.count }
    var timeFraction: Double { Self.fraction(loggedMinutes, of: plannedMinutes) }
    var activityFraction: Double { Self.fraction(completedCount, of: activityCount) }

    func day(_ name: String) -> DayLearningProgress {
        DayLearningProgress(name: name, date: plan.date(for: name), activities: plan.activities(on: name))
    }

    static func fraction(_ value: Int, of total: Int) -> Double {
        total > 0 ? min(1, max(0, Double(value) / Double(total))) : 0
    }

    /// Reserve 100% for a nonempty plan with every occurrence complete, including short remaining tasks.
    static func completionPercentage(for activities: [WeekActivity]) -> Int {
        guard !activities.isEmpty else { return 0 }
        if activities.allSatisfy(\.isDone) { return 100 }
        let planned = activities.reduce(0) { $0 + $1.minutes }
        let completed = activities.filter(\.isDone).reduce(0) { $0 + $1.minutes }
        return min(99, Int((fraction(completed, of: planned) * 100).rounded()))
    }

    static func duration(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0 min" }
        if minutes < 60 { return "\(minutes) min" }
        if minutes % 60 == 0 { return "\(minutes / 60)h" }
        return "\(minutes / 60)h \(minutes % 60) min"
    }

    /// Match common activity labels to the chosen curriculum subject without merging unrelated subjects.
    static func subjectKey(_ name: String) -> String {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "math", "maths", "mathematics": return "mathematics"
        case "coding", "computer skills": return "computer skills"
        case "art", "art & craft", "art and craft": return "art & craft"
        default: return name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}

struct DayLearningProgress {
    let name: String
    let date: Date
    let activities: [WeekActivity]
    var completed: [WeekActivity] { activities.filter(\.isDone) }
    var remaining: [WeekActivity] { activities.filter { !$0.isDone } }
    var plannedMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    var loggedMinutes: Int { completed.reduce(0) { $0 + $1.minutes } }
    var remainingMinutes: Int { max(0, plannedMinutes - loggedMinutes) }
    var isComplete: Bool { !activities.isEmpty && completed.count == activities.count }
}

struct SubjectLearningProgress: Identifiable {
    let name: String
    let activities: [WeekActivity]
    var creditedActivities: [WeekActivity]? = nil
    var id: String { LearningProgress.subjectKey(name) }
    var completedCount: Int { activities.filter(\.isDone).count }
    var plannedMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    var loggedMinutes: Int { activities.filter(\.isDone).reduce(0) { $0 + $1.minutes } }
    var fraction: Double { LearningProgress.fraction(loggedMinutes, of: plannedMinutes) }
    var creditedMinutes: Int { (creditedActivities ?? activities.filter(\.isDone)).reduce(0) { $0 + $1.minutes } }
    var completionPercentage: Int { LearningProgress.completionPercentage(for: activities) }
}

enum ProgressRange: String, Identifiable, CaseIterable {
    case day = "Day", week = "Week", month = "Month"
    var id: String { rawValue }
}

/// Every range includes dated learning from the child’s current and archived weeks.
struct ProgressTimeline {
    let interval: DateInterval
    let buckets: [ProgressChartBucket]
    let activities: [WeekActivity]
    let creditedActivities: [WeekActivity]

    init(plan: WeeklyPlan, range: ProgressRange, selectedDate: Date, calendar: Calendar = .current) {
        self.init(plans: [plan], range: range, selectedDate: selectedDate, calendar: calendar)
    }

    init(plans: [WeeklyPlan], range: ProgressRange, selectedDate: Date, calendar: Calendar = .current) {
        let start: Date
        let end: Date
        switch range {
        case .day:
            start = calendar.startOfDay(for: selectedDate)
            end = calendar.date(byAdding: .day, value: 1, to: start)!
        case .week:
            let day = calendar.startOfDay(for: selectedDate)
            let offset = (calendar.component(.weekday, from: day) + 5) % 7
            start = calendar.date(byAdding: .day, value: -offset, to: day)!
            end = calendar.date(byAdding: .day, value: 7, to: start)!
        case .month:
            let month = calendar.dateInterval(of: .month, for: selectedDate)!
            start = month.start
            end = month.end
        }
        interval = DateInterval(start: start, end: end)
        var seenWeeks: Set<Date> = []
        let weeks = plans.filter { seenWeeks.insert(calendar.startOfDay(for: $0.weekStart)).inserted }
        var seen: Set<WeekActivity.ID> = []
        let all = weeks.flatMap(\.activities).filter { seen.insert($0.id).inserted }
        let included = all.filter { $0.date >= start && $0.date < end }.sorted { $0.date < $1.date }
        let credited = all.filter {
            guard let date = $0.creditDate else { return false }
            return date >= start && date < end
        }
        activities = included
        creditedActivities = credited
        if range == .day {
            let extra = credited.filter { activity in !included.contains { $0.id == activity.id } }
            buckets = (included + extra).enumerated().map { index, activity in
                ProgressChartBucket(id: activity.id.uuidString, date: start,
                                    label: "\(index + 1)", title: activity.title,
                                    activities: included.filter { $0.id == activity.id },
                                    creditedActivities: credited.filter { $0.id == activity.id })
            }
        } else {
            let count = calendar.dateComponents([.day], from: start, to: end).day ?? 0
            buckets = (0..<count).map { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: start)!
                let weekday = (calendar.component(.weekday, from: date) + 5) % 7
                let label = range == .week ? WeeklyPlan.dayNames[weekday] : "\(calendar.component(.day, from: date))"
                return ProgressChartBucket(id: "day-\(date.timeIntervalSince1970)", date: date,
                                           label: label, title: date.formatted(.dateTime.weekday(.wide).day().month()),
                                           activities: included.filter { calendar.isDate($0.date, inSameDayAs: date) },
                                           creditedActivities: credited.filter { calendar.isDate($0.creditDate!, inSameDayAs: date) })
            }
        }
    }

    var plannedMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    var loggedMinutes: Int { creditedActivities.reduce(0) { $0 + $1.minutes } }
    var completedCount: Int { activities.filter(\.isDone).count }
    var completedPlannedMinutes: Int { activities.filter(\.isDone).reduce(0) { $0 + $1.minutes } }
    var fraction: Double { LearningProgress.fraction(completedPlannedMinutes, of: plannedMinutes) }
    var completionPercentage: Int { LearningProgress.completionPercentage(for: activities) }
}

struct ProgressChartBucket: Identifiable {
    let id: String
    let date: Date
    let label: String
    let title: String
    let activities: [WeekActivity]
    var creditedActivities: [WeekActivity]? = nil
    var plannedMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    var loggedMinutes: Int { (creditedActivities ?? activities.filter(\.isDone)).reduce(0) { $0 + $1.minutes } }
    var isComplete: Bool { !activities.isEmpty && activities.allSatisfy(\.isDone) }
}
