import SwiftUI

/// A little paper card that opens into the subject's real weekly learning checklist.
struct SubjectLearningCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let subject: SubjectLearningProgress
    let index: Int
    let selectedDate: Date
    @Binding var isExpanded: Bool
    let onToggleActivity: (WeekActivity) -> Void
    @State private var showWholeWeek: Bool
    @State private var expandedActivityID: WeekActivity.ID?

    init(subject: SubjectLearningProgress, index: Int, selectedDate: Date,
         isExpanded: Binding<Bool>, onToggleActivity: @escaping (WeekActivity) -> Void) {
        self.subject = subject
        self.index = index
        self.selectedDate = selectedDate
        _isExpanded = isExpanded
        self.onToggleActivity = onToggleActivity
        _showWholeWeek = State(initialValue: !subject.activities.contains {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        })
    }

    private var palette: SubjectCardPalette { .all[index % SubjectCardPalette.all.count] }
    private var percent: Int { Int((subject.fraction * 100).rounded()) }
    private var finished: Bool { !subject.activities.isEmpty && subject.completedCount == subject.activities.count }
    private var today: [WeekActivity] {
        subject.activities.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    private var ordered: [WeekActivity] { subject.activities.sorted { $0.date < $1.date } }
    private var visibleActivities: [WeekActivity] { showWholeWeek ? ordered : today }
    private var next: WeekActivity? { today.first { !$0.isDone } ?? ordered.first { !$0.isDone } }
    private var motion: Animation { reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.4, dampingFraction: 0.83) }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(motion) { isExpanded.toggle() }
            } label: {
                summary
                    .padding(18)
                    .contentShape(RoundedRectangle(cornerRadius: 25))
            }
            .buttonStyle(SubjectCardPressStyle(reduceMotion: reduceMotion))
            .accessibilityLabel("\(subject.name), \(percent) percent of weekly learning completed, \(subject.completedCount) of \(subject.activities.count) activities")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Close subject card" : "Open activities and learning details")
            .accessibilityIdentifier("progress.subject.\(subject.id)")

            if isExpanded {
                details
                    .padding(.horizontal, 18).padding(.bottom, 18)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .foregroundStyle(Theme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .background(palette.paper, in: .rect(cornerRadius: 25))
        .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(.white.opacity(0.85), lineWidth: 1.5))
        .shadow(color: palette.ink.opacity(isExpanded ? 0.13 : 0.07), radius: isExpanded ? 14 : 5, x: 0, y: isExpanded ? 8 : 3)
        .rotationEffect(.degrees(isExpanded || reduceMotion ? 0 : (index.isMultiple(of: 2) ? -0.8 : 0.8)))
        .padding(.vertical, 3)
        .sensoryFeedback(.selection, trigger: isExpanded)
        .onChange(of: selectedDate) { _, _ in
            showWholeWeek = today.isEmpty
            expandedActivityID = nil
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 7) {
                        Image(systemName: symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.85), in: .rect(cornerRadius: 10))
                            .rotationEffect(.degrees(reduceMotion || isExpanded ? 0 : -6))
                        Text(finished ? "WEEK, WELL EXPLORED" : "A LITTLE MORE DISCOVERY")
                            .scaledFont(8, weight: .bold, maxScale: 1.2)
                            .tracking(1.1).multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(palette.ink)
                    Text(subject.name)
                        .scaledFont(22, weight: .heavy, maxScale: 1.2)
                        .tracking(-0.6)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                progressSticker
            }

            HStack(spacing: 6) {
                Image(systemName: finished ? "checkmark.seal.fill" : "circle.grid.2x2.fill")
                Text("\(subject.completedCount) of \(subject.activities.count) activities explored")
            }
            .scaledFont(12, weight: .medium, maxScale: 1.25)
            .foregroundStyle(palette.ink.opacity(0.85))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(next == nil ? (finished ? "LOOK WHAT YOU DID" : "ROOM FOR SOMETHING NEW") : "UP NEXT")
                        .scaledFont(8, weight: .bold, maxScale: 1.2).tracking(1.1)
                    Spacer(minLength: 0)
                    if let next {
                        Text("\(next.minutes) min · \(next.date.formatted(.dateTime.weekday(.abbreviated)))")
                            .scaledFont(10, weight: .medium, maxScale: 1.2)
                    }
                }
                .foregroundStyle(palette.ink.opacity(0.8))
                Text(next?.title ?? (finished ? "A whole week of little wins." : "Make space for a new idea."))
                    .scaledFont(14, weight: .semibold, maxScale: 1.25)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.58), in: .rect(cornerRadius: 15))

            HStack {
                Text("\(LearningProgress.duration(subject.loggedMinutes)) logged")
                    .scaledFont(11, weight: .medium, maxScale: 1.25)
                Spacer(minLength: 0)
                Text(isExpanded ? "Tuck away" : "Pick this card")
                    .scaledFont(11, weight: .semibold, maxScale: 1.25)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .foregroundStyle(palette.ink)
        }
    }

    private var progressSticker: some View {
        ZStack {
            Circle().fill(.white.opacity(0.7))
            Circle().stroke(palette.ink.opacity(0.1), lineWidth: 5)
                .padding(6)
            Circle().trim(from: 0, to: subject.fraction)
                .stroke(palette.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90)).padding(6)
            VStack(spacing: 0) {
                if finished {
                    Image(systemName: "checkmark").font(.system(size: 20, weight: .bold))
                } else {
                    Text("\(percent)%").scaledFont(17, weight: .heavy, maxScale: 1.15)
                        .contentTransition(.numericText())
                    Text("THIS WEEK").scaledFont(6, weight: .bold, maxScale: 1.15).tracking(0.3)
                }
            }
            .foregroundStyle(palette.ink)
        }
        .frame(width: 65, height: 65)
        .rotationEffect(.degrees(reduceMotion || isExpanded ? 0 : 7))
        .accessibilityHidden(true)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 16) {
            Rectangle().fill(palette.ink.opacity(0.12)).frame(height: 1)
            HStack(spacing: 12) {
                timeStatistic("Planned", value: LearningProgress.duration(subject.plannedMinutes))
                Rectangle().fill(palette.ink.opacity(0.12)).frame(width: 1, height: 30)
                timeStatistic("Left to explore", value: LearningProgress.duration(max(0, subject.plannedMinutes - subject.loggedMinutes)))
            }
            HStack(spacing: 4) {
                scopeButton(selectedDate.formatted(.dateTime.weekday(.wide)), wholeWeek: false)
                scopeButton("Whole week", wholeWeek: true)
            }
            .padding(4)
            .background(.white.opacity(0.45), in: Capsule())

            if visibleActivities.isEmpty {
                Text(showWholeWeek ? "No activities in this subject yet. There’s room for a little curiosity." : "A little pause for this subject today. Take a look at the whole week or plan something new.")
                    .scaledFont(13, maxScale: 1.25).foregroundStyle(palette.ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(visibleActivities.enumerated()), id: \.element.id) { offset, activity in
                VStack(alignment: .leading, spacing: 9) {
                    if showWholeWeek && (offset == 0 || !Calendar.current.isDate(visibleActivities[offset - 1].date, inSameDayAs: activity.date)) {
                        Text(activity.date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                            .scaledFont(10, weight: .semibold, maxScale: 1.25)
                            .foregroundStyle(palette.ink.opacity(0.8))
                            .padding(.top, offset == 0 ? 0 : 5)
                    }
                    activityRow(activity)
                }
            }
            NavigationLink {
                FirstWeekView(initialDay: WeeklyPlan.dayNames[(Calendar.current.component(.weekday, from: selectedDate) + 5) % 7], backTitle: "Progress")
            } label: {
                Label(subject.activities.isEmpty ? "Plan a little learning" : "Adjust the weekly plan", systemImage: "plus")
                    .scaledFont(12, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(palette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.white.opacity(0.7), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func timeStatistic(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).scaledFont(20, weight: .bold, maxScale: 1.2)
                .contentTransition(.numericText()).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).scaledFont(10, maxScale: 1.25).foregroundStyle(palette.ink.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scopeButton(_ title: String, wholeWeek: Bool) -> some View {
        Button {
            withAnimation(motion) { showWholeWeek = wholeWeek; expandedActivityID = nil }
        } label: {
            Text(title).scaledFont(12, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(palette.ink)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(showWholeWeek == wholeWeek ? .white : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(showWholeWeek == wholeWeek ? .isSelected : [])
    }

    private func activityRow(_ activity: WeekActivity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Button { onToggleActivity(activity) } label: {
                    Image(systemName: activity.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 23, weight: .regular))
                        .foregroundStyle(activity.isDone ? palette.ink : palette.ink.opacity(0.35))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(activity.isDone ? "Undo completion of \(activity.title)" : "Complete \(activity.title)")
                VStack(alignment: .leading, spacing: 5) {
                    Text(activity.title).scaledFont(14, weight: .semibold, maxScale: 1.25)
                        .foregroundStyle(activity.isDone ? palette.ink.opacity(0.65) : Theme.ink)
                        .strikethrough(activity.isDone)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text("\(activity.minutes) min")
                        if let time = activity.time {
                            Text("· \(time.formatted(date: .omitted, time: .shortened))")
                        }
                        if activity.isDone { Text("· Done") }
                    }
                    .scaledFont(10, weight: .medium, maxScale: 1.25)
                    .foregroundStyle(palette.ink.opacity(0.8))
                }
                .padding(.vertical, 10)
                Spacer(minLength: 0)
            }
            Button {
                withAnimation(motion) { expandedActivityID = expandedActivityID == activity.id ? nil : activity.id }
            } label: {
                HStack(spacing: 4) {
                    Text(expandedActivityID == activity.id ? "Less detail" : "Activity details")
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(expandedActivityID == activity.id ? 180 : 0))
                }
                .scaledFont(10, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(palette.ink)
                .frame(minHeight: 34)
            }
            .buttonStyle(.plain)
            .padding(.leading, 52)
            .accessibilityLabel("\(expandedActivityID == activity.id ? "Hide" : "Show") details for \(activity.title)")

            if expandedActivityID == activity.id {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Your help: \(activity.helpMinutes) min, included in learning time", systemImage: "hands.sparkles")
                        .scaledFont(11, maxScale: 1.25)
                    if !activity.smallSteps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        detailText("SMALL STEPS", text: activity.smallSteps)
                    }
                    if !activity.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        detailText("NOTES & MATERIALS", text: activity.notes)
                    }
                }
                .foregroundStyle(palette.ink.opacity(0.85))
                .padding(.leading, 52).padding(.trailing, 12).padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 4).padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(activity.isDone ? 0.45 : 0.75), in: .rect(cornerRadius: 16))
    }

    private func detailText(_ label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).scaledFont(8, weight: .bold, maxScale: 1.2).tracking(0.8)
            Text(text).scaledFont(12, maxScale: 1.25).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var symbol: String {
        switch subject.id {
        case "mathematics": return "function"
        case "science": return "flask"
        case "computer skills": return "chevron.left.forwardslash.chevron.right"
        case "art & craft": return "paintpalette"
        case "english", "hindi": return "text.book.closed"
        default:
            if subject.id.contains("plumbing") { return "wrench.and.screwdriver" }
            if subject.id.contains("tailor") { return "scissors" }
            return "book.closed"
        }
    }
}

private struct SubjectCardPalette {
    let paper: Color
    let ink: Color
    static let all = [
        SubjectCardPalette(paper: Color(hex: 0xEEE7FF), ink: Color(hex: 0x5940A5)),
        SubjectCardPalette(paper: Color(hex: 0xFFE7DD), ink: Color(hex: 0x9B4D3B)),
        SubjectCardPalette(paper: Color(hex: 0xE2F0E7), ink: Color(hex: 0x386553)),
        SubjectCardPalette(paper: Color(hex: 0xFFF1CE), ink: Color(hex: 0x88621E))
    ]
}

private struct SubjectCardPressStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
