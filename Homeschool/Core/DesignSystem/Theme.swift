import SwiftUI
import UIKit

extension Color {
    /// Resolves against the view's appearance, including an in-app override.
    static func adaptive(_ light: UInt, _ dark: UInt) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
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
    static let background  = Color.adaptive(0xFAFAF8, 0x101012)
    static let surface     = Color.adaptive(0xFFFFFF, 0x202022)
    static let lavender    = Color.adaptive(0xD0C8FA, 0x3B3059)
    static let lime        = Color.adaptive(0xE6F56E, 0x3A4324)
    static let coral       = Color.adaptive(0xF0937E, 0x57392F)
    static let ink         = Color.adaptive(0x1B1D1C, 0xF5F5F7)
    static let barDark     = Color.adaptive(0x2E2F30, 0xA99BDA)
    static let muted       = Color.adaptive(0x6B6B6B, 0xA4A3AA)
    static let dotInactive = Color.adaptive(0xD9D9D6, 0x424247)
    static let buttonFill  = Color.adaptive(0x1B1D1C, 0x795DD0)
    static let buttonText  = Color.white
    static let accent     = Color.adaptive(0x7457C8, 0xBBA4FF)
    static let loadingFill = Color.adaptive(0xEEEEF0, 0x272729)
    static let accentFill  = Color(hex: 0x7561D2)
    static let warmText    = Color.adaptive(0x9C4A4B, 0xF0ADAA)

    // Used by the other screens
    static let pink      = Color.adaptive(0xF7C9C9, 0x482D38)
    static let pink_light = Color.adaptive(0xFFF0F0, 0x3A292B)
    static let yellow    = Color.adaptive(0xFFF7B0, 0x403A25)
    static let field     = Color.adaptive(0xF0F0F3, 0x232325)
    static let secondary = Color.adaptive(0x6E6E78, 0xA4A3AA)

    enum Radius { static let card: CGFloat = 24, small: CGFloat = 14 }
    enum Spacing { static let s: CGFloat = 8, m: CGFloat = 16, l: CGFloat = 24 }
}
