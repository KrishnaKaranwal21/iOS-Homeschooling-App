import Foundation

struct Child: Equatable {
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
    static let empty = Child(name: "", curriculum: "NIOS", level: "", birthDate: nil,
                             interests: [], learningDays: ["Mon", "Tue", "Thu", "Fri"],
                             hoursPerDay: 4, supportHours: 2)

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
