import SwiftUI

/// Weekly plans and learning activities shared by Home, the planner, Progress and the Syllabus tab.
extension AppState {
    /// An added day becomes part of this child's routine; its activities are planned separately.
    @discardableResult
    func addLearningDay(_ day: String, for childID: Child.ID) -> Date? {
        guard let index = children.firstIndex(where: { $0.id == childID }) else { return nil }
        var plan = weeklyPlans[childID.uuidString] ?? .firstWeek(for: children[index])
        guard plan.includeLearningDay(day) else { return nil }
        children[index].learningDays.insert(day)
        saveWeek(plan, for: childID)
        return plan.date(for: day)
    }

    /// Saves shared planner edits and asynchronously resynchronises that child's learning reminders.
    func saveWeek(_ plan: WeeklyPlan, for childID: Child.ID) {
        weeklyPlans[childID.uuidString] = plan
        if let child = children.first(where: { $0.id == childID }) {
            Task { await WeekReminders.sync(plan: plan, child: child) }
        }
    }

    /// Keeps Home, First Week, and Progress on the current calendar week without discarding the previous saved week.
    func prepareHomeWeek(for childID: Child.ID, today: Date = .now) {
        guard let child = children.first(where: { $0.id == childID }) else { return }
        let key = childID.uuidString
        let previous = weeklyPlans[key]
        let completedTopics = Set(learningPlans(for: childID).flatMap(\.activities)
            .filter(\.isDone).compactMap(\.syllabusTopicID))
        let current = WeeklyPlan.homeWeek(for: child, savedPlan: previous, now: today, completedTopicIDs: completedTopics)
        guard current != previous else { return }
        // Rebuilding the same calendar week (syllabus migration) updates it in place; only a new week archives the
        // old one.
        if let previous, !Calendar.current.isDate(previous.weekStart, inSameDayAs: current.weekStart) {
            let archiveKey = "history|\(key)|\(Int(previous.weekStart.timeIntervalSince1970))"
            weeklyPlans[archiveKey] = previous
        }
        saveWeek(current, for: childID)
    }

    /// Current occurrences take precedence over any older archived copies.
    func learningPlans(for childID: Child.ID) -> [WeeklyPlan] {
        let key = childID.uuidString
        let history = weeklyPlans.filter { $0.key.hasPrefix("history|\(key)|") }
            .map(\.value).sorted { $0.weekStart > $1.weekStart }
        return weeklyPlans[key].map { [$0] + history } ?? history
    }

    /// Ticks a syllabus topic complete, or takes it back, straight from the syllabus page.
    /// Activities already tied to the topic follow it; a topic with none gets one completed entry for today.
    @discardableResult
    func setSyllabusTopicCompleted(_ topic: SyllabusTopic, subject: SyllabusSubject,
                                   completed: Bool, for childID: Child.ID) -> Bool {
        guard let child = children.first(where: { $0.id == childID }),
              MockData.syllabus(for: child).contains(where: { $0.id == subject.id && $0.topics.contains(topic) }) else { return false }
        let childKey = childID.uuidString
        let subjectKey = NIOSSyllabus.subjectKey(subject.name)
        func isLinked(_ activity: WeekActivity) -> Bool {
            activity.syllabusTopicID == topic.id && NIOSSyllabus.subjectKey(activity.subject) == subjectKey
        }
        var foundLinked = false
        let keys = [childKey] + weeklyPlans.keys.filter { $0.hasPrefix("history|\(childKey)|") }.sorted()
        for key in keys {
            guard var plan = weeklyPlans[key] else { continue }
            var changed = false
            if completed {
                for index in plan.activities.indices where isLinked(plan.activities[index]) {
                    foundLinked = true
                    if !plan.activities[index].isDone { plan.activities[index].setCompleted(true); changed = true }
                }
            } else {
                for index in plan.activities.indices.reversed() where isLinked(plan.activities[index]) && plan.activities[index].isDone {
                    foundLinked = true
                    if plan.activities[index].isQuickCompletion == true { plan.activities.remove(at: index) }
                    else { plan.activities[index].setCompleted(false) }
                    changed = true
                }
            }
            if changed { if key == childKey { saveWeek(plan, for: childID) } else { weeklyPlans[key] = plan } }
        }
        guard completed, !foundLinked else { return true }
        prepareHomeWeek(for: childID)
        guard var plan = weeklyPlans[childKey] else { return false }
        let today = Calendar.current.startOfDay(for: .now)
        var activity = WeekActivity(title: topic.title, subject: subject.name,
                                    date: max(plan.weekStart, min(today, plan.weekEnd)), syllabusTopicID: topic.id)
        activity.isSyllabusGenerated = false
        activity.isQuickCompletion = true
        let existing = Set(plan.activities.map(\.id))
        plan.add(activity)
        for index in plan.activities.indices where !existing.contains(plan.activities[index].id) {
            plan.activities[index].setCompleted(true)
        }
        saveWeek(plan, for: childID)
        return true
    }

    /// Completion from a historical chart updates that saved week without replacing the current plan.
    @discardableResult
    func toggleLearningActivity(_ id: WeekActivity.ID, for childID: Child.ID) -> WeeklyPlan? {
        let childKey = childID.uuidString
        let keys = [childKey] + weeklyPlans.keys.filter { $0.hasPrefix("history|\(childKey)|") }.sorted()
        for key in keys {
            guard var plan = weeklyPlans[key], let index = plan.activities.firstIndex(where: { $0.id == id }) else { continue }
            plan.activities[index].setCompleted(!plan.activities[index].isDone)
            if key == childKey { saveWeek(plan, for: childID) }
            else { weeklyPlans[key] = plan }
            return plan
        }
        return nil
    }
}
