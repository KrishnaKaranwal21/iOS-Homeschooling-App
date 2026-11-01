import Foundation
import CoreLocation

@main struct FilterChecks {
    @MainActor static func main() {
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
        let ordered = GatherFeedCategory.ordered(interests: ["Art", "Coding", "Music"])
        expect(ordered.first == .all, "All Events stays first")
        expect(Array(ordered.dropFirst().prefix(3)) == [.art, .coding, .music], "Chosen interests precede general categories")
        expect(Set(ordered).count == GatherFeedCategory.allCases.count, "Categories appear once")
        expect(GatherFeedCategory.ordered(interests: []) == GatherFeedCategory.allCases, "Empty interests preserve a stable order")
        var art = event
        art.title = "Clay & create"; art.category = "Art"; art.start = saturday.addingTimeInterval(7200)
        let personalized = GatherFeedCategory.prioritize([event, art], interests: ["Art"])
        expect(personalized.first?.title == art.title, "Interest matches appear before other events")
        expect(GatherFeedCategory.prioritize([event, art], interests: []).first?.title == event.title, "Without interests dates sort chronologically")
        var birdWatch = event
        birdWatch.category = "Nature"; birdWatch.title = "Backyard Bird Watch"
        expect(GatherFeedCategory.animals.includes(birdWatch), "Animal interest includes bird watching")
        expect(!GatherFeedCategory.space.includes(birdWatch), "Space excludes unrelated nature events")
        event.start = monday
        expect(event.feedDateText(now: sunday, calendar: calendar).hasPrefix("TOMORROW • "), "Feed uses relative tomorrow and a bullet")
        expect(event.feedDateText(now: monday, calendar: calendar).hasPrefix("TODAY • "), "Feed uses relative today")
        expect(event.timeRangeWithZone.contains(event.timeZoneLabel), "Detail time range includes the time zone")
        let locations = EventLocationStore()
        var located = event
        located.mode = .inPerson
        let origin = CLLocation(latitude: 13, longitude: 80)
        expect(locations.distanceText(for: located, from: origin) == nil, "Unknown venue coordinates never produce invented distances")
        located.venueCoordinate = EventCoordinate(latitude: 13, longitude: 80)
        expect(locations.place(for: located)?.isVenue == true, "Host coordinates resolve without a network lookup")
        expect(locations.distanceText(for: located, from: nil) == nil, "Location access is needed for distances")
        expect(locations.distanceText(for: located, from: origin) == "< 0.1 km", "Nearby venue distance is formatted clearly")
        located.venueCoordinate = EventCoordinate(latitude: 13.1, longitude: 80)
        expect(locations.distanceText(for: located, from: origin)?.hasSuffix(" km") == true, "Distances include the unit")
        located.mode = .online
        expect(locations.distanceText(for: located, from: origin) == nil, "Online events never display physical distances")
        var registering = event
        registering.isRegistered = false; registering.registeredCount = 6
        registering.updateRegistration(true)
        expect(registering.registeredCount == 7 && registering.isRegistered, "Attending updates the displayed family count")
        registering.updateRegistration(true)
        expect(registering.registeredCount == 7, "Submitting again never double-counts a family")
        registering.updateRegistration(false)
        expect(registering.registeredCount == 6 && !registering.isRegistered, "Cancellation restores the count")
        registering.updateRegistration(false)
        expect(registering.registeredCount == 6, "Repeated cancellation never decrements twice")
        registering.isRegistered = true; registering.registeredCount = 0
        registering.updateRegistration(false)
        expect(registering.registeredCount == 0, "Legacy registrations never produce negative counts")
        registering.location = "Community Hall\nSRM Nagar, Potheri"
        expect(registering.addressDetailText == "SRM Nagar, Potheri, India", "Venue addresses do not repeat the area")
        expect(Set(GatherFeedCategory.ordered(interests: ["All Events", "Your events"])).count == GatherFeedCategory.allCases.count, "Utility names cannot duplicate categories")
        print("Passed \(checks) Gather filter checks")
    }
}
