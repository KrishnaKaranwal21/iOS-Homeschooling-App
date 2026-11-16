import Foundation
import XCTest
@testable import Homeschool

/// How Home turns planned activities into task cards, completion and repeats.
@MainActor
final class HomeLearningTaskTests: XCTestCase {
    func testHomeLearningTask() throws {
        let calendar = Calendar.current
        let monday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9))!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!
        var plan = WeeklyPlan(weekStart: monday, days: ["Mon", "Tue"], hoursPerDay: 2,
            activities: [WeekActivity(title: "First coding task", subject: "Computer skills", date: monday, minutes: 30),
                         WeekActivity(title: "Read together", subject: "English", date: monday, minutes: 30),
                         WeekActivity(title: "Tuesday coding", subject: "Coding", date: tuesday, minutes: 40)])
        let selected = ["Computer Skills", "English"]
        let before = LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: monday)
        var added = WeekActivity(title: "Build a number game", subject: "Coding", date: monday, minutes: 25)
        added.smallSteps = "Make a score variable."
        added.notes = "Use our saved project."
        plan.add(added)
        let cards = LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: monday)
        expect(cards.count == before.count + 1, "Adding an activity to an existing subject must add a visible card")
        expect(Set(cards.map(\.id)).count == cards.count, "Cards use unique occurrence IDs, never the shared subject key")
        let coding = cards.filter { LearningProgress.subjectKey($0.activity.subject) == "computer skills" }
        expect(coding.count == 2 && coding.allSatisfy(\.showsActivityTitle), "Alias subjects keep both tasks and show their distinguishing titles")
        let newCard = cards.first { $0.activity.title == added.title }!
        expect(newCard.activity.smallSteps == added.smallSteps && newCard.activity.notes == added.notes,
               "The new card opens its own saved instructions and notes")
        expect(newCard.subjectIndex == before[0].subjectIndex && newCard.subjectName == before[0].subjectName,
               "New activities reuse the established subject colour and canonical name")
        expect(!cards.first { $0.activity.subject == "English" }!.showsActivityTitle,
               "Single-activity subjects retain the simple headline design")
        expect(LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: tuesday).count == 1,
               "Adding Monday activity must not leak into Tuesday")
        expect(LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: wednesday).isEmpty,
               "An unplanned day remains empty")
        plan.complete(newCard.id)
        let completedCards = LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: monday)
        expect(completedCards.first { $0.id == newCard.id }!.activity.isDone,
               "Completion follows the exact card occurrence")
        expect(!completedCards.first { $0.id == before[0].id }!.activity.isDone,
               "Completing a new task must not complete the older task in the same subject")
        let restored = try JSONDecoder().decode(WeeklyPlan.self, from: JSONEncoder().encode(plan))
        expect(LearningProgress(plan: restored, selectedSubjects: selected).homeTasks(on: monday).map(\.id) == completedCards.map(\.id),
               "Saved activities keep their visible card identities after reload")
        plan.add(WeekActivity(title: "Sketch an object", subject: "Art & craft", date: monday, minutes: 20))
        expect(LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: monday).contains { $0.activity.subject == "Art & craft" },
               "A newly introduced subject also creates a card")
        var repeating = WeekActivity(title: "Daily reading", subject: "English", date: monday, minutes: 10)
        repeating.repeatRule = .learningDays
        plan.add(repeating)
        let repeatedMonday = LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: monday).first { $0.activity.title == repeating.title }!
        let repeatedTuesday = LearningProgress(plan: plan, selectedSubjects: selected).homeTasks(on: tuesday).first { $0.activity.title == repeating.title }!
        expect(repeatedMonday.id != repeatedTuesday.id, "Repeated tasks have separate dated cards")
    }
}
