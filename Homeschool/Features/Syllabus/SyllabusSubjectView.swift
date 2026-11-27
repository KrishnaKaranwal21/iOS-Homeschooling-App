import SwiftUI

struct SyllabusSubjectView: View {
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
            SyllabusTopicSheet(topic: topic, subject: subject, childID: childID, paletteIndex: paletteIndex)
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
                        .scaledFont(20, weight: .semibold).foregroundStyle(palette.ink)
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
                Text("Done").textCase(.uppercase).scaledFont(10, weight: .bold, maxScale: 1.15).tracking(0.8)
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
                    Image(systemName: "book.closed").scaledFont(28, weight: .semibold).foregroundStyle(palette.ink)
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

        let done = chapter.topics.filter {
            progress.status(of: $0, subject: subject) == .completed
        }.count

        let finished = !chapter.topics.isEmpty && done == chapter.topics.count
        let isArea = chapter.kind == "competency"

        let label = [
            chapter.isOptional == true ? "Optional" : nil,
            chapter.module.flatMap { $0.isEmpty ? nil : $0 }
                ?? (isArea ? "Learning area" : "Chapter")
        ]
        .compactMap { $0 }
        .joined(separator: " · ")

        return VStack(spacing: 0) {

            // MARK: Header

            Button {
                withAnimation(motion) {
                    if isOpen {
                        expanded.remove(chapter.id)
                    } else {
                        expanded.insert(chapter.id)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(finished ? "Done" : "\(isArea ? "Area" : "Ch") \(chapter.number)")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(cp.ink)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 62, minHeight: 32)
                        .background(cp.paper, in: Capsule())
                        .overlay(
                            Capsule().strokeBorder(cp.ink.opacity(0.14), lineWidth: 0.8)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label.uppercased())
                            .scaledFont(9, weight: .medium, maxScale: 1.3)
                            .foregroundStyle(Theme.secondary)

                        Text(chapter.title)
                            .scaledFont(15, weight: .semibold, maxScale: 1.25)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("\(done) of \(chapter.topics.count) topics")
                            .scaledFont(11, maxScale: 1.2)
                            .foregroundStyle(Theme.secondary)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.down")
                        .scaledFont(14, weight: .semibold)
                        .foregroundStyle(cp.ink)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .frame(width: 32, height: 44)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(SyllabusPressStyle(reduceMotion: reduceMotion))
            .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            .accessibilityHint(isOpen ? "Close chapter" : "Show topics")

            // MARK: Topics

            if isOpen {
                VStack(spacing: 8) {
                    ForEach(visibleTopics(in: chapter)) { topic in
                        SyllabusTopicRow(
                            topic: topic,
                            ink: cp.ink,
                            status: progress.status(of: topic, subject: subject),
                            onToggle: { toggleCompletion(topic) },
                            onOpen: { selectedTopic = topic }
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.field)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .sensoryFeedback(.selection, trigger: isOpen)
    }

}

struct SyllabusPressStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
