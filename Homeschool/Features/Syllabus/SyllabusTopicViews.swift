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

/// Topic details, laid out like the activity details on Home.
struct SyllabusTopicSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let topic: SyllabusTopic
    let subject: SyllabusSubject
    let childID: Child.ID
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
    private var customSteps: String? {
        linked.map(\.smallSteps).first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    private var customNotes: String? {
        linked.map(\.notes).first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    private var statusTint: Color { status == .completed ? Color(hex: 0x386553) : Theme.accent }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(subject.name.uppercased())
                    .scaledFont(11, weight: .semibold, maxScale: 1.25)
                    .tracking(0.5).foregroundStyle(Theme.secondary)
                Spacer(minLength: 12)
                Button { dismiss() } label: {
                    Image(systemName: "xmark").scaledFont(17, weight: .medium)
                        .frame(width: 44, height: 44).gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.35))
                }
                .accessibilityLabel("Close topic")
            }
            .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(topic.title).detailTitle()
                        if let chapter {
                            Label("\(chapter.kind == "competency" ? "Area" : "Chapter") \(chapter.number) · \(chapter.title)",
                                  systemImage: "book.closed").bodyText()
                        }
                        Label(status.rawValue, systemImage: status == .completed ? "checkmark.circle.fill" : "circle")
                            .bodyText().foregroundStyle(statusTint)
                    }
                    Text(guide.overview).bodyText().fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 14) {
                        Text(customSteps == nil ? "Try it step by step" : "Your steps").cardTitle()
                        if let customSteps {
                            Text(customSteps).bodyText()
                        } else {
                            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .scaledFont(12, weight: .semibold, maxScale: 1.3)
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 26, height: 26)
                                        .background(Theme.lilac, in: Circle())
                                        .accessibilityHidden(true)
                                    Text(step).bodyText().frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(customNotes == nil ? "What you’ll need" : "Your notes").cardTitle()
                        Text(customNotes ?? guide.materials).bodyText()
                    }
                    if let url = URL(string: topic.sourceURL) {
                        Link(destination: url) {
                            Label("Read the NIOS material", systemImage: "arrow.up.right.square")
                                .scaledFont(15, weight: .semibold, maxScale: 1.25).foregroundStyle(Theme.accent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                Button {
                    _ = state.setSyllabusTopicCompleted(topic, subject: subject, completed: status != .completed, for: childID)
                    dismiss()
                } label: {
                    Label(status == .completed ? "Mark incomplete" : "Mark complete",
                          systemImage: status == .completed ? "arrow.uturn.backward" : "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryHomeschool)

                Button {
                    state.prepareHomeWeek(for: childID)
                    showPlanner = true
                } label: {
                    Label(status == .planned ? "Planned this week" : status == .completed ? "Practise again" : "Plan this topic",
                          systemImage: status == .planned ? "calendar.badge.checkmark" : "plus")
                        .scaledFont(16, weight: .semibold, maxScale: 1.25)
                        .foregroundStyle(status == .planned ? Theme.secondary : Theme.accent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(status == .planned)
            }
            .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 10)
            .background(Theme.background)
        }
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
        .foregroundStyle(Theme.ink).background(Theme.background).buttonStyle(.plain)
        .presentationDragIndicator(.visible)
        .onChange(of: state.child.id) { _, id in if id != childID { dismiss() } }
    }
}
