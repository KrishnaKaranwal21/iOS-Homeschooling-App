import SwiftUI

struct Card<Content: View>: View {
    var color: Color = .white
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(Theme.Spacing.m).frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

struct Chip: View {
    let title: String
    var systemImage: String? = nil
    var selected = false
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
            if selected { Image(systemName: "checkmark") }
        }
        .font(.subheadline).padding(.horizontal, 14).padding(.vertical, 10)
        .background(selected ? Theme.pink : Theme.field, in: Capsule())
    }
}

struct Eyebrow: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View { Text(text.uppercased()).font(.caption2).tracking(0.8).foregroundStyle(Theme.secondary) }
}

struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold())
            if let subtitle { Text(subtitle).foregroundStyle(Theme.secondary) }
        }
    }
}

struct Mascot: View {
    var size: CGFloat = 80
    var body: some View {
        ZStack {
            Circle().fill(Theme.coral.opacity(0.85))
            Image(systemName: "face.smiling.inverse").font(.system(size: size * 0.5)).foregroundStyle(.white)
        }.frame(width: size, height: size)
    }
}

struct AvatarView: View {
    let initials: String
    var color: Color = Theme.lavender
    var size: CGFloat = 48
    var body: some View {
        Text(initials).font(.system(size: size * 0.36, weight: .semibold))
            .frame(width: size, height: size).background(color, in: Circle())
    }
}

// MARK: - Titles that appear when the page scrolls

/// For pages with their own big heading and no navigation bar: once the content scrolls under the
/// status bar, a blurred bar with the page title fades in, like the collapsed bar on Profile.
/// Apply it directly to the `ScrollView`.
private struct ScrollTitleBar: ViewModifier {
    let title: String
    @State private var isScrolled = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 40
            } action: { _, scrolled in
                isScrolled = scrolled
            }
            .overlay(alignment: .top) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.bar)   // reaches up under the status bar
                    .opacity(isScrolled ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isScrolled)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

/// For pages that keep their navigation bar: the title is hidden while the heading is on screen,
/// and fades into the bar once the page has scrolled. Apply it directly to the `ScrollView`.
private struct ScrollNavigationTitle: ViewModifier {
    let title: String
    @State private var isScrolled = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 90
            } action: { _, scrolled in
                isScrolled = scrolled
            }
            .toolbar {
                // Always in the bar, only its opacity changes, so nothing around it moves.
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .opacity(isScrolled ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isScrolled)
                        .accessibilityHidden(!isScrolled)
                }
            }
    }
}

extension View {
    func scrollTitleBar(_ title: String) -> some View { modifier(ScrollTitleBar(title: title)) }
    func scrollNavigationTitle(_ title: String) -> some View { modifier(ScrollNavigationTitle(title: title)) }
}

// MARK: - Profile building blocks
// Shared by the family's own Profile and by a parent's community profile, so both look like one system.

struct ProfileHeroChip: Identifiable {
    let id = UUID()
    let symbol: String
    let text: String
}

/// The big lavender card at the top of a profile: avatar, name, a line of detail, small facts, and the mascot.
struct ProfileHero: View {
    let initial: String
    /// Name of a photo in the asset catalog. Without it the initial is shown.
    var photoName: String? = nil
    let title: String
    let subtitle: String
    var chips: [ProfileHeroChip] = []
    /// A round button in the corner, such as "Edit".
    var actionSymbol: String? = nil
    var actionLabel = ""
    var action: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .scaledFont(26, weight: .heavy, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
                if let actionSymbol {
                    Button(action: action) {
                        Image(systemName: actionSymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Theme.chipFill))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(actionLabel)
                }
            }

            if !chips.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(chips) { chip in
                        HStack(spacing: 6) {
                            Image(systemName: chip.symbol)
                            Text(chip.text)
                        }
                        .scaledFont(13, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.chipFill))
                    }
                }
                .padding(.trailing, 80)   // room for the mascot
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(Color.white, in: .rect(cornerRadius: 28))
        .overlay(alignment: .bottomTrailing) {
            Image("HomeMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 76)
                .padding(.trailing, 14)
                .accessibilityHidden(true)
        }
        .clipShape(.rect(cornerRadius: 28))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 28)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(Theme.lavender)
            Text(initial)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.ink)
            if let photoName {
                Image(photoName).resizable().scaledToFill()
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

/// A white rounded card with an optional icon and heading.
struct ProfileCard<Content: View>: View {
    var symbol: String? = nil
    var title: String? = nil
    var subtitle: String? = nil
    var background: Color = .white
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 12) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.gatherAccent)
                            .frame(width: 34, height: 34)
                            .background(Theme.lilac, in: .rect(cornerRadius: 11))
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .scaledFont(19, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                        if let subtitle {
                            Text(subtitle)
                                .scaledFont(13, maxScale: 1.3)
                                .foregroundStyle(Theme.gatherText)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: .rect(cornerRadius: 26))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 26)
    }
}

/// One line inside a card: icon, title, value, and a chevron when it can be tapped.
struct ProfileInfoRow: View {
    let symbol: String
    let title: String
    let value: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.gatherAccent)
                .frame(width: 32, height: 32)
                .background(Theme.lilac, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(title)
                .scaledFont(16, maxScale: 1.25)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 8)
            Text(value)
                .scaledFont(15, maxScale: 1.25)
                .foregroundStyle(Theme.gatherText)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.dotInactive)
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// A pill that can be switched on and off (interests, what to connect for, distances).
struct SelectableChip: View {
    let title: String
    let isOn: Bool
    var symbol: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isOn {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                } else if let symbol {
                    Image(systemName: symbol).font(.system(size: 12))
                }
                Text(title)
            }
            .scaledFont(15, weight: isOn ? .semibold : .regular, maxScale: 1.25)
            .foregroundStyle(isOn ? Theme.ink : Theme.gatherText)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(isOn ? Theme.lavender : Theme.chipFill))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A chip that only shows something (not tappable).
struct InfoChip: View {
    let title: String
    var tint: Color = Theme.lavender

    var body: some View {
        Text(title)
            .scaledFont(15, weight: .medium, maxScale: 1.25)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(tint))
    }
}

struct ProfileDivider: View {
    var body: some View {
        Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
    }
}
