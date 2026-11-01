import Foundation

/// Calendar boundaries are evaluated in the family's current time zone.
enum GatherTimeFilter: String, CaseIterable, Identifiable {
    case upcoming = "Upcoming", today = "Today", tomorrow = "Tomorrow", weekend = "Weekend"
    var id: String { rawValue }

    func includes(start: Date, end: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard end >= now else { return false }
        switch self {
        case .upcoming: return true
        case .today: return calendar.isDate(start, inSameDayAs: now)
        case .tomorrow:
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return false }
            return calendar.isDate(start, inSameDayAs: tomorrow)
        case .weekend:
            // Include the remaining part of this weekend when today is Saturday or Sunday.
            let interval = calendar.dateIntervalOfWeekend(containing: now)
                ?? calendar.nextWeekend(startingAfter: now)
            guard let interval else { return false }
            return interval.contains(start)
        }
    }
}

enum GatherFeedCategory: String, CaseIterable, Identifiable {
    case all = "All Events", workshops = "Workshops", yours = "Your events"
    case social = "Social Activities", science = "Science", art = "Art", coding = "Coding", nature = "Nature", habit = "Habit"
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .all: "✨"
        case .workshops: "🧪"
        case .yours: "🗓️"
        case .social: "🎉"
        case .science: "🔬"
        case .art: "🎨"
        case .coding: "🧩"
        case .nature: "🌱"
        case .habit: "🌤️"
        }
    }
    func includes(_ event: Event) -> Bool {
        switch self {
        case .all: true
        case .workshops: event.kind == .workshop
        case .yours: event.isRegistered || event.isHostedByMe
        case .social: event.kind == .gathering
        default: event.category == rawValue
        }
    }
}

struct GatherFeedFilter: Equatable {
    var query = ""
    var time = GatherTimeFilter.upcoming
    var category = GatherFeedCategory.all
    var freeOnly = false
    var onlineOnly = false

    func includes(_ event: Event, now: Date = .now, calendar: Calendar = .current) -> Bool {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchable = [event.title, event.host, event.category, event.locality].joined(separator: " ")
        return time.includes(start: event.start, end: event.end, now: now, calendar: calendar)
            && category.includes(event)
            && (!freeOnly || event.isFree)
            && (!onlineOnly || event.mode == .online)
            && (search.isEmpty || searchable.localizedCaseInsensitiveContains(search))
    }
}
