import Foundation

struct Child: Equatable {
    var name: String
    var curriculum: String
    var level: String
    var birthDate: Date
    var interests: Set<String>
    var learningDays: Set<String>
    var hoursPerDay: Int
    var supportHours: Int
    /// Keys look like "groupId|Subject name" (see SubjectKey).
    var selectedSubjects: Set<String> = []

    static let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
    static let sample = Child(name: "Maya", curriculum: "NIOS", level: "Level C",
                              birthDate: Date(timeIntervalSince1970: 1_368_576_000),
                              interests: ["Coding", "Art"], learningDays: ["Mon", "Tue", "Thu", "Fri"],
                              hoursPerDay: 4, supportHours: 2)
}
