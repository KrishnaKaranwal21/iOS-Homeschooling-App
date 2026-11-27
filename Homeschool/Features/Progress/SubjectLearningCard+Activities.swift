import SwiftUI

/// One activity row of a subject card, with its steps and notes.
extension SubjectLearningCard {
    // MARK: - Activity Row

    func activityRow(
        _ activity: WeekActivity
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    onToggleActivity(activity)
                } label: {
                    Image(
                        systemName: activity.isDone
                        ? "checkmark.circle.fill"
                        : "circle"
                    )
                    .scaledFont(23, weight: .regular)
                    .foregroundStyle(
                        activity.isDone
                        ? palette.ink
                        : palette.ink.opacity(0.35)
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    activity.isDone
                    ? "Undo completion of \(activity.title)"
                    : "Complete \(activity.title)"
                )

                Button {
                    detailActivity = activity
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(activity.title)
                                .scaledFont(14, weight: .semibold, maxScale: 1.25)
                                .foregroundStyle(
                                    activity.isDone
                                    ? palette.ink.opacity(0.65)
                                    : Theme.ink
                                )
                                .strikethrough(activity.isDone)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 6) {
                                Text("\(activity.minutes) min")

                                if let time = activity.time {
                                    Text(
                                        "· \(time.formatted(date: .omitted, time: .shortened))"
                                    )
                                }

                                if activity.isDone {
                                    Text("· Done")
                                }
                            }
                            .scaledFont(10, weight: .medium, maxScale: 1.25)
                            .foregroundStyle(palette.ink.opacity(0.8))
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .scaledFont(11, weight: .semibold, maxScale: 1.25)
                            .foregroundStyle(palette.ink.opacity(0.4))
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 10).padding(.trailing, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the task description")

            }

            Button {
                withAnimation(motion) {
                    expandedActivityID =
                        expandedActivityID == activity.id
                        ? nil
                        : activity.id
                }
            } label: {
                HStack(spacing: 4) {
                    Text(
                        expandedActivityID == activity.id
                        ? "Less detail"
                        : "Activity details"
                    )

                    Image(systemName: "chevron.down").accessibilityHidden(true)
                        .rotationEffect(
                            .degrees(
                                expandedActivityID == activity.id ? 180 : 0
                            )
                        )
                }
                .scaledFont(10, weight: .semibold, maxScale: 1.25)
                .foregroundStyle(palette.ink)
                .frame(minHeight: 34)
            }
            .buttonStyle(.plain)
            .padding(.leading, 52)
            .accessibilityLabel(
                "\(expandedActivityID == activity.id ? "Hide" : "Show") details for \(activity.title)"
            )

            if expandedActivityID == activity.id {
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        "Your help: \(activity.helpMinutes) min, included in learning time",
                        systemImage: "hands.sparkles"
                    )
                    .scaledFont(11, maxScale: 1.25)

                    if !activity.smallSteps.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {
                        detailText(
                            "SMALL STEPS",
                            text: activity.smallSteps
                        )
                    }

                    if !activity.notes.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {
                        detailText(
                            "NOTES & MATERIALS",
                            text: activity.notes
                        )
                    }
                }
                .foregroundStyle(palette.ink.opacity(0.85))
                .padding(.leading, 52)
                .padding(.trailing, 12)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.surface.opacity(activity.isDone ? 0.45 : 0.75),
            in: .rect(cornerRadius: 16)
        )
    }

    // MARK: - Detail Text

    func detailText(
        _ label: String,
        text: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .scaledFont(8, weight: .bold, maxScale: 1.2)
                .tracking(0.8)

            Text(text)
                .scaledFont(12, maxScale: 1.25)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
