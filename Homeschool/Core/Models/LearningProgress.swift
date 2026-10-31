import Foundation

/// Progress is calculated from the same saved activities used by the weekly plan.
/// Removed occurrences are absent; planned activities never count as logged learning.
struct LearningProgress {
    let plan: WeeklyPlan
    let subjects: [SubjectLearningProgress]

    init(plan: WeeklyPlan, selectedSubjects: [String]) {
        self.plan = plan
        var names: [String] = []
        var keys: Set<String> = []
        for name in selectedSubjects + plan.activities.map(\.subject) {
            if keys.insert(Self.subjectKey(name)).inserted { names.append(name) }
        }
        subjects = names.map { name in
            let activities = plan.activities.filter { Self.subjectKey($0.subject) == Self.subjectKey(name) }
            return SubjectLearningProgress(name: name, activities: activities)
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
    var id: String { LearningProgress.subjectKey(name) }
    var completedCount: Int { activities.filter(\.isDone).count }
    var plannedMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    var loggedMinutes: Int { activities.filter(\.isDone).reduce(0) { $0 + $1.minutes } }
    var fraction: Double { LearningProgress.fraction(loggedMinutes, of: plannedMinutes) }
}
