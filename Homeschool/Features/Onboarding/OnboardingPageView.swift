import SwiftUI

/// One onboarding page: big title, lavender card, then a short caption.
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(page.title)
                .scaledFont(40, weight: .bold, maxScale: 1.3)
                .tracking(-1.6)
                .lineSpacing(-6)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 26)
                .padding(.top, 28)

            card
                .frame(height: 300)
                .background(Theme.lavender, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text(page.subtitle)
                    .scaledFont(16, maxScale: 1.3)
                    .foregroundStyle(Theme.muted)

                if let footnote = page.footnote {
                    HStack(spacing: 10) {
                        if let icon = page.footnoteIcon {
                            Image(systemName: icon).scaledFont(13, maxScale: 1.3)
                        }
                        Text(footnote).scaledFont(14, maxScale: 1.3)
                    }
                    .foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 36)

            Spacer(minLength: 0)
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
