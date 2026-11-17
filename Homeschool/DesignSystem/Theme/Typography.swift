import SwiftUI

// MARK: - View extensions

/// One set of text styles for every screen, so titles look the same everywhere.
///
/// - `pageTitle`: the big title at the top of a page (Gatherings, Chats, Profile, Registration...)
/// - `pageSubtitle`: the grey line under it
/// - `sectionTitle`: a heading inside a page ("Explore more", "Your children")
/// - `cardTitle`: a heading inside a card
/// - `detailTitle`: the name on a detail page (an event, a chat)
/// - `rowTitle` / `rowDetail`: the two lines of an information row
/// - `bodyText` / `caption`: paragraphs and small notes
extension View {
    func detailTitle() -> some View {
        scaledFont(28, weight: .heavy, maxScale: 1.15)
            .tracking(-0.8)
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    func rowTitle() -> some View {
        scaledFont(16, weight: .medium, maxScale: 1.25)
            .foregroundStyle(Theme.ink)
    }

    func rowDetail() -> some View {
        scaledFont(14, maxScale: 1.25)
            .foregroundStyle(Theme.secondary)
    }

    func bodyText() -> some View {
        scaledFont(15, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
    }

    func caption() -> some View {
        scaledFont(13, maxScale: 1.25)
            .foregroundStyle(Theme.secondary)
    }

    func pageTitle() -> some View {
        scaledFont(32, weight: .heavy, maxScale: 1.15)
            .tracking(-1)
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    func pageSubtitle() -> some View {
        scaledFont(16, maxScale: 1.3)
            .foregroundStyle(Theme.secondary)
    }

    func sectionTitle() -> some View {
        scaledFont(22, weight: .heavy, maxScale: 1.2)
            .tracking(-0.5)
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    func cardTitle() -> some View {
        scaledFont(18, weight: .heavy, maxScale: 1.15)
            .tracking(-0.3)
            .foregroundStyle(Theme.ink)
    }
}

// MARK: - UIScaleKey

struct UIScaleKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }

// MARK: - IsLandscapeKey

struct IsLandscapeKey: EnvironmentKey { static let defaultValue = false }

// MARK: - EnvironmentValues extensions

extension EnvironmentValues {
    /// 1 on iPhone. A little more on iPad, so text keeps its proportion on a big screen.
    var uiScale: CGFloat {
        get { self[UIScaleKey.self] }
        set { self[UIScaleKey.self] = newValue }
    }

    /// True while the window is wider than it is tall.
    var isLandscape: Bool {
        get { self[IsLandscapeKey.self] }
        set { self[IsLandscapeKey.self] = newValue }
    }
}

// MARK: - ScaledFontModifier

/// A fixed design size that still follows the user's Dynamic Type setting.
/// Use it instead of `.font(.system(size:))`, which never grows with the text-size setting.
/// `maxScale` stops the standard text sizes from breaking tight layouts. Once the person turns on one of the
/// accessibility sizes the cap is lifted to at least `accessibilityMaxScale`, so the people who need large
/// text most are not held back by it.
struct ScaledFontModifier: ViewModifier {
    /// Smallest cap used at accessibility text sizes, whatever `maxScale` the caller asked for.
    static let accessibilityMaxScale: CGFloat = 2.0

    @Environment(\.uiScale) private var uiScale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var scaledSize: CGFloat
    private let size: CGFloat
    private let weight: Font.Weight
    private let maxScale: CGFloat

    init(size: CGFloat, weight: Font.Weight, maxScale: CGFloat) {
        self.size = size
        self.weight = weight
        self.maxScale = maxScale
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: Self.textStyle(for: size))
    }

    func body(content: Content) -> some View {
        let cap = dynamicTypeSize.isAccessibilitySize ? max(maxScale, Self.accessibilityMaxScale) : maxScale
        return content.font(.system(size: min(scaledSize, size * cap) * uiScale, weight: weight))
    }

    /// Larger design sizes scale like titles, smaller ones like captions.
    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 32...: return .largeTitle
        case 24..<32: return .title
        case 20..<24: return .title3
        case 16..<20: return .body
        case 13..<16: return .footnote
        default: return .caption
        }
    }
}

// MARK: - View extensions

extension View {
    func scaledFont(_ size: CGFloat, weight: Font.Weight = .regular, maxScale: CGFloat = 1.5) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, maxScale: maxScale))
    }
}
