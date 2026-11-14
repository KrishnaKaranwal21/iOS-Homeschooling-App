import Foundation

/// Each dated activity keeps its own card identity, even when several activities share a curriculum subject.
struct HomeLearningTask: Identifiable {
    let activity: WeekActivity
    let subjectName: String
    let subjectIndex: Int
    let showsActivityTitle: Bool
    var id: WeekActivity.ID { activity.id }
}

extension LearningProgress {
    func homeTasks(on date: Date) -> [HomeLearningTask] {
        let scheduled = plan.activities(on: plan.day(for: date)).filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        return subjects.enumerated().flatMap { index, subject in
            let activities = scheduled.filter { Self.subjectKey($0.subject) == subject.id }
            return activities.map { activity in
                HomeLearningTask(activity: activity, subjectName: subject.name,
                                 subjectIndex: index, showsActivityTitle: activities.count > 1)
            }
        }
    }
}
