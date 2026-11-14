import SwiftUI

extension Theme {
    static let linen       = Color.adaptive(0xF8F6F0, 0x171719)
    static let cardBorder  = Color.adaptive(0xEFECE6, 0x333236)
    static let obsidian    = Color.adaptive(0x1A1A1A, 0xF5F5F7)
    static let systemGray  = Color.adaptive(0x8E8E93, 0xA4A3AA)
    static let pillFill    = Color.adaptive(0xF2F2F7, 0x29292D)
    static let checkBorder = Color.adaptive(0xD1D5DB, 0x56535D)
    static let insetRadius: CGFloat = 24
}

/// White inset card: 1pt hairline border, 24pt radius.
struct InsetCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.surface, in: .rect(cornerRadius: Theme.insetRadius))
            .roundedStroke(Theme.cardBorder, cornerRadius: Theme.insetRadius, lineWidth: 1)
    }
}

extension View {
    func insetCard() -> some View { modifier(InsetCardStyle()) }
}

struct SetupHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold()).foregroundStyle(Theme.obsidian)
            if let subtitle {
                Text(subtitle).foregroundStyle(Theme.systemGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    /// Strokes a rounded border using the modern `.rect(cornerRadius:)` shape.
    /// Pass `Color.clear` to hide the border while keeping layout stable.
    func roundedStroke<S: ShapeStyle>(_ style: S, cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        overlay {
            let shape: RoundedRectangle = .rect(cornerRadius: cornerRadius)
            shape.stroke(style, lineWidth: lineWidth)
        }
    }
}
