import Foundation

@main struct FilterChecks {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
        let sunday = date("2026-11-01T08:00:00Z")
        let monday = date("2026-11-02T08:00:00Z")
        let saturday = date("2026-11-07T08:00:00Z")
        var checks = 0
        func expect(_ result: Bool, _ message: String) { precondition(result, message); checks += 1 }
        expect(GatherTimeFilter.today.includes(start: sunday, end: sunday.addingTimeInterval(3600), now: sunday, calendar: calendar), "Today includes current event")
        expect(!GatherTimeFilter.today.includes(start: monday, end: monday.addingTimeInterval(3600), now: sunday, calendar: calendar), "Today excludes tomorrow")
        expect(GatherTimeFilter.tomorrow.includes(start: monday, end: monday.addingTimeInterval(3600), now: sunday, calendar: calendar), "Tomorrow uses calendar day")
        expect(GatherTimeFilter.tomorrow.includes(start: date("2026-11-01T01:00:00Z"), end: sunday, now: date("2026-10-31T23:30:00Z"), calendar: calendar), "Tomorrow crosses month boundaries")
        expect(GatherTimeFilter.weekend.includes(start: sunday, end: sunday.addingTimeInterval(3600), now: sunday, calendar: calendar), "Sunday remains part of this weekend")
        expect(!GatherTimeFilter.weekend.includes(start: saturday, end: saturday.addingTimeInterval(3600), now: sunday, calendar: calendar), "Current weekend excludes next Saturday")
        expect(GatherTimeFilter.weekend.includes(start: saturday, end: saturday.addingTimeInterval(3600), now: monday, calendar: calendar), "Weekday selects next weekend")
        expect(!GatherTimeFilter.upcoming.includes(start: sunday.addingTimeInterval(-7200), end: sunday.addingTimeInterval(-3600), now: sunday, calendar: calendar), "Finished events excluded")
        var event = Event(title: "Little Scientists", category: "Science", kind: .workshop,
            start: saturday, end: saturday.addingTimeInterval(3600), host: "Curious Minds", locality: "Potheri",
            location: "Community hall", ages: "6–10", about: "Experiments", symbol: "flask")
        var filter = GatherFeedFilter()
        expect(filter.includes(event, now: sunday, calendar: calendar), "Default includes upcoming events")
        for query in ["  scientists  ", "CURIOUS", "science", "Potheri"] {
            filter.query = query
            expect(filter.includes(event, now: sunday, calendar: calendar), "Search matches trimmed title, host, category and place")
        }
        filter.query = "Nothing like this"
        expect(!filter.includes(event, now: sunday, calendar: calendar), "Search excludes mismatches")
        filter.query = ""; filter.onlineOnly = true
        expect(!filter.includes(event, now: sunday, calendar: calendar), "Online filter excludes physical events")
        event.mode = .online
        expect(filter.includes(event, now: sunday, calendar: calendar), "Online filter includes online events")
        filter.onlineOnly = false; filter.freeOnly = true; event.price = 200
        expect(!filter.includes(event, now: sunday, calendar: calendar), "Paid events excluded when free only")
        event.price = nil
        expect(filter.includes(event, now: sunday, calendar: calendar), "Free events included")
        filter.category = .yours
        expect(!filter.includes(event, now: sunday, calendar: calendar), "Your events excludes unregistered events")
        event.isRegistered = true
        expect(filter.includes(event, now: sunday, calendar: calendar), "Your tickets remain discoverable")
        event.isRegistered = false; event.isHostedByMe = true
        expect(filter.includes(event, now: sunday, calendar: calendar), "Your hosted events remain discoverable")
        filter.category = .workshops
        expect(filter.includes(event, now: sunday, calendar: calendar), "Workshop category uses event kind")
        filter.category = .social
        expect(!filter.includes(event, now: sunday, calendar: calendar), "Social excludes workshops")
        filter.category = .science
        expect(filter.includes(event, now: sunday, calendar: calendar), "Subject category uses real category")
        print("Passed \(checks) Gather filter checks")
    }
}
