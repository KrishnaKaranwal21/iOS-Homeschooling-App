import Foundation

struct Child: Equatable, Identifiable, Codable {
    var id = UUID()
    var name: String
    var curriculum: String
    var level: String
    var birthDate: Date?
    var interests: Set<String>
    var learningDays: Set<String>
    var hoursPerDay: Int
    var supportHours: Int
    /// Keys look like "groupId|Subject name" (see SubjectKey).
    var selectedSubjects: Set<String> = []
    /// true = "Flexible order", false = "Set times".
    var flexibleOrder: Bool = true
    /// true once the parent picks a level by hand, so a new date of birth no longer changes it.
    var levelChosenManually: Bool = false

    // The fields below are optional so children saved by earlier versions still load.
    /// The id of the exam window the family registered for (see `ExamCalendar`).
    var examRegisteredSession: String? = nil
    var examRemindersSaved: Bool? = nil

    static let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    /// Blank profile used when onboarding starts: nothing is pre-filled.
    /// A new value every time, so each child gets their own id.
    static var empty: Child {
        Child(name: "", curriculum: "NIOS", level: "", birthDate: nil,
              interests: [], learningDays: ["Mon", "Tue", "Thu", "Fri"],
              hoursPerDay: 4, supportHours: 2)
    }

    /// Sample data for previews only.
    static let sample = Child(name: "Maya", curriculum: "NIOS", level: "Level C",
                              birthDate: Date(timeIntervalSince1970: 1_368_576_000),
                              interests: ["Coding", "Art"], learningDays: ["Mon", "Tue", "Thu", "Fri"],
                              hoursPerDay: 4, supportHours: 2)

    var isBasicsComplete: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !level.isEmpty
            && birthDate != nil
    }
}

extension Child {
    /// "NIOS OBE · Level C" for the OBE levels, otherwise "NIOS · Grade 10".
    var programmeText: String {
        let obeLevels = ["Level A", "Level B", "Level C"]
        let program = obeLevels.contains(level) ? "\(curriculum) OBE" : curriculum
        return level.isEmpty ? program : "\(program) · \(Curriculum.displayName(for: level))"
    }

    /// The next exam registration window for this child's level. `nil` for OBE, which has no common date.
    var examWindow: ExamWindow? { ExamCalendar.nextWindow(for: level) }

    /// Whether the family has registered this child for the next exams.
    var isExamRegistered: Bool {
        guard let window = examWindow else { return false }
        return examRegisteredSession == window.id
    }

    var examRemindersOn: Bool {
        get { examRemindersSaved ?? false }
        set { examRemindersSaved = newValue }
    }

    /// Whole days from today to the last date. Negative once it has passed.
    var daysUntilExamDeadline: Int? {
        guard let window = examWindow else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                       to: calendar.startOfDay(for: window.lastDate)).day
    }

    /// True when the child isn't registered and the last date is within a month.
    var examNeedsAttention: Bool {
        guard !isExamRegistered, let days = daysUntilExamDeadline else { return false }
        return (0...30).contains(days)
    }

    /// Names of the chosen subjects, taken from keys like "groupId|Subject name".
    var subjectNames: [String] {
        selectedSubjects.compactMap { $0.split(separator: "|", omittingEmptySubsequences: false).last.map(String.init) }
            .sorted()
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Your child" : trimmed
    }
}
