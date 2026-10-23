import SwiftUI

/// Look of the main call-to-action: full-width capsule with the title centred.
struct PrimaryButtonLabel: View {
    let title: String
    var style: PrimaryButton.Style = .dark
    /// Solid grey look for "not ready yet". The button stays tappable.
    var isDimmed = false

    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
            .contentShape(Capsule())
    }

    private var foreground: Color {
        if isDimmed { return Color.white }
        return style == .dark ? Color.white : Theme.ink
    }

    private var background: Color {
        if isDimmed { return Color(hex: 0xAEAEB2) }
        return style == .dark ? Theme.ink : Color.white
    }
}

struct PrimaryButton: View {
    enum Style { case dark, light }

    let title: String
    var style: Style = .dark
    var isDimmed = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PrimaryButtonLabel(title: title, style: style, isDimmed: isDimmed)
        }
        .buttonStyle(.plain)
    }
}
