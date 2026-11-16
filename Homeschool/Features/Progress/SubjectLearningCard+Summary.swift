import SwiftUI

/// The collapsed summary of a subject card and its progress sticker.
extension SubjectLearningCard {
    // MARK: - Summary

    var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 7) {
                        Image(systemName: symbol)
                            .scaledFont(16, weight: .semibold)
                            .frame(width: 32, height: 32)
                            .background(
                                Theme.surface.opacity(0.85),
                                in: .rect(cornerRadius: 10)
                            )
                            .rotationEffect(
                                .degrees(
                                    reduceMotion || isExpanded ? 0 : -6
                                )
                            )

                        Text(
                            finished
                            ? (overviewTitle == "Whole month"
                               ? "MONTH, WELL EXPLORED"
                               : "WEEK, WELL EXPLORED")
                            : "A LITTLE MORE DISCOVERY"
                        )
                        .scaledFont(8, weight: .bold, maxScale: 1.2)
                        .tracking(1.1)
                        .multilineTextAlignment(.leading)
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
                Image(
                    systemName: finished
                    ? "checkmark.seal.fill"
                    : "circle.grid.2x2.fill"
                )

                Text(
                    "\(subject.completedCount) of \(subject.activities.count) activities explored"
                )
            }
            .scaledFont(12, weight: .medium, maxScale: 1.25)
            .foregroundStyle(palette.ink.opacity(0.85))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(
                        next == nil
                        ? (finished
                           ? "LOOK WHAT YOU DID"
                           : "ROOM FOR SOMETHING NEW")
                        : "UP NEXT"
                    )
                    .scaledFont(8, weight: .bold, maxScale: 1.2)
                    .tracking(1.1)

                    Spacer(minLength: 0)

                    if let next {
                        Text(
                            "\(next.minutes) min · \(next.date.formatted(.dateTime.weekday(.abbreviated)))"
                        )
                        .scaledFont(10, weight: .medium, maxScale: 1.2)
                    }
                }
                .foregroundStyle(palette.ink.opacity(0.8))

                Text(
                    next?.title ??
                    (finished
                     ? "A lovely collection of little wins."
                     : "Make space for a new idea.")
                )
                .scaledFont(14, weight: .semibold, maxScale: 1.25)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.surface.opacity(0.58),
                in: .rect(cornerRadius: 15)
            )

            HStack {
                Text(
                    "\(LearningProgress.duration(subject.creditedMinutes)) credited"
                )
                .scaledFont(11, weight: .medium, maxScale: 1.25)

                Spacer(minLength: 0)

                Text(isExpanded ? "Tuck away" : "Pick this card")
                    .scaledFont(11, weight: .semibold, maxScale: 1.25)

                Image(systemName: "chevron.down").accessibilityHidden(true)
                    .scaledFont(10, weight: .semibold)
                    .rotationEffect(
                        .degrees(isExpanded ? 180 : 0)
                    )
            }
            .foregroundStyle(palette.ink)
        }
    }

    // MARK: - Progress Sticker

    var progressSticker: some View {
        ZStack {
            Circle()
                .fill(Theme.surface.opacity(0.7))

            Circle()
                .stroke(palette.ink.opacity(0.1), lineWidth: 5)
                .padding(6)

            Circle()
                .trim(from: 0, to: subject.fraction)
                .stroke(
                    palette.ink,
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .padding(6)

            VStack(spacing: 0) {
                if finished {
                    Image(systemName: "checkmark")
                        .scaledFont(20, weight: .bold)
                } else {
                    Text("\(percent)%")
                        .scaledFont(17, weight: .heavy, maxScale: 1.15)
                        .contentTransition(.numericText())

                    Text(
                        overviewTitle == "Whole month"
                        ? "THIS MONTH"
                        : "THIS WEEK"
                    )
                    .scaledFont(6, weight: .bold, maxScale: 1.15)
                    .tracking(0.3)
                }
            }
            .foregroundStyle(palette.ink)
        }
        .frame(width: 65, height: 65)
        .rotationEffect(
            .degrees(reduceMotion || isExpanded ? 0 : 7)
        )
        .accessibilityHidden(true)
    }
}
