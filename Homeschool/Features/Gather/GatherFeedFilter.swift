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
    case explore = "Explore", yours = "Your events"
    case art = "Art", nature = "Nature", music = "Music", sports = "Sports", study = "Study"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .explore: "sparkles"
        case .yours: "calendar.badge.checkmark"
        case .art: "paintpalette"
        case .nature: "leaf"
        case .music: "music.note"
        case .sports: "figure.run"
        case .study: "book"
        }
    }

    private static let utility: [Self] = [.explore, .yours]

    /// The subject categories a child's interests point to. Coding, Space, Reading and similar interests fall under Study.
    private static func selected(interests: Set<String>) -> [Self] {
        let mapped = Set(interests.map { Self(rawValue: Event.normalized($0)) }.compactMap { $0 })
        return allCases.filter { !utility.contains($0) && mapped.contains($0) }
    }

    /// "Explore" and "Your events" always come first, then the child's interests, then the rest.
    static func ordered(interests: Set<String>) -> [Self] {
        let selected = selected(interests: interests)
        return utility + selected + allCases.filter { !utility.contains($0) && !selected.contains($0) }
    }

    static func prioritize(_ events: [Event], interests: Set<String>) -> [Event] {
        let selected = selected(interests: interests)
        return events.sorted { lhs, rhs in
            let left = selected.contains { $0.includes(lhs) }
            let right = selected.contains { $0.includes(rhs) }
            if left != right { return left }
            if lhs.start != rhs.start { return lhs.start < rhs.start }
            return lhs.storageKey < rhs.storageKey
        }
    }

    func includes(_ event: Event) -> Bool {
        switch self {
        // Explore is for finding new events: ones you already host or attend live under "Your events".
        case .explore: return !(event.isRegistered || event.isHostedByMe)
        case .yours: return event.isRegistered || event.isHostedByMe
        default: return event.normalizedCategory == rawValue
        }
    }
}

struct GatherFeedFilter: Equatable {
    var query = ""
    var time = GatherTimeFilter.upcoming
    var category = GatherFeedCategory.explore
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
