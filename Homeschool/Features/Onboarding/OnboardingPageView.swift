import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            card
                .frame(height: 370)
                .background(Theme.lavender, in: RoundedRectangle(cornerRadius: 40))
                .padding(.horizontal, 24)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 14) {
                Text(page.title)
                    .font(.system(size: 40, weight: .heavy))
                    .tracking(-1.6)
                    .lineSpacing(-6)
                    .foregroundStyle(Theme.ink)

                Text(page.subtitle)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 28)

            HStack(spacing: 10) {
                if let icon = page.footnoteIcon {
                    Image(systemName: icon).font(.system(size: 14))
                }
                Text(page.footnote).font(.system(size: 15))
            }
            .foregroundStyle(Theme.muted)
            .padding(.horizontal, 28)
        }
    }

    @ViewBuilder private var card: some View {
        switch page.kind {
        case .roadmap:     RoadmapCard()
        case .community:   CommunityCard()
        case .inspiration: InspirationCard()
        }
    }
}
