import SwiftUI

/// One onboarding page: big title, lavender card, then a short caption.
struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Environment(\.isLandscape) private var isLandscape

    var body: some View {
        if sizeClass == .regular { widePage } else { phonePage }
    }

    // MARK: iPad: centred, with a larger card

    private var widePage: some View {
        Group {
            if isLandscape {
                HStack(spacing: 72) {
                    VStack(alignment: .leading, spacing: 20) {
                        wideTitle(.leading)
                        wideSubtitle(.leading)
                    }
                    .frame(maxWidth: 460, alignment: .leading)
                    wideCard
                }
            } else {
                VStack(spacing: 36) {
                    wideTitle(.center)
                    wideCard
                    wideSubtitle(.center)
                }
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }

    private func wideTitle(_ alignment: TextAlignment) -> some View {
        Text(page.title)
            .scaledFont(46, weight: .bold, maxScale: 1.2)
            .tracking(-1.8)
            .lineSpacing(-6)
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(alignment)
    }

    private func wideSubtitle(_ alignment: TextAlignment) -> some View {
        VStack(spacing: 12) {
            Text(page.subtitle)
                .scaledFont(18, maxScale: 1.3)
                .foregroundStyle(Theme.muted)
            if let footnote = page.footnote {
                HStack(spacing: 10) {
                    if let icon = page.footnoteIcon {
                        Image(systemName: icon).scaledFont(14, maxScale: 1.3)
                    }
                    Text(footnote).scaledFont(15, maxScale: 1.3)
                }
                .foregroundStyle(Theme.muted)
            }
        }
        .multilineTextAlignment(alignment)
        .frame(maxWidth: 520)
    }

    /// The phone card, drawn at its phone size and scaled up so nothing inside it gets lost.
    private var wideCard: some View {
        card
            .frame(width: 345, height: 300)
            .scaleEffect(1.32)
            .frame(width: 456, height: 396)
            .background(Theme.lavender, in: .rect(cornerRadius: 48))
            .clipShape(.rect(cornerRadius: 48))
    }

    // MARK: iPhone

    private var phonePage: some View {
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
                .background(Theme.lavender, in: .rect(cornerRadius: 40))
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
