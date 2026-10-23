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
            .background(RoundedRectangle(cornerRadius: Theme.insetRadius, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: Theme.insetRadius, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1))
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
