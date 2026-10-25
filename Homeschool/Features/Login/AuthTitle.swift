import SwiftUI

/// Heavy title plus muted subtitle, matching the onboarding typography.
struct AuthTitle: View {
    let title: String
    let subtitle: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .pageTitle()
            subtitle
                .scaledFont(16, maxScale: 1.3)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
