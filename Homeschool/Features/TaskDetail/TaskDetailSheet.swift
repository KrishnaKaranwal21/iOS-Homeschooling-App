import SwiftUI

// MARK: - TaskDetailContent

/// Everything the task page shows, so Home, Progress and the Syllabus all open the same screen.
/// Build it from a planned activity with `init(activity:paletteIndex:)`, or fill it in directly for other sources
/// (the Syllabus builds one from a topic).
struct TaskDetailContent {
    var subject: String
    var title: String
    /// An optional line under the title, such as the syllabus chapter.
    var detail: String? = nil
    var statusText: String
    var statusSymbol = "clock"
    var isDone: Bool
    /// Time tiles are hidden when there is no planned time.
    var minutes: Int? = nil
    var helpMinutes: Int? = nil
    var overview: String
    var stepsTitle: String
    var steps: [String]
    var materialsTitle: String
    var materials: String
    var materialsSymbol = "backpack"
    /// Index into `SubjectCardPalette.all`, so the page matches the card it was opened from.
    var paletteIndex = 0
    var link: URL? = nil
    var linkTitle = "Read more"
}

extension TaskDetailContent {
    /// Descriptions are suggested locally; saved steps and notes stay the source of truth for a family's own task.
    init(activity: WeekActivity, paletteIndex: Int) {
        let guide = ActivityGuide.suggested(for: activity)
        let savedSteps = Self.lines(of: activity.smallSteps)
        let hasNotes = !activity.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let timeText = activity.time?.formatted(date: .omitted, time: .shortened)
        let status: String
        if activity.isDone {
            if let done = activity.completedAt {
                status = "Completed · \(done.formatted(date: .omitted, time: .shortened))"
            } else {
                status = "Completed"
            }
        } else {
            status = timeText.map { "To do · \($0)" } ?? "To do"
        }
        self.init(subject: activity.subject, title: activity.title,
                  statusText: status, statusSymbol: activity.isDone ? "checkmark" : "clock",
                  isDone: activity.isDone, minutes: activity.minutes, helpMinutes: activity.helpMinutes,
                  overview: guide.overview,
                  stepsTitle: savedSteps.isEmpty ? "Try it step by step" : "Your steps",
                  steps: savedSteps.isEmpty ? guide.steps : savedSteps,
                  materialsTitle: hasNotes ? "Your notes" : "What you’ll need",
                  materials: hasNotes ? activity.notes : guide.materials,
                  materialsSymbol: hasNotes ? "note.text" : "backpack",
                  paletteIndex: paletteIndex)
    }

    /// Saved steps are entered one per line, so each line becomes its own step.
    static func lines(of text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - TaskDetailAction

/// An optional quiet action under the main button, such as “Plan this topic”.
struct TaskDetailAction {
    let title: String
    let systemImage: String
    var isDisabled = false
    let action: () -> Void
}

// MARK: - TaskDetailSheet

/// The one task page used across the app. It reuses the look of Home: the subject's paper colour and watermark, the
/// planner's “Learning time / Your help” tiles and shared section headings. The steps are read-only guidance.
///
/// - `onToggle` runs for the main button (complete or undo).
/// - `onDelete` is optional; when it is nil the “more” menu is hidden.
struct TaskDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let content: TaskDetailContent
    var secondary: TaskDetailAction? = nil
    let onToggle: () -> Void
    var onDelete: (() -> Void)? = nil

    @State private var confirmDelete = false
    @State private var appeared = false

    private var palette: SubjectCardPalette { SubjectCardPalette.all[content.paletteIndex % SubjectCardPalette.all.count] }
    private var symbol: String { SubjectCardPalette.symbol(for: content.subject) }
    private var doneGreen: Color { Color(hex: 0x386553) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero.reveal(appeared, order: 0, reduceMotion: reduceMotion)
                    if content.minutes != nil {
                        timeTiles.reveal(appeared, order: 1, reduceMotion: reduceMotion)
                    }
                    aboutSection.reveal(appeared, order: 2, reduceMotion: reduceMotion)
                    stepsSection.reveal(appeared, order: 3, reduceMotion: reduceMotion)
                    materialsSection.reveal(appeared, order: 4, reduceMotion: reduceMotion)
                    if let link = content.link { linkButton(link).reveal(appeared, order: 5, reduceMotion: reduceMotion) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .confirmationDialog("Remove this activity?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Remove from this day", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Keep task", role: .cancel) {}
        } message: {
            Text("“\(content.title)” will be removed from this day. Repeats on other days stay. You can undo this removal on Home.")
        }
        .onAppear { appeared = true }
        .foregroundStyle(Theme.ink).background(Theme.background).buttonStyle(.plain)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 12)
            if onDelete != nil {
                Menu {
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Remove from this day", systemImage: "trash")
                    }
                    .accessibilityIdentifier("home.activity.delete")
                } label: {
                    Image(systemName: "ellipsis").scaledFont(17, weight: .medium)
                        .frame(width: 44, height: 44)
                        .gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.35))
                }
                .accessibilityLabel("More options")
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark").scaledFont(17, weight: .medium)
                    .frame(width: 44, height: 44).gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.35))
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)
    }

    // MARK: - Hero

    /// Same paper, watermark, white ring and soft shadow as the task card on Home, just bigger.
    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(content.subject, systemImage: symbol)
                .scaledFont(13, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(palette.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Color.white.opacity(0.7), in: Capsule())
                .overlay(Capsule().strokeBorder(.white, lineWidth: 1))
            VStack(alignment: .leading, spacing: 8) {
                Text(content.title).detailTitle()
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = content.detail {
                    Label(detail, systemImage: "book.closed")
                        .scaledFont(14, maxScale: 1.25)
                        .foregroundStyle(palette.ink.opacity(0.8))
                }
            }
            Label(content.statusText, systemImage: content.statusSymbol)
                .scaledFont(14, weight: .medium, maxScale: 1.25)
                .foregroundStyle(content.isDone ? doneGreen : palette.ink.opacity(0.8))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .trailing) {
                palette.paper
                Image(systemName: symbol)
                    .scaledFont(120, weight: .ultraLight)
                    .foregroundStyle(palette.ink.opacity(0.08))
                    .rotationEffect(.degrees(-15))
                    .padding(.trailing, 14).padding(.top, 36)
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .accessibilityHidden(true)
        }
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(Theme.surface.opacity(0.9), lineWidth: 1.5))
        .shadow(color: palette.ink.opacity(0.10), radius: 12, y: 6)
    }

    // MARK: - Time tiles (match the planner's “Learning time” and “Your help” tiles)

    private var timeTiles: some View {
        HStack(spacing: 10) {
            if let minutes = content.minutes {
                timeTile(title: "Learning time", minutes: minutes, detail: "Total activity time")
                if let help = content.helpMinutes, help > 0 {
                    timeTile(title: "Your help", minutes: help, detail: "Part of the \(minutes) min")
                }
            }
        }
    }

    private func timeTile(title: String, minutes: Int, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).scaledFont(13, weight: .medium, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(minutes)").scaledFont(31, weight: .bold, maxScale: 1.2)
                Text("min").scaledFont(15, weight: .medium, maxScale: 1.2)
            }
            Text(detail).scaledFont(11, maxScale: 1.2).foregroundStyle(WeekStyle.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(WeekStyle.field, in: .rect(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Theme.surface, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(minutes) minutes. \(detail)")
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About this task").sectionTitle()
            Text(content.overview)
                .scaledFont(16, maxScale: 1.3)
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Steps (read-only, joined by a guide line)

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(content.stepsTitle).sectionTitle()
                Spacer(minLength: 8)
                Text("\(content.steps.count) steps")
                    .scaledFont(12, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.lilac, in: Capsule())
            }
            VStack(spacing: 0) {
                ForEach(Array(content.steps.enumerated()), id: \.offset) { index, step in
                    stepRow(index: index, text: step, isLast: index == content.steps.count - 1)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Theme.cardBorder, lineWidth: 1))
            .shadow(color: Theme.ink.opacity(0.04), radius: 6, y: 3)
        }
    }

    private func stepRow(index: Int, text: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Text("\(index + 1)")
                    .scaledFont(13, weight: .bold, maxScale: 1.3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 30, height: 30)
                    .background(Theme.lilac, in: Circle())
                if !isLast {
                    Capsule().fill(Theme.lilacBorder)
                        .frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            Text(text).bodyText()
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4).padding(.bottom, isLast ? 0 : 18)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(index + 1): \(text)")
    }

    // MARK: - Materials / notes

    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.materialsTitle).sectionTitle()
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: content.materialsSymbol)
                    .scaledFont(18, weight: .semibold, maxScale: 1.3)
                    .foregroundStyle(palette.ink)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.75), in: Circle())
                    .accessibilityHidden(true)
                Text(content.materials).bodyText()
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.paper.opacity(0.6), in: .rect(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Theme.surface.opacity(0.9), lineWidth: 1.5))
        }
    }

    private func linkButton(_ url: URL) -> some View {
        Link(destination: url) {
            Label(content.linkTitle, systemImage: "arrow.up.right.square")
                .scaledFont(15, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Theme.lilac, in: Capsule())
        }
    }

    // MARK: - Floating action

    private var actionBar: some View {
        VStack(spacing: 6) {
            Button {
                onToggle()
                dismiss()
            } label: {
                Label(content.isDone ? "Mark incomplete" : "Mark complete",
                      systemImage: content.isDone ? "arrow.uturn.backward" : "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primaryHomeschool(isDimmed: false))
            .shadow(color: Theme.ink.opacity(0.18), radius: 14, y: 6)
            .accessibilityIdentifier("home.activity.complete")

            if let secondary {
                Button(action: secondary.action) {
                    Label(secondary.title, systemImage: secondary.systemImage)
                        .scaledFont(16, weight: .semibold, maxScale: 1.25)
                        .foregroundStyle(secondary.isDisabled ? Theme.secondary : Theme.accent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .disabled(secondary.isDisabled)
            }
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 10)
        .background {
            LinearGradient(colors: [Theme.background.opacity(0), Theme.background, Theme.background],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Entrance animation

private extension View {
    /// Fades and lifts each section in a beat after the last, skipped when Reduce Motion is on.
    func reveal(_ appeared: Bool, order: Int, reduceMotion: Bool) -> some View {
        opacity(appeared || reduceMotion ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 14)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.06 * Double(order)), value: appeared)
    }
}
