import SwiftUI

/// A little paper card that opens into the subject's real weekly learning checklist.
struct SubjectLearningCard: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let subject: SubjectLearningProgress
    let index: Int
    let selectedDate: Date
    let overviewTitle: String
    let allowsPlanning: Bool

    @Binding var isExpanded: Bool

    let onToggleActivity: (WeekActivity) -> Void
    let onPlan: () -> Void

    @State var showWholeWeek: Bool
    @State var expandedActivityID: WeekActivity.ID?

    init(
        subject: SubjectLearningProgress,
        index: Int,
        selectedDate: Date,
        overviewTitle: String = "Whole week",
        allowsPlanning: Bool = true,
        isExpanded: Binding<Bool>,
        onToggleActivity: @escaping (WeekActivity) -> Void,
        onPlan: @escaping () -> Void
    ) {
        self.subject = subject
        self.index = index
        self.selectedDate = selectedDate
        self.overviewTitle = overviewTitle
        self.allowsPlanning = allowsPlanning
        _isExpanded = isExpanded
        self.onToggleActivity = onToggleActivity
        self.onPlan = onPlan

        _showWholeWeek = State(
            initialValue: !subject.activities.contains {
                Calendar.current.isDate(
                    $0.date,
                    inSameDayAs: selectedDate
                )
            }
        )
    }

    var palette: SubjectCardPalette {
        .all[index % SubjectCardPalette.all.count]
    }

    var percent: Int {
        subject.completionPercentage
    }

    var finished: Bool {
        !subject.activities.isEmpty &&
        subject.completedCount == subject.activities.count
    }

    var today: [WeekActivity] {
        subject.activities.filter {
            Calendar.current.isDate(
                $0.date,
                inSameDayAs: selectedDate
            )
        }
    }

    var ordered: [WeekActivity] {
        subject.activities.sorted { $0.date < $1.date }
    }

    var visibleActivities: [WeekActivity] {
        showWholeWeek ? ordered : today
    }

    var next: WeekActivity? {
        today.first { !$0.isDone } ??
        ordered.first { !$0.isDone }
    }

    var motion: Animation {
        reduceMotion
        ? .easeOut(duration: 0.15)
        : .spring(response: 0.4, dampingFraction: 0.83)
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(motion) {
                    isExpanded.toggle()
                }
            } label: {
                summary
                    .padding(18)
                    .contentShape(RoundedRectangle(cornerRadius: 25))
            }
            .buttonStyle(
                SubjectCardPressStyle(reduceMotion: reduceMotion)
            )
            .accessibilityLabel(
                "\(subject.name), \(percent) percent of \(overviewTitle == "Whole month" ? "monthly" : "weekly") learning completed, \(subject.completedCount) of \(subject.activities.count) activities"
            )
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(
                isExpanded
                ? "Close subject card"
                : "Open activities and learning details"
            )
            .accessibilityIdentifier("progress.subject.\(subject.id)")

            if isExpanded {
                details
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                    .transition(
                        reduceMotion
                        ? .opacity
                        : .opacity.combined(with: .move(edge: .top))
                    )
            }
        }
        .foregroundStyle(Theme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .background(
            palette.paper,
            in: .rect(cornerRadius: 25)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .strokeBorder(
                    Theme.surface.opacity(0.85),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: palette.ink.opacity(isExpanded ? 0.13 : 0.07),
            radius: isExpanded ? 14 : 5,
            x: 0,
            y: isExpanded ? 8 : 3
        )
        .rotationEffect(
            .degrees(
                isExpanded || reduceMotion
                ? 0
                : (index.isMultiple(of: 2) ? -0.8 : 0.8)
            )
        )
        .padding(.vertical, 3)
        .sensoryFeedback(.selection, trigger: isExpanded)
        .onChange(of: selectedDate) { _, _ in
            showWholeWeek = today.isEmpty
            expandedActivityID = nil
        }
    }

    var symbol: String {
        SubjectCardPalette.symbol(for: subject.name)
    }
}

/// Presses a subject card in slightly unless Reduce Motion is on.
private struct SubjectCardPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed && !reduceMotion ? 0.98 : 1
            )
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
