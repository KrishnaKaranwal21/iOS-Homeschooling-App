import SwiftUI

/// A fixed design size that still follows the user's Dynamic Type setting.
/// Use it instead of `.font(.system(size:))`, which never grows with the text-size setting.
/// `maxScale` stops very large accessibility sizes from breaking tight layouts.
struct ScaledFontModifier: ViewModifier {
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
        content.font(.system(size: min(scaledSize, size * maxScale), weight: weight))
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

extension View {
    func scaledFont(_ size: CGFloat, weight: Font.Weight = .regular, maxScale: CGFloat = 1.5) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, maxScale: maxScale))
    }
}
