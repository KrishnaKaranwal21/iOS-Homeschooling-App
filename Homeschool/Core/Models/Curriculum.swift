import Foundation

struct SubjectOption: Identifiable, Hashable {
    let name: String
    var code: String? = nil
    var id: String { name }
}

struct SubjectGroup: Identifiable {
    let id: String
    let title: String
    var note: String? = nil
    let options: [SubjectOption]
    var minPick: Int = 0
    var maxPick: Int? = nil
    var locked: Bool = false
    var preselect: [String] = []
}

struct LevelCurriculum {
    let level: String
    let equivalent: String
    let summary: String
    let minSubjects: Int
    let maxSubjects: Int?
    let groups: [SubjectGroup]
}

enum SubjectKey {
    static func make(_ group: SubjectGroup, _ option: SubjectOption) -> String {
        group.id + "|" + option.name
    }
}

extension LevelCurriculum {
    func isSelected(_ group: SubjectGroup, _ option: SubjectOption, in selected: Set<String>) -> Bool {
        selected.contains(SubjectKey.make(group, option))
    }

    func count(in group: SubjectGroup, selected: Set<String>) -> Int {
        group.options.filter { isSelected(group, $0, in: selected) }.count
    }

    /// Same subject listed in two groups only counts once.
    func uniqueTotal(selected: Set<String>) -> Int {
        var names = Set<String>()
        for group in groups {
            for option in group.options where isSelected(group, option, in: selected) {
                names.insert(option.name)
            }
        }
        return names.count
    }

    func isComplete(selected: Set<String>) -> Bool {
        let total = uniqueTotal(selected: selected)
        if total < minSubjects { return false }
        if let m = maxSubjects, total > m { return false }
        for group in groups {
            let c = count(in: group, selected: selected)
            if c < group.minPick { return false }
            if let m = group.maxPick, c > m { return false }
        }
        return true
    }

    func progressText(selected: Set<String>) -> String {
        let total = uniqueTotal(selected: selected)
        if let m = maxSubjects {
            return "\(total) selected · \(minSubjects) to \(m) needed"
        }
        return "\(total) selected · minimum \(minSubjects)"
    }
}

enum Curriculum {
    static let levels = ["Level A", "Level B", "Level C", "Grade 10", "Grade 12"]

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
        summary: "4 to 5 subjects. At least one language, plus Basic Mathematics and Environmental Studies (EVS), with computer skills and creative crafts.",
        minSubjects: 4, maxSubjects: 5,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects",
                         options: parse(["Basic Mathematics", "Environmental Studies (EVS)"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Choose at least 1",
                         options: parse(basicLanguages), minPick: 1, preselect: ["English"]),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill",
                         options: parse(["Computer Skills", "Creative Crafts"]), preselect: ["Computer Skills"])
        ])

    private static let levelB = LevelCurriculum(
        level: "Level B", equivalent: "Classes 4–5",
        summary: "At least 5 subjects. At least one language, plus Mathematics and Environmental Studies (EVS), with pre-vocational and skill modules.",
        minSubjects: 5, maxSubjects: nil,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects",
                         options: parse(["Mathematics", "Environmental Studies (EVS)"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Choose at least 1",
                         options: parse(basicLanguages), minPick: 1, preselect: ["English"]),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill",
                         options: parse(["Computer Skills", "Cutting & Tailoring", "Basic Agriculture", "Vermicomposting"]),
                         preselect: ["Computer Skills"])
        ])

    private static let levelC = LevelCurriculum(
        level: "Level C", equivalent: "Classes 6–8",
        summary: "At least 5 subjects with one mandatory language. Core academics are Mathematics, Science and Social Science, with practical pre-vocational tracks.",
        minSubjects: 5, maxSubjects: nil,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects",
                         options: parse(["Mathematics", "Science", "Social Science"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Choose at least 1",
                         options: parse(basicLanguages), minPick: 1, preselect: ["English"]),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill",
                         options: parse(["Computer Skills", "Cutting & Tailoring", "Basic Electrician & Plumbing",
                                         "Vermicomposting", "Yoga & Health"]),
                         preselect: ["Computer Skills"])
        ])

    // MARK: Secondary (Grade 10)

    private static let grade10 = LevelCurriculum(
        level: "Grade 10", equivalent: "Secondary Course",
        summary: "5 to 7 subjects in total, with 1 or 2 languages. You can add up to two extra electives.",
        minSubjects: 5, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "langA", title: "Language (Group A)", note: "Choose 1 or 2",
                         options: parse(["Hindi|201", "English|202", "Bengali|203", "Marathi|204", "Telugu|205",
                                         "Urdu|206", "Gujarati|207", "Sanskrit|208", "Punjabi|209", "Assamese|210",
                                         "Nepali|231", "Odia|232", "Malayalam|233", "Kannada|234", "Arabic|235",
                                         "Persian|236", "Tamil|237"]),
                         minPick: 1, maxPick: 2, preselect: ["English"]),
            SubjectGroup(id: "gB", title: "Academic & Vocational Electives (Group B)",
                         note: "Choose your remaining 3 to 4 subjects (up to 5 with the 7-subject maximum)",
                         options: parse(["Mathematics|211", "Science & Technology|212", "Social Science|213",
                                         "Economics|214", "Business Studies|215", "Home Science|216",
                                         "Psychology|222", "Indian Culture & Heritage|223", "Painting|225",
                                         "Data Entry Operations|229", "Accountancy|224",
                                         "Bakery & Confectionery|256", "Certificate in Desktop Publishing|217",
                                         "Basic Computing|608", "Yoga|614", "Carpentry", "Solar Energy Technician"]))
        ])

    // MARK: Senior Secondary (Grade 12)

    private static let grade12 = LevelCurriculum(
        level: "Grade 12", equivalent: "Senior Secondary Course",
        summary: "5 to 7 subjects in total, with 1 or 2 languages. Only one subject from each of Groups C, D, E and F.",
        minSubjects: 5, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "langA", title: "Language (Group A)", note: "Choose 1 or 2",
                         options: parse(["Hindi|301", "English|302", "Bengali|303", "Tamil|304", "Urdu|306",
                                         "Sanskrit|309", "Punjabi|310"]),
                         minPick: 1, maxPick: 2, preselect: ["English"]),
            SubjectGroup(id: "gB", title: "General Electives (Group B)", note: "No group limit",
                         options: parse(["Mathematics|311", "Home Science|321", "Economics|318",
                                         "Business Studies|319", "Accountancy|320", "Painting|332",
                                         "Environmental Science|333", "Mass Communication|335",
                                         "Data Entry Operations|336", "Tourism|337", "Introduction to Law|338",
                                         "Library & Information Science|339"])),
            SubjectGroup(id: "gC", title: "Elective Block 1 (Group C)", note: "Maximum 1 subject",
                         options: parse(["Physics|312", "History|315", "Library & Information Science|339"]), maxPick: 1),
            SubjectGroup(id: "gD", title: "Elective Block 2 (Group D)", note: "Maximum 1 subject",
                         options: parse(["Chemistry|313", "Political Science|317", "Mass Communication|335"]), maxPick: 1),
            SubjectGroup(id: "gE", title: "Elective Block 3 (Group E)", note: "Maximum 1 subject",
                         options: parse(["Biology|314", "Geography|316", "Introduction to Law|338"]), maxPick: 1),
            SubjectGroup(id: "gF", title: "Elective Block 4 (Group F)", note: "Maximum 1 subject",
                         options: parse(["Computer Science|330", "Sociology|331", "Tourism|337"]), maxPick: 1)
        ])
}
