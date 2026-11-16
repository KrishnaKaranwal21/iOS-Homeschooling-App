import SwiftUI

/// The expanded details of a subject card: time statistics and the activity list.
extension SubjectLearningCard {
    // MARK: - Details

    var details: some View {
        VStack(alignment: .leading, spacing: 16) {
            Rectangle()
                .fill(palette.ink.opacity(0.12))
                .frame(height: 1)

            HStack(spacing: 12) {
                timeStatistic(
                    "Planned",
                    value: LearningProgress.duration(
                        subject.plannedMinutes
                    )
                )

                Rectangle()
                    .fill(palette.ink.opacity(0.12))
                    .frame(width: 1, height: 30)

                timeStatistic(
                    "Left to explore",
                    value: LearningProgress.duration(
                        max(
                            0,
                            subject.plannedMinutes - subject.loggedMinutes
                        )
                    )
                )
            }

            Picker("Activity range", selection: $showWholeWeek) {
                Text(
                    selectedDate.formatted(
                        .dateTime.weekday(.wide)
                    )
                )
                .tag(false)

                Text(overviewTitle)
                    .tag(true)
            }
            .pickerStyle(.segmented)
            .tint(.white)
            .frame(height: 44)
            .onChange(of: showWholeWeek) { _, _ in
                expandedActivityID = nil
            }

            if visibleActivities.isEmpty {
                Text(
                    showWholeWeek
                    ? "No activities in this subject yet. There’s room for a little curiosity."
                    : "A little pause for this subject today. Take a look at the full plan or add something new."
                )
                .scaledFont(13, maxScale: 1.25)
                .foregroundStyle(palette.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(
                Array(visibleActivities.enumerated()),
                id: \.element.id
            ) { offset, activity in
                VStack(alignment: .leading, spacing: 9) {
                    if showWholeWeek &&
                        (offset == 0 ||
                         !Calendar.current.isDate(
                            visibleActivities[offset - 1].date,
                            inSameDayAs: activity.date
                         )) {

                        Text(
                            activity.date.formatted(
                                .dateTime.weekday(.wide).day().month(.abbreviated)
                            )
                        )
                        .scaledFont(10, weight: .semibold, maxScale: 1.25)
                        .foregroundStyle(palette.ink.opacity(0.8))
                        .padding(.top, offset == 0 ? 0 : 5)
                    }

                    activityRow(activity)
                }
            }

            if allowsPlanning {
                Button(action: onPlan) {
                    Label(
                        subject.activities.isEmpty
                        ? "Plan a little learning"
                        : "Adjust the plan",
                        systemImage: "plus"
                    )
                    .scaledFont(12, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(palette.ink)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        Theme.surface.opacity(0.7),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Time Statistics

    func timeStatistic(
        _ title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .scaledFont(20, weight: .bold, maxScale: 1.2)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .scaledFont(10, maxScale: 1.25)
                .foregroundStyle(palette.ink.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
