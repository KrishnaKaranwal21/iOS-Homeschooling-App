import Foundation

struct SyllabusTopic: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let sourceURL: String
}

struct SyllabusChapter: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let number: String
    let sourceURL: String
    let topics: [SyllabusTopic]
    var kind: String? = nil
    var module: String? = nil
    var isOptional: Bool? = nil
}

struct SyllabusSubject: Identifiable, Codable, Hashable {
    let id: String
    let level: String
    let name: String
    let code: String?
    let sourceURL: String
    let sourceTitle: String
    let edition: String
    /// 'outline' is a verified model curriculum; 'lessons' is an official study-material index.
    let coverage: String
    let note: String?
    let chapters: [SyllabusChapter]
    var topics: [SyllabusTopic] { chapters.flatMap(\.topics) }
    var hasOutline: Bool { !topics.isEmpty }
    /// Every to-do the planner generates for this subject comes from these topics, in syllabus order.
    /// Official lesson indexes and published NIOS outlines both qualify; optional modules need a parent's choice
    /// before scheduling, and source-only subjects have no verified topics, so nothing is invented for them.
    var planningTopics: [SyllabusTopic] {
        guard coverage == "lessons" || coverage == "outline" else { return [] }
        return chapters.filter { $0.isOptional != true }.flatMap(\.topics)
    }
}

struct SyllabusCatalogue: Codable {
    let checkedOn: String
    let subjects: [SyllabusSubject]
}

enum SyllabusTopicStatus: String, CaseIterable {
    case notStarted = "Not started"
    case planned = "This week"
    case completed = "Completed"
}

/// Topic progress is evidence from one child's saved activities, never inferred from a subject total.
struct SyllabusProgress {
    private let activitiesByTopic: [String: [WeekActivity]]
    let weekStart: Date
    private let weekEnd: Date

    init(plans: [WeeklyPlan], now: Date = .now, calendar: Calendar = .current) {
        var seen: Set<WeekActivity.ID> = []
        // The caller supplies the active plan first; a stale archived occurrence must not override it.
        let activities = plans.flatMap(\.activities).filter { seen.insert($0.id).inserted }
        activitiesByTopic = Dictionary(grouping: activities.filter { $0.syllabusTopicID != nil }, by: { $0.syllabusTopicID! })
        let today = calendar.startOfDay(for: now)
        weekStart = calendar.date(byAdding: .day, value: -((calendar.component(.weekday, from: today) + 5) % 7), to: today)!
        weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
    }

    func activities(for topic: SyllabusTopic, subject: SyllabusSubject) -> [WeekActivity] {
        (activitiesByTopic[topic.id] ?? []).filter {
            NIOSSyllabus.subjectKey($0.subject) == NIOSSyllabus.subjectKey(subject.name)
        }.sorted { $0.date < $1.date }
    }

    func status(of topic: SyllabusTopic, subject: SyllabusSubject) -> SyllabusTopicStatus {
        let linked = activities(for: topic, subject: subject)
        if linked.contains(where: \.isDone) { return .completed }
        if linked.contains(where: { !$0.isDone && $0.date >= weekStart && $0.date < weekEnd }) { return .planned }
        return .notStarted
    }

    func count(_ status: SyllabusTopicStatus, in subject: SyllabusSubject) -> Int {
        subject.topics.filter { self.status(of: $0, subject: subject) == status }.count
    }
}

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
