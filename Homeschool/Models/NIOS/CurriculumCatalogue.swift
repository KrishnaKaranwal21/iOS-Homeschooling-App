import Foundation

enum Curriculum {
    static let levels = ["Level A", "Level B", "Level C", "Grade 10", "Grade 12"]

    /// Names parents recognise: "Secondary" and "Senior Secondary" instead of Grade 10 and Grade 12.
    static func displayName(for level: String) -> String {
        switch level {
        case "Grade 10": return "Secondary"
        case "Grade 12": return "Senior Secondary"
        default:         return level
        }
    }

    static func plural(_ n: Int, _ unit: String) -> String { n == 1 ? unit : unit + "s" }

    static func data(for level: String) -> LevelCurriculum {
        switch level {
        case "Level A": return levelA
        case "Level B": return levelB
        case "Grade 10": return grade10
        case "Grade 12": return grade12
        default: return levelC
        }
    }

    /// "Name|Code" strings -> options (code is optional).
    private static func parse(_ items: [String]) -> [SubjectOption] {
        items.map { item in
            let parts = item.split(separator: "|").map(String.init)
            return SubjectOption(name: parts[0], code: parts.count > 1 ? parts[1] : nil)
        }
    }

    private static let basicLanguages = ["Hindi", "English", "Sanskrit", "Urdu", "Regional language"]

    // MARK: Open Basic Education

    private static let levelA = LevelCurriculum(
        level: "Level A", equivalent: "Classes 1–3",
        summary: "Minimum 4 subjects. 1 or 2 languages, Basic Mathematics and EVS (compulsory) and exactly 1 pre-vocational skill.",
        minSubjects: 4, maxSubjects: 5,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects", note: "Academic group. Both are compulsory.",
                         options: parse(["Basic Mathematics", "Environmental Studies (EVS)"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Group 1. Pick 1 or 2 languages.", unit: "language",
                         options: parse(basicLanguages), minPick: 1, maxPick: 2),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill", note: "Group 3. Pick exactly 1.", unit: "skill",
                         options: parse(["Computer Skills", "Creative Crafts"]),
                         minPick: 1, maxPick: 1)
        ])

    private static let levelB = LevelCurriculum(
        level: "Level B", equivalent: "Classes 4–5",
        summary: "4 to 7 subjects. 1 or 2 languages (3 only with 7 subjects), Mathematics and EVS (compulsory) and 1 or 2 skills.",
        minSubjects: 4, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects", note: "Academic group. Both are compulsory.",
                         options: parse(["Mathematics", "Environmental Studies (EVS)"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Group 1. Pick 1 or 2 languages.", unit: "language",
                         options: parse(basicLanguages), minPick: 1, maxPick: 2, maxPickAtFullLoad: 3),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill", note: "Group 3. Pick 1 or 2 skills.", unit: "skill",
                         options: parse(["Computer Skills", "Cutting & Tailoring", "Basic Agriculture", "Vermicomposting"]),
                         minPick: 1, maxPick: 2)
        ])

    private static let levelC = LevelCurriculum(
        level: "Level C", equivalent: "Classes 6–8",
        summary: "5 to 7 subjects. 1 or 2 languages (3 only with 7 subjects), Mathematics, Science and Social Science (compulsory) and 1 or 2 skills.",
        minSubjects: 5, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects", note: "Academic group. All three are compulsory.",
                         options: parse(["Mathematics", "Science", "Social Science"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Group 1. Pick 1 or 2 languages.", unit: "language",
                         options: parse(basicLanguages), minPick: 1, maxPick: 2, maxPickAtFullLoad: 3),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill", note: "Group 3. Pick 1 or 2 skills.", unit: "skill",
                         options: parse(["Computer Skills", "Cutting & Tailoring", "Basic Plumbing & Electrical Wiring",
                                         "Vermicomposting", "Yoga & Health"]),
                         minPick: 1, maxPick: 2)
        ])

    // MARK: Secondary (Grade 10)

    private static let grade10 = LevelCurriculum(
        level: "Grade 10", equivalent: "Secondary Course",
        summary: "Pass at least 5 subjects, register up to 7. 1 or 2 languages. Group B needs at least 4 subjects with 1 language, or 3 with 2 languages.",
        minSubjects: 5, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "langA", title: "Language (Group A)", note: "Pick 1 or 2 languages. A third would only be an extra paper.",
                         unit: "language",
                         options: parse(["Hindi|201", "English|202", "Bengali|203", "Marathi|204", "Telugu|205",
                                         "Urdu|206", "Gujarati|207", "Sanskrit|209", "Punjabi|210", "Assamese|228",
                                         "Nepali|231", "Odia|233", "Malayalam|232", "Kannada|208", "Arabic|235",
                                         "Persian|236", "Tamil|237"]),
                         minPick: 1, maxPick: 2),
            SubjectGroup(id: "gB", title: "Academic & Vocational Electives (Group B)",
                         note: "At least 4 with 1 language, at least 3 with 2 languages. The 7 subject total caps the rest.",
                         options: parse(["Mathematics|211", "Science & Technology|212", "Social Science|213",
                                         "Economics|214", "Business Studies|215", "Home Science|216",
                                         "Psychology|222", "Indian Culture & Heritage|223", "Painting|225",
                                         "Data Entry Operations|229", "Accountancy|224",
                                         "Bakery & Confectionery|256", "Certificate in Desktop Publishing|217",
                                         "Basic Computing|608", "Yoga|614", "Carpentry", "Solar Energy Technician"]),
                         maxPick: 6, fillsTotal: true)
        ])

    // MARK: Senior Secondary (Grade 12)

    private static let grade12 = LevelCurriculum(
        level: "Grade 12", equivalent: "Senior Secondary Course",
        summary: "Pass at least 5 subjects, register up to 7. 1 or 2 languages, up to 5 free electives, and at most 1 subject from each of Groups C, D, E and F.",
        minSubjects: 5, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "langA", title: "Language (Group A)", note: "Pick 1 or 2 languages.", unit: "language",
                         options: parse(["Hindi|301", "English|302", "Bengali|303", "Tamil|304", "Urdu|306",
                                         "Sanskrit|309", "Punjabi|310"]),
                         minPick: 1, maxPick: 2),
            SubjectGroup(id: "gB", title: "General Electives (Group B)", note: "Free choice, up to 5 subjects.",
                         options: parse(["Mathematics|311", "Home Science|321", "Economics|318",
                                         "Business Studies|319", "Accountancy|320", "Painting|332",
                                         "Environmental Science|333", "Mass Communication|335",
                                         "Data Entry Operations|336", "Tourism|337", "Introduction to Law|338",
                                         "Library & Information Science|339"]),
                         maxPick: 5),
            SubjectGroup(id: "gC", title: "Elective Block 1 (Group C)", note: "Maximum 1 subject.",
                         options: parse(["Physics|312", "History|315", "Environmental Science|333",
                                         "Library & Information Science|339"]), maxPick: 1),
            SubjectGroup(id: "gD", title: "Elective Block 2 (Group D)", note: "Maximum 1 subject.",
                         options: parse(["Chemistry|313", "Political Science|317", "Mass Communication|335",
                                         "Military Studies|374"]), maxPick: 1),
            SubjectGroup(id: "gE", title: "Elective Block 3 (Group E)", note: "Maximum 1 subject.",
                         options: parse(["Biology|314", "Geography|316", "Introduction to Law|338",
                                         "Military History|375"]), maxPick: 1),
            SubjectGroup(id: "gF", title: "Elective Block 4 (Group F)", note: "Maximum 1 subject.",
                         options: parse(["Computer Science|330", "Sociology|331", "Tourism|337",
                                         "Physical Education|373"]), maxPick: 1)
        ])
}
