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
    var unit: String = "subject"
    let options: [SubjectOption]
    var minPick: Int = 0
    var maxPick: Int? = nil
    /// Higher limit that is only valid when the learner registers the full subject ceiling.
    var maxPickAtFullLoad: Int? = nil
    /// Minimum depends on how many subjects the other groups already provide.
    var fillsTotal: Bool = false
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

struct Requirement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let met: Bool
}

enum SubjectKey {
    static func make(_ group: SubjectGroup, _ option: SubjectOption) -> String {
        group.id + "|" + option.name
    }
}

// MARK: - Rule engine

extension LevelCurriculum {
    func isSelected(_ group: SubjectGroup, _ option: SubjectOption, in selected: Set<String>) -> Bool {
        group.locked || selected.contains(SubjectKey.make(group, option))
    }

    func count(in group: SubjectGroup, selected: Set<String>) -> Int {
        group.options.filter { isSelected(group, $0, in: selected) }.count
    }

    /// The same subject listed in two groups only counts once.
    func uniqueTotal(selected: Set<String>) -> Int {
        var names = Set<String>()
        for group in groups {
            for option in group.options where isSelected(group, option, in: selected) {
                names.insert(option.name)
            }
        }
        return names.count
    }

    func effectiveMin(_ group: SubjectGroup, selected: Set<String>) -> Int {
        guard group.fillsTotal else { return group.minPick }
        let others = uniqueTotal(selected: selected) - count(in: group, selected: selected)
        return max(group.minPick, minSubjects - others)
    }

    func allowedMax(_ group: SubjectGroup, selected: Set<String>) -> Int? {
        guard let base = group.maxPick else { return nil }
        if let full = group.maxPickAtFullLoad, let cap = maxSubjects,
           uniqueTotal(selected: selected) == cap {
            return full
        }
        return base
    }

    func isGroupSatisfied(_ group: SubjectGroup, selected: Set<String>) -> Bool {
        let c = count(in: group, selected: selected)
        if c < effectiveMin(group, selected: selected) { return false }
        if let m = allowedMax(group, selected: selected), c > m { return false }
        return true
    }

    func isComplete(selected: Set<String>) -> Bool {
        let total = uniqueTotal(selected: selected)
        if total < minSubjects { return false }
        if let m = maxSubjects, total > m { return false }
        return groups.allSatisfy { isGroupSatisfied($0, selected: selected) }
    }

    func rangeText(for group: SubjectGroup, selected: Set<String>) -> String {
        let minValue = effectiveMin(group, selected: selected)
        var text: String
        if let max = group.maxPick {
            text = minValue == max ? "pick \(max)" : (minValue > 0 ? "pick \(minValue)–\(max)" : "up to \(max)")
        } else if minValue > 0 {
            text = "pick at least \(minValue)"
        } else {
            text = "optional"
        }
        if let full = group.maxPickAtFullLoad, let cap = maxSubjects {
            text += " (\(full) only with \(cap) subjects)"
        }
        return text
    }

    var totalRangeText: String {
        if let m = maxSubjects {
            return m == minSubjects ? "need \(m)" : "need \(minSubjects)–\(m)"
        }
        return "need at least \(minSubjects)"
    }

    func progressText(selected: Set<String>) -> String {
        "\(uniqueTotal(selected: selected)) selected · \(totalRangeText)"
    }

    func requirements(selected: Set<String>) -> [Requirement] {
        var list: [Requirement] = []
        for group in groups {
            if group.locked {
                list.append(Requirement(id: group.id, title: group.title,
                                        detail: "\(group.options.count) added for you", met: true))
            } else if group.minPick > 0 || group.fillsTotal {
                let c = count(in: group, selected: selected)
                list.append(Requirement(id: group.id, title: group.title,
                                        detail: "\(c) chosen · \(rangeText(for: group, selected: selected))",
                                        met: isGroupSatisfied(group, selected: selected)))
            }
        }
        let total = uniqueTotal(selected: selected)
        var totalMet = total >= minSubjects
        if let m = maxSubjects, total > m { totalMet = false }
        list.append(Requirement(id: "total", title: "Total subjects",
                                detail: "\(total) chosen · \(totalRangeText)", met: totalMet))
        return list
    }

    /// What the learner still has to do, or nil when everything is fine.
    func hint(selected: Set<String>) -> String? {
        let total = uniqueTotal(selected: selected)
        for group in groups where !group.locked {
            let c = count(in: group, selected: selected)
            let need = effectiveMin(group, selected: selected)
            if c < need {
                return "Pick at least \(need) \(Curriculum.plural(need, group.unit)) in \(group.title)."
            }
            if let m = allowedMax(group, selected: selected), c > m {
                if let cap = maxSubjects, group.maxPickAtFullLoad != nil {
                    return "\(c) \(Curriculum.plural(c, group.unit)) are only allowed with \(cap) subjects in total. Add subjects or remove one."
                }
                return "Remove \(c - m). Only \(m) \(Curriculum.plural(m, group.unit)) allowed in \(group.title)."
            }
        }
        if total < minSubjects {
            let n = minSubjects - total
            return "Choose \(n) more subject\(n == 1 ? "" : "s") to continue."
        }
        if let m = maxSubjects, total > m {
            let n = total - m
            return "Remove \(n) subject\(n == 1 ? "" : "s"). The maximum is \(m)."
        }
        return nil
    }
}

// MARK: - NIOS data

enum Curriculum {
    static let levels = ["Level A", "Level B", "Level C", "Grade 10", "Grade 12"]

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
                         options: parse(basicLanguages), minPick: 1, maxPick: 2, preselect: ["English"]),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill", note: "Group 3. Pick exactly 1.", unit: "skill",
                         options: parse(["Computer Skills", "Creative Crafts"]),
                         minPick: 1, maxPick: 1, preselect: ["Computer Skills"])
        ])

    private static let levelB = LevelCurriculum(
        level: "Level B", equivalent: "Classes 4–5",
        summary: "4 to 7 subjects. 1 or 2 languages (3 only with 7 subjects), Mathematics and EVS (compulsory) and 1 or 2 skills.",
        minSubjects: 4, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects", note: "Academic group. Both are compulsory.",
                         options: parse(["Mathematics", "Environmental Studies (EVS)"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Group 1. Pick 1 or 2 languages.", unit: "language",
                         options: parse(basicLanguages), minPick: 1, maxPick: 2, maxPickAtFullLoad: 3,
                         preselect: ["English"]),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill", note: "Group 3. Pick 1 or 2 skills.", unit: "skill",
                         options: parse(["Computer Skills", "Cutting & Tailoring", "Basic Agriculture", "Vermicomposting"]),
                         minPick: 1, maxPick: 2, preselect: ["Computer Skills"])
        ])

    private static let levelC = LevelCurriculum(
        level: "Level C", equivalent: "Classes 6–8",
        summary: "5 to 7 subjects. 1 or 2 languages (3 only with 7 subjects), Mathematics, Science and Social Science (compulsory) and 1 or 2 skills.",
        minSubjects: 5, maxSubjects: 7,
        groups: [
            SubjectGroup(id: "core", title: "Mandatory Subjects", note: "Academic group. All three are compulsory.",
                         options: parse(["Mathematics", "Science", "Social Science"]), locked: true),
            SubjectGroup(id: "lang", title: "Language", note: "Group 1. Pick 1 or 2 languages.", unit: "language",
                         options: parse(basicLanguages), minPick: 1, maxPick: 2, maxPickAtFullLoad: 3,
                         preselect: ["English"]),
            SubjectGroup(id: "skill", title: "Pre-Vocational Skill", note: "Group 3. Pick 1 or 2 skills.", unit: "skill",
                         options: parse(["Computer Skills", "Cutting & Tailoring", "Basic Plumbing & Electrical Wiring",
                                         "Vermicomposting", "Yoga & Health"]),
                         minPick: 1, maxPick: 2, preselect: ["Computer Skills"])
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
                                         "Urdu|206", "Gujarati|207", "Sanskrit|208", "Punjabi|209", "Assamese|210",
                                         "Nepali|231", "Odia|232", "Malayalam|233", "Kannada|234", "Arabic|235",
                                         "Persian|236", "Tamil|237"]),
                         minPick: 1, maxPick: 2, preselect: ["English"]),
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
                         minPick: 1, maxPick: 2, preselect: ["English"]),
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
