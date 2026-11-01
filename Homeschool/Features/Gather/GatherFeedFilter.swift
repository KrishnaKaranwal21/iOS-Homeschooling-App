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
    case animals = "Animals", music = "Music", space = "Space", sports = "Sports", reading = "Reading"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .all: "sparkles"
        case .workshops: "hammer"
        case .yours: "calendar.badge.checkmark"
        case .social: "person.2"
        case .science: "flask"
        case .art: "paintpalette"
        case .coding: "chevron.left.forwardslash.chevron.right"
        case .nature: "leaf"
        case .habit: "arrow.triangle.2.circlepath"
        case .animals: "pawprint"
        case .music: "music.note"
        case .space: "moon.stars"
        case .sports: "figure.run"
        case .reading: "book"
        }
    }

    static func ordered(interests: Set<String>) -> [Self] {
        let selected = allCases.filter { ![Self.all, .workshops, .yours, .social].contains($0) && interests.contains($0.rawValue) }
        return [.all] + selected + allCases.filter { $0 != .all && !selected.contains($0) }
    }

    static func prioritize(_ events: [Event], interests: Set<String>) -> [Event] {
        let selected = allCases.filter { ![Self.all, .workshops, .yours, .social].contains($0) && interests.contains($0.rawValue) }
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
        case .all: return true
        case .workshops: return event.kind == .workshop
        case .yours: return event.isRegistered || event.isHostedByMe
        case .social: return event.kind == .gathering
        case .animals:
            return event.category == rawValue || matches(event, words: ["animal", "bird", "wildlife", "pet "])
        case .space:
            return event.category == rawValue || matches(event, words: ["astronomy", "space", "stargaz", "planet"])
        default: return event.category == rawValue
        }
    }

    private func matches(_ event: Event, words: [String]) -> Bool {
        let text = "\(event.title) \(event.about)"
        return words.contains { text.localizedCaseInsensitiveContains($0) }
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
