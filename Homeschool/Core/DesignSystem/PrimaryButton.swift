import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = "arrow.right"
    var style: Style = .dark
    let action: () -> Void
    enum Style { case dark, light }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let systemImage { Image(systemName: systemImage) }
            }
            .padding(.horizontal, 24).frame(height: 56)
            .foregroundStyle(style == .dark ? .white : Theme.ink)
            .background(style == .dark ? Theme.ink : .white, in: Capsule())
        }
    }
}
