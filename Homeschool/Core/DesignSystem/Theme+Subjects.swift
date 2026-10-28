import SwiftUI

extension Theme {
    static let linen       = Color(hex: 0xF8F6F0)
    static let cardBorder  = Color(hex: 0xEFECE6)
    static let obsidian    = Color(hex: 0x1A1A1A)
    static let systemGray  = Color(hex: 0x8E8E93)
    static let pillFill    = Color(hex: 0xF2F2F7)
    static let checkBorder = Color(hex: 0xD1D5DB)
    static let insetRadius: CGFloat = 24
}

/// White inset card: 1pt hairline border, 24pt radius.
struct InsetCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white, in: .rect(cornerRadius: Theme.insetRadius))
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
