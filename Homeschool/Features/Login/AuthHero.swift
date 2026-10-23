import SwiftUI

/// Lavender rounded card used at the top of the login and verify screens.
/// Same card shape, ink / blush / coral circles and type as the onboarding pages.
struct AuthHero: View {
    let eyebrow: String
    var symbol: String = "person.2"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow)
                .font(.system(size: 14, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(Theme.ink)

            Spacer(minLength: 16)

            HStack(spacing: 14) {
                Circle().fill(Theme.ink)
                    .frame(width: 54, height: 54)
                    .overlay(Image(systemName: "face.smiling")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.white))
                Circle().fill(Color(hex: 0xFFC8C9))
                    .frame(width: 54, height: 54)
                    .overlay(Image(systemName: symbol)
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.ink))
                Circle().fill(Theme.coral)
                    .frame(width: 54, height: 54)
                    .overlay(Image(systemName: "heart")
                        .font(.system(size: 21))
                        .foregroundStyle(Theme.ink))
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(Theme.lavender, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
    }
}

/// Heavy title plus muted subtitle, matching the onboarding typography.
struct AuthTitle: View {
    let title: String
    let subtitle: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 34, weight: .heavy))
                .tracking(-1.2)
                .foregroundStyle(Theme.ink)
            subtitle
                .font(.system(size: 17))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
