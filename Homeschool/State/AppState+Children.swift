import SwiftUI

/// Child profiles: selecting, adding, editing and removing learners.
extension AppState {
    /// Selects an existing child by ID so all tabs derive their data from that family member.
    func selectChild(_ id: Child.ID) {
        guard children.contains(where: { $0.id == id }) else { return }
        selectedChildID = id
    }

    /// Adds a child and switches to them.
    func addChild(_ newChild: Child) {
        children.append(newChild)
        selectedChildID = newChild.id
    }

    /// Removes a child and everything saved for them. The last remaining child can't be removed.
    func removeChild(_ id: Child.ID) {
        guard children.count > 1, children.contains(where: { $0.id == id }) else { return }
        let key = id.uuidString
        weeklyPlans = weeklyPlans.filter { k, _ in k != key && !k.hasPrefix("history|\(key)|") }
        children.removeAll { $0.id == id }
        if selectedChildID == id, let first = children.first { selectedChildID = first.id }
    }

    /// Switches a child's NIOS level. Subjects depend on the level, so they are cleared and chosen again.
    @discardableResult
    func changeLevel(of id: Child.ID, to level: String) -> Child? {
        guard var changed = children.first(where: { $0.id == id }), changed.level != level else { return nil }
        changed.level = level
        changed.levelChosenManually = true
        changed.selectedSubjects = []
        updateChild(changed)
        return changed
    }

    /// Replaces the matching child in the observable array so profile persistence and dependent screens update.
    func updateChild(_ updated: Child) {
        guard let index = children.firstIndex(where: { $0.id == updated.id }) else { return }
        let previous = children[index]
        children[index] = updated
        // Learning days, hours per day and subjects shape the saved week, so Home, the planner and Progress must
        // follow.
        if previous.learningDays != updated.learningDays
            || previous.hoursPerDay != updated.hoursPerDay
            || previous.selectedSubjects != updated.selectedSubjects {
            syncWeek(with: updated)
        }
    }

    /// Re-applies a child's current rhythm and subjects to their saved week.
    /// Without a saved week there is nothing to update: screens build the week from the profile directly.
    func syncWeek(with child: Child) {
        let key = child.id.uuidString
        guard weeklyPlans[key] != nil else { return }
        // A saved week from an earlier calendar week is archived and rebuilt from the updated profile.
        prepareHomeWeek(for: child.id)
        guard let saved = weeklyPlans[key] else { return }
        let completedTopics = Set(learningPlans(for: child.id).flatMap(\.activities)
            .filter(\.isDone).compactMap(\.syllabusTopicID))
        let updated = saved.reconciled(with: child, completedTopicIDs: completedTopics)
        if updated != saved { saveWeek(updated, for: child.id) }
    }

    /// Encodes all child profiles locally and refreshes their exam-deadline notification schedule.
    func saveChildren() {
        storedChildren = Self.encode(children)
        syncExamReminders()
    }

    /// Re-plans the "exam form closes soon" notifications for every child who isn't registered.
    func syncExamReminders() {
        // Only the main app shows pop-ups and schedules reminders, not onboarding, login or setup.
        guard stage == .main else { return }
        let snapshot = children
        Task { await ExamReminders.sync(children: snapshot) }
    }

    /// Finds and reverses the completion flag of a simple Home TaskItem, independently of weekly learning
    /// activities.
    func toggle(_ task: TaskItem) {
        guard let i = tasks.firstIndex(of: task) else { return }
        tasks[i].isDone.toggle()
    }
}
