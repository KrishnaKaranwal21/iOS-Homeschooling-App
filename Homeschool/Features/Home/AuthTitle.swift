import SwiftUI

/// Heavy title plus muted subtitle, matching the onboarding typography.
struct AuthTitle: View {
    let title: String
    let subtitle: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .scaledFont(34, weight: .heavy)
                .tracking(-1.2)
                .foregroundStyle(Theme.ink)
            subtitle
                .scaledFont(17)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
