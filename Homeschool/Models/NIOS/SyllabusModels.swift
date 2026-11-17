import Foundation

// MARK: - SyllabusTopic

struct SyllabusTopic: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let sourceURL: String
}

// MARK: - SyllabusChapter

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

// MARK: - SyllabusSubject

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

// MARK: - SyllabusCatalogue

struct SyllabusCatalogue: Codable {
    let checkedOn: String
    let subjects: [SyllabusSubject]
}

// MARK: - SyllabusTopicStatus

enum SyllabusTopicStatus: String, CaseIterable {
    case notStarted = "Not started"
    case planned = "This week"
    case completed = "Completed"
}

// MARK: - SyllabusProgress

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
