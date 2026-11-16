import SwiftUI

// MARK: - InsetCardStyle

/// White inset card: 1pt hairline border, 24pt radius.
struct InsetCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.surface, in: .rect(cornerRadius: Theme.insetRadius))
            .roundedStroke(Theme.cardBorder, cornerRadius: Theme.insetRadius, lineWidth: 1)
    }
}

// MARK: - View extensions

extension View {
    func insetCard() -> some View { modifier(InsetCardStyle()) }
}

// MARK: - View extensions

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

// MARK: - GatherFieldStyle

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

// MARK: - View extensions

extension View {
    func gatherField(minHeight: CGFloat = 52) -> some View {
        modifier(GatherFieldStyle(minHeight: minHeight))
    }
}

// MARK: - GatherGlass

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

// MARK: - View extensions

extension View {
    func gatherGlass<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = true) -> some View {
        modifier(GatherGlass(shape: shape, tint: tint, interactive: interactive))
    }
}

// MARK: - GatherGlassContainer

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

// MARK: - HomeschoolSwitchStyle

/// Keep Apple's accessible switch and its native Liquid Glass rendering on iOS 26+.
struct HomeschoolSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) { configuration.label }
            .toggleStyle(.switch)
            .tint(Theme.tabSelected)
    }
}
