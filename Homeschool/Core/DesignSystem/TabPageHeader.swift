import SwiftUI

/// Shared metrics keep the five main page headings in the same position.
enum TabPageLayout {
    static let horizontalInset: CGFloat = 20
    static let topInset: CGFloat = 8
    static let headerHeight: CGFloat = 48
    static let headerContentWidth: CGFloat = 610
}

struct TabPageHeader<Actions: View>: View {
    let title: String
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .pageTitle()
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
            Spacer(minLength: 8)
            actions
        }
        .frame(minHeight: TabPageLayout.headerHeight)
        .frame(maxWidth: TabPageLayout.headerContentWidth)
        .frame(maxWidth: .infinity)
    }
}
