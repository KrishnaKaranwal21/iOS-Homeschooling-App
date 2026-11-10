import Foundation

// Run with swiftc alongside Child, Curriculum, ExamCalendar, WeeklyPlan and LearningProgress.
@main struct ProgressTimelineChecks {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day))!
        }
        var checks = 0
        func expect(_ result: Bool, _ message: String) {
            precondition(result, message)
            checks += 1
        }
        let monday = date(2026, 10, 26)
        let tuesday = date(2026, 10, 27)
        let november = date(2026, 11, 1)
        let plan = WeeklyPlan(weekStart: monday, days: ["Mon", "Tue", "Sun"], hoursPerDay: 2, activities: [
            WeekActivity(title: "Fractions", subject: "Maths", date: monday, minutes: 60, isDone: true),
            WeekActivity(title: "Read", subject: "English", date: monday, minutes: 30),
            WeekActivity(title: "Explore", subject: "Science", date: tuesday, minutes: 45),
            WeekActivity(title: "Make", subject: "Art", date: november, minutes: 90, isDone: true)
        ])
        let day = ProgressTimeline(plan: plan, range: .day, selectedDate: monday, calendar: calendar)
        expect(day.buckets.count == 2, "Day contains one bar per activity")
        expect(day.plannedMinutes == 90 && day.loggedMinutes == 60, "Day totals exclude other days")
        expect(day.completedCount == 1, "Planned learning does not count as completed")
        expect(abs(day.fraction - 2.0 / 3.0) < 0.001, "Completion reflects learning minutes")
        expect(day.buckets[0].isComplete && !day.buckets[1].isComplete, "Each activity bar retains completion")
        expect(Set(day.buckets.map(\.id)).count == 2, "Activities have stable distinct selection IDs")

        let week = ProgressTimeline(plan: plan, range: .week, selectedDate: tuesday, calendar: calendar)
        expect(week.buckets.count == 7, "Week includes seven dates")
        expect(week.buckets.first?.label == "Mon" && week.buckets.last?.label == "Sun", "Week follows saved Monday-based plan")
        expect(week.plannedMinutes == 225 && week.loggedMinutes == 150, "Week includes both sides of month boundary")
        expect(week.buckets[2].plannedMinutes == 0, "Unplanned day stays empty")

        let october = ProgressTimeline(plan: plan, range: .month, selectedDate: monday, calendar: calendar)
        expect(october.buckets.count == 31, "Month renders every calendar day")
        expect(october.plannedMinutes == 135 && october.loggedMinutes == 60, "October excludes November activity")
        expect(october.buckets[0].activities.isEmpty, "Month never invents learning outside saved dates")
        let nextMonth = ProgressTimeline(plan: plan, range: .month, selectedDate: november, calendar: calendar)
        expect(nextMonth.buckets.count == 30 && nextMonth.loggedMinutes == 90, "November includes only its own dates")
        expect(nextMonth.fraction == 1, "Fully completed month reaches 100 percent")

        let rest = ProgressTimeline(plan: plan, range: .day, selectedDate: date(2026, 10, 28), calendar: calendar)
        expect(rest.buckets.isEmpty && rest.fraction == 0, "Empty day has zero completion without division by zero")
        let leapMonth = ProgressTimeline(plan: plan, range: .month, selectedDate: date(2028, 2, 1), calendar: calendar)
        expect(leapMonth.buckets.count == 29, "Leap February includes 29 days")
        expect(leapMonth.activities.isEmpty && leapMonth.fraction == 0, "Empty month has no fabricated totals")

        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let dstMonth = ProgressTimeline(plan: plan, range: .month, selectedDate: date(2026, 3, 1), calendar: calendar)
        expect(dstMonth.buckets.count == 31, "Daylight-saving transition does not lose calendar dates")
        expect(Set(dstMonth.buckets.map(\.id)).count == 31, "Day IDs remain unique across daylight saving")
        print("Passed \(checks) progress timeline checks")
    }
}
