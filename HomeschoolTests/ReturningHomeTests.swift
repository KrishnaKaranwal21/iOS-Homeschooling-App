import Foundation
import XCTest
@testable import Homeschool

/// The weekly plan on Home: week boundaries, custom edits, completion and new weeks.
@MainActor
final class ReturningHomeTests: XCTestCase {
    func testReturningHome() throws {
        let calendar = Calendar.current
        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day))!
        }
        var child = Child.empty
        child.name = "Adwin"
        child.learningDays = ["Mon", "Thu"]
        child.hoursPerDay = 3
        child.selectedSubjects = ["core|Mathematics", "core|Science"]
        let thursday = date(2026, 11, 12)
        let generated = WeeklyPlan.homeWeek(for: child, savedPlan: nil, now: thursday)
        expect(calendar.isDate(generated.weekStart, inSameDayAs: date(2026, 11, 9)), "Home starts with the current Monday-based week")
        expect(Set(generated.activities.map(\.subject)) == Set(child.subjectNames), "Home suggestions follow the selected curriculum subjects")
        expect(generated.days == ["Mon", "Thu"], "Home respects the child chosen learning weekdays")
        expect(generated.minutes(on: "Thu") == 180, "Day tiles and daily totals use the same planned durations")
        expect(generated.activities(on: "Fri").isEmpty, "Rest days do not acquire fabricated activities")

        var saved = generated
        let id = saved.activities(on: "Thu")[0].id
        saved.activities[saved.activities.firstIndex(where: { $0.id == id })!].title = "Our custom activity"
        expect(saved.complete(id), "Completing a Home task changes the saved occurrence")
        let restored = WeeklyPlan.homeWeek(for: child, savedPlan: saved, now: thursday)
        expect(restored == saved, "Returning to Home in the same week preserves custom edits, IDs, and completion")
        let day = DayLearningProgress(name: "Thu", date: thursday, activities: restored.activities(on: "Thu"))
        let progress = ProgressTimeline(plan: restored, range: .day, selectedDate: thursday)
        expect(day.completed.count == 1 && day.remaining.count == 1, "The completed dropdown and next task partition the saved day")
        expect(day.loggedMinutes == progress.loggedMinutes, "Home completion and Progress logged time agree")
        expect(day.remainingMinutes + day.loggedMinutes == day.plannedMinutes, "Time left excludes exactly the completed duration")
        let data = try JSONEncoder().encode(restored)
        let decoded = try JSONDecoder().decode(WeeklyPlan.self, from: data)
        expect(decoded == saved, "Persistence round trip preserves the daily checklist and completion")

        let nextWeek = WeeklyPlan.homeWeek(for: child, savedPlan: saved, now: date(2026, 11, 19))
        expect(nextWeek.activities.allSatisfy { !$0.isDone }, "A new week does not inherit last week completion")
        expect(Set(nextWeek.activities.map(\.id)).isDisjoint(with: Set(saved.activities.map(\.id))), "New-week occurrences have distinct IDs")
        expect(saved.activities.contains { $0.id == id && $0.isDone }, "Creating the next week leaves the previous plan value intact for archival")
        expect(calendar.isDate(nextWeek.weekStart, inSameDayAs: date(2026, 11, 16)), "New-week activities have real current-week dates")
        let sunday = WeeklyPlan.homeWeek(for: child, savedPlan: saved, now: date(2026, 11, 15))
        expect(sunday == saved, "Sunday remains in the saved week without resetting its completion")

        var updated = restored
        updated.add(WeekActivity(title: "Read together", subject: "Reading", date: thursday, minutes: 20))
        expect(updated.activities(on: "Thu").count == 3 && updated.minutes(on: "Thu") == 200, "Adding a Home task updates the same dated plan used by Progress")
        expect(updated.completedActivities(on: "Thu").count == 1, "Adding a task preserves already completed learning")
        var otherChild = child
        otherChild.id = UUID()
        otherChild.selectedSubjects = ["language|English"]
        let other = WeeklyPlan.homeWeek(for: otherChild, savedPlan: nil, now: thursday)
        expect(other.activities.allSatisfy { $0.subject == "English" && !$0.isDone }, "A second child gets their own curriculum activities and completion state")
    }
}
