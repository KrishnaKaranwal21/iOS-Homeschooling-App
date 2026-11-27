import SwiftUI

struct SyllabusTopicRow: View {
    let topic: SyllabusTopic
    let ink: Color
    let status: SyllabusTopicStatus
    let onToggle: () -> Void
    let onOpen: () -> Void

    private var done: Bool { status == .completed }
    private var tint: Color {
        switch status {
        case .completed: Color(hex: 0x386553)
        case .planned: Theme.accent
        case .notStarted: ink.opacity(0.55)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // The circle ticks the topic; the rest of the row opens its details.
            Button(action: onToggle) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(tint)
                    .frame(width: 54, height: 54)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(done ? "Mark \(topic.title) incomplete" : "Mark \(topic.title) complete")

            Button(action: onOpen) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(topic.title).scaledFont(15, weight: .semibold, maxScale: 1.3)
                            .foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                        if status != .notStarted {
                            Text(status.rawValue).scaledFont(12, weight: .medium, maxScale: 1.25).foregroundStyle(tint)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14).padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens topic details")
        }
        .background(Theme.surface.opacity(0.78), in: .rect(cornerRadius: 17))
    }
}

/// Topic details. This uses the shared `TaskDetailSheet`, so a topic opens the same page as a task on Home or Progress;
/// this wrapper only gathers the topic's content and handles ticking it off and planning it.
struct SyllabusTopicSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let topic: SyllabusTopic
    let subject: SyllabusSubject
    let childID: Child.ID
    /// Matches the subject's colour on the syllabus page it was opened from.
    var paletteIndex = 0
    @State private var showPlanner = false
    @State private var saveError = false

    private var progress: SyllabusProgress { SyllabusProgress(plans: state.learningPlans(for: childID)) }
    private var status: SyllabusTopicStatus { progress.status(of: topic, subject: subject) }
    private var linked: [WeekActivity] { progress.activities(for: topic, subject: subject) }
    private var currentWeek: WeeklyPlan? { state.weeklyPlans[childID.uuidString] }
    private var chapter: SyllabusChapter? { subject.chapters.first { $0.topics.contains(topic) } }
    private var guide: ActivityGuide {
        .suggested(for: linked.first ?? WeekActivity(title: topic.title, subject: subject.name, date: .now, syllabusTopicID: topic.id))
    }
    private var customSteps: [String] {
        linked.lazy.map { TaskDetailContent.lines(of: $0.smallSteps) }.first { !$0.isEmpty } ?? []
    }
    private var customNotes: String? {
        linked.map(\.notes).first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var content: TaskDetailContent {
        let chapterText = chapter.map {
            "\($0.kind == "competency" ? "Area" : "Chapter") \($0.number) · \($0.title)"
        }
        let symbol: String
        switch status {
        case .completed: symbol = "checkmark"
        case .planned: symbol = "calendar"
        case .notStarted: symbol = "circle.dashed"
        }
        return TaskDetailContent(
            subject: subject.name, title: topic.title, detail: chapterText,
            statusText: status.rawValue, statusSymbol: symbol, isDone: status == .completed,
            minutes: linked.first?.minutes, helpMinutes: linked.first?.helpMinutes,
            overview: guide.overview,
            stepsTitle: customSteps.isEmpty ? "Try it step by step" : "Your steps",
            steps: customSteps.isEmpty ? guide.steps : customSteps,
            materialsTitle: customNotes == nil ? "What you’ll need" : "Your notes",
            materials: customNotes ?? guide.materials,
            materialsSymbol: customNotes == nil ? "backpack" : "note.text",
            paletteIndex: paletteIndex,
            link: URL(string: topic.sourceURL), linkTitle: "Read the NIOS material")
    }

    var body: some View {
        TaskDetailSheet(
            content: content,
            secondary: TaskDetailAction(
                title: status == .planned ? "Planned this week" : status == .completed ? "Practise again" : "Plan this topic",
                systemImage: status == .planned ? "calendar.badge.checkmark" : "plus",
                isDisabled: status == .planned
            ) {
                state.prepareHomeWeek(for: childID)
                showPlanner = true
            },
            onToggle: {
                _ = state.setSyllabusTopicCompleted(topic, subject: subject, completed: status != .completed, for: childID)
            })
        .sheet(isPresented: $showPlanner) {
            if let week = currentWeek {
                let date = max(week.weekStart, min(Calendar.current.startOfDay(for: .now), week.weekEnd))
                WeekTaskSheet(activity: WeekActivity(title: topic.title, subject: subject.name, date: date,
                              syllabusTopicID: topic.id), week: week, isEditing: false) { activity in
                    guard state.child.id == childID, var latest = currentWeek,
                          latest.weekStart == week.weekStart else { saveError = true; return }
                    latest.add(activity)
                    state.saveWeek(latest, for: childID)
                }
            }
        }
        .alert("The week changed", isPresented: $saveError) {
            Button("OK", role: .cancel) { }
        } message: { Text("Open the planner again to add this topic to the current week.") }
        .presentationDragIndicator(.visible)
        .onChange(of: state.child.id) { _, id in if id != childID { dismiss() } }
    }
}
