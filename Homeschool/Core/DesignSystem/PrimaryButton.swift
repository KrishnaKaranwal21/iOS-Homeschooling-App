import SwiftUI

/// Look of the main call-to-action: full-width capsule with the title centred.
/// Use it as `Button("Title") { ... }.buttonStyle(.primaryHomeschool)`.
struct PrimaryButtonStyle: ButtonStyle {
    enum Tone { case dark, light }

    var tone: Tone = .dark
    /// Solid grey look for "not ready yet". The button stays tappable.
    var isDimmed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
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
