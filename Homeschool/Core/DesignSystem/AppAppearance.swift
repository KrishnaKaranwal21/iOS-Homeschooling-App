import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    static let storageKey = "app.appearance"
    case system, light, dark
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }
    var detail: String {
        switch self {
        case .system: "Follow your device’s appearance automatically."
        case .light: "A light canvas with soft, playful colors."
        case .dark: "Charcoal surfaces with a little violet glow."
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage(AppAppearance.storageKey) private var selected = AppAppearance.system.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Make yourself at home.")
                .font(.title3.weight(.semibold)).foregroundStyle(Theme.ink)
            Text("Choose how Homeschool looks. System changes with your device, including its automatic day and night schedule.")
                .foregroundStyle(Theme.secondary)
            VStack(spacing: 0) {
                ForEach(AppAppearance.allCases) { appearance in
                    Button { selected = appearance.rawValue } label: {
                        HStack(spacing: 16) {
                            Image(systemName: appearance.symbol)
                                .font(.system(size: 22)).foregroundStyle(Theme.accent)
                                .frame(width: 48, height: 48)
                                .background(Theme.lilac, in: .rect(cornerRadius: 15))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(appearance.title).font(.headline).foregroundStyle(Theme.ink)
                                Text(appearance.detail).font(.subheadline).foregroundStyle(Theme.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: selected == appearance.rawValue ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 23)).foregroundStyle(selected == appearance.rawValue ? Theme.accent : Theme.checkBorder)
                        }
                        .padding(18).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected == appearance.rawValue ? .isSelected : [])
                    .accessibilityIdentifier("appearance.\(appearance.rawValue)")
                    if appearance != .dark { Divider().padding(.leading, 82) }
                }
            }
            .background(Theme.surface, in: .rect(cornerRadius: 26))
            .roundedStroke(Theme.lilacBorder, cornerRadius: 26)
        }
    }
}
