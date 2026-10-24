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
        return level.isEmpty ? program : "\(program) · \(level)"
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
