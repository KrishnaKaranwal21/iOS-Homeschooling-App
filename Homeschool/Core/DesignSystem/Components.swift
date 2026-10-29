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
