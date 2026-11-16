import SwiftUI

struct SyllabusDashboardView: View {
    @Environment(AppState.self) private var state
    @State private var showAddChild = false
    private var subjects: [SyllabusSubject] { MockData.syllabus(for: state.child) }
    private var progress: SyllabusProgress { SyllabusProgress(plans: state.learningPlans(for: state.child.id)) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("Syllabus").pageTitle()
                    Spacer()
                    ChildSwitcherMenu(onAddChild: { showAddChild = true }) {
                        HStack(spacing: 7) {
                            AvatarView(initials: String(state.child.displayName.prefix(1)), size: 28)
                            Text(state.child.displayName).font(.subheadline.weight(.medium)).lineLimit(1)
                            Image(systemName: "chevron.down").font(.caption)
                        }
                        .padding(9).gatherGlass(in: Capsule(), tint: Theme.lavender.opacity(0.25))
                    }
                }
                if subjects.isEmpty {
                    ContentUnavailableView("Choose a NIOS level", systemImage: "books.vertical",
                        description: Text("Your child’s level and chosen subjects determine the syllabus. Choose them in your child’s learning profile."))
                } else {
                    ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                        NavigationLink {
                            SyllabusSubjectView(subject: subject, childID: state.child.id, paletteIndex: index)
                        } label: {
                            subjectCard(subject, index: index)
                        }.buttonStyle(.plain)
                    }
                }
                Text("Sources checked 17 Nov 2026 · Available offline")
                    .font(.caption2).foregroundStyle(Theme.secondary)
            }
            .padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .scrollNavigationTitle("Syllabus")
        .toolbarVisibility(.visible, for: .navigationBar)
        .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
        .onAppear { state.prepareHomeWeek(for: state.child.id) }
        .onChange(of: state.child.id) { _, id in state.prepareHomeWeek(for: id) }
    }

    private func subjectCard(_ subject: SyllabusSubject, index: Int) -> some View {
        let palette = SubjectCardPalette.all[index % SubjectCardPalette.all.count]
        let done = progress.count(.completed, in: subject)
        let planned = progress.count(.planned, in: subject)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: SubjectCardPalette.symbol(for: subject.name))
                    .font(.title2).foregroundStyle(palette.ink).frame(width: 46, height: 46)
                    .background(.white.opacity(0.8), in: .rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.name).font(.title3.bold()).multilineTextAlignment(.leading)
                    Text(subject.hasOutline ? "\(subject.chapters.count) \(subject.chapters.allSatisfy { $0.kind == "competency" } ? "learning areas" : "chapters") · \(subject.topics.count) topics" : "Official materials")
                        .font(.caption).foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundStyle(palette.ink)
            }
            if subject.hasOutline {
                ProgressView(value: Double(done), total: Double(max(1, subject.topics.count))).tint(palette.ink)
                HStack {
                    Label("\(done) completed", systemImage: "checkmark.circle")
                    Spacer()
                    Text("\(planned) this week")
                }.font(.caption.weight(.medium)).foregroundStyle(palette.ink)
            } else {
                Text("View the NIOS source and outline availability.").font(.footnote).foregroundStyle(palette.ink)
            }
        }
        .padding(20).background(palette.paper, in: .rect(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(.white, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }
}

private struct SyllabusSubjectView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let subject: SyllabusSubject
    let childID: Child.ID
    /// The same colour the subject card had on the previous page, so the two feel like one thing.
    let paletteIndex: Int
    @State private var filter: SyllabusTopicStatus?
    @State private var expanded: Set<String> = []
    @State private var selectedTopic: SyllabusTopic?
    @State private var tickFeedback = 0
    private var progress: SyllabusProgress { SyllabusProgress(plans: state.learningPlans(for: childID)) }

    private var palette: SubjectCardPalette { SubjectCardPalette.all[paletteIndex % SubjectCardPalette.all.count] }
    /// Every chapter uses its subject's colour, so the whole page reads as one subject.
    private func palette(forChapter chapter: SyllabusChapter) -> SubjectCardPalette { palette }
    private var motion: Animation { reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.83) }

    private func visibleTopics(in chapter: SyllabusChapter) -> [SyllabusTopic] {
        chapter.topics.filter { topic in
            filter == nil || progress.status(of: topic, subject: subject) == filter
        }
    }

    private var metaLine: String {
        [Curriculum.displayName(for: subject.level), subject.code].compactMap { $0 }.joined(separator: " · ")
    }
    private var doneCount: Int { progress.count(.completed, in: subject) }
    private var plannedCount: Int { progress.count(.planned, in: subject) }
    private var fraction: Double { Double(doneCount) / Double(max(1, subject.topics.count)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 26)
                sheet
            }
            .frame(maxWidth: 650)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .scrollNavigationTitle(subject.name)
        .background(palette.paper.ignoresSafeArea())
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .onAppear { expandMatches() }
        .onChange(of: filter) { _, _ in expandMatches() }
        .sheet(item: $selectedTopic) { topic in
            SyllabusTopicSheet(topic: topic, subject: subject, childID: childID)
        }
        .sensoryFeedback(.success, trigger: tickFeedback)
        .onChange(of: state.child.id) { _, id in if id != childID { dismiss() } }
    }

    private func toggleCompletion(_ topic: SyllabusTopic) {
        let completing = progress.status(of: topic, subject: subject) != .completed
        withAnimation(motion) {
            _ = state.setSyllabusTopicCompleted(topic, subject: subject, completed: completing, for: childID)
        }
        tickFeedback += 1
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: SubjectCardPalette.symbol(for: subject.name))
                        .font(.system(size: 20, weight: .semibold)).foregroundStyle(palette.ink)
                        .frame(width: 46, height: 46)
                        .background(Theme.surface.opacity(0.85), in: .rect(cornerRadius: 14))
                        .rotationEffect(.degrees(reduceMotion ? 0 : -6))
                    Text(subject.name).pageTitle()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if !metaLine.isEmpty {
                        Text(metaLine)
                            .scaledFont(15, weight: .medium, maxScale: 1.25)
                            .foregroundStyle(palette.ink)
                    }
                }
                Spacer(minLength: 0)
                if subject.hasOutline { progressSticker }
            }
            FlowLayout(spacing: 8) {
                if subject.hasOutline {
                    heroPill("\(doneCount) of \(subject.topics.count) explored", symbol: "checkmark.seal.fill")
                    if plannedCount > 0 { heroPill("\(plannedCount) this week", symbol: "calendar") }
                } else {
                    heroPill("Official materials", symbol: "book.closed.fill")
                }
                if let url = URL(string: subject.sourceURL) {
                    Link(destination: url) {
                        Label("NIOS source", systemImage: "arrow.up.right")
                            .scaledFont(12, weight: .semibold, maxScale: 1.25)
                            .foregroundStyle(palette.ink)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .gatherGlass(in: Capsule(), tint: palette.ink.opacity(0.12))
                    }
                }
            }
        }
    }

    private func heroPill(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .scaledFont(12, weight: .semibold, maxScale: 1.25)
            .foregroundStyle(palette.ink)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Theme.surface.opacity(0.7), in: .capsule)
    }

    private var progressSticker: some View {
        ZStack {
            Circle().fill(Theme.surface.opacity(0.7))
            Circle().stroke(palette.ink.opacity(0.1), lineWidth: 6).padding(8)
            Circle().trim(from: 0, to: fraction)
                .stroke(palette.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90)).padding(8)
            VStack(spacing: 0) {
                Text("\(Int((fraction * 100).rounded()))%")
                    .scaledFont(24, weight: .heavy, maxScale: 1.15)
                    .contentTransition(.numericText())
                Text("DONE").scaledFont(10, weight: .bold, maxScale: 1.15).tracking(0.8)
            }.foregroundStyle(palette.ink)
        }
        .frame(width: 100, height: 100)
        .rotationEffect(.degrees(reduceMotion ? 0 : 7))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(doneCount) of \(subject.topics.count) topics completed")
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            if subject.hasOutline {
                filterBar
                let chapters = subject.chapters.filter { !visibleTopics(in: $0).isEmpty }
                if chapters.isEmpty {
                    ContentUnavailableView("Nothing here yet", systemImage: "line.3.horizontal.decrease",
                                           description: Text("Try a different filter."))
                } else {
                    ForEach(chapters) { chapter in chapterCard(chapter) }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed").font(.system(size: 28, weight: .semibold)).foregroundStyle(palette.ink)
                    Text("No chapter outline yet").cardTitle()
                    Text("Open the official NIOS material to follow along.").rowDetail().multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(28)
                .background(palette.paper, in: .rect(cornerRadius: 25))
                .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(Theme.surface.opacity(0.85), lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38)
                .fill(Theme.surface)
                .mask {
                    VStack(spacing: 0) {
                        Color.black
                        LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 72)
                    }
                }
        }
        .padding(.horizontal, 10)
    }

    private var filterBar: some View {
        HStack(spacing: 6) {
            filterChip("All", selected: filter == nil) { filter = nil }
            ForEach(SyllabusTopicStatus.allCases, id: \.self) { status in
                filterChip(status.rawValue, selected: filter == status) { filter = status }
            }
            Spacer(minLength: 0)
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(motion) { action() }
        } label: {
            Text(title)
                .scaledFont(13, weight: .semibold, maxScale: 1.15)
                .lineLimit(1).minimumScaleFactor(0.75)
                .foregroundStyle(selected ? Theme.buttonText : palette.ink)
                .padding(.horizontal, 13).frame(height: 38)
                .background(selected ? palette.ink : palette.paper, in: .capsule)
        }
        .buttonStyle(SyllabusPressStyle(reduceMotion: reduceMotion))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func expandMatches() {
        if filter != nil {
            expanded = Set(subject.chapters.filter { !visibleTopics(in: $0).isEmpty }.map(\.id))
        }
    }

    // MARK: Chapter card
    // Same look as the task rows on Home: a quiet grey card with only the pill coloured.

    private func chapterCard(_ chapter: SyllabusChapter) -> some View {
        let cp = palette(forChapter: chapter)
        let isOpen = expanded.contains(chapter.id)
        let done = chapter.topics.filter { progress.status(of: $0, subject: subject) == .completed }.count
        let finished = !chapter.topics.isEmpty && done == chapter.topics.count
        let isArea = chapter.kind == "competency"
        let label = [chapter.isOptional == true ? "Optional" : nil,
                     chapter.module.flatMap { $0.isEmpty ? nil : $0 } ?? (isArea ? "Learning area" : "Chapter")]
            .compactMap { $0 }.joined(separator: " · ")
        return VStack(spacing: 0) {
            Button {
                withAnimation(motion) {
                    if isOpen { expanded.remove(chapter.id) } else { expanded.insert(chapter.id) }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(finished ? "Done" : "\(isArea ? "Area" : "Ch") \(chapter.number)")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .foregroundStyle(cp.ink)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 62, minHeight: 32)
                        .background(cp.paper, in: Capsule())
                        .overlay(Capsule().strokeBorder(cp.ink.opacity(0.14), lineWidth: 0.8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label.uppercased())
                            .scaledFont(9, weight: .medium, maxScale: 1.3).foregroundStyle(Theme.secondary)
                            .multilineTextAlignment(.leading)
                        Text(chapter.title).scaledFont(15, weight: .semibold, maxScale: 1.25)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(done) of \(chapter.topics.count) topics")
                            .scaledFont(11, maxScale: 1.2).foregroundStyle(Theme.secondary)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(cp.ink)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .frame(width: 32, height: 44)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .contentShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(SyllabusPressStyle(reduceMotion: reduceMotion))
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            .accessibilityHint(isOpen ? "Close chapter" : "Show topics")

            if isOpen {
                VStack(spacing: 8) {
                    ForEach(visibleTopics(in: chapter)) { topic in
                        SyllabusTopicRow(topic: topic, ink: cp.ink,
                                         status: progress.status(of: topic, subject: subject),
                                         onToggle: { toggleCompletion(topic) },
                                         onOpen: { selectedTopic = topic })
                    }
                }
                .padding(.horizontal, 10).padding(.bottom, 10)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.field, in: .rect(cornerRadius: 24))
        .sensoryFeedback(.selection, trigger: isOpen)
    }
}

private struct SyllabusPressStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SyllabusTopicRow: View {
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
private struct SyllabusTopicSheet: View {
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
                    Image(systemName: "xmark").font(.system(size: 17, weight: .medium))
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
