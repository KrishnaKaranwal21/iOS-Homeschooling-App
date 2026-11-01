import SwiftUI

/// Presented above the tab bar, with a snapshot of the day's actual learning log.
struct DailyWrapUpView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var titleFocused: Bool
    @State private var appeared = false
    let summary: DayLearningSummary
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.48)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                ViewThatFits(in: .vertical) {
                    card
                    ScrollView { card }
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                }
                .frame(maxWidth: 390)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onContinue)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.45, dampingFraction: 0.83)) {
                appeared = true
            }
            titleFocused = true
        }
    }

    private var card: some View {
        VStack(spacing: 16) {
            Text("Learning, wrapped up.")
                .scaledFont(25, weight: .bold, maxScale: 1.25)
                .tracking(-0.5)
                .foregroundStyle(Color.adaptive(0x1E2923, 0xF5F5F7))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)

            Image("LearningCelebration")
                .resizable()
                .scaledToFit()
                .frame(height: 158)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("\(summary.minutes) min of learning logged")
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Color.adaptive(0x1E2923, 0xF5F5F7))
                Text("\(summary.activityCount) \(summary.activityCount == 1 ? "activity" : "activities") completed")
                    .scaledFont(13, maxScale: 1.25)
                    .foregroundStyle(WeekStyle.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12).padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.adaptive(0xDCD9FF, 0x3B3059), in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.8), lineWidth: 1))
            .accessibilityElement(children: .combine)

            Text("Now enjoy a little time with \(summary.childName).\nThe rest of the day is yours.")
                .scaledFont(14, maxScale: 1.25)
                .foregroundStyle(WeekStyle.secondary)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onContinue) {
                Text("Continue")
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.buttonFill, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("week.wrapUp.continue")
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.adaptive(0xEBEBF0, 0x242426), in: .rect(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(.white.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.14), radius: 30, y: 12)
    }
}
