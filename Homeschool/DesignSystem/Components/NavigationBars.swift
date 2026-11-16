import SwiftUI

// MARK: - TranslucentBarBackground

/// The blurred bar behind a page title, like the collapsed bar in the iOS Settings app: the content
/// scrolls under it and shows through, blurred, with a hairline along the bottom. It reaches up
/// under the status bar.
struct TranslucentBarBackground: View {
    var showsDivider = true

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial.opacity(0.85))
            .overlay(alignment: .bottom) {
                if showsDivider {
                    Rectangle().fill(Color.primary.opacity(0.14)).frame(height: 0.5)
                }
            }
            .ignoresSafeArea(edges: .top)
    }
}

// MARK: - ScrollTitleBar

/// For pages with their own big heading and no navigation bar: once the content scrolls under the
/// status bar, a blurred bar with the page title fades in, like the collapsed bar on Profile.
/// Apply it directly to the `ScrollView`.
struct ScrollTitleBar: ViewModifier {
    let title: String
    @Environment(\.horizontalSizeClass) private var sizeClass
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
                    .background { TranslucentBarBackground() }
                    // On iPad the page has a real navigation bar, so this bar isn't needed.
                    .opacity(isScrolled && sizeClass != .regular ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isScrolled)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

// MARK: - ScrollBlurHeader

/// For pages with their own fixed header (back button, share, close ...): the header stays on top and
/// gets the same blurred bar as the collapsed bar in iOS Settings once the content scrolls under it.
struct ScrollBlurHeader<Bar: View>: ViewModifier {
    let bar: Bar
    @State private var scrollProgress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                let offsetY = geometry.contentOffset.y + geometry.contentInsets.top
                // A larger divisor makes the blur fade in more slowly.
                let progress = offsetY / 12.0
                return min(max(progress, 0), 1) // Clamp between 0 and 1
            } action: { _, progress in
                scrollProgress = progress
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                bar.background {
                    TranslucentBarBackground()
                        .opacity(scrollProgress) // Smooth continuous opacity
                }
            }
    }
}

// MARK: - ScrollNavigationTitle

/// For pages that keep their navigation bar: the title is hidden while the heading is on screen,
/// and fades into the bar once the page has scrolled. Apply it directly to the `ScrollView`.
struct ScrollNavigationTitle: ViewModifier {
    let title: String
    @Environment(\.horizontalSizeClass) private var sizeClass
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
                        // The centre of the bar belongs to the tab bar on iPad.
                        .opacity(isScrolled && sizeClass != .regular ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isScrolled)
                        .accessibilityHidden(!isScrolled || sizeClass == .regular)
                }
            }
    }
}

// MARK: - View extensions

extension View {
    func scrollTitleBar(_ title: String) -> some View { modifier(ScrollTitleBar(title: title)) }
    func scrollBlurHeader<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View { modifier(ScrollBlurHeader(bar: bar())) }
    func scrollNavigationTitle(_ title: String) -> some View { modifier(ScrollNavigationTitle(title: title)) }
}

// MARK: - TabPageLayout

/// Shared metrics keep the five main page headings in the same position.
enum TabPageLayout {
    static let horizontalInset: CGFloat = 20
    static let topInset: CGFloat = 8
    static let headerHeight: CGFloat = 48
    static let headerContentWidth: CGFloat = 610
}

// MARK: - TabPageHeader

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
