import Foundation

/// The offline catalogue is curated from official NIOS curriculum and study-material sources.
enum NIOSSyllabus {
    static let catalogue: SyllabusCatalogue = {
        guard let url = Bundle.main.url(forResource: "NIOSSyllabus", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalogue = try? JSONDecoder().decode(SyllabusCatalogue.self, from: data) else {
            return SyllabusCatalogue(checkedOn: "", subjects: [])
        }
        return catalogue
    }()

    static func canonicalLevel(_ level: String) -> String? {
        let value = level.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case "level a", "a", "class 1", "class 2", "class 3", "grade 1", "grade 2", "grade 3": return "Level A"
        case "level b", "b", "class 4", "class 5", "grade 4", "grade 5": return "Level B"
        case "level c", "c", "class 6", "class 7", "class 8", "grade 6", "grade 7", "grade 8": return "Level C"
        case "grade 10", "secondary", "class 9", "class 10", "grade 9": return "Grade 10"
        case "grade 12", "senior secondary", "class 11", "class 12", "grade 11": return "Grade 12"
        default: return nil
        }
    }

    static func subjectKey(_ name: String) -> String {
        let key = LearningProgress.subjectKey(name)
        switch key {
        case "basic mathematics": return "mathematics"
        case "science and technology", "science & technology": return "science & technology"
        case "environmental studies", "evs", "environmental studies (evs)": return "environmental studies (evs)"
        case "basic computer skills", "basic computing": return key == "basic computing" ? "basic computing" : "computer skills"
        case "physical education and yog", "physical education & yoga": return "physical education"
        default: return key
        }
    }

    static func subject(named name: String, level: String, in catalogue: SyllabusCatalogue = catalogue) -> SyllabusSubject? {
        guard let level = canonicalLevel(level) else { return nil }
        return catalogue.subjects.first { $0.level == level && subjectKey($0.name) == subjectKey(name) }
    }

    static func selectedSubjects(for child: Child, in catalogue: SyllabusCatalogue = catalogue) -> [SyllabusSubject] {
        guard child.curriculum.caseInsensitiveCompare("NIOS") == .orderedSame,
              let level = canonicalLevel(child.level) else { return [] }
        let curriculum = Curriculum.data(for: level)
        var seen: Set<String> = []
        return curriculum.groups.flatMap { group in
            group.options.filter { curriculum.isSelected(group, $0, in: child.selectedSubjects) }.compactMap { option in
                guard seen.insert(subjectKey(option.name)).inserted else { return nil }
                if let source = subject(named: option.name, level: level, in: catalogue) {
                    // Preserve the name selected in setup, even if NIOS uses a longer official title.
                    return SyllabusSubject(id: source.id, level: source.level, name: option.name, code: source.code,
                        sourceURL: source.sourceURL, sourceTitle: source.sourceTitle, edition: source.edition,
                        coverage: source.coverage, note: source.note, chapters: source.chapters)
                }
                return SyllabusSubject(id: "\(level)|\(subjectKey(option.name))", level: level, name: option.name, code: option.code,
                    sourceURL: officialIndex(for: level), sourceTitle: "NIOS course materials", edition: "",
                    coverage: "sourceOnly", note: "A NIOS chapter outline for this choice has not yet been verified. Confirm this subject and its learning material with your accredited agency.", chapters: [])
            }
        }
    }

    static func officialIndex(for level: String) -> String {
        switch canonicalLevel(level) {
        case "Grade 10": return "https://nios.ac.in/online-course-material/secondary-courses.aspx"
        case "Grade 12": return "https://nios.ac.in/online-course-material/sr-secondary-courses.aspx"
        default: return "https://nios.ac.in/departmentsunits/academic/open-basic-education-(obe)/obesimen.aspx"
        }
    }
}
