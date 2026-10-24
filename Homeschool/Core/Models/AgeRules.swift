import Foundation

/// NIOS minimum-age rules, plus the level a child of a given age usually studies at.
/// If NIOS changes its rules, edit the table below. Nothing else needs to change.
enum AgeRules {
    struct Rule {
        /// Matches the names in `Curriculum.levels`.
        let level: String
        /// Class equivalency shown to parents.
        let grade: String
        let minimumAge: Int
        /// The age is counted on this date of the admission year.
        let cutoffMonth: Int
        let cutoffDay: Int
    }

    static let rules: [Rule] = [
        // OBE levels: age as of March 31 of the admission year.
        Rule(level: "Level A", grade: "Classes 1–3", minimumAge: 7,  cutoffMonth: 3, cutoffDay: 31),
        Rule(level: "Level B", grade: "Classes 4–5", minimumAge: 9,  cutoffMonth: 3, cutoffDay: 31),
        Rule(level: "Level C", grade: "Classes 6–8", minimumAge: 12, cutoffMonth: 3, cutoffDay: 31),
        // Secondary / Senior Secondary: age as of the registration cut-off (31 July, Block 1).
        Rule(level: "Grade 10", grade: "Class 10", minimumAge: 14, cutoffMonth: 7, cutoffDay: 31),
        Rule(level: "Grade 12", grade: "Class 12", minimumAge: 15, cutoffMonth: 7, cutoffDay: 31)
    ]

    static func rule(for level: String) -> Rule? {
        rules.first { $0.level == level }
    }

    /// Completed years between two dates (never negative).
    static func age(of birthDate: Date, on date: Date) -> Int {
        max(Calendar.current.dateComponents([.year], from: birthDate, to: date).year ?? 0, 0)
    }

    /// The level a child of this age usually studies at. Parents can change it.
    static func suggestedLevel(for birthDate: Date, today: Date = Date()) -> String {
        switch age(of: birthDate, on: today) {
        case ..<9:     return "Level A"
        case 9..<12:   return "Level B"
        case 12..<14:  return "Level C"
        case 14..<17:  return "Grade 10"
        default:       return "Grade 12"
        }
    }

    /// Friendly note: which level children of this age are usually in.
    static func typicalNote(for birthDate: Date, today: Date = Date()) -> String {
        let years = age(of: birthDate, on: today)
        guard years >= 7, let rule = rule(for: suggestedLevel(for: birthDate, today: today)) else {
            return "NIOS starts at Level A (Classes 1–3) for children aged 7 and above."
        }
        return "At age \(years), children usually study at \(rule.level) (\(rule.grade)) in NIOS."
    }

    /// Red heads-up when the chosen level has a higher minimum age. Only informs, never blocks.
    static func minimumAgeWarning(level: String, birthDate: Date, name: String, today: Date = Date()) -> String? {
        let calendar = Calendar.current
        guard let rule = rule(for: level),
              let cutoff = calendar.date(from: DateComponents(year: calendar.component(.year, from: today),
                                                              month: rule.cutoffMonth,
                                                              day: rule.cutoffDay))
        else { return nil }

        let ageAtCutoff = age(of: birthDate, on: cutoff)
        guard ageAtCutoff < rule.minimumAge else { return nil }

        let who = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let child = who.isEmpty ? "Your child" : who
        let date = cutoff.formatted(.dateTime.day().month(.wide).year())
        return "Minimum age for \(rule.level) (\(rule.grade)) is \(rule.minimumAge) years, counted on \(date). "
            + "\(child) would be \(ageAtCutoff) then. You can still choose this level if you wish."
    }
}
