import SwiftUI

/// Look of the main call-to-action: full-width capsule with the title centred.
/// Use it as `Button("Title") { ... }.buttonStyle(.primaryHomeschool)`.
struct PrimaryButtonStyle: ButtonStyle {
    enum Tone { case dark, light }

    var tone: Tone = .dark
    /// Solid grey look for "not ready yet". The button stays tappable.
    var isDimmed = false

    @Environment(\.uiScale) private var uiScale

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(uiScale > 1 ? .title3.weight(.semibold) : .headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: uiScale > 1 ? 62 : 56)
            .foregroundStyle(foreground)
            .background(background, in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var foreground: Color {
        if isDimmed { return Color.white }
        return tone == .dark ? Color.white : Theme.ink
    }

    private var background: Color {
        if isDimmed { return Color(hex: 0xAEAEB2) }
        return tone == .dark ? Theme.ink : Color.white
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryHomeschool: PrimaryButtonStyle { PrimaryButtonStyle() }

    static func primaryHomeschool(isDimmed: Bool) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isDimmed: isDimmed)
    }
}
