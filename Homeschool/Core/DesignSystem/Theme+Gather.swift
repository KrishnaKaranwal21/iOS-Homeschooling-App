import SwiftUI

extension Theme {
    /// Purple-tinted greys and fills used on the Gather screens.
    static let gatherText   = Color.adaptive(0x77748F, 0xA7A3B3)
    static let gatherAccent = Color.adaptive(0x3D2FA0, 0xBBA4FF)
    static let lilac        = Color.adaptive(0xEFEBFC, 0x2D273D)
    static let lilacBorder  = Color.adaptive(0xDDD7F5, 0x40384F)
    static let chipFill     = Color.adaptive(0xF0EFF8, 0x28252F)

    /// Tab bar colours, the same on every tab.
    static let tabSelected     = Color.adaptive(0x6F6A9A, 0xBBA4FF)
    static let tabIconInactive = Color.adaptive(0xB5AED0, 0x81798F)
    static let tabLabelInactive = Color.adaptive(0x8E8E93, 0xA4A3AA)
    /// Unselected tab icon and label: darker than the old lilac, still lighter than `tabSelected`.
    static let tabUnselectedIcon  = Color.adaptive(0x9A94BA, 0xA49BAD)
    static let tabUnselectedLabel = Color.adaptive(0x8A85AA, 0xADA5BC)
}

/// White rounded box with a hairline border, used for form fields on the Gather screens.
struct GatherFieldStyle: ViewModifier {
    var minHeight: CGFloat = 52

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: 16))
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
