import SwiftUI

// MARK: - Color extensions

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

// MARK: - Theme

/// The app's palette and layout constants.
///
/// Learnook is **light-appearance only by design**: its pastel illustrations, cards and mascot were drawn
/// against a warm off-white page, and many screens pair these tokens with inline colours. The light lock is set
/// in `HomeschoolApp` (`preferredColorScheme`) and in the build settings (`UIUserInterfaceStyle = Light`).
/// Supporting Dark Mode means giving every token below (and the inline colours in `Features/`) a dark variant,
/// ideally as colour sets in `Assets.xcassets`, and then removing both locks.
enum Theme {
    static let background  = Color(hex: 0xFAFAF8)
    static let surface     = Color(hex: 0xFFFFFF)
    static let lavender    = Color(hex: 0xD0C8FA)
    static let lime        = Color(hex: 0xE6F56E)
    static let coral       = Color(hex: 0xF0937E)
    static let ink         = Color(hex: 0x1B1D1C)
    static let barDark     = Color(hex: 0x2E2F30)
    static let muted       = Color(hex: 0x6B6B6B)
    static let dotInactive = Color(hex: 0xD9D9D6)
    static let buttonFill  = Color(hex: 0x1B1D1C)
    static let buttonText  = Color.white
    static let accent     = Color(hex: 0x7457C8)
    static let loadingFill = Color(hex: 0xEEEEF0)
    static let accentFill  = Color(hex: 0x7561D2)
    static let warmText    = Color(hex: 0x9C4A4B)

    // MARK: - Additional tones

    static let pink      = Color(hex: 0xF7C9C9)
    static let pinkLight = Color(hex: 0xFFF0F0)
    static let yellow    = Color(hex: 0xFFF7B0)
    static let field     = Color(hex: 0xF0F0F3)
    static let secondary = Color(hex: 0x6E6E78)

    enum Radius { static let card: CGFloat = 24, small: CGFloat = 14 }
    enum Spacing { static let s: CGFloat = 8, m: CGFloat = 16, l: CGFloat = 24 }
}

// MARK: - Surfaces and neutrals

extension Theme {
    static let linen       = Color(hex: 0xF8F6F0)
    static let cardBorder  = Color(hex: 0xEFECE6)
    static let obsidian    = Color(hex: 0x1A1A1A)
    static let systemGray  = Color(hex: 0x8E8E93)
    static let pillFill    = Color(hex: 0xF2F2F7)
    static let checkBorder = Color(hex: 0xD1D5DB)
    static let insetRadius: CGFloat = 24
}

// MARK: - Gather and tab bar

extension Theme {
    /// Purple-tinted greys and fills used on the Gather screens.
    static let gatherText   = Color(hex: 0x77748F)
    static let gatherAccent = Color(hex: 0x3D2FA0)
    static let lilac        = Color(hex: 0xEFEBFC)
    static let lilacBorder  = Color(hex: 0xDDD7F5)
    static let chipFill     = Color(hex: 0xF0EFF8)

    /// Tab bar colours, the same on every tab.
    static let tabSelected     = Color(hex: 0x6F6A9A)
    static let tabIconInactive = Color(hex: 0xB5AED0)
    static let tabLabelInactive = Color(hex: 0x8E8E93)
    /// Unselected tab icon and label: darker than the old lilac, still lighter than `tabSelected`.
    static let tabUnselectedIcon  = Color(hex: 0x9A94BA)
    static let tabUnselectedLabel = Color(hex: 0x8A85AA)
}
