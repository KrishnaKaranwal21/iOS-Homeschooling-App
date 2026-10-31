import SwiftUI

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

/// White rounded box with a hairline border, used for form fields on the Gather screens.
struct GatherFieldStyle: ViewModifier {
    var minHeight: CGFloat = 52

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(Color.white, in: .rect(cornerRadius: 16))
            .roundedStroke(Theme.cardBorder, cornerRadius: 16, lineWidth: 1)
    }
}

extension View {
    func gatherField(minHeight: CGFloat = 52) -> some View {
        modifier(GatherFieldStyle(minHeight: minHeight))
    }
}

// MARK: - Glass that works on every supported iOS

/// Liquid Glass on iOS 26 and newer, a frosted material on older versions.
struct GatherGlass<S: Shape>: ViewModifier {
    let shape: S
    var tint: Color?
    var interactive = true

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(glass, in: shape)
        } else {
            content
                .background { shape.fill(tint?.opacity(0.35) ?? Color.clear) }
                .background(.ultraThinMaterial, in: shape)
        }
    }

    @available(iOS 26, *)
    private var glass: Glass {
        var result = Glass.regular
        if let tint { result = result.tint(tint) }
        if interactive { result = result.interactive() }
        return result
    }
}

extension View {
    func gatherGlass<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = true) -> some View {
        modifier(GatherGlass(shape: shape, tint: tint, interactive: interactive))
    }
}

/// Groups nearby glass buttons on iOS 26 and newer. On older versions it just shows its content.
struct GatherGlassContainer<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
