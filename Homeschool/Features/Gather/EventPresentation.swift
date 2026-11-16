import Foundation

/// Display text and links derived from an `Event` for the Gather screens.
extension Event {
    /// The event's web link when it is an online event and its location is a valid http(s) address.
    var onlineURL: URL? {
        guard mode == .online, let url = URL(string: location.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return nil }
        return url
    }

    /// Upper-case feed date such as "TODAY • 10:00 AM" or "TOMORROW • …", relative to `now`.
    func feedDateText(now: Date = .now, calendar: Calendar = .current) -> String {
        let day: String
        if calendar.isDate(start, inSameDayAs: now) {
            day = "TODAY"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(start, inSameDayAs: tomorrow) {
            day = "TOMORROW"
        } else {
            var style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
            style.calendar = calendar
            style.timeZone = calendar.timeZone
            day = start.formatted(style).uppercased()
        }
        return "\(day) • \(timeWithZone)"
    }

    var timeZoneLabel: String { TimeZone.current.abbreviation(for: start) ?? TimeZone.current.identifier }
    var timeWithZone: String { "\(start.formatted(date: .omitted, time: .shortened)) \(timeZoneLabel)" }
    var timeRangeWithZone: String {
        "\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened)) \(timeZoneLabel)"
    }
    var addressDetailText: String {
        var parts = [locationLines.detail].compactMap { $0 }.filter { !$0.isEmpty }
        for component in [locality, country] where !component.isEmpty {
            if !parts.joined(separator: ", ").localizedCaseInsensitiveContains(component) { parts.append(component) }
        }
        return parts.joined(separator: ", ")
    }
    var fullDateText: String { start.formatted(.dateTime.weekday(.wide).day().month(.wide).year()) }
}
