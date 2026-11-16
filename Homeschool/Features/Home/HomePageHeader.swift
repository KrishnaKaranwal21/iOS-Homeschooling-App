import SwiftUI

/// A compact native-style title keeps the learner switcher next to Profile on both Home layouts.
struct HomePageHeader: View {
    @Environment(AppState.self) private var state
    let dateText: String
    let onAddChild: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            TabPageHeader(title: "Home") {
                ChildSwitcherMenu(onAddChild: onAddChild) {
                    HStack(spacing: 7) {
                        AvatarView(initials: String(state.child.displayName.prefix(1)).uppercased(),
                                   color: Theme.lavender, size: 26)
                        Text(state.child.displayName)
                            .scaledFont(14, weight: .medium, maxScale: 1.2)
                            .lineLimit(1).minimumScaleFactor(0.8)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.leading, 5).padding(.trailing, 12).frame(height: 36)
                    .gatherGlass(in: Capsule(), tint: Theme.lilac)
                }
                NavigationLink { ProfileView() } label: {
                    Image(systemName: "person")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                        .gatherGlass(in: Circle(), tint: Theme.lilac)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Profile")
            }
            .buttonStyle(.plain)

            Text(dateText)
                .scaledFont(14, maxScale: 1.3)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: TabPageLayout.headerContentWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
    }
}
