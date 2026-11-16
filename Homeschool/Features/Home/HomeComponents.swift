import SwiftUI

// MARK: - HomeSubjectSelection

struct HomeSubjectSelection: Identifiable {
    let activity: WeekActivity
    var id: WeekActivity.ID { activity.id }
}

// MARK: - HomeSubjectPressStyle

struct HomeSubjectPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - HomePalette

enum HomePalette {
    /// Match the soft lavender surface and deeper purple text used by Progress.
    static let taskSurface = Color(hex: 0xE6DEFF)
    static let taskAccent = Color(hex: 0x4430A5)
    static let ink = Color(hex: 0x1B1D1C)
    static let onInk = Color(hex: 0xFFFFFF)
    static let coral = Color(hex: 0xB46759)
    /// Add-activity button: soft lavender disc, white ring, deep navy plus.
    static let plusFill = Color(hex: 0xE6E0FF)
    static let plusInk = Color(hex: 0x2B2559)
    static let plusRing = Color(hex: 0xFFFFFF)
}

// MARK: - HomePageHeader

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
                        Image(systemName: "chevron.down").accessibilityHidden(true)
                            .scaledFont(10, weight: .semibold)
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.leading, 5).padding(.trailing, 12).frame(height: 36)
                    .gatherGlass(in: Capsule(), tint: Theme.lilac)
                }
                NavigationLink { ProfileView() } label: {
                    Image(systemName: "person")
                        .scaledFont(18, weight: .regular)
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
