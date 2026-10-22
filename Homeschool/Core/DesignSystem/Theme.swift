import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum Theme {
    static let background  = Color(hex: 0xFAFAF8)
    static let lavender    = Color(hex: 0xD0C8FA)
    static let lime        = Color(hex: 0xE6F56E)
    static let coral       = Color(hex: 0xF0937E)
    static let ink         = Color(hex: 0x1B1D1C)
    static let barDark     = Color(hex: 0x2E2F30)
    static let muted       = Color(hex: 0x6B6B6B)
    static let dotInactive = Color(hex: 0xD9D9D6)

    // Used by the other screens
    static let pink      = Color(hex: 0xF7C9C9)
    static let yellow    = Color(hex: 0xFFF7B0)
    static let field     = Color(hex: 0xF0F0F3)
    static let secondary = Color(hex: 0x6E6E78)

    enum Radius { static let card: CGFloat = 24, small: CGFloat = 14 }
    enum Spacing { static let s: CGFloat = 8, m: CGFloat = 16, l: CGFloat = 24 }
}
